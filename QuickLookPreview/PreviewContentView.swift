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
    let isDarkMode: Bool
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

    /// Detects potentially sensitive environment and credential files.
    /// NOTE: This is UI-only (shows a warning banner). Users can still copy content.
    private var isEnvFile: Bool {
        let lowercased = state.filename.lowercased()
        let ext = (state.fileURL?.pathExtension ?? "").lowercased()

        // Direct .env files and variants
        if lowercased.hasPrefix(".env") { return true }

        // Environment file variants
        let envPatterns = [".env.example", ".env.template", ".env.sample", ".env.local", ".env.development", ".env.production", ".env.test"]
        if envPatterns.contains(where: { lowercased == $0 || lowercased.hasSuffix($0) }) { return true }

        // Credentials/secrets files
        let credentialNames: Set<String> = [
            "credentials", "secrets", ".credentials", ".secrets",
            "credentials.json", "secrets.json", "secrets.yaml", "secrets.yml",
            "service-account.json", "serviceaccount.json"
        ]
        if credentialNames.contains(lowercased) { return true }

        // AWS config files
        let awsFiles: Set<String> = ["credentials", "config"]
        if awsFiles.contains(lowercased) && (state.fileURL?.path.contains(".aws/") ?? false) { return true }

        // SSH private keys (by name pattern)
        let sshKeyPatterns = ["id_rsa", "id_ed25519", "id_dsa", "id_ecdsa"]
        if sshKeyPatterns.contains(where: { lowercased == $0 || lowercased.hasPrefix($0) }) { return true }

        // Key/certificate files by extension
        let sensitiveExtensions: Set<String> = ["pem", "key", "p12", "pfx", "keystore", "jks"]
        if sensitiveExtensions.contains(ext) { return true }

        // Suffix patterns
        if lowercased.hasSuffix(".credentials") || lowercased.hasSuffix(".secrets") { return true }

        return false
    }

    init(state: PreviewState) {
        self.state = state
        _showRenderedMarkdown = State(initialValue: SharedSettings.shared.markdownRenderMode == "rendered")
        // Skip "Highlighting..." badge entirely when cache provided pre-highlighted content
        _highlightedContent = State(initialValue: state.preHighlightedContent)
        _isReady = State(initialValue: state.preHighlightedContent != nil)
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

                    if isMarkdown && showRenderedMarkdown {
                        // Rendered markdown needs highlighting to complete
                        if isReady {
                            MarkdownRenderedViewLegacy(
                                content: state.content,
                                fontSize: isCompactMode ? settings.fontSize * 0.8 : settings.fontSize
                            )
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        // Code/raw view - show IMMEDIATELY with plain text
                        ScrollView([.horizontal, .vertical]) {
                            HStack(alignment: .top, spacing: 0) {
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
                        .animation(.easeIn(duration: 0.15), value: highlightedContent != nil)
                    }

                    // Non-blocking loading indicator (top-right corner)
                    if !isReady && !(isMarkdown && showRenderedMarkdown) {
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Highlighting...")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .padding(12)
                            Spacer()
                        }
                    }
                }
            }
        }
        .task(id: state.fileURL) {
            await highlightCode()
        }
    }

    private var backgroundColor: Color {
        ThemeManager.shared.backgroundColor
    }

    private func highlightCode() async {
        // PERFORMANCE DIAGNOSTICS: Detailed timing instrumentation
        let startTime = CFAbsoluteTimeGetCurrent()
        perfLog("[dotViewer PERF] highlightCode START - file: %@, lines: %d, language: %@", state.filename, state.lineCount, state.language ?? "nil")

        // Capture MainActor-isolated values before any background dispatch
        let currentTheme = SharedSettings.shared.selectedTheme
        let systemIsDark = state.isDarkMode

        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            let usedFast = FastSyntaxHighlighter.isSupported(state.language)
            perfLog("[dotViewer PERF] highlightCode COMPLETE - total: %.3fs, highlighter: %@", elapsed, usedFast ? "Fast" : "HighlightSwift")
            DotViewerLogger.preview.info("Highlight \(self.state.filename): \(String(format: "%.1f", elapsed * 1000))ms (\(usedFast ? "fast" : "HighlightSwift"), \(self.state.lineCount) lines)")
        }

        // Use pre-highlighted content if available (from cache or pre-warming)
        perfLog("[dotViewer PERF] [+%.3fs] cache check START", CFAbsoluteTimeGetCurrent() - startTime)
        if let preHighlighted = state.preHighlightedContent {
            perfLog("[dotViewer PERF] [+%.3fs] cache check: HIT (pre-highlighted)", CFAbsoluteTimeGetCurrent() - startTime)
            highlightedContent = preHighlighted
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }
        perfLog("[dotViewer PERF] [+%.3fs] cache check: MISS", CFAbsoluteTimeGetCurrent() - startTime)

        // Cooperative cancellation check - bail early if user navigated away
        guard !Task.isCancelled else {
            perfLog("[dotViewer PERF] Task cancelled after cache check")
            return
        }

        // Skip syntax highlighting for very large files (>2000 lines) - show plain text immediately
        // This prevents the UI from hanging on massive files like package-lock.json
        let maxLinesForHighlighting = 2000

        if state.lineCount > maxLinesForHighlighting {
            // Large file - skip highlighting entirely, show plain text immediately
            perfLog("[dotViewer PERF] [+%.3fs] SKIP: file too large (%d > %d lines)", CFAbsoluteTimeGetCurrent() - startTime, state.lineCount, maxLinesForHighlighting)
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // Skip syntax highlighting for unknown file types - auto-detection is very slow
        // Files like .viminfo have no known language, and HighlightSwift's automatic mode
        // runs multiple parsers which can take 10+ seconds
        if state.language == nil {
            perfLog("[dotViewer PERF] [+%.3fs] SKIP: no language detected (would trigger slow auto-detection)", CFAbsoluteTimeGetCurrent() - startTime)
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // Skip highlighting for files explicitly marked as plaintext (history files, logs, etc.)
        // These files have no meaningful syntax and would just waste CPU cycles
        if state.language == "plaintext" {
            perfLog("[dotViewer PERF] [+%.3fs] SKIP: plaintext file (no syntax to highlight)", CFAbsoluteTimeGetCurrent() - startTime)
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // Use custom highlighting for markdown (HighlightSwift has bugs that cause red text)
        if state.language == "markdown" {
            perfLog("[dotViewer PERF] [+%.3fs] PATH: markdown (custom highlighting)", CFAbsoluteTimeGetCurrent() - startTime)
            let markdownStart = CFAbsoluteTimeGetCurrent()
            let result = highlightMarkdownRaw(state.content)
            perfLog("[dotViewer PERF] [+%.3fs] markdown highlighting took: %.3fs", CFAbsoluteTimeGetCurrent() - startTime, CFAbsoluteTimeGetCurrent() - markdownStart)
            highlightedContent = result
            // Cache the result (memory + disk)
            if let modDate = state.modificationDate, let path = state.fileURL?.path {
                HighlightCache.shared.set(
                    path: path,
                    modDate: modDate,
                    theme: currentTheme,
                    language: state.language,
                    isDark: state.isDarkMode,
                    highlighted: result
                )
                perfLog("[dotViewer PERF] highlightCode - cached markdown result for future use")
            }
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // Content-based fast path: skip highlighting for files that don't look like code
        // This catches data files, logs, and other non-code content that has a detected language
        if shouldSkipHighlightingBasedOnContent(state.content) {
            perfLog("[dotViewer PERF] [+%.3fs] SKIP: content-based heuristic (not code-like)", CFAbsoluteTimeGetCurrent() - startTime)
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
            return
        }

        // For other files, use SyntaxHighlighter (which uses FastSyntaxHighlighter for supported languages)
        let isFastSupported = FastSyntaxHighlighter.isSupported(state.language)
        perfLog("[dotViewer PERF] [+%.3fs] PATH: SyntaxHighlighter (FastSyntaxHighlighter supported: %@)", CFAbsoluteTimeGetCurrent() - startTime, isFastSupported ? "YES" : "NO")

        // Cooperative cancellation check - bail before expensive highlighting
        guard !Task.isCancelled else {
            perfLog("[dotViewer PERF] Task cancelled before highlighting")
            return
        }

        let content = state.content
        let language = state.language
        let lineCount = state.lineCount
        let progressiveThreshold = 200

        // Progressive highlighting for files (200+ lines) with FastSyntaxHighlighter support
        if isFastSupported && lineCount >= progressiveThreshold {
            perfLog("[dotViewer PERF] [+%.3fs] PROGRESSIVE: %d lines, highlighting first 150 lines first", CFAbsoluteTimeGetCurrent() - startTime, lineCount)

            // Extract first ~150 lines for immediate highlighting
            let firstChunkLines = 150
            let firstChunk = extractFirstLines(from: content, count: firstChunkLines)

            // Phase 1: Highlight first chunk on a detached .userInitiated task
            let chunkResult: AttributedString? = await Task.detached(priority: .userInitiated) {
                let highlighter = SyntaxHighlighter()
                return try? await highlighter.highlight(code: firstChunk, language: language, theme: currentTheme, isDark: systemIsDark)
            }.value

            guard !Task.isCancelled else {
                perfLog("[dotViewer PERF] Task cancelled after progressive chunk")
                return
            }

            // Show first chunk highlighted + plain text remainder immediately
            if let chunkHighlighted = chunkResult {
                let remainder = String(content.dropFirst(firstChunk.count))
                var remainderAttr = AttributedString(remainder)
                remainderAttr.foregroundColor = nil // Use default text color
                highlightedContent = chunkHighlighted + remainderAttr
                withAnimation(.easeIn(duration: 0.15)) {
                    isReady = true
                }
                perfLog("[dotViewer PERF] [+%.3fs] PROGRESSIVE: first chunk displayed", CFAbsoluteTimeGetCurrent() - startTime)
            }

            // Phase 2: Highlight full file on a detached .utility task in background
            let fullResult: AttributedString? = await Task.detached(priority: .utility) {
                let highlighter = SyntaxHighlighter()
                return try? await highlighter.highlight(code: content, language: language, theme: currentTheme, isDark: systemIsDark)
            }.value

            guard !Task.isCancelled else {
                perfLog("[dotViewer PERF] Task cancelled after full progressive highlight")
                return
            }

            if let fullHighlighted = fullResult {
                // Swap in full result seamlessly (same colors, no flash)
                highlightedContent = fullHighlighted
                // Cache the full result
                if let modDate = state.modificationDate, let path = state.fileURL?.path {
                    HighlightCache.shared.set(
                        path: path,
                        modDate: modDate,
                        theme: currentTheme,
                        language: state.language,
                        isDark: state.isDarkMode,
                        highlighted: fullHighlighted
                    )
                    perfLog("[dotViewer PERF] [+%.3fs] PROGRESSIVE: full result cached", CFAbsoluteTimeGetCurrent() - startTime)
                }
            }

            if !isReady {
                withAnimation(.easeIn(duration: 0.15)) {
                    isReady = true
                }
            }
            return
        }

        // Standard path: highlight entire file on a detached background task
        // Fast path (optimized single-pass scanner) gets more headroom; slow path keeps 2s
        let timeoutNanoseconds: UInt64 = isFastSupported ? 4_000_000_000 : 2_000_000_000
        let highlightStart = CFAbsoluteTimeGetCurrent()

        // Use TaskGroup for reliable timeout with proper cancellation propagation
        let result: AttributedString? = await withTaskGroup(of: AttributedString?.self) { group in
            // Add the highlighting task on a detached executor (off MainActor)
            group.addTask {
                await Task.detached(priority: .userInitiated) {
                    let highlighter = SyntaxHighlighter()
                    return try? await highlighter.highlight(
                        code: content,
                        language: language,
                        theme: currentTheme,
                        isDark: systemIsDark
                    )
                }.value
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
        perfLog("[dotViewer PERF] [+%.3fs] SyntaxHighlighter.highlight took: %.3fs, result: %@", CFAbsoluteTimeGetCurrent() - startTime, highlightDuration, result != nil ? "success" : "nil (timeout?)")

        // Cooperative cancellation check - bail if user navigated away during highlighting
        guard !Task.isCancelled else {
            perfLog("[dotViewer PERF] Task cancelled after highlighting")
            return
        }

        // Use result if available
        if let highlighted = result {
            highlightedContent = highlighted
            // Cache the result (memory + disk)
            if let modDate = state.modificationDate, let path = state.fileURL?.path {
                HighlightCache.shared.set(
                    path: path,
                    modDate: modDate,
                    theme: currentTheme,
                    language: state.language,
                    isDark: state.isDarkMode,
                    highlighted: highlighted
                )
                perfLog("[dotViewer PERF] [+%.3fs] cached result for future use", CFAbsoluteTimeGetCurrent() - startTime)
            }
        }

        // Fade in the content smoothly (whether highlighting succeeded or timed out)
        perfLog("[dotViewer PERF] [+%.3fs] setting isReady = true, starting animation", CFAbsoluteTimeGetCurrent() - startTime)
        withAnimation(.easeIn(duration: 0.15)) {
            isReady = true
        }
    }

    /// Extract the first N lines from a string efficiently
    private func extractFirstLines(from content: String, count: Int) -> String {
        var linesSeen = 0
        var endIndex = content.startIndex
        for char in content {
            if char == "\n" {
                linesSeen += 1
                if linesSeen >= count {
                    break
                }
            }
            endIndex = content.index(after: endIndex)
        }
        return String(content[content.startIndex..<endIndex])
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
    @MainActor
    private func highlightMarkdownRaw(_ content: String) -> AttributedString {
        var attributed = AttributedString(content)
        let text = content

        // Get theme-specific colors (ThemeManager is @MainActor, so this is safe)
        let colors = markdownColorsForTheme(ThemeManager.shared.selectedTheme)

        // Helper to apply color to regex matches
        // Uses .appKit.foregroundColor (NSColor) to survive RTF cache serialization
        func applyPattern(_ pattern: String, color: NSColor, bold: Bool = false) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)

            for match in matches {
                guard let range = Range(match.range, in: text),
                      let attrRange = Range(range, in: attributed) else { continue }
                attributed[attrRange].appKit.foregroundColor = color
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
        applyPattern("\\*\\*[^*]+?\\*\\*", color: colors.bold, bold: true)  // Bold (non-greedy)
        applyPattern("^\\s*[-*+]\\s", color: colors.heading)               // List markers
        applyPattern("^\\s*\\d+\\.\\s", color: colors.heading)             // Numbered lists

        return attributed
    }

    /// Returns theme-matched colors for markdown syntax highlighting
    /// Uses NSColor to ensure colors survive RTF cache serialization
    @MainActor
    private func markdownColorsForTheme(_ theme: String) -> (heading: NSColor, code: NSColor, link: NSColor, bold: NSColor, quote: NSColor) {
        switch theme {
        case "atomOneLight":
            return (
                heading: NSColor(Color(hex: "#a626a4")),  // Purple - keywords
                code: NSColor(Color(hex: "#50a14f")),     // Green - strings
                link: NSColor(Color(hex: "#4078f2")),     // Blue - functions
                bold: NSColor(Color(hex: "#383a42")),     // Dark gray - text
                quote: NSColor(Color(hex: "#a0a1a7"))     // Gray - comments
            )
        case "atomOneDark", "blackout":
            return (
                heading: NSColor(Color(hex: "#c678dd")),  // Purple - keywords
                code: NSColor(Color(hex: "#98c379")),     // Green - strings
                link: NSColor(Color(hex: "#61afef")),     // Blue - functions
                bold: NSColor(Color(hex: "#abb2bf")),     // Light gray - text
                quote: NSColor(Color(hex: "#5c6370"))     // Gray - comments
            )
        case "github":
            return (
                heading: NSColor(Color(hex: "#d73a49")),  // Red - keywords
                code: NSColor(Color(hex: "#032f62")),     // Dark blue - strings
                link: NSColor(Color(hex: "#0366d6")),     // Blue - links
                bold: NSColor(Color(hex: "#24292e")),     // Dark - text
                quote: NSColor(Color(hex: "#6a737d"))     // Gray - comments
            )
        case "githubDark":
            return (
                heading: NSColor(Color(hex: "#ff7b72")),  // Salmon - keywords
                code: NSColor(Color(hex: "#a5d6ff")),     // Light blue - strings
                link: NSColor(Color(hex: "#58a6ff")),     // Blue - links
                bold: NSColor(Color(hex: "#c9d1d9")),     // Light - text
                quote: NSColor(Color(hex: "#8b949e"))     // Gray - comments
            )
        case "xcode":
            return (
                heading: NSColor(Color(hex: "#9b2393")),  // Purple - keywords
                code: NSColor(Color(hex: "#c41a16")),     // Red - strings
                link: NSColor(Color(hex: "#0f68a0")),     // Blue - links
                bold: NSColor(Color(hex: "#000000")),     // Black - text
                quote: NSColor(Color(hex: "#5d6c79"))     // Gray - comments
            )
        case "xcodeDark":
            return (
                heading: NSColor(Color(hex: "#fc5fa3")),  // Pink - keywords
                code: NSColor(Color(hex: "#fc6a5d")),     // Coral - strings
                link: NSColor(Color(hex: "#6699ff")),     // Blue - links
                bold: NSColor(Color(hex: "#ffffff")),     // White - text
                quote: NSColor(Color(hex: "#7f8c98"))     // Gray - comments
            )
        case "solarizedLight":
            return (
                heading: NSColor(Color(hex: "#859900")),  // Green - keywords
                code: NSColor(Color(hex: "#2aa198")),     // Cyan - strings
                link: NSColor(Color(hex: "#268bd2")),     // Blue - links
                bold: NSColor(Color(hex: "#657b83")),     // Base00 - text
                quote: NSColor(Color(hex: "#93a1a1"))     // Base1 - comments
            )
        case "solarizedDark":
            return (
                heading: NSColor(Color(hex: "#859900")),  // Green - keywords
                code: NSColor(Color(hex: "#2aa198")),     // Cyan - strings
                link: NSColor(Color(hex: "#268bd2")),     // Blue - links
                bold: NSColor(Color(hex: "#839496")),     // Base0 - text
                quote: NSColor(Color(hex: "#586e75"))     // Base01 - comments
            )
        case "tokyoNight":
            return (
                heading: NSColor(Color(hex: "#bb9af7")),  // Purple - keywords
                code: NSColor(Color(hex: "#9ece6a")),     // Green - strings
                link: NSColor(Color(hex: "#7aa2f7")),     // Blue - links
                bold: NSColor(Color(hex: "#a9b1d6")),     // Light - text
                quote: NSColor(Color(hex: "#565f89"))     // Gray - comments
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

// MarkdownRenderedViewLegacy, MarkdownBlock, MarkdownBlockView, and related types
// have been extracted to MarkdownRenderedViewLegacy.swift for maintainability.
