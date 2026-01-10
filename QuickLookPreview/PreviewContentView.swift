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
                    // Rendered markdown view
                    MarkdownRenderedView(content: state.content, fontSize: settings.fontSize)
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
    let isMarkdown: Bool
    @Binding var showRenderedMarkdown: Bool

    @State private var copied = false

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

// MARK: - Markdown Rendered View

struct MarkdownRenderedView: View {
    let content: String
    let fontSize: Double

    private var renderedContent: AttributedString {
        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .inlineOnlyPreservingWhitespace
            return try AttributedString(markdown: content, options: options)
        } catch {
            return AttributedString(content)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Parse content line by line for better markdown rendering
                    ForEach(parseMarkdownBlocks(content), id: \.id) { block in
                        MarkdownBlockView(block: block, fontSize: fontSize)
                    }
                }
                .padding(20)
                .frame(minWidth: geometry.size.width, alignment: .topLeading)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func parseMarkdownBlocks(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: "\n")
        var currentIndex = 0

        while currentIndex < lines.count {
            let line = lines[currentIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("# ") {
                blocks.append(MarkdownBlock(type: .h1, content: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(MarkdownBlock(type: .h2, content: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("### ") {
                blocks.append(MarkdownBlock(type: .h3, content: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("#### ") {
                blocks.append(MarkdownBlock(type: .h4, content: String(trimmed.dropFirst(5))))
            } else if trimmed.hasPrefix("```") {
                // Code block - collect until closing ```
                var codeLines: [String] = []
                currentIndex += 1
                while currentIndex < lines.count && !lines[currentIndex].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[currentIndex])
                    currentIndex += 1
                }
                blocks.append(MarkdownBlock(type: .codeBlock, content: codeLines.joined(separator: "\n")))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(MarkdownBlock(type: .listItem, content: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("> ") {
                blocks.append(MarkdownBlock(type: .blockquote, content: String(trimmed.dropFirst(2))))
            } else if trimmed.isEmpty {
                // Skip empty lines
            } else {
                blocks.append(MarkdownBlock(type: .paragraph, content: line))
            }

            currentIndex += 1
        }

        return blocks
    }
}

struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: MarkdownBlockType
    let content: String
}

enum MarkdownBlockType {
    case h1, h2, h3, h4
    case paragraph
    case codeBlock
    case listItem
    case blockquote
}

struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let fontSize: Double

    var body: some View {
        switch block.type {
        case .h1:
            Text(parseInlineMarkdown(block.content))
                .font(.system(size: fontSize * 2, weight: .bold))
                .padding(.bottom, 8)
        case .h2:
            Text(parseInlineMarkdown(block.content))
                .font(.system(size: fontSize * 1.6, weight: .bold))
                .padding(.bottom, 6)
        case .h3:
            Text(parseInlineMarkdown(block.content))
                .font(.system(size: fontSize * 1.3, weight: .semibold))
                .padding(.bottom, 4)
        case .h4:
            Text(parseInlineMarkdown(block.content))
                .font(.system(size: fontSize * 1.1, weight: .semibold))
                .padding(.bottom, 2)
        case .paragraph:
            Text(parseInlineMarkdown(block.content))
                .font(.system(size: fontSize))
        case .codeBlock:
            Text(block.content)
                .font(.system(size: fontSize * 0.9, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        case .listItem:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: fontSize))
                Text(parseInlineMarkdown(block.content))
                    .font(.system(size: fontSize))
            }
        case .blockquote:
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 3)
                Text(parseInlineMarkdown(block.content))
                    .font(.system(size: fontSize))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text)
        } catch {
            return AttributedString(text)
        }
    }
}

