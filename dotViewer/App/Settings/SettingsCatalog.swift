import Foundation

/// Stable identity of every row in Settings. Search results point at these, and each row carries
/// its ID through `.settingsAnchor(_:)` so a result can scroll to and highlight it.
enum SettingID: String, CaseIterable, Hashable, Sendable {
    case fileInfoHeader, previewUnknownFiles, forceTextForUnknown, maxFileSize, truncationWarning
    case theme, codeFont, fontSize, lineNumbers, wordWrap, interfaceTextSize
    case markdownDefaultMode, markdownRawHighlighting, markdownInlineImages, markdownTOC, markdownTOCOpen
    case markdownFont, markdownMatchCodeSize, markdownFontSize, markdownWidth, markdownAlignment, markdownCustomCSS
    case windowSizeMode, windowDimensions, codeWidth, codeAlignment, markdownRawAlignment
    case copyBehavior, copyLineNumbers
    case findButton, findShortcut, spacePanel, accessibilityPermission, finderPermission
    case previewCache, cacheLifetime, cacheSize, clearCache, performanceLogging, uninstall
}

struct SettingsEntry: Identifiable, Hashable, Sendable {
    let id: SettingID
    let pane: SettingsPane
    let title: String
    /// Words people might type instead of the title — synonyms, the old labels, related terms.
    let keywords: [String]
}

/// Every setting in the Settings window, for search.
enum SettingsCatalog {
    static let entries: [SettingsEntry] = [
        // General
        .init(id: .fileInfoHeader, pane: .general, title: "File info header",
              keywords: ["header", "filename", "language", "line count", "file size"]),
        .init(id: .previewUnknownFiles, pane: .general, title: "Preview unknown file types",
              keywords: ["unknown", "unsupported", "extension", "registry", "routed"]),
        .init(id: .forceTextForUnknown, pane: .general, title: "Show unknown text as plain text",
              keywords: ["force", "plain text", "mime", "fallback", "unknown"]),
        .init(id: .maxFileSize, pane: .general, title: "Maximum file size",
              keywords: ["large", "limit", "truncate", "kb", "size"]),
        .init(id: .truncationWarning, pane: .general, title: "Truncation warning",
              keywords: ["truncated", "large file", "notice"]),

        // Appearance
        .init(id: .theme, pane: .appearance, title: "Theme",
              keywords: ["colour", "color", "dark", "light", "github", "xcode", "solarized", "atom",
                         "tokyo", "blackout", "syntax"]),
        .init(id: .codeFont, pane: .appearance, title: "Code font",
              keywords: ["font", "monospace", "mono", "typeface", "family", "sf mono"]),
        .init(id: .fontSize, pane: .appearance, title: "Font size",
              keywords: ["text size", "zoom", "points", "pt"]),
        .init(id: .lineNumbers, pane: .appearance, title: "Line numbers",
              keywords: ["gutter", "numbers"]),
        .init(id: .wordWrap, pane: .appearance, title: "Wrap long lines",
              keywords: ["word wrap", "soft wrap", "horizontal scroll"]),
        .init(id: .interfaceTextSize, pane: .appearance, title: "Interface text size",
              keywords: ["app text", "dynamic type", "larger text", "ui", "accessibility"]),

        // Markdown
        .init(id: .markdownDefaultMode, pane: .markdown, title: "Open Markdown as",
              keywords: ["raw", "rendered", "default mode", "md"]),
        .init(id: .markdownRawHighlighting, pane: .markdown, title: "Highlight syntax in raw view",
              keywords: ["raw", "syntax", "colours", "colors"]),
        .init(id: .markdownInlineImages, pane: .markdown, title: "Show images",
              keywords: ["inline images", "pictures"]),
        .init(id: .markdownTOC, pane: .markdown, title: "Table of contents button",
              keywords: ["toc", "outline", "headings", "navigation"]),
        .init(id: .markdownTOCOpen, pane: .markdown, title: "Open table of contents by default",
              keywords: ["toc", "sidebar", "outline"]),
        .init(id: .markdownFont, pane: .markdown, title: "Rendered font",
              keywords: ["prose", "font", "typeface", "serif", "sans"]),
        .init(id: .markdownMatchCodeSize, pane: .markdown, title: "Match code font size",
              keywords: ["sync", "same size"]),
        .init(id: .markdownFontSize, pane: .markdown, title: "Rendered font size",
              keywords: ["text size", "markdown size"]),
        .init(id: .markdownWidth, pane: .markdown, title: "Rendered width",
              keywords: ["max width", "column", "line length", "measure"]),
        .init(id: .markdownAlignment, pane: .markdown, title: "Rendered alignment",
              keywords: ["centre", "center", "left", "right", "align"]),
        .init(id: .markdownCustomCSS, pane: .markdown, title: "Custom CSS",
              keywords: ["stylesheet", "style", "css", "override", "replace"]),

        // Window
        .init(id: .windowSizeMode, pane: .window, title: "Window size",
              keywords: ["quick look window", "preview size", "auto", "fixed", "aspect ratio",
                         "fit content", "remember"]),
        .init(id: .windowDimensions, pane: .window, title: "Window dimensions",
              keywords: ["width", "height", "ratio", "base width", "pixels"]),
        .init(id: .codeWidth, pane: .window, title: "Code width",
              keywords: ["content width", "max width", "raw width", "line length"]),
        .init(id: .codeAlignment, pane: .window, title: "Code alignment",
              keywords: ["centre", "center", "left", "right", "align"]),
        .init(id: .markdownRawAlignment, pane: .window, title: "Markdown raw alignment",
              keywords: ["raw", "centre", "center", "align"]),

        // Copy
        .init(id: .copyBehavior, pane: .copy, title: "When you select text",
              keywords: ["copy", "clipboard", "auto-copy", "selection", "copy button", "hold", "shake",
                         "toast", "undo"]),
        .init(id: .copyLineNumbers, pane: .copy, title: "Include line numbers",
              keywords: ["copy", "clipboard", "gutter"]),

        // Shortcuts
        .init(id: .findButton, pane: .shortcuts, title: "Find button in preview",
              keywords: ["search", "find", "magnifier", "header"]),
        .init(id: .findShortcut, pane: .shortcuts, title: "⌘F search",
              keywords: ["command f", "cmd f", "find", "search", "keyboard"]),
        .init(id: .spacePanel, pane: .shortcuts, title: "⌥Space preview",
              keywords: ["option space", "alt space", "panel", "ts", "typescript", "finder"]),
        .init(id: .accessibilityPermission, pane: .shortcuts, title: "Accessibility access",
              keywords: ["permission", "privacy", "tcc", "grant", "keyboard"]),
        .init(id: .finderPermission, pane: .shortcuts, title: "Finder access",
              keywords: ["automation", "apple events", "permission", "privacy", "tcc"]),

        // Advanced
        .init(id: .previewCache, pane: .advanced, title: "Preview cache",
              keywords: ["cache", "speed", "performance"]),
        .init(id: .cacheLifetime, pane: .advanced, title: "Keep previews for",
              keywords: ["ttl", "cache", "expiry", "time", "seconds"]),
        .init(id: .cacheSize, pane: .advanced, title: "Cache size limit",
              keywords: ["cache", "mb", "disk", "storage"]),
        .init(id: .clearCache, pane: .advanced, title: "Clear cache",
              keywords: ["cache", "reset", "delete", "purge"]),
        .init(id: .performanceLogging, pane: .advanced, title: "Performance logging",
              keywords: ["logs", "diagnostics", "timing", "debug", "console"]),
        .init(id: .uninstall, pane: .advanced, title: "Uninstall dotViewer",
              keywords: ["remove", "delete", "trash", "danger"]),
    ]

    private static let byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })

    static func entry(_ id: SettingID) -> SettingsEntry {
        guard let entry = byID[id] else { preconditionFailure("No catalog entry for \(id)") }
        return entry
    }

    /// Settings whose title, pane name or keywords contain every word of `query`, ignoring case,
    /// accents and width. A blank query matches nothing — the sidebar shows the panes instead.
    static func search(_ query: String) -> [SettingsEntry] {
        let tokens = fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return [] }
        let matches = entries.filter { entry in
            let haystack = fold(([entry.title, entry.pane.title] + entry.keywords).joined(separator: " "))
            return tokens.allSatisfy(haystack.contains)
        }
        return rank(matches, tokens: tokens)
    }

    /// Orders search results. Matches arrive in catalog (pane) order.
    static func rank(_ matches: [SettingsEntry], tokens: [String]) -> [SettingsEntry] {
        // TODO(owner): decide how results are ordered — see the Settings plan, Task 8.
        matches
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }
}
