import Foundation
import CryptoKit
import OSLog

public struct PreviewCacheKey: Hashable, Sendable {
    public let rawKey: String

    public init(
        url: URL,
        fileSize: Int,
        mtime: TimeInterval,
        showLineNumbers: Bool,
        codeFontSize: Double,
        markdownUseSyntaxHighlightInRaw: Bool,
        allowUnknown: Bool,
        forceTextForUnknown: Bool,
        languageId: String,
        theme: String,
        showHeader: Bool,
        markdownDefaultMode: String,
        markdownRenderFontSize: Double,
        markdownRenderedWidthMode: String,
        markdownRenderedCustomMaxWidth: Int,
        markdownShowInlineImages: Bool,
        markdownCustomCSS: String,
        markdownCustomCSSOverride: Bool,
        markdownTOCDefaultOpen: Bool,
        includeLineNumbersInCopy: Bool,
        codeContentWidthMode: String,
        codeContentCustomMaxWidth: Int,
        wordWrap: Bool = false
    ) {
        rawKey = [
            url.path,
            "\(fileSize)",
            "\(mtime)",
            showLineNumbers ? "ln1" : "ln0",
            String(format: "%.2f", codeFontSize),
            markdownUseSyntaxHighlightInRaw ? "mdhl1" : "mdhl0",
            allowUnknown ? "au1" : "au0",
            forceTextForUnknown ? "ft1" : "ft0",
            languageId,
            theme,
            showHeader ? "hdr1" : "hdr0",
            markdownDefaultMode,
            String(format: "%.2f", markdownRenderFontSize),
            markdownRenderedWidthMode,
            "\(markdownRenderedCustomMaxWidth)",
            markdownShowInlineImages ? "mdimg1" : "mdimg0",
            markdownCustomCSSOverride ? "mdcss1" : "mdcss0",
            markdownCustomCSS,
            markdownTOCDefaultOpen ? "toc1" : "toc0",
            includeLineNumbersInCopy ? "lnc1" : "lnc0",
            codeContentWidthMode,
            "\(codeContentCustomMaxWidth)",
            wordWrap ? "ww1" : "ww0"
        ].joined(separator: "|")
    }

    public var fileName: String {
        let digest = SHA256.hash(data: Data(rawKey.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

public struct PreviewCacheEntry: Codable, Sendable {
    public let createdAt: Date
    public let rawHTML: String
    public let renderedHTML: String?
    public let rawText: String
    public let lineCount: Int
    public let fileSizeBytes: Int
    public let isTruncated: Bool

    public init(
        createdAt: Date,
        rawHTML: String,
        renderedHTML: String?,
        rawText: String,
        lineCount: Int,
        fileSizeBytes: Int,
        isTruncated: Bool
    ) {
        self.createdAt = createdAt
        self.rawHTML = rawHTML
        self.renderedHTML = renderedHTML
        self.rawText = rawText
        self.lineCount = lineCount
        self.fileSizeBytes = fileSizeBytes
        self.isTruncated = isTruncated
    }

    public var byteSize: Int {
        rawHTML.utf8.count +
            (renderedHTML?.utf8.count ?? 0) +
            rawText.utf8.count
    }
}

final class PreviewCacheEntryWrapper: NSObject {
    let entry: PreviewCacheEntry

    init(entry: PreviewCacheEntry) {
        self.entry = entry
    }
}

public actor PreviewCache {
    public static let shared = PreviewCache()

    private let memoryCache = NSCache<NSString, PreviewCacheEntryWrapper>()
    private let log = Logger(subsystem: "com.stianlars1.dotViewer", category: "PreviewCache")

    private init() {}

    public func handleClearIfRequested() {
        if SharedSettings.shared.previewCacheClearRequested {
            SharedSettings.shared.previewCacheClearRequested = false
            clearAll()
        }
    }

    public func load(key: PreviewCacheKey, ttlSeconds: Int) -> PreviewCacheEntry? {
        let keyString = key.rawKey as NSString
        let maxBytes = SharedSettings.shared.previewCacheMaxMB * 1_024 * 1_024
        memoryCache.totalCostLimit = maxBytes
        if let cached = memoryCache.object(forKey: keyString)?.entry {
            if !isExpired(entry: cached, ttlSeconds: ttlSeconds) {
                return cached
            }
            memoryCache.removeObject(forKey: keyString)
        }

        guard let fileURL = cacheFileURL(for: key.fileName),
              let data = try? Data(contentsOf: fileURL),
              let entry = try? JSONDecoder().decode(PreviewCacheEntry.self, from: data)
        else {
            return nil
        }

        if isExpired(entry: entry, ttlSeconds: ttlSeconds) {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        memoryCache.setObject(PreviewCacheEntryWrapper(entry: entry), forKey: keyString, cost: entry.byteSize)
        return entry
    }

    public func store(key: PreviewCacheKey, entry: PreviewCacheEntry, ttlSeconds: Int, maxBytes: Int) {
        let keyString = key.rawKey as NSString
        memoryCache.totalCostLimit = maxBytes
        memoryCache.setObject(PreviewCacheEntryWrapper(entry: entry), forKey: keyString, cost: entry.byteSize)

        guard let fileURL = cacheFileURL(for: key.fileName) else { return }
        if let data = try? JSONEncoder().encode(entry) {
            try? data.write(to: fileURL, options: .atomic)
        }

        pruneExpired(ttlSeconds: ttlSeconds)
        enforceSizeLimit(maxBytes: maxBytes)
    }

    public func clearAll() {
        memoryCache.removeAllObjects()
        guard let dir = cacheDirectory() else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func cacheDirectory() -> URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedSettings.appGroupId) else {
            log.error("Missing app group container for preview cache")
            return nil
        }
        let dir = container.appendingPathComponent("PreviewCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func cacheFileURL(for fileName: String) -> URL? {
        guard let dir = cacheDirectory() else { return nil }
        return dir.appendingPathComponent(fileName).appendingPathExtension("json")
    }

    private func isExpired(entry: PreviewCacheEntry, ttlSeconds: Int) -> Bool {
        let age = Date().timeIntervalSince(entry.createdAt)
        return age > TimeInterval(ttlSeconds)
    }

    private func pruneExpired(ttlSeconds: Int) {
        guard let dir = cacheDirectory() else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            guard let data = try? Data(contentsOf: file),
                  let entry = try? JSONDecoder().decode(PreviewCacheEntry.self, from: data)
            else { continue }
            if isExpired(entry: entry, ttlSeconds: ttlSeconds) {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private func enforceSizeLimit(maxBytes: Int) {
        guard let dir = cacheDirectory() else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])) ?? []
        var items: [(url: URL, date: Date, size: Int)] = []
        var totalSize = 0

        for file in files {
            let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            let size = values?.fileSize ?? 0
            let date = values?.contentModificationDate ?? Date.distantPast
            items.append((file, date, size))
            totalSize += size
        }

        if totalSize <= maxBytes { return }

        let sorted = items.sorted { $0.date < $1.date }
        var size = totalSize
        for item in sorted {
            if size <= maxBytes { break }
            try? FileManager.default.removeItem(at: item.url)
            size -= item.size
        }
    }
}
