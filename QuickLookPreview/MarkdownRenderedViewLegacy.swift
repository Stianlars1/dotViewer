import SwiftUI
import AppKit

// MARK: - Markdown Data Types

struct TaskItem: Identifiable {
    let id: Int
    let checked: Bool
    let text: String
}

struct MarkdownBlock: Identifiable {
    /// Deterministic ID based on block position to avoid unnecessary SwiftUI re-renders.
    /// UUID() would cause every block to be treated as new on each parse.
    let id: Int
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

// MARK: - Legacy Markdown Rendered View (Typora-inspired SwiftUI version)
// Preserved as fallback in case WKWebView has issues

struct MarkdownRenderedViewLegacy: View {
    let content: String
    let fontSize: Double

    // Cached parsed blocks to prevent regeneration on every render
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
                blocks.append(MarkdownBlock(id: blocks.count, type: .paragraph, content: joined))
                paragraphBuffer.removeAll()
            }
        }

        while currentIndex < lines.count {
            let line = lines[currentIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for block-level elements (these interrupt paragraphs)
            if trimmed.hasPrefix("# ") {
                flushParagraph()
                blocks.append(MarkdownBlock(id: blocks.count, type: .h1, content: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("## ") {
                flushParagraph()
                blocks.append(MarkdownBlock(id: blocks.count, type: .h2, content: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(id: blocks.count, type: .h3, content: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("#### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(id: blocks.count, type: .h4, content: String(trimmed.dropFirst(5))))
            } else if trimmed.hasPrefix("##### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(id: blocks.count, type: .h5, content: String(trimmed.dropFirst(6))))
            } else if trimmed.hasPrefix("###### ") {
                flushParagraph()
                blocks.append(MarkdownBlock(id: blocks.count, type: .h6, content: String(trimmed.dropFirst(7))))
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
                blocks.append(MarkdownBlock(id: blocks.count, type: .codeBlock, content: codeLines.joined(separator: "\n"), language: language))
            } else if let imageMatch = trimmed.firstMatch(of: /^!\[([^\]]*)\]\(([^)]+)\)$/) {
                // Image: ![alt](url)
                flushParagraph()
                let alt = String(imageMatch.1)
                let url = String(imageMatch.2)
                blocks.append(MarkdownBlock(id: blocks.count, type: .image, content: alt, imageURL: url))
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
                    var block = MarkdownBlock(id: blocks.count, type: .table, content: "")
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
                        taskItems.append(TaskItem(id: taskItems.count, checked: isChecked, text: text))
                        currentIndex += 1
                    } else if taskLine.hasPrefix("- [") || taskLine.hasPrefix("* [") {
                        // Malformed task item - skip
                        currentIndex += 1
                    } else {
                        break
                    }
                }

                if !taskItems.isEmpty {
                    var block = MarkdownBlock(id: blocks.count, type: .taskList, content: "")
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
                blocks.append(MarkdownBlock(id: blocks.count, type: .unorderedList, content: listItems.joined(separator: "\n")))
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
                blocks.append(MarkdownBlock(id: blocks.count, type: .orderedList, content: listItems.joined(separator: "\n")))
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
                blocks.append(MarkdownBlock(id: blocks.count, type: .blockquote, content: quoteLines.joined(separator: "\n")))
            } else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                blocks.append(MarkdownBlock(id: blocks.count, type: .horizontalRule, content: ""))
            } else if trimmed.isEmpty {
                // Empty line - flush paragraph and add spacer
                flushParagraph()
                blocks.append(MarkdownBlock(id: blocks.count, type: .spacer, content: ""))
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

// MARK: - Markdown Block View

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
                            Text("\u{2022}")
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
    // SAFETY NOTE: These use `try!` because patterns are compile-time literals that
    // have been tested. Failure indicates a programming error, not a runtime condition.
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
