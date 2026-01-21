import SwiftUI
import AppKit

// MARK: - Preview State

struct PreviewState {
    let content: String
    let filename: String
    let language: String?
    let lineCount: Int
    let fileSize: String
    let isTruncated: Bool
    let truncationMessage: String?
    let fileURL: URL?
    let modificationDate: Date?
    let preHighlightedContent: AttributedString?
}

// MARK: - Main Preview View

struct PreviewContentView: View {
    let state: PreviewState

    @State private var highlightedContent: AttributedString?
    @State private var isReady = false
    @State private var showRenderedMarkdown: Bool

    private var settings: SharedSettings { SharedSettings.shared }

    private var isMarkdown: Bool {
        state.language == "markdown"
    }

    /// Detects potentially sensitive environment files
    private var isEnvFile: Bool {
        let lowercased = state.filename.lowercased()
        return lowercased.hasPrefix(".env") ||
               lowercased == "credentials" ||
               lowercased == "secrets" ||
               lowercased.hasSuffix(".credentials") ||
               lowercased.hasSuffix(".secrets")
    }

    init(state: PreviewState) {
        self.state = state
        // Initialize markdown mode from settings
        _showRenderedMarkdown = State(initialValue: SharedSettings.shared.markdownRenderMode == "rendered")
    }

    var body: some View {
        GeometryReader { outerGeometry in
            // Detect compact mode (Finder preview pane is typically small)
            let isCompactMode = outerGeometry.size.width < 350 || outerGeometry.size.height < 250

            VStack(spacing: 0) {
                // Header - hide in compact mode (Finder preview pane)
                if settings.showPreviewHeader && !isCompactMode {
                    PreviewHeaderView(
                        filename: state.filename,
                        language: state.language,
                        lineCount: state.lineCount,
                        fileSize: state.fileSize,
                        content: state.content,
                        fileURL: state.fileURL,
                        isMarkdown: isMarkdown,
                        showRenderedMarkdown: $showRenderedMarkdown
                    )
                }

                // Security warning for env files - always show
                if isEnvFile && !isCompactMode {
                    EnvFileSecurityBanner()
                }

                // Truncation warning - also hide in compact mode
                if state.isTruncated, settings.showTruncationWarning, let message = state.truncationMessage, !isCompactMode {
                    TruncationBanner(message: message)
                }

                // Content area
                ZStack(alignment: .topLeading) {
                    // Background always visible
                    backgroundColor

                    // Loading indicator while highlighting
                    if !isReady {
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)

                            // Show what we're doing for larger files
                            if state.lineCount > 500 {
                                VStack(spacing: 4) {
                                    Text("Highlighting \(state.lineCount) lines...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if let lang = state.language, lang != "plaintext" {
                                        Text(LanguageDetector.displayName(for: lang))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Content (fades in when ready)
                    if isMarkdown && showRenderedMarkdown {
                        // Rendered markdown view (Typora-inspired native SwiftUI)
                        MarkdownRenderedViewLegacy(
                            content: state.content,
                            fontSize: isCompactMode ? settings.fontSize * 0.8 : settings.fontSize
                        )
                        .opacity(isReady ? 1 : 0)
                    } else {
                        // Code view
                        ScrollView([.horizontal, .vertical]) {
                            HStack(alignment: .top, spacing: 0) {
                                // Hide line numbers in compact mode
                                if settings.showLineNumbers && !isCompactMode {
                                    LineNumbersColumn(
                                        lineCount: state.lineCount,
                                        fontSize: settings.fontSize
                                    )
                                }

                                CodeContentView(
                                    plainContent: state.content,
                                    highlightedContent: highlightedContent,
                                    fontSize: isCompactMode ? settings.fontSize * 0.8 : settings.fontSize
                                )
                            }
                            .frame(minWidth: outerGeometry.size.width, minHeight: outerGeometry.size.height, alignment: .topLeading)
                        }
                        .opacity(isReady ? 1 : 0)
                    }
                }
            }
        }
        .task {
            await highlightCode()
        }
    }

    private var backgroundColor: Color {
        ThemeManager.shared.backgroundColor
    }

    private func highlightCode() async {
        // PERFORMANCE DIAGNOSTICS: Detailed timing instrumentation
        let startTime = CFAbsoluteTimeGetCurrent()
        NSLog("[dotViewer PERF] highlightCode START - file: %@, lines: %d, language: %@", state.filename, state.lineCount, state.language ?? "nil")

        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            let usedFast = FastSyntaxHighlighter.isSupported(state.language)
            NSLog("[dotViewer PERF] highlightCode COMPLETE - total: %.3fs, highlighter: %@", elapsed, usedFast ? "Fast" : "HighlightSwift")
            DotViewerLogger.preview.info("Highlight \(self.state.filename): \(String(format: "%.1f", elapsed * 1000))ms (\(usedFast ? "fast" : "HighlightSwift"), \(self.state.lineCount) lines)")
        }

        // Use pre-highlighted content if available (from cache or pre-warming)
        NSLog("[dotViewer PERF] [+%.3fs] cache check START", CFAbsoluteTimeGetCurrent() - startTime)
        if let preHighlighted = state.preHighlightedContent {
            NSLog("[dotViewer PERF] [+%.3fs] cache check: HIT (pre-highlighted)", CFAbsoluteTimeGetCurrent() - startTime)
            highlightedContent = preHighlighted
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }
        NSLog("[dotViewer PERF] [+%.3fs] cache check: MISS", CFAbsoluteTimeGetCurrent() - startTime)

        // Skip syntax highlighting for very large files (>2000 lines) - show plain text immediately
        // This prevents the UI from hanging on massive files like package-lock.json
        let maxLinesForHighlighting = 2000

        if state.lineCount > maxLinesForHighlighting {
            // Large file - skip highlighting entirely, show plain text immediately
            NSLog("[dotViewer PERF] [+%.3fs] SKIP: file too large (%d > %d lines)", CFAbsoluteTimeGetCurrent() - startTime, state.lineCount, maxLinesForHighlighting)
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // Skip syntax highlighting for unknown file types - auto-detection is very slow
        // Files like .viminfo have no known language, and HighlightSwift's automatic mode
        // runs multiple parsers which can take 10+ seconds
        if state.language == nil {
            NSLog("[dotViewer PERF] [+%.3fs] SKIP: no language detected (would trigger slow auto-detection)", CFAbsoluteTimeGetCurrent() - startTime)
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // Skip highlighting for files explicitly marked as plaintext (history files, logs, etc.)
        // These files have no meaningful syntax and would just waste CPU cycles
        if state.language == "plaintext" {
            NSLog("[dotViewer PERF] [+%.3fs] SKIP: plaintext file (no syntax to highlight)", CFAbsoluteTimeGetCurrent() - startTime)
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // Use custom highlighting for markdown (HighlightSwift has bugs that cause red text)
        if state.language == "markdown" {
            NSLog("[dotViewer PERF] [+%.3fs] PATH: markdown (custom highlighting)", CFAbsoluteTimeGetCurrent() - startTime)
            let markdownStart = CFAbsoluteTimeGetCurrent()
            let result = highlightMarkdownRaw(state.content)
            NSLog("[dotViewer PERF] [+%.3fs] markdown highlighting took: %.3fs", CFAbsoluteTimeGetCurrent() - startTime, CFAbsoluteTimeGetCurrent() - markdownStart)
            highlightedContent = result
            // Cache the result (memory + disk)
            if let modDate = state.modificationDate, let path = state.fileURL?.path {
                let theme = SharedSettings.shared.selectedTheme
                HighlightCache.shared.set(
                    path: path,
                    modDate: modDate,
                    theme: theme,
                    highlighted: result
                )
                NSLog("[dotViewer PERF] highlightCode - cached markdown result for future use")
            }
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // Content-based fast path: skip highlighting for files that don't look like code
        // This catches data files, logs, and other non-code content that has a detected language
        if shouldSkipHighlightingBasedOnContent(state.content) {
            NSLog("[dotViewer PERF] [+%.3fs] SKIP: content-based heuristic (not code-like)", CFAbsoluteTimeGetCurrent() - startTime)
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // For other files, use SyntaxHighlighter (which uses FastSyntaxHighlighter for supported languages)
        let isFastSupported = FastSyntaxHighlighter.isSupported(state.language)
        NSLog("[dotViewer PERF] [+%.3fs] PATH: SyntaxHighlighter (FastSyntaxHighlighter supported: %@)", CFAbsoluteTimeGetCurrent() - startTime, isFastSupported ? "YES" : "NO")

        let highlighter = SyntaxHighlighter()
        let timeoutNanoseconds: UInt64 = 2_000_000_000 // 2 seconds
        let highlightStart = CFAbsoluteTimeGetCurrent()

        // Use TaskGroup for reliable timeout with proper cancellation propagation
        let result: AttributedString? = await withTaskGroup(of: AttributedString?.self) { group in
            // Add the highlighting task
            group.addTask {
                do {
                    return try await highlighter.highlight(
                        code: self.state.content,
                        language: self.state.language
                    )
                } catch {
                    return nil
                }
            }

            // Add the timeout task
            group.addTask {
                do {
                    try await Task.sleep(nanoseconds: timeoutNanoseconds)
                } catch {
                    // Task was cancelled, return nil
                }
                return nil // Timeout returns nil
            }

            // Return the first non-nil result, or nil if timeout wins
            var highlighted: AttributedString? = nil
            for await taskResult in group {
                if let result = taskResult {
                    highlighted = result
                    group.cancelAll() // Cancel remaining tasks
                    break
                }
            }

            // If we got nil from timeout, cancel the highlight task
            group.cancelAll()
            return highlighted
        }

        let highlightDuration = CFAbsoluteTimeGetCurrent() - highlightStart
        NSLog("[dotViewer PERF] [+%.3fs] SyntaxHighlighter.highlight took: %.3fs, result: %@", CFAbsoluteTimeGetCurrent() - startTime, highlightDuration, result != nil ? "success" : "nil (timeout?)")

        // Use result if available
        if let highlighted = result {
            highlightedContent = highlighted
            // Cache the result (memory + disk)
            if let modDate = state.modificationDate, let path = state.fileURL?.path {
                let theme = SharedSettings.shared.selectedTheme
                HighlightCache.shared.set(
                    path: path,
                    modDate: modDate,
                    theme: theme,
                    highlighted: highlighted
                )
                NSLog("[dotViewer PERF] [+%.3fs] cached result for future use", CFAbsoluteTimeGetCurrent() - startTime)
            }
        }

        // Fade in the content smoothly (whether highlighting succeeded or timed out)
        NSLog("[dotViewer PERF] [+%.3fs] setting isReady = true, starting animation", CFAbsoluteTimeGetCurrent() - startTime)
        withAnimation(.easeIn(duration: 0.15)) {
            isReady = true
        }
    }

    /// Heuristic to detect files that won't benefit from syntax highlighting
    /// Returns true if the file content looks like data rather than code
    private func shouldSkipHighlightingBasedOnContent(_ content: String) -> Bool {
        // Sample first 2000 characters for analysis (enough to detect patterns)
        let sampleSize = min(2000, content.count)
        guard sampleSize > 100 else { return false } // Very small files are fine to highlight

        let sample = String(content.prefix(sampleSize))

        // Count alphanumeric characters vs total
        var alphanumericCount = 0
        var totalCount = 0

        for char in sample {
            if !char.isNewline {
                totalCount += 1
                if char.isLetter || char.isNumber {
                    alphanumericCount += 1
                }
            }
        }

        guard totalCount > 0 else { return false }

        let alphanumericRatio = Double(alphanumericCount) / Double(totalCount)

        // If less than 25% alphanumeric, likely a data file (binary-ish, special chars heavy)
        // Examples: Base64 encoded data, hex dumps, binary logs
        if alphanumericRatio < 0.25 {
            return true
        }

        // Check for repetitive patterns that suggest data, not code
        // Count unique lines - very repetitive content suggests generated/data files
        let lines = sample.components(separatedBy: .newlines).filter { !$0.isEmpty }
        if lines.count > 20 {
            let uniqueLines = Set(lines)
            let uniqueRatio = Double(uniqueLines.count) / Double(lines.count)

            // If less than 10% unique lines, it's highly repetitive (likely data)
            if uniqueRatio < 0.10 {
                return true
            }
        }

        return false
    }

    /// Custom markdown syntax highlighting that matches the user's selected theme
    private func highlightMarkdownRaw(_ content: String) -> AttributedString {
        var attributed = AttributedString(content)
        let text = content

        // Get theme-specific colors
        let colors = markdownColorsForTheme(ThemeManager.shared.selectedTheme)

        // Helper to apply color to regex matches
        func applyPattern(_ pattern: String, color: Color, bold: Bool = false) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)

            for match in matches {
                guard let range = Range(match.range, in: text),
                      let attrRange = Range(range, in: attributed) else { continue }
                attributed[attrRange].foregroundColor = color
                if bold {
                    attributed[attrRange].inlinePresentationIntent = .stronglyEmphasized
                }
            }
        }

        // Apply patterns (order matters - more specific patterns first)
        applyPattern("^#{1,6}\\s.*$", color: colors.heading, bold: true)  // Headers
        applyPattern("^>.*$", color: colors.quote)                         // Blockquotes
        applyPattern("```[\\s\\S]*?```", color: colors.code)               // Code blocks (BEFORE inline code!)
        applyPattern("(?<!`)`(?!`)[^`]+`(?!`)", color: colors.code)        // Inline code (exclude triple backticks)
        applyPattern("\\[([^\\]]+)\\]\\([^)]+\\)", color: colors.link)     // Links
        applyPattern("\\*\\*[^*]+\\*\\*", color: colors.bold, bold: true)  // Bold
        applyPattern("^\\s*[-*+]\\s", color: colors.heading)               // List markers
        applyPattern("^\\s*\\d+\\.\\s", color: colors.heading)             // Numbered lists

        return attributed
    }

    /// Returns theme-matched colors for markdown syntax highlighting
    private func markdownColorsForTheme(_ theme: String) -> (heading: Color, code: Color, link: Color, bold: Color, quote: Color) {
        switch theme {
        case "atomOneLight":
            return (
                heading: Color(hex: "#a626a4"),  // Purple - keywords
                code: Color(hex: "#50a14f"),     // Green - strings
                link: Color(hex: "#4078f2"),     // Blue - functions
                bold: Color(hex: "#383a42"),     // Dark gray - text
                quote: Color(hex: "#a0a1a7")     // Gray - comments
            )
        case "atomOneDark", "blackout":
            return (
                heading: Color(hex: "#c678dd"),  // Purple - keywords
                code: Color(hex: "#98c379"),     // Green - strings
                link: Color(hex: "#61afef"),     // Blue - functions
                bold: Color(hex: "#abb2bf"),     // Light gray - text
                quote: Color(hex: "#5c6370")     // Gray - comments
            )
        case "github":
            return (
                heading: Color(hex: "#d73a49"),  // Red - keywords
                code: Color(hex: "#032f62"),     // Dark blue - strings
                link: Color(hex: "#0366d6"),     // Blue - links
                bold: Color(hex: "#24292e"),     // Dark - text
                quote: Color(hex: "#6a737d")     // Gray - comments
            )
        case "githubDark":
            return (
                heading: Color(hex: "#ff7b72"),  // Salmon - keywords
                code: Color(hex: "#a5d6ff"),     // Light blue - strings
                link: Color(hex: "#58a6ff"),     // Blue - links
                bold: Color(hex: "#c9d1d9"),     // Light - text
                quote: Color(hex: "#8b949e")     // Gray - comments
            )
        case "xcode":
            return (
                heading: Color(hex: "#9b2393"),  // Purple - keywords
                code: Color(hex: "#c41a16"),     // Red - strings
                link: Color(hex: "#0f68a0"),     // Blue - links
                bold: Color(hex: "#000000"),     // Black - text
                quote: Color(hex: "#5d6c79")     // Gray - comments
            )
        case "xcodeDark":
            return (
                heading: Color(hex: "#fc5fa3"),  // Pink - keywords
                code: Color(hex: "#fc6a5d"),     // Coral - strings
                link: Color(hex: "#6699ff"),     // Blue - links
                bold: Color(hex: "#ffffff"),     // White - text
                quote: Color(hex: "#7f8c98")     // Gray - comments
            )
        case "solarizedLight":
            return (
                heading: Color(hex: "#859900"),  // Green - keywords
                code: Color(hex: "#2aa198"),     // Cyan - strings
                link: Color(hex: "#268bd2"),     // Blue - links
                bold: Color(hex: "#657b83"),     // Base00 - text
                quote: Color(hex: "#93a1a1")     // Base1 - comments
            )
        case "solarizedDark":
            return (
                heading: Color(hex: "#859900"),  // Green - keywords
                code: Color(hex: "#2aa198"),     // Cyan - strings
                link: Color(hex: "#268bd2"),     // Blue - links
                bold: Color(hex: "#839496"),     // Base0 - text
                quote: Color(hex: "#586e75")     // Base01 - comments
            )
        case "tokyoNight":
            return (
                heading: Color(hex: "#bb9af7"),  // Purple - keywords
                code: Color(hex: "#9ece6a"),     // Green - strings
                link: Color(hex: "#7aa2f7"),     // Blue - links
                bold: Color(hex: "#a9b1d6"),     // Light - text
                quote: Color(hex: "#565f89")     // Gray - comments
            )
        case "auto":
            // Follow system appearance
            if ThemeManager.shared.systemAppearanceIsDark {
                return markdownColorsForTheme("atomOneDark")
            } else {
                return markdownColorsForTheme("atomOneLight")
            }
        default:
            return markdownColorsForTheme("atomOneLight")
        }
    }
}

// MARK: - Header View

struct PreviewHeaderView: View {
    let filename: String
    let language: String?
    let lineCount: Int
    let fileSize: String
    let content: String
    let fileURL: URL?
    let isMarkdown: Bool
    @Binding var showRenderedMarkdown: Bool

    @State private var copied = false

    private var settings: SharedSettings { SharedSettings.shared }

    var body: some View {
        HStack(spacing: 12) {
            // File icon only (filename already shown in Apple's native header)
            Image(systemName: iconForLanguage(language))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            // Markdown toggle (only for markdown files)
            if isMarkdown {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showRenderedMarkdown.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showRenderedMarkdown ? "doc.richtext" : "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 10))
                        Text(showRenderedMarkdown ? "Rendered" : "Raw")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(Color.purple)
                    .clipShape(Capsule())
                }
                .buttonStyle(.borderless)
                .help(showRenderedMarkdown ? "Show raw markdown" : "Show rendered preview")
            }

            // Language badge
            if let lang = language {
                Text(LanguageDetector.displayName(for: lang))
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }

            // Stats
            Text("\(lineCount) lines")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Text("•")
                .foregroundStyle(.tertiary)

            Text(fileSize)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            // Copy button
            Button {
                copyToClipboard()
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Copy to clipboard")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    private func iconForLanguage(_ language: String?) -> String {
        guard let lang = language?.lowercased() else { return "doc.text" }

        switch lang {
        case "javascript", "typescript", "jsx", "tsx":
            return "curlybraces"
        case "python":
            return "chevron.left.forwardslash.chevron.right"
        case "swift":
            return "swift"
        case "html", "xml":
            return "chevron.left.slash.chevron.right"
        case "css", "scss", "sass", "less":
            return "paintbrush"
        case "json", "yaml", "toml":
            return "list.bullet.rectangle"
        case "markdown", "md":
            return "text.justify"
        case "bash", "shell", "sh", "zsh":
            return "terminal"
        case "sql":
            return "cylinder"
        case "dockerfile", "docker":
            return "shippingbox"
        case "go":
            return "g.circle"
        case "rust":
            return "r.circle"
        case "ruby":
            return "diamond"
        case "php":
            return "p.circle"
        default:
            return "doc.text"
        }
    }
}

// MARK: - Truncation Banner

struct TruncationBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)

            Text(message)
                .font(.system(size: 11))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.yellow.opacity(0.1))
    }
}

// MARK: - Environment File Security Banner

struct EnvFileSecurityBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.orange)

            Text("This file may contain sensitive data (API keys, passwords)")
                .font(.system(size: 11))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
    }
}

// MARK: - Line Numbers Column

struct LineNumbersColumn: View {
    let lineCount: Int
    let fontSize: Double

    private let maxDisplayLines = 5000

    /// Pre-computed line numbers string - single Text view instead of 5000 views
    private var lineNumbersText: String {
        (1...min(lineCount, maxDisplayLines))
            .map { String($0) }
            .joined(separator: "\n")
    }

    var body: some View {
        Text(lineNumbersText)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.trailing)
            .lineSpacing(fontSize * 0.4)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.05))
            .overlay(alignment: .trailing) {
                Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color.gray.opacity(0.2))
            }
    }
}

// MARK: - Code Content View

struct CodeContentView: View {
    let plainContent: String
    let highlightedContent: AttributedString?
    let fontSize: Double

    private var settings: SharedSettings { SharedSettings.shared }

    var body: some View {
        Group {
            if let highlighted = highlightedContent {
                Text(highlighted)
            } else {
                Text(plainContent)
                    .foregroundStyle(textColor)
            }
        }
        .font(.system(size: fontSize, design: .monospaced))
        .textSelection(.enabled)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var textColor: Color {
        ThemeManager.shared.textColor
    }
}

// MARK: - Legacy Markdown Rendered View (Typora-inspired SwiftUI version)
// Preserved as fallback in case WKWebView has issues

struct MarkdownRenderedViewLegacy: View {
    let content: String
    let fontSize: Double

    // Cached parsed blocks to prevent UUID regeneration on every render
    @State private var cachedBlocks: [MarkdownBlock] = []

    // Theme-aware color palette
    private var isDarkTheme: Bool {
        let theme = ThemeManager.shared.selectedTheme
        return theme.contains("Dark") || theme == "tokyoNight" || theme == "blackout" ||
               (theme == "auto" && ThemeManager.shared.systemAppearanceIsDark)
    }

    private var backgroundColor: Color { ThemeManager.shared.backgroundColor }
    private var headingColor: Color { ThemeManager.shared.textColor }
    private var bodyColor: Color { ThemeManager.shared.textColor.opacity(0.9) }
    private var linkColor: Color { Color(nsColor: NSColor(red: 0.25, green: 0.47, blue: 0.85, alpha: 1.0)) }
    private var codeBlockBg: Color { isDarkTheme ? Color.white.opacity(0.08) : Color.black.opacity(0.04) }
    private var inlineCodeBg: Color { isDarkTheme ? Color.white.opacity(0.12) : Color.black.opacity(0.06) }
    private var blockquoteBorder: Color { ThemeManager.shared.textColor.opacity(0.3) }
    private var blockquoteText: Color { ThemeManager.shared.textColor.opacity(0.7) }
    private var hrColor: Color { isDarkTheme ? Color.white.opacity(0.15) : Color.black.opacity(0.12) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(cachedBlocks, id: \.id) { block in
                        MarkdownBlockView(
                            block: block,
                            fontSize: fontSize,
                            headingColor: headingColor,
                            bodyColor: bodyColor,
                            linkColor: linkColor,
                            codeBlockBg: codeBlockBg,
                            inlineCodeBg: inlineCodeBg,
                            blockquoteBorder: blockquoteBorder,
                            blockquoteText: blockquoteText,
                            hrColor: hrColor
                        )
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
                .frame(minWidth: geometry.size.width, alignment: .topLeading)
            }
        }
        .background(backgroundColor)
        .task(id: content) {
            // Parse markdown blocks only when content changes
            cachedBlocks = parseMarkdownBlocks(content)
        }
    }

    private func parseMarkdownBlocks(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: "\n")
        var currentIndex = 0
        var paragraphBuffer: [String] = []

        // Helper to flush buffered paragraph lines
        func flushParagraph() {
            if !paragraphBuffer.isEmpty {
                let joined = paragraphBuffer.joined(separator: " ")
                blocks.append(MarkdownBlock(type: .paragraph, content: joined))
                paragraphBuffer.removeAll()
            }
        }

        while currentIndex < lines.count {
            let line = lines[currentIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for block-level elements (these interrupt paragraphs)
            if trimmed.hasPrefix("# ") {
                flushParagraph()
                blocks.append(MarkdownBlock(type: .h1, content: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("## ") {
                flushParagraph()
                blocks.append(MarkdownBlock(type: .h2, content: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(type: .h3, content: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("#### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(type: .h4, content: String(trimmed.dropFirst(5))))
            } else if trimmed.hasPrefix("##### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(type: .h5, content: String(trimmed.dropFirst(6))))
            } else if trimmed.hasPrefix("###### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(type: .h6, content: String(trimmed.dropFirst(7))))
            } else if trimmed.hasPrefix("```") {
                flushParagraph()
                // Code block with optional language
                let langPart = String(trimmed.dropFirst(3))
                let language = langPart.isEmpty ? nil : langPart
                var codeLines: [String] = []
                currentIndex += 1
                while currentIndex < lines.count && !lines[currentIndex].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[currentIndex])
                    currentIndex += 1
                }
                blocks.append(MarkdownBlock(type: .codeBlock, content: codeLines.joined(separator: "\n"), language: language))
            } else if let imageMatch = trimmed.firstMatch(of: /^!\[([^\]]*)\]\(([^)]+)\)$/) {
                // Image: ![alt](url)
                flushParagraph()
                let alt = String(imageMatch.1)
                let url = String(imageMatch.2)
                blocks.append(MarkdownBlock(type: .image, content: alt, imageURL: url))
            } else if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                // Table row - collect all table rows
                flushParagraph()
                var tableRows: [[String]] = []
                var tableIndex = currentIndex

                while tableIndex < lines.count {
                    let tableLine = lines[tableIndex].trimmingCharacters(in: .whitespaces)
                    if tableLine.hasPrefix("|") && tableLine.hasSuffix("|") {
                        // Parse cells from this row
                        let inner = String(tableLine.dropFirst().dropLast())
                        let cells = inner.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }

                        // Skip separator rows (e.g., |---|---|)
                        let isSeparator = cells.allSatisfy { cell in
                            cell.replacingOccurrences(of: "-", with: "")
                                .replacingOccurrences(of: ":", with: "")
                                .isEmpty
                        }

                        if !isSeparator {
                            tableRows.append(cells)
                        }
                        tableIndex += 1
                    } else {
                        break
                    }
                }

                if !tableRows.isEmpty {
                    var block = MarkdownBlock(type: .table, content: "")
                    block.tableRows = tableRows
                    blocks.append(block)
                }
                currentIndex = tableIndex - 1  // -1 because loop will increment
            } else if trimmed.hasPrefix("- [") || trimmed.hasPrefix("* [") {
                // Task list item
                flushParagraph()
                var taskItems: [TaskItem] = []

                while currentIndex < lines.count {
                    let taskLine = lines[currentIndex].trimmingCharacters(in: .whitespaces)
                    if let match = taskLine.firstMatch(of: /^[-*]\s*\[([ xX])\]\s*(.*)$/) {
                        let isChecked = String(match.1).lowercased() == "x"
                        let text = String(match.2)
                        taskItems.append(TaskItem(checked: isChecked, text: text))
                        currentIndex += 1
                    } else if taskLine.hasPrefix("- [") || taskLine.hasPrefix("* [") {
                        // Malformed task item - skip
                        currentIndex += 1
                    } else {
                        break
                    }
                }

                if !taskItems.isEmpty {
                    var block = MarkdownBlock(type: .taskList, content: "")
                    block.taskItems = taskItems
                    blocks.append(block)
                }
                currentIndex -= 1  // -1 because loop will increment
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                // Collect consecutive list items
                var listItems: [String] = [String(trimmed.dropFirst(2))]
                while currentIndex + 1 < lines.count {
                    let nextLine = lines[currentIndex + 1].trimmingCharacters(in: .whitespaces)
                    if nextLine.hasPrefix("- ") || nextLine.hasPrefix("* ") {
                        listItems.append(String(nextLine.dropFirst(2)))
                        currentIndex += 1
                    } else {
                        break
                    }
                }
                blocks.append(MarkdownBlock(type: .unorderedList, content: listItems.joined(separator: "\n")))
            } else if let match = trimmed.firstMatch(of: /^(\d+)\.\s+(.*)/) {
                flushParagraph()
                // Numbered list
                var listItems: [String] = [String(match.2)]
                while currentIndex + 1 < lines.count {
                    let nextLine = lines[currentIndex + 1].trimmingCharacters(in: .whitespaces)
                    if let nextMatch = nextLine.firstMatch(of: /^(\d+)\.\s+(.*)/) {
                        listItems.append(String(nextMatch.2))
                        currentIndex += 1
                    } else {
                        break
                    }
                }
                blocks.append(MarkdownBlock(type: .orderedList, content: listItems.joined(separator: "\n")))
            } else if trimmed.hasPrefix("> ") {
                flushParagraph()
                // Collect consecutive blockquote lines
                var quoteLines: [String] = [String(trimmed.dropFirst(2))]
                while currentIndex + 1 < lines.count {
                    let nextLine = lines[currentIndex + 1].trimmingCharacters(in: .whitespaces)
                    if nextLine.hasPrefix("> ") {
                        quoteLines.append(String(nextLine.dropFirst(2)))
                        currentIndex += 1
                    } else {
                        break
                    }
                }
                blocks.append(MarkdownBlock(type: .blockquote, content: quoteLines.joined(separator: "\n")))
            } else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                blocks.append(MarkdownBlock(type: .horizontalRule, content: ""))
            } else if trimmed.isEmpty {
                // Empty line - flush paragraph and add spacer
                flushParagraph()
                blocks.append(MarkdownBlock(type: .spacer, content: ""))
            } else {
                // Regular text line - add to paragraph buffer
                paragraphBuffer.append(trimmed)
            }

            currentIndex += 1
        }

        // Flush any remaining paragraph content
        flushParagraph()

        return blocks
    }
}

struct TaskItem: Identifiable {
    let id = UUID()
    let checked: Bool
    let text: String
}

struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: MarkdownBlockType
    let content: String
    var language: String? = nil
    var imageURL: String? = nil
    var tableRows: [[String]]? = nil  // For tables: array of rows, each row is array of cells
    var taskItems: [TaskItem]? = nil  // For task lists
}

enum MarkdownBlockType {
    case h1, h2, h3, h4, h5, h6
    case paragraph
    case codeBlock
    case unorderedList
    case orderedList
    case blockquote
    case horizontalRule
    case spacer
    case image
    case table
    case taskList
}

struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let fontSize: Double
    let headingColor: Color
    let bodyColor: Color
    let linkColor: Color
    let codeBlockBg: Color
    let inlineCodeBg: Color
    let blockquoteBorder: Color
    let blockquoteText: Color
    let hrColor: Color

    // Typora uses a nice serif font for body text
    private var bodyFont: Font {
        .system(size: fontSize, design: .serif)
    }

    var body: some View {
        Group {
            switch block.type {
            case .h1:
                VStack(alignment: .leading, spacing: 0) {
                    Text(parseInlineMarkdown(block.content))
                        .font(.system(size: fontSize * 2.2, weight: .bold, design: .default))
                        .foregroundStyle(headingColor)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                    Rectangle()
                        .fill(hrColor)
                        .frame(height: 1)
                }
                .padding(.bottom, 16)

            case .h2:
                VStack(alignment: .leading, spacing: 0) {
                    Text(parseInlineMarkdown(block.content))
                        .font(.system(size: fontSize * 1.8, weight: .bold, design: .default))
                        .foregroundStyle(headingColor)
                        .padding(.top, 20)
                        .padding(.bottom, 6)
                    Rectangle()
                        .fill(hrColor)
                        .frame(height: 1)
                }
                .padding(.bottom, 12)

            case .h3:
                Text(parseInlineMarkdown(block.content))
                    .font(.system(size: fontSize * 1.5, weight: .semibold, design: .default))
                    .foregroundStyle(headingColor)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

            case .h4:
                Text(parseInlineMarkdown(block.content))
                    .font(.system(size: fontSize * 1.25, weight: .semibold, design: .default))
                    .foregroundStyle(headingColor)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

            case .h5:
                Text(parseInlineMarkdown(block.content))
                    .font(.system(size: fontSize * 1.1, weight: .semibold, design: .default))
                    .foregroundStyle(headingColor)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

            case .h6:
                Text(parseInlineMarkdown(block.content))
                    .font(.system(size: fontSize, weight: .semibold, design: .default))
                    .foregroundStyle(blockquoteText)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

            case .paragraph:
                Text(parseInlineMarkdown(block.content))
                    .font(bodyFont)
                    .foregroundStyle(bodyColor)
                    .lineSpacing(fontSize * 0.5)
                    .padding(.vertical, 6)

            case .codeBlock:
                VStack(alignment: .leading, spacing: 0) {
                    if let lang = block.language, !lang.isEmpty {
                        Text(lang.uppercased())
                            .font(.system(size: fontSize * 0.7, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                    }
                    Text(highlightCode(block.content, language: block.language))
                        .font(.system(size: fontSize * 0.9, design: .monospaced))
                        .padding(.horizontal, 16)
                        .padding(.vertical, block.language != nil ? 8 : 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(codeBlockBg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(hrColor, lineWidth: 1)
                )
                .padding(.vertical, 8)

            case .unorderedList:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(block.content.components(separatedBy: "\n"), id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .font(.system(size: fontSize * 1.2, weight: .bold))
                                .foregroundStyle(headingColor)
                                .frame(width: 16)
                            Text(parseInlineMarkdown(item))
                                .font(bodyFont)
                                .foregroundStyle(bodyColor)
                                .lineSpacing(fontSize * 0.4)
                        }
                    }
                }
                .padding(.leading, 8)
                .padding(.vertical, 6)

            case .orderedList:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(block.content.components(separatedBy: "\n").enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.system(size: fontSize, weight: .medium, design: .default))
                                .foregroundStyle(headingColor)
                                .frame(width: 24, alignment: .trailing)
                            Text(parseInlineMarkdown(item))
                                .font(bodyFont)
                                .foregroundStyle(bodyColor)
                                .lineSpacing(fontSize * 0.4)
                        }
                    }
                }
                .padding(.leading, 8)
                .padding(.vertical, 6)

            case .blockquote:
                HStack(alignment: .top, spacing: 16) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(blockquoteBorder)
                        .frame(width: 4)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(block.content.components(separatedBy: "\n"), id: \.self) { line in
                            Text(parseInlineMarkdown(line))
                                .font(.system(size: fontSize, design: .serif))
                                .italic()
                                .foregroundStyle(blockquoteText)
                                .lineSpacing(fontSize * 0.4)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.leading, 8)

            case .horizontalRule:
                Rectangle()
                    .fill(hrColor)
                    .frame(height: 2)
                    .padding(.vertical, 24)

            case .spacer:
                Spacer()
                    .frame(height: fontSize * 0.8)

            case .image:
                // Render image placeholder with alt text and URL
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: fontSize * 1.5))
                            .foregroundStyle(blockquoteText)
                        VStack(alignment: .leading, spacing: 2) {
                            if !block.content.isEmpty {
                                Text(block.content)
                                    .font(.system(size: fontSize * 0.9, weight: .medium))
                                    .foregroundStyle(headingColor)
                            }
                            if let url = block.imageURL {
                                Text(url)
                                    .font(.system(size: fontSize * 0.75, design: .monospaced))
                                    .foregroundStyle(linkColor)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(codeBlockBg)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(hrColor, lineWidth: 1)
                    )
                }
                .padding(.vertical, 8)

            case .table:
                // Render markdown table
                if let rows = block.tableRows, !rows.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                            HStack(spacing: 0) {
                                ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                    Text(parseInlineMarkdown(cell))
                                        .font(rowIndex == 0 ?
                                              .system(size: fontSize * 0.9, weight: .semibold) :
                                              .system(size: fontSize * 0.9))
                                        .foregroundStyle(rowIndex == 0 ? headingColor : bodyColor)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            rowIndex == 0 ? codeBlockBg :
                                            (rowIndex % 2 == 0 ? Color.clear : codeBlockBg.opacity(0.5))
                                        )
                                        .overlay(
                                            Rectangle()
                                                .stroke(hrColor, lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(hrColor, lineWidth: 1)
                    )
                    .padding(.vertical, 8)
                }

            case .taskList:
                // Render task list with checkboxes
                if let items = block.taskItems {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(items) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: item.checked ? "checkmark.square.fill" : "square")
                                    .font(.system(size: fontSize * 1.1))
                                    .foregroundStyle(item.checked ? Color.green : blockquoteText)
                                    .frame(width: 20)
                                Text(parseInlineMarkdown(item.text))
                                    .font(bodyFont)
                                    .foregroundStyle(item.checked ? blockquoteText : bodyColor)
                                    .strikethrough(item.checked, color: blockquoteText)
                                    .lineSpacing(fontSize * 0.4)
                            }
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        do {
            var attributed = try AttributedString(markdown: text)
            // Style links with our link color
            for run in attributed.runs {
                if run.link != nil {
                    attributed[run.range].foregroundColor = linkColor
                    attributed[run.range].underlineStyle = .single
                }
            }
            return attributed
        } catch {
            return AttributedString(text)
        }
    }

    // MARK: - Simple Syntax Highlighting for Code Blocks

    // Pre-compiled regex patterns (static to avoid recompilation)
    private static let lineCommentRegex = try! NSRegularExpression(pattern: "//[^\n]*")
    private static let blockCommentRegex = try! NSRegularExpression(pattern: "/\\*[\\s\\S]*?\\*/")
    private static let hashCommentRegex = try! NSRegularExpression(pattern: "#[^\n]*")
    private static let doubleStringRegex = try! NSRegularExpression(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"")
    private static let singleStringRegex = try! NSRegularExpression(pattern: "'(?:[^'\\\\]|\\\\.)*'")
    private static let backtickStringRegex = try! NSRegularExpression(pattern: "`(?:[^`\\\\]|\\\\.)*`")
    private static let numberRegex = try! NSRegularExpression(pattern: "\\b\\d+\\.?\\d*\\b")

    /// Index mapping for O(1) highlight lookups
    private struct IndexMapping {
        let utf16ToChar: [Int]           // UTF-16 offset -> character index
        let attrIndices: [AttributedString.Index]  // character index -> AttributedString.Index
    }

    private func buildIndexMapping(code: String, attributed: AttributedString) -> IndexMapping {
        // Build UTF-16 offset to character index mapping - O(n) once
        var utf16ToChar: [Int] = []
        utf16ToChar.reserveCapacity(code.utf16.count + 1)
        var charIdx = 0
        for char in code {
            for _ in 0..<char.utf16.count {
                utf16ToChar.append(charIdx)
            }
            charIdx += 1
        }
        utf16ToChar.append(charIdx)

        // Build character index to AttributedString.Index mapping - O(n) once
        var attrIndices: [AttributedString.Index] = []
        attrIndices.reserveCapacity(charIdx + 1)
        var idx = attributed.startIndex
        attrIndices.append(idx)
        while idx < attributed.endIndex {
            idx = attributed.index(afterCharacter: idx)
            attrIndices.append(idx)
        }

        return IndexMapping(utf16ToChar: utf16ToChar, attrIndices: attrIndices)
    }

    private func highlightCode(_ code: String, language: String?) -> AttributedString {
        var result = AttributedString(code)

        // Define colors based on theme
        let isDark = ThemeManager.shared.selectedTheme.contains("Dark") ||
                     ThemeManager.shared.selectedTheme == "tokyoNight" ||
                     ThemeManager.shared.selectedTheme == "blackout" ||
                     (ThemeManager.shared.selectedTheme == "auto" && ThemeManager.shared.systemAppearanceIsDark)

        let keywordColor = isDark ? Color(red: 0.8, green: 0.5, blue: 0.9) : Color(red: 0.6, green: 0.2, blue: 0.7)
        let stringColor = isDark ? Color(red: 0.6, green: 0.8, blue: 0.5) : Color(red: 0.2, green: 0.5, blue: 0.2)
        let commentColor = isDark ? Color(red: 0.5, green: 0.5, blue: 0.5) : Color(red: 0.4, green: 0.4, blue: 0.4)
        let numberColor = isDark ? Color(red: 0.85, green: 0.7, blue: 0.4) : Color(red: 0.7, green: 0.4, blue: 0.1)
        let typeColor = isDark ? Color(red: 0.4, green: 0.8, blue: 0.9) : Color(red: 0.1, green: 0.5, blue: 0.6)
        let defaultColor = bodyColor

        // Set default color
        result.foregroundColor = defaultColor

        // Build index mapping once for O(1) lookups
        let mapping = buildIndexMapping(code: code, attributed: result)
        let codeNS = code as NSString

        // Define keywords per language
        let keywords: Set<String>
        let types: Set<String>

        switch language?.lowercased() {
        case "swift":
            keywords = ["func", "let", "var", "if", "else", "guard", "return", "import", "class", "struct", "enum", "protocol", "extension", "private", "public", "internal", "fileprivate", "static", "final", "override", "init", "deinit", "self", "super", "nil", "true", "false", "for", "while", "repeat", "switch", "case", "default", "break", "continue", "fallthrough", "where", "in", "do", "try", "catch", "throw", "throws", "rethrows", "defer", "as", "is", "async", "await", "@State", "@Binding", "@Published", "@ObservedObject", "@StateObject", "@Environment", "@MainActor", "some", "any"]
            types = ["String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set", "Optional", "Result", "Error", "View", "Color", "Text", "Button", "VStack", "HStack", "ZStack", "ForEach", "List", "NavigationView", "NavigationStack", "URL", "Data", "Date", "UUID"]
        case "javascript", "js", "typescript", "ts", "jsx", "tsx":
            keywords = ["function", "const", "let", "var", "if", "else", "return", "import", "export", "from", "default", "class", "extends", "new", "this", "super", "null", "undefined", "true", "false", "for", "while", "do", "switch", "case", "break", "continue", "try", "catch", "throw", "finally", "async", "await", "yield", "of", "in", "typeof", "instanceof", "void", "delete", "=>", "interface", "type", "enum", "implements", "private", "public", "protected", "readonly", "static", "abstract", "as"]
            types = ["string", "number", "boolean", "object", "any", "void", "never", "unknown", "Promise", "Array", "Map", "Set", "Date", "Error", "Function", "Object", "String", "Number", "Boolean", "RegExp", "Symbol", "console", "window", "document", "React", "useState", "useEffect", "useRef", "useCallback", "useMemo"]
        case "python", "py":
            keywords = ["def", "class", "if", "elif", "else", "return", "import", "from", "as", "try", "except", "finally", "raise", "with", "for", "while", "break", "continue", "pass", "lambda", "yield", "global", "nonlocal", "assert", "del", "in", "is", "not", "and", "or", "True", "False", "None", "self", "async", "await"]
            types = ["str", "int", "float", "bool", "list", "dict", "tuple", "set", "bytes", "type", "object", "print", "len", "range", "enumerate", "zip", "map", "filter", "sorted", "reversed", "open", "file", "Exception"]
        case "rust", "rs":
            keywords = ["fn", "let", "mut", "const", "if", "else", "match", "return", "use", "mod", "pub", "crate", "self", "super", "struct", "enum", "impl", "trait", "for", "while", "loop", "break", "continue", "move", "ref", "static", "unsafe", "async", "await", "dyn", "where", "as", "in", "true", "false"]
            types = ["i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128", "usize", "f32", "f64", "bool", "char", "str", "String", "Vec", "Option", "Result", "Box", "Rc", "Arc", "Cell", "RefCell", "HashMap", "HashSet", "Self"]
        case "go", "golang":
            keywords = ["func", "var", "const", "if", "else", "return", "import", "package", "type", "struct", "interface", "for", "range", "switch", "case", "default", "break", "continue", "go", "select", "chan", "defer", "map", "make", "new", "nil", "true", "false", "append", "len", "cap", "close", "delete", "copy", "panic", "recover"]
            types = ["string", "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "float32", "float64", "bool", "byte", "rune", "error", "any"]
        default:
            // Generic keywords for unknown languages
            keywords = ["function", "func", "def", "class", "if", "else", "elif", "return", "import", "export", "from", "const", "let", "var", "for", "while", "do", "switch", "case", "break", "continue", "try", "catch", "throw", "finally", "true", "false", "null", "nil", "None", "undefined", "self", "this", "new", "public", "private", "protected", "static", "void", "async", "await"]
            types = ["String", "Int", "Integer", "Float", "Double", "Bool", "Boolean", "Array", "List", "Map", "Dict", "Set", "Object", "Error", "Exception"]
        }

        // 1. Highlight comments (using pre-compiled regex)
        applyHighlight(regex: Self.lineCommentRegex, to: &result, code: codeNS, mapping: mapping, color: commentColor)
        applyHighlight(regex: Self.blockCommentRegex, to: &result, code: codeNS, mapping: mapping, color: commentColor)
        applyHighlight(regex: Self.hashCommentRegex, to: &result, code: codeNS, mapping: mapping, color: commentColor)

        // 2. Highlight strings
        applyHighlight(regex: Self.doubleStringRegex, to: &result, code: codeNS, mapping: mapping, color: stringColor)
        applyHighlight(regex: Self.singleStringRegex, to: &result, code: codeNS, mapping: mapping, color: stringColor)
        applyHighlight(regex: Self.backtickStringRegex, to: &result, code: codeNS, mapping: mapping, color: stringColor)

        // 3. Highlight numbers
        applyHighlight(regex: Self.numberRegex, to: &result, code: codeNS, mapping: mapping, color: numberColor)

        // 4. Highlight keywords
        for keyword in keywords {
            highlightWord(in: &result, code: codeNS, word: keyword, mapping: mapping, color: keywordColor)
        }

        // 5. Highlight types
        for typeName in types {
            highlightWord(in: &result, code: codeNS, word: typeName, mapping: mapping, color: typeColor)
        }

        return result
    }

    /// Apply highlighting using pre-built index mapping - O(m) where m is match count
    private func applyHighlight(regex: NSRegularExpression, to attributed: inout AttributedString, code: NSString, mapping: IndexMapping, color: Color) {
        let matches = regex.matches(in: code as String, options: [], range: NSRange(location: 0, length: code.length))

        for match in matches {
            let loc = match.range.location
            let end = loc + match.range.length

            // Bounds check
            guard loc < mapping.utf16ToChar.count && end <= mapping.utf16ToChar.count else { continue }

            let startChar = mapping.utf16ToChar[loc]
            let endChar = mapping.utf16ToChar[end]

            guard startChar < mapping.attrIndices.count && endChar < mapping.attrIndices.count else { continue }

            // O(1) index lookup instead of O(n) distance calculation
            attributed[mapping.attrIndices[startChar]..<mapping.attrIndices[endChar]].foregroundColor = color
        }
    }

    private func highlightWord(in attributed: inout AttributedString, code: NSString, word: String, mapping: IndexMapping, color: Color) {
        let escapedWord = NSRegularExpression.escapedPattern(for: word)
        guard let regex = try? NSRegularExpression(pattern: "\\b\(escapedWord)\\b") else { return }
        applyHighlight(regex: regex, to: &attributed, code: code, mapping: mapping, color: color)
    }
}
