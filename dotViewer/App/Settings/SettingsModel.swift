import Observation
import Shared

/// Every value the Settings window edits, observable by all panes at once.
///
/// Reads start from `SharedSettings` (the App Group store the Quick Look extensions read) and every
/// change writes straight back through its setter, which keeps the store's own clamping and
/// sanitising. One object instead of per-view `@State` copies means coupled values — the code and
/// rendered-Markdown font sizes when they are synced — are kept consistent in one place.
@MainActor
@Observable
final class SettingsModel {
    private let store = SharedSettings.shared

    // MARK: Appearance

    var theme: String { didSet { store.selectedTheme = theme } }
    var codeFontFamily: String { didSet { store.codeFontFamilyName = codeFontFamily } }
    var interfaceTextSize: String { didSet { store.appUIFontSizePreset = interfaceTextSize } }
    var showLineNumbers: Bool { didSet { store.showLineNumbers = showLineNumbers } }
    var wordWrap: Bool { didSet { store.wordWrap = wordWrap } }

    var fontSize: Double {
        didSet {
            store.fontSize = fontSize
            if syncFontSizes, markdownFontSize != fontSize { markdownFontSize = fontSize }
        }
    }

    // MARK: Markdown

    /// While on, the rendered-Markdown size follows the code size, and either slider moves both.
    var syncFontSizes: Bool {
        didSet {
            store.syncFontSizes = syncFontSizes
            if syncFontSizes, markdownFontSize != fontSize { markdownFontSize = fontSize }
        }
    }

    var markdownFontSize: Double {
        didSet {
            store.markdownRenderFontSize = markdownFontSize
            if syncFontSizes, fontSize != markdownFontSize { fontSize = markdownFontSize }
        }
    }

    var markdownDefaultMode: String { didSet { store.markdownDefaultMode = markdownDefaultMode } }
    var markdownShowImages: Bool { didSet { store.markdownShowInlineImages = markdownShowImages } }
    var markdownRawHighlighting: Bool { didSet { store.markdownUseSyntaxHighlightInRaw = markdownRawHighlighting } }
    var markdownShowTOC: Bool { didSet { store.markdownShowTOC = markdownShowTOC } }
    var markdownTOCOpen: Bool { didSet { store.markdownTOCDefaultOpen = markdownTOCOpen } }
    var markdownFont: String { didSet { store.markdownRenderedFontFamilyName = markdownFont } }
    var markdownWidthMode: String { didSet { store.markdownRenderedWidthMode = markdownWidthMode } }
    var markdownMaxWidth: Int { didSet { store.markdownRenderedCustomMaxWidth = markdownMaxWidth } }
    var markdownAlignment: String { didSet { store.markdownRenderedContentAlignment = markdownAlignment } }
    var customCSS: String { didSet { store.markdownCustomCSS = customCSS } }
    var customCSSReplacesBuiltIn: Bool { didSet { store.markdownCustomCSSOverride = customCSSReplacesBuiltIn } }

    // MARK: Window and content width

    var windowSizeMode: String { didSet { store.previewWindowSizeMode = windowSizeMode } }
    var windowFixedWidth: Int { didSet { store.previewWindowFixedWidth = windowFixedWidth } }
    var windowFixedHeight: Int { didSet { store.previewWindowFixedHeight = windowFixedHeight } }
    var windowAspectRatio: String { didSet { store.previewWindowAspectRatio = windowAspectRatio } }
    var windowAspectBaseWidth: Int { didSet { store.previewWindowAspectBaseWidth = windowAspectBaseWidth } }
    var codeWidthMode: String { didSet { store.codeContentWidthMode = codeWidthMode } }
    var codeMaxWidth: Int { didSet { store.codeContentCustomMaxWidth = codeMaxWidth } }
    var codeAlignment: String { didSet { store.codeContentAlignment = codeAlignment } }
    var markdownRawAlignment: String { didSet { store.markdownRawContentAlignment = markdownRawAlignment } }

    // MARK: General

    var showFileInfoHeader: Bool { didSet { store.showFileInfoHeader = showFileInfoHeader } }
    var previewUnknownFiles: Bool { didSet { store.previewAllFileTypes = previewUnknownFiles } }
    var forceTextForUnknown: Bool { didSet { store.previewForceTextForUnknown = forceTextForUnknown } }
    var showTruncationWarning: Bool { didSet { store.showTruncationWarning = showTruncationWarning } }

    /// The slider works in kilobytes; the store keeps bytes.
    var maxFileSizeKB: Double { didSet { store.maxFileSizeBytes = Int(maxFileSizeKB * 1000) } }

    // MARK: Copy and shortcuts

    var copyBehavior: String { didSet { store.copyBehavior = copyBehavior } }
    var includeLineNumbersInCopy: Bool { didSet { store.includeLineNumbersInCopy = includeLineNumbersInCopy } }
    var showSearchButton: Bool { didSet { store.showSearchButton = showSearchButton } }
    var previewPanelEnabled: Bool { didSet { store.previewPanelEnabled = previewPanelEnabled } }

    // MARK: Advanced

    var previewCacheEnabled: Bool { didSet { store.previewCacheEnabled = previewCacheEnabled } }
    var cacheTTLSeconds: Int { didSet { store.previewCacheTTLSeconds = cacheTTLSeconds } }
    var cacheMaxMB: Int { didSet { store.previewCacheMaxMB = cacheMaxMB } }
    var performanceLogging: Bool { didSet { store.performanceLoggingEnabled = performanceLogging } }

    init() {
        let store = SharedSettings.shared
        theme = store.selectedTheme
        codeFontFamily = store.codeFontFamilyName
        interfaceTextSize = store.appUIFontSizePreset
        showLineNumbers = store.showLineNumbers
        wordWrap = store.wordWrap
        fontSize = store.fontSize
        syncFontSizes = store.syncFontSizes
        markdownFontSize = store.markdownRenderFontSize
        markdownDefaultMode = store.markdownDefaultMode
        markdownShowImages = store.markdownShowInlineImages
        markdownRawHighlighting = store.markdownUseSyntaxHighlightInRaw
        markdownShowTOC = store.markdownShowTOC
        markdownTOCOpen = store.markdownTOCDefaultOpen
        markdownFont = store.markdownRenderedFontFamilyName
        markdownWidthMode = store.markdownRenderedWidthMode
        markdownMaxWidth = store.markdownRenderedCustomMaxWidth
        markdownAlignment = store.markdownRenderedContentAlignment
        customCSS = store.markdownCustomCSS
        customCSSReplacesBuiltIn = store.markdownCustomCSSOverride
        windowSizeMode = store.previewWindowSizeMode
        windowFixedWidth = store.previewWindowFixedWidth
        windowFixedHeight = store.previewWindowFixedHeight
        windowAspectRatio = store.previewWindowAspectRatio
        windowAspectBaseWidth = store.previewWindowAspectBaseWidth
        codeWidthMode = store.codeContentWidthMode
        codeMaxWidth = store.codeContentCustomMaxWidth
        codeAlignment = store.codeContentAlignment
        markdownRawAlignment = store.markdownRawContentAlignment
        showFileInfoHeader = store.showFileInfoHeader
        previewUnknownFiles = store.previewAllFileTypes
        forceTextForUnknown = store.previewForceTextForUnknown
        showTruncationWarning = store.showTruncationWarning
        maxFileSizeKB = Double(store.maxFileSizeBytes) / 1000
        copyBehavior = store.copyBehavior
        includeLineNumbersInCopy = store.includeLineNumbersInCopy
        showSearchButton = store.showSearchButton
        previewPanelEnabled = store.previewPanelEnabled
        previewCacheEnabled = store.previewCacheEnabled
        cacheTTLSeconds = store.previewCacheTTLSeconds
        cacheMaxMB = store.previewCacheMaxMB
        performanceLogging = store.performanceLoggingEnabled
    }

    // MARK: Actions

    /// Forgets the size "Remember" mode last requested, so the next preview starts from the default.
    func resetRememberedWindowSize() {
        store.resetPreviewWindowLastSize()
    }

    /// Turns the remembered size into the fixed size and switches to Fixed mode.
    func saveRememberedSizeAsFixed() {
        store.copyLastSizeToFixed()
        windowFixedWidth = store.previewWindowFixedWidth
        windowFixedHeight = store.previewWindowFixedHeight
        windowSizeMode = "fixed"
    }

    /// The extensions own the cache; they clear it the next time they see this flag.
    func clearPreviewCache() {
        store.previewCacheClearRequested = true
    }
}
