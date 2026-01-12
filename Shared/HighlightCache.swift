import Foundation

/// Thread-safe LRU cache for highlighted code content.
/// Caches AttributedString results to avoid re-highlighting the same file.
final class HighlightCache: @unchecked Sendable {
    static let shared = HighlightCache()

    private let lock = NSLock()
    private var cache: [String: CacheEntry] = [:]
    private var accessOrder: [String] = []
    private let maxEntries = 20

    struct CacheEntry {
        let highlighted: AttributedString
        let modificationDate: Date
    }

    private init() {
        cache.reserveCapacity(maxEntries)
        accessOrder.reserveCapacity(maxEntries)
    }

    /// Get cached highlighted content if it exists and file hasn't been modified.
    /// - Parameters:
    ///   - path: The file path
    ///   - modDate: The file's modification date
    /// - Returns: Cached AttributedString if valid, nil otherwise
    func get(path: String, modDate: Date) -> AttributedString? {
        lock.withLock {
            guard let entry = cache[path],
                  entry.modificationDate == modDate else {
                // Cache miss or stale entry
                if cache[path] != nil {
                    // Remove stale entry
                    cache.removeValue(forKey: path)
                    if let idx = accessOrder.firstIndex(of: path) {
                        accessOrder.remove(at: idx)
                    }
                }
                return nil
            }
            // Update access order for LRU
            if let idx = accessOrder.firstIndex(of: path) {
                accessOrder.remove(at: idx)
                accessOrder.append(path)
            }
            return entry.highlighted
        }
    }

    /// Store highlighted content in the cache.
    /// - Parameters:
    ///   - path: The file path
    ///   - modDate: The file's modification date
    ///   - highlighted: The highlighted AttributedString to cache
    func set(path: String, modDate: Date, highlighted: AttributedString) {
        lock.withLock {
            // If already in cache, update and move to end
            if cache[path] != nil {
                cache[path] = CacheEntry(highlighted: highlighted, modificationDate: modDate)
                if let idx = accessOrder.firstIndex(of: path) {
                    accessOrder.remove(at: idx)
                    accessOrder.append(path)
                }
                return
            }

            // Evict oldest if at capacity
            while cache.count >= maxEntries, let oldest = accessOrder.first {
                cache.removeValue(forKey: oldest)
                accessOrder.removeFirst()
            }

            cache[path] = CacheEntry(highlighted: highlighted, modificationDate: modDate)
            accessOrder.append(path)
        }
    }

    /// Clear the entire cache.
    func clear() {
        lock.withLock {
            cache.removeAll()
            accessOrder.removeAll()
        }
    }
}
