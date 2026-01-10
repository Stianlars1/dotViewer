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

    init(state: PreviewState) {
        self.state = state
        // Initialize markdown mode from settings
        _showRenderedMarkdown = State(initialValue: SharedSettings.shared.markdownRenderMode == "rendered")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (optional)
            if settings.showPreviewHeader {
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

            // Truncation warning
            if state.isTruncated, settings.showTruncationWarning, let message = state.truncationMessage {
                TruncationBanner(message: message)
            }

            // Content area
            ZStack(alignment: .topLeading) {
                // Background always visible
                backgroundColor

                // Loading indicator while highlighting
                if !isReady {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Content (fades in when ready)
                if isMarkdown && showRenderedMarkdown {
                    // Rendered markdown view using WKWebView
                    MarkdownWebView(
                        markdown: state.content,
                        baseURL: state.fileURL?.deletingLastPathComponent(),
                        fontSize: settings.fontSize
                    )
                    .opacity(isReady ? 1 : 0)
                } else {
                    // Code view
                    GeometryReader { geometry in
                        ScrollView([.horizontal, .vertical]) {
                            HStack(alignment: .top, spacing: 0) {
                                if settings.showLineNumbers {
                                    LineNumbersColumn(
                                        lineCount: state.lineCount,
                                        fontSize: settings.fontSize
                                    )
                                }

                                CodeContentView(
                                    plainContent: state.content,
                                    highlightedContent: highlightedContent,
                                    fontSize: settings.fontSize
                                )
                            }
                            .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .topLeading)
                        }
                    }
                    .opacity(isReady ? 1 : 0)
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
        let highlighter = SyntaxHighlighter()
        do {
            let result = try await highlighter.highlight(
                code: state.content,
                language: state.language
            )
            highlightedContent = result
        } catch {
            // Keep plain text - highlightedContent stays nil
        }

        // Fade in the content smoothly
        withAnimation(.easeIn(duration: 0.15)) {
            isReady = true
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
            // File icon and name
            HStack(spacing: 8) {
                Image(systemName: iconForLanguage(language))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(filename)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }

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

            // Open in App button
            if settings.showOpenInAppButton, let url = fileURL {
                Button {
                    openInPreferredApp(url: url)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 11))
                        if let editorName = settings.preferredEditorName {
                            Text(editorName)
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(Color.green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.borderless)
                .help(settings.preferredEditorName != nil ? "Open in \(settings.preferredEditorName!)" : "Open in default app")
            }

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

    private func openInPreferredApp(url: URL) {
        if let bundleId = settings.preferredEditorBundleId,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            // Open with preferred app
            NSWorkspace.shared.open(
                [url],
                withApplicationAt: appURL,
                configuration: NSWorkspace.OpenConfiguration()
            ) { app, error in
                if let error = error {
                    print("[PreviewContentView] Error opening file: \(error.localizedDescription)")
                } else {
                    print("[PreviewContentView] ✅ Opened file in \(app?.localizedName ?? "app")")
                }
            }
        } else {
            // Open with system default
            NSWorkspace.shared.open(url)
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

// MARK: - Line Numbers Column

struct LineNumbersColumn: View {
    let lineCount: Int
    let fontSize: Double

    private let maxDisplayLines = 5000

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...min(lineCount, maxDisplayLines), id: \.self) { line in
                Text("\(line)")
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(height: fontSize * 1.4)
            }
        }
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

    // Theme-aware color palette
    private var isDarkTheme: Bool {
        let theme = ThemeManager.shared.selectedTheme
        return theme.contains("Dark") || theme == "tokyoNight" ||
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
                    ForEach(parseMarkdownBlocks(content), id: \.id) { block in
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

struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: MarkdownBlockType
    let content: String
    var language: String? = nil
    var imageURL: String? = nil
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
                    Text(block.content)
                        .font(.system(size: fontSize * 0.9, design: .monospaced))
                        .foregroundStyle(bodyColor)
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
}

