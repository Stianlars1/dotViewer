import Foundation
import CryptoKit
import AppKit

/// Disk-based cache for highlighted AttributedStrings.
/// Uses App Groups for persistence across QuickLook XPC terminations.
///
/// Performance optimizations:
/// - Synchronous reads for fast cache hits (<50ms target)
/// - Asynchronous writes to avoid blocking highlighting
/// - LRU cleanup runs only after writes, never during reads
final class DiskCache: @unchecked Sendable {
    static let shared = DiskCache()

    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024  // 100MB
    private let maxEntries: Int = 500
    private let fileManager = FileManager.default
    private let writeQueue = DispatchQueue(label: "no.skreland.dotViewer.diskCache.write", qos: .utility)

    /// Track writes to trigger cleanup periodically (every N writes)
    private var writeCount: Int = 0
    private let cleanupInterval: Int = 10
    private let cleanupLock = NSLock()

    /// Cache format version - increment when serialization format changes
    /// v1: NSKeyedArchiver (incompatible with SwiftUI AttributedString)
    /// v2: RTF encoding (works with all AttributedString attributes)
    private static let cacheVersion = 2
    private let versionFile = "cache_version"

    private init() {
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

        // Create directory if needed - with proper error handling
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            NSLog("[dotViewer Cache] Init - cache directory created: %@", cacheDirectory.path)
        } catch {
            NSLog("[dotViewer Cache] ERROR creating cache directory: %@", error.localizedDescription)
        }

        // Verify directory exists
        let exists = fileManager.fileExists(atPath: cacheDirectory.path)
        NSLog("[dotViewer Cache] Init - cache directory exists: %@", exists ? "YES" : "NO")
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
    func cacheKey(filePath: String, modificationDate: Date, theme: String, language: String?) -> String {
        let lang = language ?? "unknown"

        // Resolve "auto" theme to actual appearance so cache invalidates when appearance changes
        let resolvedTheme: String
        if theme == "auto" {
            // Determine dark mode using the most reliable API available
            // NSAppearance.currentDrawing() is available in macOS 12+ and works in XPC contexts
            // Fall back to NSApp?.effectiveAppearance for older APIs
            let appearance = NSAppearance.currentDrawing()
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            resolvedTheme = isDark ? "auto-dark" : "auto-light"
        } else {
            resolvedTheme = theme
        }

        let input = "\(filePath)|\(modificationDate.timeIntervalSince1970)|\(resolvedTheme)|\(lang)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Read (Synchronous for Performance)

    /// Get cached AttributedString from disk.
    /// SYNCHRONOUS - optimized for fast cache hits.
    /// Returns nil if not found or corrupted.
    func get(key: String) -> AttributedString? {
        let fileURL = cacheDirectory.appendingPathComponent(key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            // Read RTF data and decode to NSAttributedString
            let rtfData = try Data(contentsOf: fileURL)
            let nsAttrString = try NSAttributedString(
                data: rtfData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
            // Update access time for LRU (async to not block read)
            writeQueue.async {
                try? FileManager.default.setAttributes(
                    [.modificationDate: Date()],
                    ofItemAtPath: fileURL.path
                )
            }
            perfLog("[dotViewer Cache] Disk HIT for key: \(key.prefix(16))...")
            return AttributedString(nsAttrString)
        } catch {
            perfLog("[dotViewer Cache] Disk read error: \(error.localizedDescription)")
            // Remove corrupted file asynchronously
            writeQueue.async {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        return nil
    }

    // MARK: - Write (Asynchronous)

    /// Save AttributedString to disk.
    /// ASYNCHRONOUS - does not block the caller.
    func set(key: String, value: AttributedString) {
        // Debug: Verify set() is being called
        NSLog("[dotViewer Cache] set() called for key: %@", String(key.prefix(16)))

        writeQueue.async { [weak self] in
            guard let self = self else { return }

            let fileURL = self.cacheDirectory.appendingPathComponent(key)

            // Ensure directory exists before writing (fallback if init failed)
            if !self.fileManager.fileExists(atPath: self.cacheDirectory.path) {
                do {
                    try self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
                    NSLog("[dotViewer Cache] Created cache directory on write: %@", self.cacheDirectory.path)
                } catch {
                    NSLog("[dotViewer Cache] ERROR creating directory on write: %@", error.localizedDescription)
                    return
                }
            }

            do {
                // Convert SwiftUI AttributedString to NSAttributedString
                let nsAttrString = NSAttributedString(value)
                let range = NSRange(location: 0, length: nsAttrString.length)

                // Encode as RTF (avoids NSKeyedArchiver issues with SwiftUI attributes)
                guard let rtfData = nsAttrString.rtf(from: range, documentAttributes: [
                    .documentType: NSAttributedString.DocumentType.rtf
                ]) else {
                    NSLog("[dotViewer Cache] RTF encoding FAILED for key: %@", String(key.prefix(16)))
                    perfLog("[dotViewer Cache] RTF encoding failed for key: \(key.prefix(16))...")
                    return
                }

                // Debug: Log RTF data size
                NSLog("[dotViewer Cache] RTF data size: %d bytes", rtfData.count)

                try rtfData.write(to: fileURL, options: .atomic)

                // Debug: Confirm write completed
                NSLog("[dotViewer Cache] Write completed to: %@", fileURL.path)
                perfLog("[dotViewer Cache] Disk WRITE for key: \(key.prefix(16))... (\(rtfData.count) bytes)")

                // Trigger cleanup periodically
                self.incrementWriteAndCleanupIfNeeded()
            } catch {
                perfLog("[dotViewer Cache] Disk write error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cleanup

    /// Increment write counter and trigger cleanup if interval reached.
    private func incrementWriteAndCleanupIfNeeded() {
        cleanupLock.withLock {
            writeCount += 1
            if writeCount >= cleanupInterval {
                writeCount = 0
                // Already on writeQueue, safe to run cleanup inline
                performCleanup()
            }
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
                try? fileManager.removeItem(at: file.url)
                totalSize -= file.size
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
