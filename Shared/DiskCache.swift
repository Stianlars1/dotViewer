import Foundation
import CryptoKit

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

    private init() {
        // Use App Groups container for cross-process persistence
        // MUST match the identifier in entitlements files
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.stianlars1.dotViewer.shared"
        ) else {
            // Fallback to temporary directory - cache won't persist but app will still work
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("HighlightCache", isDirectory: true)
            try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            self.cacheDirectory = tempDir
            perfLog("[dotViewer Cache] WARNING: App Group container not available, using temp directory")
            return
        }

        cacheDirectory = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)
            .appendingPathComponent("HighlightCache", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        perfLog("[dotViewer Cache] DiskCache initialized at: \(cacheDirectory.path)")
    }

    // MARK: - Cache Key Generation

    /// Generate cache key from file metadata + theme + language.
    /// Key = SHA256(filePath + modificationDate + theme + language)
    /// This ensures cache invalidates when: file changes, file moves, theme changes, or language detection changes.
    func cacheKey(filePath: String, modificationDate: Date, theme: String, language: String?) -> String {
        let lang = language ?? "unknown"
        let input = "\(filePath)|\(modificationDate.timeIntervalSince1970)|\(theme)|\(lang)"
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
            let data = try Data(contentsOf: fileURL)
            let nsAttrString = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSAttributedString.self,
                from: data
            )
            if let nsAttrString = nsAttrString {
                // Update access time for LRU (async to not block read)
                writeQueue.async {
                    try? FileManager.default.setAttributes(
                        [.modificationDate: Date()],
                        ofItemAtPath: fileURL.path
                    )
                }
                perfLog("[dotViewer Cache] Disk HIT for key: \(key.prefix(16))...")
                return AttributedString(nsAttrString)
            }
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
        writeQueue.async { [weak self] in
            guard let self = self else { return }

            let fileURL = self.cacheDirectory.appendingPathComponent(key)

            do {
                let nsAttrString = NSAttributedString(value)
                let data = try NSKeyedArchiver.archivedData(
                    withRootObject: nsAttrString,
                    requiringSecureCoding: false
                )
                try data.write(to: fileURL, options: .atomic)
                perfLog("[dotViewer Cache] Disk WRITE for key: \(key.prefix(16))... (\(data.count) bytes)")

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
