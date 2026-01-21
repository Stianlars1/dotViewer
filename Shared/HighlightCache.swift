import Foundation

/// Two-tier cache for highlighted code content.
/// Memory tier: Fast access for current session
/// Disk tier: Survives QuickLook XPC termination
///
/// Performance strategy:
/// - On get(): Check memory first (fast), then disk (persistent). Promote disk hits to memory.
/// - On set(): Write to both memory (synchronous) and disk (async).
/// - Memory handles fast repeated access (same file, scrolling)
/// - Disk handles XPC restart survival
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

    /// Generate cache key for a file.
    /// Key = SHA256(filePath + modificationDate + theme)
    func cacheKey(path: String, modDate: Date, theme: String) -> String {
        return diskCache.cacheKey(filePath: path, modificationDate: modDate, theme: theme)
    }

    /// Get cached highlighted content.
    /// Checks memory first (fast), then disk (persistent).
    /// Disk hits are promoted to memory for faster subsequent access.
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
            // Promote to memory cache for faster subsequent access
            setInMemory(key: key, value: diskEntry)
            return diskEntry
        }

        NSLog("[dotViewer Cache] MISS for: \(path.components(separatedBy: "/").last ?? path)")
        return nil
    }

    /// Store highlighted content in both memory and disk.
    /// Memory write is synchronous (fast).
    /// Disk write is asynchronous (doesn't block caller).
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

    /// Clear memory cache (disk cache remains for persistence).
    func clearMemory() {
        lock.withLock {
            memoryCache.removeAll()
            accessOrder.removeAll()
        }
    }

    /// Clear all caches (memory + disk).
    func clearAll() {
        clearMemory()
        diskCache.clear()
    }

    /// Get cache statistics.
    func stats() -> (memory: Int, disk: (entries: Int, sizeKB: Int)) {
        let memCount = lock.withLock { memoryCache.count }
        let diskStats = diskCache.stats()
        return (memCount, diskStats)
    }

    // MARK: - Legacy API (deprecated, for backward compatibility)

    /// Deprecated: Use get(path:modDate:theme:) instead.
    /// This method uses "auto" as the default theme.
    @available(*, deprecated, message: "Use get(path:modDate:theme:) instead")
    func get(path: String, modDate: Date) -> AttributedString? {
        return get(path: path, modDate: modDate, theme: "auto")
    }

    /// Deprecated: Use set(path:modDate:theme:highlighted:) instead.
    /// This method uses "auto" as the default theme.
    @available(*, deprecated, message: "Use set(path:modDate:theme:highlighted:) instead")
    func set(path: String, modDate: Date, highlighted: AttributedString) {
        set(path: path, modDate: modDate, theme: "auto", highlighted: highlighted)
    }

    /// Deprecated: Use clearMemory() or clearAll() instead.
    @available(*, deprecated, message: "Use clearMemory() or clearAll() instead")
    func clear() {
        clearMemory()
    }
}
