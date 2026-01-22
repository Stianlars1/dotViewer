import Foundation
import os

/// Two-tier cache for highlighted code content.
/// Memory tier: Fast access for current session
/// Disk tier: Survives QuickLook XPC termination
///
/// Performance strategy:
/// - On get(): Check memory first (fast), then disk (persistent). Promote disk hits to memory.
/// - On set(): Write to both memory (synchronous) and disk (async).
/// - Memory handles fast repeated access (same file, scrolling)
/// - Disk handles XPC restart survival
///
/// Thread Safety (@unchecked Sendable justification):
/// This class is manually verified thread-safe through:
/// - `cacheState`: OSAllocatedUnfairLock protecting all memory cache operations
/// - `diskCache`: Delegated to DiskCache.shared which has its own synchronization
/// - All public methods use `cacheState.withLock { }` for atomic access
final class HighlightCache: @unchecked Sendable {
    static let shared = HighlightCache()

    private struct CacheState {
        var memoryCache: [String: MemoryCacheEntry] = [:]
        var accessOrder: [String] = []
        var currentMemoryBytes: Int = 0
    }

    private let cacheState: OSAllocatedUnfairLock<CacheState>
    private let maxMemoryEntries = 20
    private let maxMemoryBytes = 10 * 1024 * 1024  // 10MB byte limit

    private let diskCache = DiskCache.shared

    struct MemoryCacheEntry {
        let highlighted: AttributedString
        let cacheKey: String  // For disk cache coordination
        let estimatedBytes: Int  // Estimated memory footprint
    }

    private init() {
        var state = CacheState()
        state.memoryCache.reserveCapacity(20)
        state.accessOrder.reserveCapacity(20)
        cacheState = OSAllocatedUnfairLock(initialState: state)
    }

    /// Estimate the memory size of an AttributedString.
    /// Uses character count * 2 (UTF-16) + overhead for attributes.
    private func estimateSize(_ attributed: AttributedString) -> Int {
        let charCount = attributed.characters.count
        // UTF-16 encoding (2 bytes/char) + attribute overhead (~24 bytes per run)
        return charCount * 2 + 256  // minimum 256 bytes overhead
    }

    /// Generate cache key for a file.
    /// Key = SHA256(filePath + modificationDate + theme + language)
    func cacheKey(path: String, modDate: Date, theme: String, language: String?) -> String {
        return diskCache.cacheKey(filePath: path, modificationDate: modDate, theme: theme, language: language)
    }

    /// Get cached highlighted content.
    /// Checks memory first (fast), then disk (persistent).
    /// Disk hits are promoted to memory for faster subsequent access.
    func get(path: String, modDate: Date, theme: String, language: String?) -> AttributedString? {
        let key = cacheKey(path: path, modDate: modDate, theme: theme, language: language)

        // 1. Check memory cache (fast path)
        if let entry = getFromMemory(key: key) {
            perfLog("[dotViewer Cache] Memory HIT for: \(path.components(separatedBy: "/").last ?? path)")
            return entry
        }

        // 2. Check disk cache (slower but persistent)
        if let diskEntry = diskCache.get(key: key) {
            perfLog("[dotViewer Cache] Disk HIT, promoting to memory for: \(path.components(separatedBy: "/").last ?? path)")
            // Promote to memory cache for faster subsequent access
            setInMemory(key: key, value: diskEntry)
            return diskEntry
        }

        perfLog("[dotViewer Cache] MISS for: \(path.components(separatedBy: "/").last ?? path)")
        return nil
    }

    /// Store highlighted content in both memory and disk.
    /// Memory write is synchronous (fast).
    /// Disk write is asynchronous (doesn't block caller).
    func set(path: String, modDate: Date, theme: String, language: String?, highlighted: AttributedString) {
        let key = cacheKey(path: path, modDate: modDate, theme: theme, language: language)

        // Write to memory (synchronous, fast)
        setInMemory(key: key, value: highlighted)

        // Write to disk (async, persistent)
        diskCache.set(key: key, value: highlighted)

        perfLog("[dotViewer Cache] SET for: \(path.components(separatedBy: "/").last ?? path)")
    }

    // MARK: - Memory Cache Operations

    private func getFromMemory(key: String) -> AttributedString? {
        cacheState.withLock { state in
            guard let entry = state.memoryCache[key] else { return nil }

            // Update access order for LRU
            if let idx = state.accessOrder.firstIndex(of: key) {
                state.accessOrder.remove(at: idx)
            }
            state.accessOrder.append(key)
            return entry.highlighted
        }
    }

    private func setInMemory(key: String, value: AttributedString) {
        let entrySize = estimateSize(value)

        // Skip caching if single entry exceeds the byte limit
        guard entrySize <= maxMemoryBytes else {
            perfLog("[HighlightCache] Entry too large to cache: \(entrySize) bytes")
            return
        }

        cacheState.withLock { state in
            // If already in cache, remove old entry's byte count first
            if let existing = state.memoryCache[key] {
                state.currentMemoryBytes -= existing.estimatedBytes
                if let idx = state.accessOrder.firstIndex(of: key) {
                    state.accessOrder.remove(at: idx)
                }
            }

            // Evict oldest entries until within both entry count and byte limits
            while (!state.accessOrder.isEmpty &&
                   (state.memoryCache.count >= maxMemoryEntries ||
                    state.currentMemoryBytes + entrySize > maxMemoryBytes)),
                  let oldest = state.accessOrder.first {
                if let evicted = state.memoryCache.removeValue(forKey: oldest) {
                    state.currentMemoryBytes -= evicted.estimatedBytes
                }
                state.accessOrder.removeFirst()
            }

            let entry = MemoryCacheEntry(highlighted: value, cacheKey: key, estimatedBytes: entrySize)
            state.memoryCache[key] = entry
            state.currentMemoryBytes += entrySize
            state.accessOrder.append(key)
        }
    }

    /// Clear memory cache (disk cache remains for persistence).
    func clearMemory() {
        cacheState.withLock { state in
            state.memoryCache.removeAll()
            state.accessOrder.removeAll()
            state.currentMemoryBytes = 0
        }
    }

    /// Clear all caches (memory + disk).
    func clearAll() {
        clearMemory()
        diskCache.clear()
    }

    /// Get cache statistics.
    func stats() -> (memory: (entries: Int, sizeBytes: Int), disk: (entries: Int, sizeKB: Int)) {
        let (memCount, memBytes) = cacheState.withLock { state in
            (state.memoryCache.count, state.currentMemoryBytes)
        }
        let diskStats = diskCache.stats()
        return ((memCount, memBytes), diskStats)
    }

    // MARK: - Legacy API (deprecated)

    // NOTE: These legacy methods exist for backwards compatibility during transition.
    // They were part of v1 cache API before theme/language were added to cache keys.
    // Migration path:
    // - get(path:modDate:) → get(path:modDate:theme:language:)
    // - set(path:modDate:highlighted:) → set(path:modDate:theme:language:highlighted:)
    // - clear() → clearMemory() or clearAll()
    //
    // These will be removed in a future version once all callers are migrated.

    /// Deprecated: Use get(path:modDate:theme:language:) instead.
    /// This method uses "auto" as the default theme and nil language.
    @available(*, deprecated, message: "Use get(path:modDate:theme:language:) instead")
    func get(path: String, modDate: Date) -> AttributedString? {
        return get(path: path, modDate: modDate, theme: "auto", language: nil)
    }

    /// Deprecated: Use set(path:modDate:theme:language:highlighted:) instead.
    /// This method uses "auto" as the default theme and nil language.
    @available(*, deprecated, message: "Use set(path:modDate:theme:language:highlighted:) instead")
    func set(path: String, modDate: Date, highlighted: AttributedString) {
        set(path: path, modDate: modDate, theme: "auto", language: nil, highlighted: highlighted)
    }

    /// Deprecated: Use clearMemory() or clearAll() instead.
    @available(*, deprecated, message: "Use clearMemory() or clearAll() instead")
    func clear() {
        clearMemory()
    }
}
