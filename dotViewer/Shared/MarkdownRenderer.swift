import Foundation
import AppKit

public enum MarkdownRenderer {
    public static func renderHTML(from markdown: String) -> String {
        convertMarkdownToHTML(markdown)
    }

    public static func generateTOC(from markdown: String) -> String? {
        let lines = markdown.components(separatedBy: "\n")
        var headings: [(level: Int, text: String, slug: String)] = []
        var inFencedBlock = false
        var currentFence = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Track fenced code blocks — must match convertMarkdownToHTML logic
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let fence = trimmed.hasPrefix("```") ? "```" : "~~~"
                if inFencedBlock && currentFence == fence {
                    inFencedBlock = false
                    currentFence = ""
                } else if !inFencedBlock {
                    inFencedBlock = true
                    currentFence = fence
                }
                continue
            }

            if inFencedBlock { continue }

            guard trimmed.hasPrefix("#") else { continue }
            let level = min(trimmed.prefix(while: { $0 == "#" }).count, 6)
            let afterHashes = trimmed.dropFirst(level)
            guard afterHashes.isEmpty || afterHashes.hasPrefix(" ") else { continue }
            let text = afterHashes.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: #"\s+#+\s*$"#, with: "", options: .regularExpression)
            let slug = generateSlug(text)
            headings.append((level, text, slug))
        }

        guard headings.count >= 2 else { return nil }

        var html = "<ul>"
        for heading in headings {
            let cssClass = "toc-h\(heading.level)"
            html += "<li class=\"\(cssClass)\"><a href=\"#\(heading.slug)\">\(escapeHTML(heading.text))</a></li>"
        }
        html += "</ul>"
        return html
    }

    private static func generateSlug(_ text: String) -> String {
        let stripped = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return stripped.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)
    }

    // MARK: - Block-level parsing

    private static func convertMarkdownToHTML(_ markdown: String) -> String {
        var html = ""
        var lines = markdown.components(separatedBy: "\n")
        if let firstLine = lines.first {
            lines[0] = stripUTF8BOM(firstLine)
        }
        var i = 0

        if let (frontmatterHTML, nextIndex) = parseLeadingYAMLFrontmatter(lines: lines) {
            html += frontmatterHTML
            i = nextIndex
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // === Fenced code blocks ===
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let fence = trimmed.hasPrefix("```") ? "```" : "~~~"
                let lang = String(trimmed.dropFirst(fence.count)).trimmingCharacters(in: .whitespaces)
                let langAttr = lang.isEmpty ? "" : " class=\"language-\(escapeHTML(lang))\""
                let langLabel = lang.isEmpty ? "" : "<div class=\"code-lang\">\(escapeHTML(lang))</div>"
                var codeLines: [String] = []
                i += 1
                while i < lines.count {
                    if lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(fence) {
                        i += 1
                        break
                    }
                    codeLines.append(lines[i])
                    i += 1
                }
                html += "<pre>\(langLabel)<code\(langAttr)>\(escapeHTML(codeLines.joined(separator: "\n")))</code></pre>\n"
                continue
            }

            // === Empty lines ===
            if trimmed.isEmpty {
                i += 1
                continue
            }

            // === HTML blocks (pass-through) ===
            if looksLikeHTMLBlock(trimmed) {
                html += line + "\n"
                i += 1
                continue
            }

            // === ATX Headings ===
            if trimmed.hasPrefix("#") {
                let level = min(trimmed.prefix(while: { $0 == "#" }).count, 6)
                let afterHashes = trimmed.dropFirst(level)
                if afterHashes.isEmpty || afterHashes.hasPrefix(" ") {
                    let text = afterHashes.trimmingCharacters(in: .whitespaces)
                    let cleaned = text.replacingOccurrences(
                        of: #"\s+#+\s*$"#, with: "", options: .regularExpression
                    )
                    let slug = generateSlug(cleaned)
                    html += "<h\(level) id=\"\(slug)\">\(processInline(cleaned))</h\(level)>\n"
                    i += 1
                    continue
                }
            }

            // === Setext Headings (underline-style) ===
            if (i + 1) < lines.count && !trimmed.isEmpty
                && !trimmed.hasPrefix(">") && !isListItem(trimmed) {
                let nextTrimmed = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if !nextTrimmed.isEmpty && nextTrimmed.allSatisfy({ $0 == "=" }) && nextTrimmed.count >= 2 {
                    let slug = generateSlug(trimmed)
                    html += "<h1 id=\"\(slug)\">\(processInline(trimmed))</h1>\n"
                    i += 2
                    continue
                }
                if !nextTrimmed.isEmpty && nextTrimmed.allSatisfy({ $0 == "-" }) && nextTrimmed.count >= 2
                    && !isHorizontalRule(trimmed) {
                    let slug = generateSlug(trimmed)
                    html += "<h2 id=\"\(slug)\">\(processInline(trimmed))</h2>\n"
                    i += 2
                    continue
                }
            }

            // === Horizontal rules ===
            if isHorizontalRule(trimmed) {
                html += "<hr>\n"
                i += 1
                continue
            }

            // === GFM Tables ===
            if trimmed.contains("|") && (i + 1) < lines.count {
                let nextTrimmed = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if isTableSeparator(nextTrimmed) {
                    html += parseTable(lines: lines, startIndex: &i)
                    continue
                }
            }

            // === Blockquotes (multi-line merge) ===
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count {
                    let qt = lines[i].trimmingCharacters(in: .whitespaces)
                    if qt.hasPrefix(">") {
                        var content = String(qt.dropFirst())
                        if content.hasPrefix(" ") { content = String(content.dropFirst()) }
                        quoteLines.append(content)
                        i += 1
                    } else if !qt.isEmpty && !quoteLines.isEmpty
                                && !qt.hasPrefix("#") && !qt.hasPrefix("```")
                                && !isListItem(qt) && !looksLikeHTMLBlock(qt) {
                        quoteLines.append(qt)
                        i += 1
                    } else {
                        break
                    }
                }
                let innerHTML = convertMarkdownToHTML(quoteLines.joined(separator: "\n"))
                html += "<blockquote>\(innerHTML)</blockquote>\n"
                continue
            }

            // === Lists ===
            if isListItem(trimmed) {
                html += parseList(lines: lines, index: &i)
                continue
            }

            // === Paragraphs (multi-line merge) ===
            var paraLines: [String] = []
            while i < lines.count {
                let pt = lines[i].trimmingCharacters(in: .whitespaces)
                if pt.isEmpty { break }
                if pt.hasPrefix("#") || pt.hasPrefix("```") || pt.hasPrefix("~~~") { break }
                if pt.hasPrefix(">") || isListItem(pt) || looksLikeHTMLBlock(pt) { break }
                if isHorizontalRule(pt) { break }
                if pt.contains("|") && (i + 1) < lines.count
                    && isTableSeparator(lines[i + 1].trimmingCharacters(in: .whitespaces)) { break }
                paraLines.append(pt)
                i += 1
            }
            if !paraLines.isEmpty {
                html += "<p>\(processInline(paraLines.joined(separator: "\n")))</p>\n"
            }
        }

        return html
    }

    private static func stripUTF8BOM(_ line: String) -> String {
        guard line.hasPrefix("\u{FEFF}") else { return line }
        return String(line.dropFirst())
    }

    private static func parseLeadingYAMLFrontmatter(lines: [String]) -> (String, Int)? {
        guard !lines.isEmpty else { return nil }
        guard lines[0].trimmingCharacters(in: .whitespaces) == "---" else { return nil }

        var contentLines: [String] = []
        var hasMetadataLikeLine = false
        var closingIndex: Int?

        var i = 1
        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed == "---" || trimmed == "..." {
                closingIndex = i
                break
            }
            contentLines.append(lines[i])
            if parseFrontmatterKeyValue(trimmed) != nil {
                hasMetadataLikeLine = true
            }
            i += 1
        }

        guard let close = closingIndex, hasMetadataLikeLine else { return nil }

        var html = "<div class=\"frontmatter\" data-format=\"yaml\">\n"
        for contentLine in contentLines {
            let trimmed = contentLine.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if let (key, value) = parseFrontmatterKeyValue(trimmed) {
                html += "<div class=\"frontmatter-row\"><span class=\"frontmatter-key\">\(escapeHTML(key)):</span><span class=\"frontmatter-value\">\(escapeHTML(value))</span></div>\n"
            } else {
                html += "<div class=\"frontmatter-row\"><span class=\"frontmatter-raw\">\(escapeHTML(trimmed))</span></div>\n"
            }
        }
        html += "</div>\n"
        return (html, close + 1)
    }

    private static func parseFrontmatterKeyValue(_ line: String) -> (key: String, value: String)? {
        guard let colonIndex = line.firstIndex(of: ":") else { return nil }
        let rawKey = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
        guard !rawKey.isEmpty else { return nil }
        guard rawKey.range(of: #"^[A-Za-z0-9_.-]+$"#, options: .regularExpression) != nil else {
            return nil
        }

        let valueStart = line.index(after: colonIndex)
        let rawValue = String(line[valueStart...]).trimmingCharacters(in: .whitespaces)
        return (rawKey, rawValue)
    }

    // MARK: - HTML block detection

    private static let blockTags: Set<String> = [
        "address", "article", "aside", "blockquote", "center", "details",
        "dialog", "dd", "div", "dl", "dt", "fieldset", "figcaption",
        "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6",
        "header", "hr", "li", "main", "nav", "ol", "p", "pre", "section",
        "summary", "table", "tbody", "td", "tfoot", "th", "thead", "tr",
        "ul", "video", "audio", "canvas", "iframe", "source", "picture"
    ]

    private static func looksLikeHTMLBlock(_ line: String) -> Bool {
        guard line.hasPrefix("<") else { return false }
        if line.hasPrefix("<!--") { return true }
        let rest = line.dropFirst()
        let isClosing = rest.hasPrefix("/")
        let tagPart = isClosing ? rest.dropFirst() : rest
        let tagName = String(tagPart.prefix(while: { $0.isLetter || $0.isNumber })).lowercased()
        return blockTags.contains(tagName)
    }

    // MARK: - Horizontal rule

    private static func isHorizontalRule(_ line: String) -> Bool {
        let chars = line.filter { !$0.isWhitespace }
        guard chars.count >= 3, let first = chars.first else { return false }
        guard first == "-" || first == "*" || first == "_" else { return false }
        return chars.allSatisfy { $0 == first }
    }

    // MARK: - Table parsing

    private static func isTableSeparator(_ line: String) -> Bool {
        line.range(of: #"^\|?(\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?$"#, options: .regularExpression) != nil
    }

    private static func parseTableRow(_ row: String) -> [String] {
        var t = row.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("|") { t = String(t.dropFirst()) }
        if t.hasSuffix("|") { t = String(t.dropLast()) }
        return t.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func parseAlignments(_ separator: String) -> [String] {
        parseTableRow(separator).map { cell in
            let c = cell.trimmingCharacters(in: .whitespaces)
            let left = c.hasPrefix(":")
            let right = c.hasSuffix(":")
            if left && right { return "center" }
            if right { return "right" }
            if left { return "left" }
            return ""
        }
    }

    private static func parseTable(lines: [String], startIndex i: inout Int) -> String {
        let headerCells = parseTableRow(lines[i].trimmingCharacters(in: .whitespaces))
        let alignments = parseAlignments(lines[i + 1].trimmingCharacters(in: .whitespaces))
        i += 2

        var html = "<table>\n<thead>\n<tr>\n"
        for (ci, cell) in headerCells.enumerated() {
            let align = ci < alignments.count ? alignments[ci] : ""
            let style = align.isEmpty ? "" : " style=\"text-align:\(align)\""
            html += "<th\(style)>\(processInline(cell))</th>\n"
        }
        html += "</tr>\n</thead>\n<tbody>\n"

        while i < lines.count {
            let rowLine = lines[i].trimmingCharacters(in: .whitespaces)
            guard !rowLine.isEmpty, rowLine.contains("|") else { break }
            let cells = parseTableRow(rowLine)
            html += "<tr>\n"
            let colCount = max(cells.count, headerCells.count)
            for ci in 0..<colCount {
                let cell = ci < cells.count ? cells[ci] : ""
                let align = ci < alignments.count ? alignments[ci] : ""
                let style = align.isEmpty ? "" : " style=\"text-align:\(align)\""
                html += "<td\(style)>\(processInline(cell))</td>\n"
            }
            html += "</tr>\n"
            i += 1
        }
        html += "</tbody>\n</table>\n"
        return html
    }

    // MARK: - List parsing

    private static func isListItem(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        if isHorizontalRule(t) { return false }
        if t.range(of: #"^[-*+]\s+"#, options: .regularExpression) != nil { return true }
        if t.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil { return true }
        return false
    }

    private static func listIndent(_ line: String) -> Int {
        line.prefix(while: { $0 == " " }).count
    }

    private static func parseList(lines: [String], index i: inout Int) -> String {
        let firstTrimmed = lines[i].trimmingCharacters(in: .whitespaces)
        let isOrdered = firstTrimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil
        let tag = isOrdered ? "ol" : "ul"
        let baseIndent = listIndent(lines[i])

        var html = "<\(tag)>\n"

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                // Peek ahead: if next non-empty line is a list item at same/deeper indent, continue
                var j = i + 1
                while j < lines.count && lines[j].trimmingCharacters(in: .whitespaces).isEmpty { j += 1 }
                if j < lines.count && isListItem(lines[j].trimmingCharacters(in: .whitespaces))
                    && listIndent(lines[j]) >= baseIndent {
                    i += 1
                    continue
                }
                break
            }

            let indent = listIndent(line)

            // Sub-list at deeper indent
            if indent > baseIndent && isListItem(trimmed) {
                let subHTML = parseList(lines: lines, index: &i)
                if html.hasSuffix("</li>\n") {
                    html = String(html.dropLast("</li>\n".count))
                    html += "\n\(subHTML)</li>\n"
                } else {
                    html += subHTML
                }
                continue
            }

            // Not our list item — stop
            if !isListItem(trimmed) || indent < baseIndent { break }

            // Parse item: check task list FIRST, then UL, then OL
            if let match = trimmed.firstMatch(of: #/^[-*+]\s+\[([ xX])\]\s+(.*)/#) {
                let checked = String(match.1).lowercased() == "x"
                let content = String(match.2)
                let attr = checked ? " checked disabled" : " disabled"
                html += "<li class=\"task-item\"><input type=\"checkbox\"\(attr)> \(processInline(content))</li>\n"
            } else if let match = trimmed.firstMatch(of: #/^[-*+]\s+(.*)/#) {
                html += "<li>\(processInline(String(match.1)))</li>\n"
            } else if let match = trimmed.firstMatch(of: #/^[0-9]+[.]\s+(.*)/#) {
                html += "<li>\(processInline(String(match.1)))</li>\n"
            }
            i += 1
        }

        html += "</\(tag)>\n"
        return html
    }

    // MARK: - Inline processing

    private static func processInline(_ text: String) -> String {
        var result = ""
        let chars = Array(text)
        var i = 0

        while i < chars.count {
            // Hard line break: two+ trailing spaces before newline
            if chars[i] == "\n" {
                // Check if previous chars were spaces (hard break)
                let trailing = result.reversed().prefix(while: { $0 == " " }).count
                if trailing >= 2 {
                    // Remove trailing spaces and insert <br>
                    result = String(result.dropLast(trailing))
                    result += "<br>\n"
                } else {
                    result += "\n"
                }
                i += 1
                continue
            }

            // Backslash escape: \* \# \[ etc.
            if chars[i] == "\\" && i + 1 < chars.count {
                let next = chars[i + 1]
                if "\\`*_{}[]()#+-.!|~>".contains(next) {
                    result += escapeChar(next)
                    i += 2
                    continue
                }
            }

            // Inline code: `code`
            if chars[i] == "`" {
                if let end = indexOf(chars, from: i + 1, char: "`") {
                    let code = String(chars[(i + 1)..<end])
                    result += "<code>\(escapeHTML(code))</code>"
                    i = end + 1
                    continue
                }
            }

            // HTML tags: pass through <tag...> sequences
            if chars[i] == "<" && i + 1 < chars.count {
                let next = chars[i + 1]
                if next.isLetter || next == "/" || next == "!" {
                    if let end = indexOf(chars, from: i + 1, char: ">") {
                        result += String(chars[i...end])
                        i = end + 1
                        continue
                    }
                }
            }

            // Auto-link: bare URLs (https://... or http://...)
            if chars[i] == "h" && i + 7 < chars.count {
                let remaining = String(chars[i...])
                if remaining.hasPrefix("https://") || remaining.hasPrefix("http://") {
                    let urlChars = remaining.prefix(while: { !$0.isWhitespace && $0 != ")" && $0 != ">" && $0 != "\"" })
                    var url = String(urlChars)
                    // Strip trailing punctuation that's likely not part of URL
                    while url.hasSuffix(".") || url.hasSuffix(",") || url.hasSuffix(";") || url.hasSuffix(":") {
                        url = String(url.dropLast())
                    }
                    if url.count > 8 {
                        result += "<a href=\"\(escapeHTML(url))\">\(escapeHTML(url))</a>"
                        i += url.count
                        continue
                    }
                }
            }

            // Image: ![alt](url) — must check BEFORE link
            if chars[i] == "!" && i + 1 < chars.count && chars[i + 1] == "[" {
                if let (imgHTML, endIdx) = parseLinkOrImage(chars, from: i, isImage: true) {
                    result += imgHTML
                    i = endIdx
                    continue
                }
            }

            // Link: [text](url)
            if chars[i] == "[" {
                if let (linkHTML, endIdx) = parseLinkOrImage(chars, from: i, isImage: false) {
                    result += linkHTML
                    i = endIdx
                    continue
                }
            }

            // Bold+Italic: ***text*** or ___text___
            if chars[i] == "*" && i + 2 < chars.count && chars[i + 1] == "*" && chars[i + 2] == "*" {
                if let end = findDelimiter(chars, from: i + 3, delimiter: ["*", "*", "*"]) {
                    let inner = String(chars[(i + 3)..<end])
                    result += "<strong><em>\(processInline(inner))</em></strong>"
                    i = end + 3
                    continue
                }
            }
            if chars[i] == "_" && i + 2 < chars.count && chars[i + 1] == "_" && chars[i + 2] == "_" {
                if let end = findDelimiter(chars, from: i + 3, delimiter: ["_", "_", "_"]) {
                    let inner = String(chars[(i + 3)..<end])
                    result += "<strong><em>\(processInline(inner))</em></strong>"
                    i = end + 3
                    continue
                }
            }

            // Bold: **text** or __text__
            if chars[i] == "*" && i + 1 < chars.count && chars[i + 1] == "*" {
                if let end = findDelimiter(chars, from: i + 2, delimiter: ["*", "*"]) {
                    let inner = String(chars[(i + 2)..<end])
                    result += "<strong>\(processInline(inner))</strong>"
                    i = end + 2
                    continue
                }
            }
            if chars[i] == "_" && i + 1 < chars.count && chars[i + 1] == "_" {
                if let end = findDelimiter(chars, from: i + 2, delimiter: ["_", "_"]) {
                    let inner = String(chars[(i + 2)..<end])
                    result += "<strong>\(processInline(inner))</strong>"
                    i = end + 2
                    continue
                }
            }

            // Strikethrough: ~~text~~
            if chars[i] == "~" && i + 1 < chars.count && chars[i + 1] == "~" {
                if let end = findDelimiter(chars, from: i + 2, delimiter: ["~", "~"]) {
                    let inner = String(chars[(i + 2)..<end])
                    result += "<del>\(processInline(inner))</del>"
                    i = end + 2
                    continue
                }
            }

            // Italic: *text* (single, not **)
            if chars[i] == "*" && !(i + 1 < chars.count && chars[i + 1] == "*") {
                if let end = findSingleDelimiter(chars, from: i + 1, ch: "*") {
                    let inner = String(chars[(i + 1)..<end])
                    if !inner.isEmpty {
                        result += "<em>\(processInline(inner))</em>"
                        i = end + 1
                        continue
                    }
                }
            }

            // Italic: _text_ (single, not __)
            if chars[i] == "_" && !(i + 1 < chars.count && chars[i + 1] == "_") {
                if let end = findSingleDelimiter(chars, from: i + 1, ch: "_") {
                    let inner = String(chars[(i + 1)..<end])
                    if !inner.isEmpty {
                        result += "<em>\(processInline(inner))</em>"
                        i = end + 1
                        continue
                    }
                }
            }

            // Plain character — HTML escape
            result += escapeChar(chars[i])
            i += 1
        }

        return result
    }

    // MARK: - Inline helpers

    private static func indexOf(_ chars: [Character], from start: Int, char: Character) -> Int? {
        var i = start
        while i < chars.count {
            if chars[i] == char { return i }
            i += 1
        }
        return nil
    }

    private static func findClosingBracket(_ chars: [Character], from start: Int) -> Int? {
        var depth = 1
        var i = start
        while i < chars.count {
            if chars[i] == "[" { depth += 1 }
            else if chars[i] == "]" {
                depth -= 1
                if depth == 0 { return i }
            }
            i += 1
        }
        return nil
    }

    private static func findMatchingParen(_ chars: [Character], from start: Int) -> Int? {
        var depth = 0
        var i = start
        while i < chars.count {
            if chars[i] == "(" { depth += 1 }
            else if chars[i] == ")" {
                depth -= 1
                if depth == 0 { return i }
            }
            i += 1
        }
        return nil
    }

    private static func findDelimiter(_ chars: [Character], from start: Int, delimiter: [Character]) -> Int? {
        var i = start
        while i <= chars.count - delimiter.count {
            if Array(chars[i..<(i + delimiter.count)]) == delimiter { return i }
            i += 1
        }
        return nil
    }

    private static func findSingleDelimiter(_ chars: [Character], from start: Int, ch: Character) -> Int? {
        var i = start
        while i < chars.count {
            if chars[i] == ch {
                // Don't match doubled delimiter
                if i + 1 < chars.count && chars[i + 1] == ch {
                    i += 2
                    continue
                }
                return i
            }
            i += 1
        }
        return nil
    }

    private static func parseLinkOrImage(_ chars: [Character], from start: Int, isImage: Bool) -> (String, Int)? {
        let bracketStart = isImage ? start + 2 : start + 1
        guard let closeBracket = findClosingBracket(chars, from: bracketStart) else { return nil }
        let afterBracket = closeBracket + 1
        guard afterBracket < chars.count && chars[afterBracket] == "(" else { return nil }
        guard let closeParen = findMatchingParen(chars, from: afterBracket) else { return nil }

        let altOrText = String(chars[bracketStart..<closeBracket])
        let url = String(chars[(afterBracket + 1)..<closeParen])

        if isImage {
            return ("<img src=\"\(escapeHTML(url))\" alt=\"\(escapeHTML(altOrText))\">", closeParen + 1)
        } else {
            return ("<a href=\"\(escapeHTML(url))\">\(processInline(altOrText))</a>", closeParen + 1)
        }
    }

    // MARK: - HTML escaping

    private static func escapeHTML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        return escaped
    }

    private static func escapeChar(_ ch: Character) -> String {
        switch ch {
        case "&": return "&amp;"
        case "<": return "&lt;"
        case ">": return "&gt;"
        case "\"": return "&quot;"
        default: return String(ch)
        }
    }
}
