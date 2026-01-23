import Foundation
import CryptoKit
import os
import AppKit

/// Disk-based cache for highlighted AttributedStrings.
/// Uses App Groups for persistence across QuickLook XPC terminations.
///
/// Performance optimizations:
/// - Synchronous reads for fast cache hits (<50ms target)
/// - Asynchronous writes to avoid blocking highlighting
/// - LRU cleanup runs only after writes, never during reads
///
/// Thread Safety (@unchecked Sendable justification):
/// This class is manually verified thread-safe through:
/// - `writeQueue`: Serial DispatchQueue for all write operations and cleanup
/// - `cleanupLock`: NSLock protecting writeCount state
/// - Read operations are inherently safe (filesystem reads from stable files)
/// - No mutable shared state is accessed without synchronization
final class DiskCache: @unchecked Sendable {
    static let shared = DiskCache()

    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024  // 100MB
    private let maxEntries: Int = 500
    private let fileManager = FileManager.default
    private let writeQueue = DispatchQueue(label: "no.skreland.dotViewer.diskCache.write", qos: .utility)

    /// Track writes to trigger cleanup periodically (every N writes)
    private struct CleanupState {
        var writeCount: Int = 0
        var lastCleanupTime: Date = .distantPast
    }
    private let cleanupInterval: Int = 10
    private let cleanupState: OSAllocatedUnfairLock<CleanupState>

    /// Rate limiting: Minimum time between cleanups (seconds)
    private let cleanupMinInterval: TimeInterval = 30.0

    /// Cache format version - increment when serialization format changes
    /// v1: NSKeyedArchiver (incompatible with SwiftUI AttributedString)
    /// v2: RTF encoding (works with all AttributedString attributes)
    /// v3: Binary plist encoding (5-15ms decode vs 50-200ms RTF)
    private static let cacheVersion = 3
    private let versionFile = "cache_version"

    private init() {
        cleanupState = OSAllocatedUnfairLock(initialState: CleanupState())

        // Quick Look extension sandbox cannot create directories in App Group container.
        // Use the extension's own Application Support directory instead.
        // Note: Cache won't be shared with main app, but will persist across QL sessions.
        let appSupportURLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)

        if let appSupportURL = appSupportURLs.first {
            cacheDirectory = appSupportURL
                .appendingPathComponent("HighlightCache", isDirectory: true)
        } else {
            // Fallback to temporary directory
            cacheDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("HighlightCache", isDirectory: true)
            perfLog("[dotViewer Cache] WARNING: Application Support not available, using temp directory")
        }

        // Create directory if needed
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            NSLog("[dotViewer Cache] ERROR creating cache directory: %@", error.localizedDescription)
        }

        perfLog("[dotViewer Cache] DiskCache initialized at: \(cacheDirectory.path)")

        // Migrate cache if version changed (clears old format entries)
        migrateCacheIfNeeded()
    }

    /// Check cache version and clear if format changed
    private func migrateCacheIfNeeded() {
        let versionFileURL = cacheDirectory.appendingPathComponent(versionFile)

        // Read current version
        var currentVersion = 0
        if let data = try? Data(contentsOf: versionFileURL),
           let str = String(data: data, encoding: .utf8),
           let version = Int(str) {
            currentVersion = version
        }

        // If version mismatch, clear cache and write new version
        if currentVersion != Self.cacheVersion {
            perfLog("[dotViewer Cache] Cache version mismatch (\(currentVersion) → \(Self.cacheVersion)), clearing old cache")

            // Clear all cached files (but not the version file)
            if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
                for file in files where file.lastPathComponent != versionFile {
                    try? fileManager.removeItem(at: file)
                }
            }

            // Write new version
            if let versionData = "\(Self.cacheVersion)".data(using: .utf8) {
                try? versionData.write(to: versionFileURL, options: .atomic)
            }

            perfLog("[dotViewer Cache] Cache cleared and version updated to \(Self.cacheVersion)")
        }
    }

    // MARK: - Cache Key Generation

    /// Generate cache key from file metadata + theme + language.
    /// Key = SHA256(filePath + modificationDate + theme + language)
    /// This ensures cache invalidates when: file changes, file moves, theme changes, or language detection changes.
    func cacheKey(filePath: String, modificationDate: Date, theme: String, language: String?, isDark: Bool) -> String {
        let lang = language ?? "unknown"

        // Resolve "auto" theme using the caller-provided isDark flag.
        // This avoids calling NSAppearance.currentDrawing() which returns
        // unreliable results on background GCD queues (no drawing context).
        let resolvedTheme: String
        if theme == "auto" {
            resolvedTheme = isDark ? "auto-dark" : "auto-light"
        } else {
            resolvedTheme = theme
        }

        let input = "\(filePath)|\(modificationDate.timeIntervalSince1970)|\(resolvedTheme)|\(lang)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Path Validation

    /// Validates that a cache key is safe to use as a filename.
    /// Defense in depth - sandbox provides primary protection, this adds logging.
    private func isValidCacheKey(_ key: String) -> Bool {
        // SHA256 hash should be exactly 64 hex characters
        guard key.count == 64 else { return false }

        // Should only contain hex characters
        let hexChars = CharacterSet(charactersIn: "0123456789abcdef")
        guard key.unicodeScalars.allSatisfy({ hexChars.contains($0) }) else { return false }

        // Paranoid check: no path traversal (shouldn't be possible with hex-only, but defense in depth)
        if key.contains("..") || key.contains("/") || key.contains("\\") { return false }

        return true
    }

    // MARK: - Binary Plist Serialization

    private struct CacheEntry: Codable {
        let text: String
        let runs: [ColorRun]

        struct ColorRun: Codable {
            let offset: Int
            let length: Int
            let r: Float, g: Float, b: Float, a: Float
        }
    }

    // MARK: - Read (Synchronous for Performance)

    /// Get cached AttributedString from disk.
    /// SYNCHRONOUS - optimized for fast cache hits.
    /// Returns nil if not found or corrupted.
    func get(key: String) -> AttributedString? {
        // Validate key before using as filename
        guard isValidCacheKey(key) else { return nil }

        let fileURL = cacheDirectory.appendingPathComponent(key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let entry = try PropertyListDecoder().decode(CacheEntry.self, from: data)

            // Reconstruct NSMutableAttributedString from text + color runs
            let mutableAttr = NSMutableAttributedString(string: entry.text)
            if !entry.runs.isEmpty {
                mutableAttr.beginEditing()
                for run in entry.runs {
                    let color = NSColor(
                        red: CGFloat(run.r), green: CGFloat(run.g),
                        blue: CGFloat(run.b), alpha: CGFloat(run.a)
                    )
                    let range = NSRange(location: run.offset, length: run.length)
                    if range.location + range.length <= mutableAttr.length {
                        mutableAttr.addAttribute(.foregroundColor, value: color, range: range)
                    }
                }
                mutableAttr.endEditing()
            }

            // Update access time for LRU (async to not block read)
            writeQueue.async {
                try? FileManager.default.setAttributes(
                    [.modificationDate: Date()],
                    ofItemAtPath: fileURL.path
                )
            }
            perfLog("[dotViewer Cache] Disk HIT for key: \(key.prefix(16))...")
            return AttributedString(mutableAttr)
        } catch {
            perfLog("[dotViewer Cache] Disk read error: \(error.localizedDescription)")
            // Remove corrupted file asynchronously
            writeQueue.async {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        return nil
    }

    // MARK: - Write (Fully Asynchronous)

    /// Save AttributedString to disk.
    /// FULLY ASYNCHRONOUS - encode + write happen on writeQueue.
    func set(key: String, value: AttributedString) {
        // Validate key before using as filename
        guard isValidCacheKey(key) else { return }

        // Extract color runs on the caller's thread (fast, no I/O)
        let nsAttrString = NSAttributedString(value)
        let text = nsAttrString.string
        let fullRange = NSRange(location: 0, length: nsAttrString.length)
        var runs: [CacheEntry.ColorRun] = []

        nsAttrString.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { attr, range, _ in
            guard let color = attr as? NSColor else { return }
            // Convert to sRGB for consistent storage
            guard let rgbColor = color.usingColorSpace(.sRGB) else { return }
            runs.append(CacheEntry.ColorRun(
                offset: range.location, length: range.length,
                r: Float(rgbColor.redComponent), g: Float(rgbColor.greenComponent),
                b: Float(rgbColor.blueComponent), a: Float(rgbColor.alphaComponent)
            ))
        }

        let entry = CacheEntry(text: text, runs: runs)
        let cacheDir = self.cacheDirectory

        writeQueue.async { [weak self] in
            guard let self = self else { return }

            // Ensure directory exists
            if !self.fileManager.fileExists(atPath: cacheDir.path) {
                do {
                    try self.fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
                } catch {
                    perfLog("[dotViewer Cache] ERROR creating directory on write: \(error.localizedDescription)")
                    return
                }
            }

            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .binary
                let data = try encoder.encode(entry)
                let fileURL = cacheDir.appendingPathComponent(key)
                try data.write(to: fileURL, options: .atomic)
                perfLog("[dotViewer Cache] Disk WRITE for key: \(key.prefix(16))... (\(data.count) bytes)")
            } catch {
                perfLog("[dotViewer Cache] Disk write error: \(error.localizedDescription)")
            }

            self.incrementWriteAndCleanupIfNeeded()
        }
    }

    // MARK: - Cleanup

    /// Increment write counter and trigger cleanup if interval reached.
    /// Cleanup is rate-limited to avoid frequent disk scans during rapid file navigation.
    private func incrementWriteAndCleanupIfNeeded() {
        let shouldCleanup = cleanupState.withLock { state -> Bool in
            state.writeCount += 1
            if state.writeCount >= cleanupInterval {
                // Check rate limiting - don't cleanup more often than cleanupMinInterval
                let now = Date()
                if now.timeIntervalSince(state.lastCleanupTime) >= cleanupMinInterval {
                    state.writeCount = 0
                    state.lastCleanupTime = now
                    return true
                }
            }
            return false
        }

        // Run cleanup OUTSIDE the lock to avoid blocking writes during I/O
        if shouldCleanup {
            performCleanup()
        }
    }

    /// Remove old entries if cache exceeds limits.
    /// Called on writeQueue, never blocks reads.
    private func performCleanup() {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )

            // Check total size and count
            var totalSize: Int = 0
            var fileInfos: [(url: URL, date: Date, size: Int)] = []

            for fileURL in files {
                let attrs = try fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                let size = attrs.fileSize ?? 0
                let date = attrs.contentModificationDate ?? Date.distantPast
                totalSize += size
                fileInfos.append((fileURL, date, size))
            }

            // If under limits, no cleanup needed
            if fileInfos.count <= maxEntries && totalSize <= maxCacheSize {
                return
            }

            perfLog("[dotViewer Cache] Cleanup: \(fileInfos.count) entries, \(totalSize / 1024)KB")

            // Sort by modification date (oldest first for LRU eviction)
            fileInfos.sort { $0.date < $1.date }

            // Remove oldest until under limits
            var removed = 0
            while (fileInfos.count - removed > maxEntries || totalSize > maxCacheSize) && removed < fileInfos.count {
                let file = fileInfos[removed]
                do {
                    try fileManager.removeItem(at: file.url)
                    totalSize -= file.size
                } catch {
                    // Non-critical: file may already be removed or locked
                }
                removed += 1
            }

            if removed > 0 {
                perfLog("[dotViewer Cache] Cleaned up \(removed) old entries")
            }
        } catch {
            perfLog("[dotViewer Cache] Cleanup error: \(error.localizedDescription)")
        }
    }

    /// Clear entire cache.
    func clear() {
        writeQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let files = try self.fileManager.contentsOfDirectory(
                    at: self.cacheDirectory,
                    includingPropertiesForKeys: nil
                )
                for file in files {
                    try? self.fileManager.removeItem(at: file)
                }
                perfLog("[dotViewer Cache] Cache cleared")
            } catch {
                perfLog("[dotViewer Cache] Clear error: \(error.localizedDescription)")
            }
        }
    }

    /// Get cache statistics.
    func stats() -> (entries: Int, sizeKB: Int) {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            var totalSize = 0
            for file in files {
                let attrs = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += attrs.fileSize ?? 0
            }
            return (files.count, totalSize / 1024)
        } catch {
            return (0, 0)
        }
    }
}
