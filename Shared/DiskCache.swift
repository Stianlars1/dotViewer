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
    private var writeCount: Int = 0
    private let cleanupInterval: Int = 10
    private let cleanupLock = NSLock()

    /// Rate limiting: Minimum time between cleanups (seconds)
    private let cleanupMinInterval: TimeInterval = 30.0
    private var lastCleanupTime: Date = .distantPast

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
            do {
                let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
                for file in files where file.lastPathComponent != versionFile {
                    do {
                        try fileManager.removeItem(at: file)
                    } catch {
                        NSLog("[dotViewer Cache] WARNING: Failed to remove old cache file %@: %@", file.lastPathComponent, error.localizedDescription)
                    }
                }
            } catch {
                NSLog("[dotViewer Cache] WARNING: Failed to enumerate cache directory during migration: %@", error.localizedDescription)
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

    // MARK: - Path Validation

    /// Validates that a cache key is safe to use as a filename.
    /// Defense in depth - sandbox provides primary protection, this adds logging.
    private func isValidCacheKey(_ key: String) -> Bool {
        // SHA256 hash should be exactly 64 hex characters
        guard key.count == 64 else {
            NSLog("[dotViewer Cache] WARNING: Invalid cache key length: %d (expected 64)", key.count)
            return false
        }

        // Should only contain hex characters
        let hexChars = CharacterSet(charactersIn: "0123456789abcdef")
        guard key.unicodeScalars.allSatisfy({ hexChars.contains($0) }) else {
            NSLog("[dotViewer Cache] WARNING: Cache key contains non-hex characters")
            return false
        }

        // Paranoid check: no path traversal (shouldn't be possible with hex-only, but defense in depth)
        if key.contains("..") || key.contains("/") || key.contains("\\") {
            NSLog("[dotViewer Cache] WARNING: Cache key contains path traversal attempt: %@", key.prefix(20) as CVarArg)
            return false
        }

        return true
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
            // Read RTF data and decode to NSAttributedString
            let rtfData = try Data(contentsOf: fileURL)
            let nsAttrString = try NSAttributedString(
                data: rtfData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
            // Update access time for LRU (async to not block read)
            writeQueue.async {
                do {
                    try FileManager.default.setAttributes(
                        [.modificationDate: Date()],
                        ofItemAtPath: fileURL.path
                    )
                } catch {
                    // Non-critical: LRU tracking may be slightly off, but cache still works
                    NSLog("[dotViewer Cache] DEBUG: Failed to update access time for %@: %@", key.prefix(16) as CVarArg, error.localizedDescription)
                }
            }
            perfLog("[dotViewer Cache] Disk HIT for key: \(key.prefix(16))...")
            return AttributedString(nsAttrString)
        } catch {
            perfLog("[dotViewer Cache] Disk read error: \(error.localizedDescription)")
            // Remove corrupted file asynchronously
            writeQueue.async {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    NSLog("[dotViewer Cache] Removed corrupted cache file: %@", key.prefix(16) as CVarArg)
                } catch {
                    NSLog("[dotViewer Cache] WARNING: Failed to remove corrupted cache file %@: %@", key.prefix(16) as CVarArg, error.localizedDescription)
                }
            }
        }

        return nil
    }

    // MARK: - Write (Asynchronous)

    /// Save AttributedString to disk.
    /// ASYNCHRONOUS - does not block the caller.
    func set(key: String, value: AttributedString) {
        // Validate key before using as filename
        guard isValidCacheKey(key) else {
            NSLog("[dotViewer Cache] set() rejected - invalid key")
            return
        }

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
    /// Cleanup is rate-limited to avoid frequent disk scans during rapid file navigation.
    private func incrementWriteAndCleanupIfNeeded() {
        var shouldCleanup = false

        cleanupLock.withLock {
            writeCount += 1
            if writeCount >= cleanupInterval {
                // Check rate limiting - don't cleanup more often than cleanupMinInterval
                let now = Date()
                if now.timeIntervalSince(lastCleanupTime) >= cleanupMinInterval {
                    writeCount = 0
                    lastCleanupTime = now
                    shouldCleanup = true
                }
            }
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
            var removalErrors = 0
            while (fileInfos.count - removed > maxEntries || totalSize > maxCacheSize) && removed < fileInfos.count {
                let file = fileInfos[removed]
                do {
                    try fileManager.removeItem(at: file.url)
                    totalSize -= file.size
                } catch {
                    removalErrors += 1
                    if removalErrors <= 3 { // Limit log spam
                        NSLog("[dotViewer Cache] WARNING: Failed to remove cache file during cleanup: %@", error.localizedDescription)
                    }
                }
                removed += 1
            }

            if removalErrors > 3 {
                NSLog("[dotViewer Cache] WARNING: %d additional cleanup errors suppressed", removalErrors - 3)
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
                var clearErrors = 0
                for file in files {
                    do {
                        try self.fileManager.removeItem(at: file)
                    } catch {
                        clearErrors += 1
                        if clearErrors <= 3 {
                            NSLog("[dotViewer Cache] WARNING: Failed to clear cache file %@: %@", file.lastPathComponent, error.localizedDescription)
                        }
                    }
                }
                if clearErrors > 3 {
                    NSLog("[dotViewer Cache] WARNING: %d additional clear errors suppressed", clearErrors - 3)
                }
                perfLog("[dotViewer Cache] Cache cleared (\(clearErrors) errors)")
            } catch {
                NSLog("[dotViewer Cache] ERROR: Failed to enumerate cache directory for clear: %@", error.localizedDescription)
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
