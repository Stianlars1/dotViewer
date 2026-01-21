---
phase: P3-persistent-cache
plan: 01
type: execute
wave: 1
depends_on: ["P2-01"]
files_modified:
  - Shared/DiskCache.swift (new)
  - Shared/HighlightCache.swift
autonomous: true
---

<objective>
Design and implement a two-tier cache system (memory + disk) that persists highlighted content across QuickLook XPC terminations.

Purpose: QuickLook extensions run as XPC services that get terminated by the system. Current in-memory cache is lost every time. Disk cache ensures files only need highlighting ONCE.

Output: DiskCache.swift with persistent storage using App Groups.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/milestones/v1.1-performance-ROADMAP.md
@.planning/phases/P1-diagnostics/DIAGNOSTICS.md
@Shared/HighlightCache.swift
@Shared/SharedSettings.swift
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create DiskCache.swift with App Groups storage</name>
  <files>Shared/DiskCache.swift</files>
  <action>
Create a new file `Shared/DiskCache.swift` with a disk-based cache implementation.

**Cache Key Strategy:**
- Key = SHA256(filePath + fileModificationDate + themeIdentifier)
- This ensures cache invalidates when: file changes, file moves, or theme changes

**Storage Location:**
- Use App Groups container: `group.no.skreland.dotViewer`
- Cache directory: `{container}/Library/Caches/HighlightCache/`

**Implementation:**

```swift
import Foundation
import CryptoKit

/// Disk-based cache for highlighted AttributedStrings
/// Uses App Groups for persistence across QuickLook XPC terminations
final class DiskCache: @unchecked Sendable {
    static let shared = DiskCache()

    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024  // 100MB
    private let maxEntries: Int = 500
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "no.skreland.dotViewer.diskCache", qos: .utility)

    private init() {
        // Use App Groups container for cross-process persistence
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.no.skreland.dotViewer"
        ) else {
            fatalError("App Group container not available")
        }

        cacheDirectory = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)
            .appendingPathComponent("HighlightCache", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        NSLog("[dotViewer Cache] DiskCache initialized at: \(cacheDirectory.path)")
    }

    // MARK: - Cache Key Generation

    /// Generate cache key from file metadata + theme
    func cacheKey(filePath: String, modificationDate: Date, theme: String) -> String {
        let input = "\(filePath)|\(modificationDate.timeIntervalSince1970)|\(theme)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Read/Write

    /// Get cached AttributedString from disk
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
                // Update access time for LRU
                try? fileManager.setAttributes(
                    [.modificationDate: Date()],
                    ofItemAtPath: fileURL.path
                )
                NSLog("[dotViewer Cache] Disk HIT for key: \(key.prefix(16))...")
                return AttributedString(nsAttrString)
            }
        } catch {
            NSLog("[dotViewer Cache] Disk read error: \(error.localizedDescription)")
            // Remove corrupted file
            try? fileManager.removeItem(at: fileURL)
        }

        return nil
    }

    /// Save AttributedString to disk
    func set(key: String, value: AttributedString) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let fileURL = self.cacheDirectory.appendingPathComponent(key)

            do {
                let nsAttrString = NSAttributedString(value)
                let data = try NSKeyedArchiver.archivedData(
                    withRootObject: nsAttrString,
                    requiringSecureCoding: false
                )
                try data.write(to: fileURL, options: .atomic)
                NSLog("[dotViewer Cache] Disk WRITE for key: \(key.prefix(16))... (\(data.count) bytes)")

                // Run cleanup periodically
                self.cleanupIfNeeded()
            } catch {
                NSLog("[dotViewer Cache] Disk write error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cleanup

    /// Remove old entries if cache exceeds limits
    private func cleanupIfNeeded() {
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

            NSLog("[dotViewer Cache] Cleanup: \(fileInfos.count) entries, \(totalSize / 1024)KB")

            // Sort by modification date (oldest first)
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
                NSLog("[dotViewer Cache] Cleaned up \(removed) old entries")
            }
        } catch {
            NSLog("[dotViewer Cache] Cleanup error: \(error.localizedDescription)")
        }
    }

    /// Clear entire cache
    func clear() {
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                let files = try self.fileManager.contentsOfDirectory(
                    at: self.cacheDirectory,
                    includingPropertiesForKeys: nil
                )
                for file in files {
                    try? self.fileManager.removeItem(at: file)
                }
                NSLog("[dotViewer Cache] Cache cleared")
            } catch {
                NSLog("[dotViewer Cache] Clear error: \(error.localizedDescription)")
            }
        }
    }

    /// Get cache statistics
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
```

Add this file to both the main app target AND the QuickLookPreview extension target in Xcode.
  </action>
  <verify>
Build succeeds for both targets:
```bash
xcodebuild -scheme dotViewer -configuration Debug build 2>&1 | tail -5
```
  </verify>
  <done>
- DiskCache.swift created with App Groups storage
- SHA256 cache key generation
- LRU-based cleanup
- Thread-safe async writes
  </done>
</task>

<task type="auto">
  <name>Task 2: Refactor HighlightCache to use two-tier caching</name>
  <files>Shared/HighlightCache.swift</files>
  <action>
Modify HighlightCache to become a two-tier cache: memory (fast) + disk (persistent).

**Strategy:**
1. On `get()`: Check memory first, then disk. If found on disk, populate memory.
2. On `set()`: Write to both memory and disk.
3. Memory tier handles fast repeated access (same file, scrolling, etc.)
4. Disk tier handles XPC restart survival

**Updated implementation:**

```swift
import Foundation

/// Two-tier cache for highlighted code content.
/// Memory tier: Fast access for current session
/// Disk tier: Survives QuickLook XPC termination
final class HighlightCache: @unchecked Sendable {
    static let shared = HighlightCache()

    private let lock = NSLock()
    private var memoryCache: [String: MemoryCacheEntry] = [:]
    private var accessOrder: [String] = []
    private let maxMemoryEntries = 20

    private let diskCache = DiskCache.shared

    struct MemoryCacheEntry {
        let highlighted: AttributedString
        let cacheKey: String  // For disk cache coordination
    }

    private init() {
        memoryCache.reserveCapacity(maxMemoryEntries)
        accessOrder.reserveCapacity(maxMemoryEntries)
    }

    /// Generate cache key for a file
    func cacheKey(path: String, modDate: Date, theme: String) -> String {
        return diskCache.cacheKey(filePath: path, modificationDate: modDate, theme: theme)
    }

    /// Get cached highlighted content
    /// Checks memory first, then disk
    func get(path: String, modDate: Date, theme: String) -> AttributedString? {
        let key = cacheKey(path: path, modDate: modDate, theme: theme)

        // 1. Check memory cache (fast path)
        if let entry = getFromMemory(key: key) {
            NSLog("[dotViewer Cache] Memory HIT for: \(path.components(separatedBy: "/").last ?? path)")
            return entry
        }

        // 2. Check disk cache (slower but persistent)
        if let diskEntry = diskCache.get(key: key) {
            NSLog("[dotViewer Cache] Disk HIT, promoting to memory for: \(path.components(separatedBy: "/").last ?? path)")
            // Promote to memory cache
            setInMemory(key: key, value: diskEntry)
            return diskEntry
        }

        NSLog("[dotViewer Cache] MISS for: \(path.components(separatedBy: "/").last ?? path)")
        return nil
    }

    /// Store highlighted content in both memory and disk
    func set(path: String, modDate: Date, theme: String, highlighted: AttributedString) {
        let key = cacheKey(path: path, modDate: modDate, theme: theme)

        // Write to memory (synchronous, fast)
        setInMemory(key: key, value: highlighted)

        // Write to disk (async, persistent)
        diskCache.set(key: key, value: highlighted)

        NSLog("[dotViewer Cache] SET for: \(path.components(separatedBy: "/").last ?? path)")
    }

    // MARK: - Memory Cache Operations

    private func getFromMemory(key: String) -> AttributedString? {
        lock.withLock {
            guard let entry = memoryCache[key] else { return nil }

            // Update access order for LRU
            if let idx = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: idx)
                accessOrder.append(key)
            }
            return entry.highlighted
        }
    }

    private func setInMemory(key: String, value: AttributedString) {
        lock.withLock {
            // If already in cache, update and move to end
            if memoryCache[key] != nil {
                memoryCache[key] = MemoryCacheEntry(highlighted: value, cacheKey: key)
                if let idx = accessOrder.firstIndex(of: key) {
                    accessOrder.remove(at: idx)
                    accessOrder.append(key)
                }
                return
            }

            // Evict oldest if at capacity
            while memoryCache.count >= maxMemoryEntries, let oldest = accessOrder.first {
                memoryCache.removeValue(forKey: oldest)
                accessOrder.removeFirst()
            }

            memoryCache[key] = MemoryCacheEntry(highlighted: value, cacheKey: key)
            accessOrder.append(key)
        }
    }

    /// Clear memory cache (disk cache remains for persistence)
    func clearMemory() {
        lock.withLock {
            memoryCache.removeAll()
            accessOrder.removeAll()
        }
    }

    /// Clear all caches (memory + disk)
    func clearAll() {
        clearMemory()
        diskCache.clear()
    }

    /// Get cache statistics
    func stats() -> (memory: Int, disk: (entries: Int, sizeKB: Int)) {
        let memCount = lock.withLock { memoryCache.count }
        let diskStats = diskCache.stats()
        return (memCount, diskStats)
    }
}
```

Delete the old `CacheEntry` struct and `modificationDate` logic - we now use a unified cache key that includes all invalidation factors.
  </action>
  <verify>Build succeeds</verify>
  <done>
- HighlightCache refactored to two-tier (memory + disk)
- Memory tier for fast repeated access
- Disk tier for XPC restart survival
- Unified cache key includes theme
  </done>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] `xcodebuild -scheme dotViewer -configuration Debug build` succeeds
- [ ] DiskCache.swift compiles and is included in both targets
- [ ] HighlightCache uses DiskCache for persistence
- [ ] Cache directory created in App Groups container
</verification>

<success_criteria>

- All tasks completed
- All verification checks pass
- Two-tier cache architecture implemented
- Ready for integration in next plan
  </success_criteria>

<output>
After completion, create `.planning/phases/P3-persistent-cache/P3-01-SUMMARY.md`
</output>
