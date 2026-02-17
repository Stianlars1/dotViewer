import Foundation
import os.log

private let settingsLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "SharedSettings")

/// Shared settings stored in the App Group container.
/// Thread-safe for access from the main app and the Quick Look extension.
public final class SharedSettings: @unchecked Sendable {
    public static let appGroupId = "group.stianlars1.dotViewer.shared"
    public static let shared = SharedSettings()

    private let lock = NSLock()
    private let defaults: UserDefaults
    public let isUsingAppGroup: Bool

    private init() {
        if let suiteDefaults = UserDefaults(suiteName: Self.appGroupId) {
            defaults = suiteDefaults
            isUsingAppGroup = true
            settingsLogger.info("App Group container accessed successfully")
        } else {
            defaults = .standard
            isUsingAppGroup = false
            settingsLogger.error("Could not access App Group container - settings will not sync between app and extension")
        }
    }

    // MARK: - Appearance

    public var selectedTheme: String {
        get { lock.withLock { defaults.string(forKey: "selectedTheme") ?? "auto" } }
        set { lock.withLock { defaults.set(newValue, forKey: "selectedTheme") } }
    }

    public var fontSize: Double {
        get {
            lock.withLock {
                let value = defaults.double(forKey: "fontSize")
                return value > 0 ? value : 13
            }
        }
        set {
            lock.withLock {
                let clamped = max(10, min(24, newValue))
                defaults.set(clamped, forKey: "fontSize")
            }
        }
    }

    public var appUIFontSizePreset: String {
        get {
            lock.withLock {
                let value = defaults.string(forKey: "appUIFontSizePreset") ?? "system"
                return Self.allowedAppUIFontSizePresets.contains(value) ? value : "system"
            }
        }
        set {
            lock.withLock {
                let sanitized = Self.allowedAppUIFontSizePresets.contains(newValue) ? newValue : "system"
                defaults.set(sanitized, forKey: "appUIFontSizePreset")
            }
        }
    }

    public var showLineNumbers: Bool {
        get { lock.withLock { defaults.object(forKey: "showLineNumbers") as? Bool ?? false } }
        set { lock.withLock { defaults.set(newValue, forKey: "showLineNumbers") } }
    }

    public var wordWrap: Bool {
        get { lock.withLock { defaults.object(forKey: "wordWrap") as? Bool ?? false } }
        set { lock.withLock { defaults.set(newValue, forKey: "wordWrap") } }
    }

    // MARK: - Preview Limits

    public var maxFileSizeBytes: Int {
        get {
            lock.withLock {
                let value = defaults.integer(forKey: "maxFileSizeBytes")
                return value > 0 ? value : 100_000
            }
        }
        set {
            lock.withLock {
                let clamped = max(10_000, min(500_000, newValue))
                defaults.set(clamped, forKey: "maxFileSizeBytes")
            }
        }
    }

    public var thumbnailMaxBytes: Int {
        get {
            lock.withLock {
                let value = defaults.integer(forKey: "thumbnailMaxBytes")
                return value > 0 ? value : 24_000
            }
        }
        set {
            lock.withLock {
                let clamped = max(4_000, min(100_000, newValue))
                defaults.set(clamped, forKey: "thumbnailMaxBytes")
            }
        }
    }

    public var thumbnailMaxLines: Int {
        get {
            lock.withLock {
                let value = defaults.integer(forKey: "thumbnailMaxLines")
                return value > 0 ? value : 60
            }
        }
        set {
            lock.withLock {
                let clamped = max(10, min(200, newValue))
                defaults.set(clamped, forKey: "thumbnailMaxLines")
            }
        }
    }

    public var showTruncationWarning: Bool {
        get { lock.withLock { defaults.object(forKey: "showTruncationWarning") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "showTruncationWarning") } }
    }

    // MARK: - Preview UI

    public var showFileInfoHeader: Bool {
        get { lock.withLock { defaults.object(forKey: "showFileInfoHeader") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "showFileInfoHeader") } }
    }

    public var copyBehavior: String {
        get { lock.withLock { defaults.string(forKey: "copyBehavior") ?? "autoCopy" } }
        set { lock.withLock { defaults.set(newValue, forKey: "copyBehavior") } }
    }

    public var showSearchButton: Bool {
        get { lock.withLock { defaults.object(forKey: "showSearchButton") as? Bool ?? false } }
        set { lock.withLock { defaults.set(newValue, forKey: "showSearchButton") } }
    }

    public var includeLineNumbersInCopy: Bool {
        get { lock.withLock { defaults.object(forKey: "includeLineNumbersInCopy") as? Bool ?? false } }
        set { lock.withLock { defaults.set(newValue, forKey: "includeLineNumbersInCopy") } }
    }

    public var codeContentWidthMode: String {
        get {
            lock.withLock {
                let value = defaults.string(forKey: "codeContentWidthMode") ?? "auto"
                return Self.allowedWidthModes.contains(value) ? value : "auto"
            }
        }
        set {
            lock.withLock {
                let sanitized = Self.allowedWidthModes.contains(newValue) ? newValue : "auto"
                defaults.set(sanitized, forKey: "codeContentWidthMode")
            }
        }
    }

    public var codeContentCustomMaxWidth: Int {
        get {
            lock.withLock {
                let value = defaults.integer(forKey: "codeContentCustomMaxWidth")
                return value > 0 ? max(480, min(2400, value)) : 1200
            }
        }
        set {
            lock.withLock {
                let clamped = max(480, min(2400, newValue))
                defaults.set(clamped, forKey: "codeContentCustomMaxWidth")
            }
        }
    }

    public var markdownPreviewMode: String {
        get { markdownDefaultMode }
        set { markdownDefaultMode = newValue }
    }

    public var syncFontSizes: Bool {
        get { lock.withLock { defaults.object(forKey: "syncFontSizes") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "syncFontSizes") } }
    }

    // MARK: - Markdown Settings

    public var markdownDefaultMode: String {
        get {
            lock.withLock {
                if let value = defaults.string(forKey: "markdownDefaultMode") {
                    return value
                }
                if let legacy = defaults.string(forKey: "markdownPreviewMode") {
                    return legacy
                }
                return "raw"
            }
        }
        set {
            lock.withLock {
                defaults.set(newValue, forKey: "markdownDefaultMode")
            }
        }
    }

    public var markdownShowInlineImages: Bool {
        get { lock.withLock { defaults.object(forKey: "markdownShowInlineImages") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "markdownShowInlineImages") } }
    }

    public var markdownUseSyntaxHighlightInRaw: Bool {
        get { lock.withLock { defaults.object(forKey: "markdownUseSyntaxHighlightInRaw") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "markdownUseSyntaxHighlightInRaw") } }
    }

    public var markdownRenderFontSize: Double {
        get {
            lock.withLock {
                if defaults.object(forKey: "syncFontSizes") as? Bool ?? true {
                    let codeFontSize = defaults.double(forKey: "fontSize")
                    return codeFontSize > 0 ? codeFontSize : 13
                }
                let value = defaults.double(forKey: "markdownRenderFontSize")
                return value > 0 ? value : 14
            }
        }
        set {
            lock.withLock {
                let clamped = max(10, min(24, newValue))
                defaults.set(clamped, forKey: "markdownRenderFontSize")
            }
        }
    }

    public var markdownCustomCSS: String {
        get { lock.withLock { defaults.string(forKey: "markdownCustomCSS") ?? "" } }
        set { lock.withLock { defaults.set(newValue, forKey: "markdownCustomCSS") } }
    }

    public var markdownCustomCSSOverride: Bool {
        get { lock.withLock { defaults.object(forKey: "markdownCustomCSSOverride") as? Bool ?? false } }
        set { lock.withLock { defaults.set(newValue, forKey: "markdownCustomCSSOverride") } }
    }

    public var markdownShowTOC: Bool {
        get { lock.withLock { defaults.object(forKey: "markdownShowTOC") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "markdownShowTOC") } }
    }

    public var markdownTOCDefaultOpen: Bool {
        get { lock.withLock { defaults.object(forKey: "markdownTOCDefaultOpen") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "markdownTOCDefaultOpen") } }
    }

    public var markdownRenderedWidthMode: String {
        get {
            lock.withLock {
                let value = defaults.string(forKey: "markdownRenderedWidthMode") ?? "auto"
                return Self.allowedWidthModes.contains(value) ? value : "auto"
            }
        }
        set {
            lock.withLock {
                let sanitized = Self.allowedWidthModes.contains(newValue) ? newValue : "auto"
                defaults.set(sanitized, forKey: "markdownRenderedWidthMode")
            }
        }
    }

    public var markdownRenderedCustomMaxWidth: Int {
        get {
            lock.withLock {
                let value = defaults.integer(forKey: "markdownRenderedCustomMaxWidth")
                return value > 0 ? max(480, min(2400, value)) : 900
            }
        }
        set {
            lock.withLock {
                let clamped = max(480, min(2400, newValue))
                defaults.set(clamped, forKey: "markdownRenderedCustomMaxWidth")
            }
        }
    }

    public var previewAllFileTypes: Bool {
        get { lock.withLock { defaults.object(forKey: "previewAllFileTypes") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "previewAllFileTypes") } }
    }

    // MARK: - Preview Diagnostics & Cache

    private static var defaultPerformanceLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    public var performanceLoggingEnabled: Bool {
        get { lock.withLock { defaults.object(forKey: "performanceLoggingEnabled") as? Bool ?? Self.defaultPerformanceLoggingEnabled } }
        set { lock.withLock { defaults.set(newValue, forKey: "performanceLoggingEnabled") } }
    }

    public var previewCacheEnabled: Bool {
        get { lock.withLock { defaults.object(forKey: "previewCacheEnabled") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "previewCacheEnabled") } }
    }

    public var previewCacheMaxMB: Int {
        get {
            lock.withLock {
                let value = defaults.integer(forKey: "previewCacheMaxMB")
                return value > 0 ? value : 100
            }
        }
        set {
            lock.withLock {
                let clamped = max(10, min(500, newValue))
                defaults.set(clamped, forKey: "previewCacheMaxMB")
            }
        }
    }

    public var previewCacheTTLSeconds: Int {
        get {
            lock.withLock {
                let value = defaults.integer(forKey: "previewCacheTTLSeconds")
                return value > 0 ? value : 60
            }
        }
        set {
            lock.withLock {
                let clamped = max(5, min(600, newValue))
                defaults.set(clamped, forKey: "previewCacheTTLSeconds")
            }
        }
    }

    public var previewCacheClearRequested: Bool {
        get { lock.withLock { defaults.object(forKey: "previewCacheClearRequested") as? Bool ?? false } }
        set { lock.withLock { defaults.set(newValue, forKey: "previewCacheClearRequested") } }
    }

    public var previewForceTextForUnknown: Bool {
        get { lock.withLock { defaults.object(forKey: "previewForceTextForUnknown") as? Bool ?? true } }
        set { lock.withLock { defaults.set(newValue, forKey: "previewForceTextForUnknown") } }
    }

    // MARK: - File Types

    public var disabledFileTypes: Set<String> {
        get {
            lock.withLock {
                let array = defaults.stringArray(forKey: "disabledFileTypes") ?? []
                return Set(array)
            }
        }
        set {
            lock.withLock {
                defaults.set(Array(newValue), forKey: "disabledFileTypes")
            }
        }
    }

    public var customExtensions: [CustomExtension] {
        get {
            lock.withLock {
                guard let data = defaults.data(forKey: "customExtensions"),
                      let extensions = try? JSONDecoder().decode([CustomExtension].self, from: data)
                else { return [] }
                return extensions
            }
        }
        set {
            lock.withLock {
                do {
                    let data = try JSONEncoder().encode(newValue)
                    defaults.set(data, forKey: "customExtensions")
                } catch {
                    settingsLogger.error("Failed to encode custom extensions: \(error.localizedDescription)")
                }
            }
        }
    }

    private static let allowedWidthModes: Set<String> = ["auto", "custom"]
    private static let allowedAppUIFontSizePresets: Set<String> = [
        "system",
        "xSmall",
        "small",
        "medium",
        "large",
        "xLarge",
        "xxLarge",
        "xxxLarge",
    ]
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
