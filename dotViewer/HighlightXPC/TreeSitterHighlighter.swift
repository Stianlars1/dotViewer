import Foundation

final class TreeSitterHighlighter {
    private struct LanguageConfig {
        let id: String
        let language: OpaquePointer
        let query: OpaquePointer
    }

    private let configs: [String: LanguageConfig]

    init() {
        configs = Self.loadConfigs()
    }

    func highlight(
        code: String,
        language: String,
        showLineNumbers: Bool,
        shouldCancel: (() -> Bool)? = nil
    ) -> String? {
        if shouldCancel?() == true {
            return nil
        }
        let loweredLanguage = language.lowercased()
        guard let config = configs[loweredLanguage] else {
            // We support a small set of tree-sitter grammars. For everything else, we still apply a
            // lightweight heuristic highlighter so "supported file types" don't silently turn into
            // plain text.
            guard loweredLanguage != "plaintext", !loweredLanguage.isEmpty else {
                return Self.renderPlain(code: code, showLineNumbers: showLineNumbers)
            }
            guard let data = code.data(using: .utf8) else {
                return Self.renderPlain(code: code, showLineNumbers: showLineNumbers)
            }
            let captures = Self.fallbackHighlightCaptures(data: data, shouldCancel: shouldCancel)
            if shouldCancel?() == true {
                return nil
            }
            return Self.renderHighlighted(data: data, captures: captures, showLineNumbers: showLineNumbers)
        }

        guard let data = code.data(using: .utf8) else {
            return Self.renderPlain(code: code, showLineNumbers: showLineNumbers)
        }

        guard let parser = ts_parser_new() else {
            return Self.renderPlain(code: code, showLineNumbers: showLineNumbers)
        }
        defer { ts_parser_delete(parser) }

        if !ts_parser_set_language(parser, config.language) {
            return Self.renderPlain(code: code, showLineNumbers: showLineNumbers)
        }

        let tree: OpaquePointer? = data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return nil
            }
            return ts_parser_parse_string(
                parser,
                nil,
                baseAddress.assumingMemoryBound(to: CChar.self),
                UInt32(data.count)
            )
        }

        guard let tree else {
            return Self.renderPlain(code: code, showLineNumbers: showLineNumbers)
        }
        defer { ts_tree_delete(tree) }

        if shouldCancel?() == true {
            return nil
        }

        guard let cursor = ts_query_cursor_new() else {
            return Self.renderPlain(code: code, showLineNumbers: showLineNumbers)
        }
        defer { ts_query_cursor_delete(cursor) }

        let rootNode = ts_tree_root_node(tree)
        ts_query_cursor_exec(cursor, config.query, rootNode)

        var captures: [Capture] = []
        var match = TSQueryMatch()
        var captureIndex: UInt32 = 0
        var captureCount = 0

        while ts_query_cursor_next_capture(cursor, &match, &captureIndex) {
            captureCount += 1
            if captureCount % 200 == 0, shouldCancel?() == true {
                return nil
            }
            guard let capturePtr = match.captures else { continue }
            let captureBuffer = UnsafeBufferPointer(start: capturePtr, count: Int(match.capture_count))
            let capture = captureBuffer[Int(captureIndex)]
            let node = capture.node
            let start = Int(ts_node_start_byte(node))
            let end = Int(ts_node_end_byte(node))

            if start >= end || start < 0 || end > data.count {
                continue
            }

            var nameLength: UInt32 = 0
            guard let namePtr = ts_query_capture_name_for_id(config.query, capture.index, &nameLength) else {
                continue
            }

            let nameBytes = UnsafeBufferPointer(start: UnsafeRawPointer(namePtr).assumingMemoryBound(to: UInt8.self),
                                                count: Int(nameLength))
            let name = String(decoding: nameBytes, as: UTF8.self)

            captures.append(Capture(start: start, end: end, name: name))
        }

        captures.sort { lhs, rhs in
            if lhs.start == rhs.start {
                return lhs.end > rhs.end
            }
            return lhs.start < rhs.start
        }

        if shouldCancel?() == true {
            return nil
        }
        return Self.renderHighlighted(data: data, captures: captures, showLineNumbers: showLineNumbers)
    }
}

private extension TreeSitterHighlighter {
    struct Capture {
        let start: Int
        let end: Int
        let name: String
    }

    private static let fallbackKeywords: Set<String> = [
        // Common keywords across many languages.
        "as", "async", "await", "break", "case", "catch", "class", "const", "continue", "defer", "default", "do",
        "else", "enum", "except", "export", "extends", "extension", "fallthrough", "false", "finally", "for",
        "foreach", "from", "func", "function", "guard", "if", "import", "in", "interface", "internal", "is",
        "lambda", "let", "match", "module", "mut", "namespace", "new", "nil", "of", "operator", "override",
        "package", "private", "protected", "protocol", "public", "raise", "readonly", "return", "self", "static",
        "struct", "super", "switch", "throw", "throws", "trait", "true", "try", "type", "typedef", "typeof",
        "union", "using", "var", "virtual", "void", "where", "while", "with", "yield"
    ]

    private static func loadConfigs() -> [String: LanguageConfig] {
        var configs: [String: LanguageConfig] = [:]

        let languages: [(String, OpaquePointer?)] = [
            ("swift", tree_sitter_swift()),
            ("python", tree_sitter_python()),
            ("javascript", tree_sitter_javascript()),
            ("typescript", tree_sitter_typescript()),
            ("tsx", tree_sitter_tsx()),
            ("json", tree_sitter_json()),
            ("yaml", tree_sitter_yaml()),
            ("markdown", tree_sitter_markdown()),
            ("bash", tree_sitter_bash()),
            ("html", tree_sitter_html()),
            ("css", tree_sitter_css()),
            ("xml", tree_sitter_xml()),
            ("ini", tree_sitter_ini()),
            ("toml", tree_sitter_toml()),
        ]

        for (id, language) in languages {
            guard let language,
                  let queryString = loadQuery(named: id),
                  let query = compileQuery(queryString, language: language)
            else {
                continue
            }
            configs[id] = LanguageConfig(id: id, language: language, query: query)
        }

        return configs
    }

    static func fallbackHighlightCaptures(data: Data, shouldCancel: (() -> Bool)?) -> [Capture] {
        // A fast, UTF-8 byte based fallback highlighter. This is intentionally simple:
        // - comments (//, #, --, /* */)
        // - strings ("...", '...', `...`, and basic triple quotes)
        // - numbers (decimal + 0x/0b/0o)
        // - keywords (common cross-language list)
        let bytes = Array(data)
        let count = bytes.count

        func isDigit(_ b: UInt8) -> Bool { b >= 48 && b <= 57 } // 0-9
        func isLowerAlpha(_ b: UInt8) -> Bool { b >= 97 && b <= 122 } // a-z
        func isUpperAlpha(_ b: UInt8) -> Bool { b >= 65 && b <= 90 } // A-Z
        func isAlpha(_ b: UInt8) -> Bool { isLowerAlpha(b) || isUpperAlpha(b) }
        func isIdentifierStart(_ b: UInt8) -> Bool { isAlpha(b) || b == 95 } // _
        func isIdentifierContinue(_ b: UInt8) -> Bool { isIdentifierStart(b) || isDigit(b) }

        var captures: [Capture] = []
        captures.reserveCapacity(min(4096, max(128, count / 12)))

        var i = 0
        while i < count {
            if i % 4096 == 0, shouldCancel?() == true {
                return []
            }

            let b = bytes[i]

            // Line comments: //, #, --
            if b == 47, i + 1 < count, bytes[i + 1] == 47 { // //
                let start = i
                i += 2
                while i < count, bytes[i] != 10 { i += 1 } // \n
                captures.append(Capture(start: start, end: i, name: "comment"))
                continue
            }
            if b == 35 { // #
                let start = i
                i += 1
                while i < count, bytes[i] != 10 { i += 1 }
                captures.append(Capture(start: start, end: i, name: "comment"))
                continue
            }
            if b == 45, i + 1 < count, bytes[i + 1] == 45 { // --
                let start = i
                i += 2
                while i < count, bytes[i] != 10 { i += 1 }
                captures.append(Capture(start: start, end: i, name: "comment"))
                continue
            }

            // Block comment: /* ... */
            if b == 47, i + 1 < count, bytes[i + 1] == 42 { // /*
                let start = i
                i += 2
                while i + 1 < count {
                    if i % 4096 == 0, shouldCancel?() == true {
                        return []
                    }
                    if bytes[i] == 42, bytes[i + 1] == 47 { // */
                        i += 2
                        break
                    }
                    i += 1
                }
                captures.append(Capture(start: start, end: min(i, count), name: "comment"))
                continue
            }

            // HTML-ish comment: <!-- ... -->
            if b == 60, i + 3 < count, bytes[i + 1] == 33, bytes[i + 2] == 45, bytes[i + 3] == 45 { // <!--
                let start = i
                i += 4
                while i + 2 < count {
                    if i % 4096 == 0, shouldCancel?() == true {
                        return []
                    }
                    if bytes[i] == 45, bytes[i + 1] == 45, bytes[i + 2] == 62 { // -->
                        i += 3
                        break
                    }
                    i += 1
                }
                captures.append(Capture(start: start, end: min(i, count), name: "comment"))
                continue
            }

            // Strings: "...", '...', `...`, basic triple quotes.
            if b == 34 || b == 39 || b == 96 { // " ' `
                let quote = b
                let start = i

                // Triple quote support for " and ' (""" ... """ or ''' ... ''')
                let isTriple: Bool
                if (quote == 34 || quote == 39), i + 2 < count, bytes[i + 1] == quote, bytes[i + 2] == quote {
                    isTriple = true
                    i += 3
                } else {
                    isTriple = false
                    i += 1
                }

                while i < count {
                    if i % 4096 == 0, shouldCancel?() == true {
                        return []
                    }

                    let c = bytes[i]
                    if c == 92 { // backslash escape
                        i += 2
                        continue
                    }

                    if isTriple {
                        if i + 2 < count, bytes[i] == quote, bytes[i + 1] == quote, bytes[i + 2] == quote {
                            i += 3
                            break
                        }
                        i += 1
                    } else {
                        if c == quote {
                            i += 1
                            break
                        }
                        i += 1
                    }
                }

                captures.append(Capture(start: start, end: min(i, count), name: "string"))
                continue
            }

            // Numbers
            if isDigit(b) {
                let start = i

                if b == 48, i + 1 < count { // 0x, 0b, 0o prefixes
                    let n1 = bytes[i + 1]
                    if n1 == 120 || n1 == 88 { // x/X
                        i += 2
                        while i < count {
                            let c = bytes[i]
                            let isHex = isDigit(c) || (c >= 97 && c <= 102) || (c >= 65 && c <= 70) || c == 95 // _ a-f A-F
                            if !isHex { break }
                            i += 1
                        }
                        captures.append(Capture(start: start, end: i, name: "number"))
                        continue
                    }
                    if n1 == 98 || n1 == 66 { // b/B
                        i += 2
                        while i < count {
                            let c = bytes[i]
                            if c != 48, c != 49, c != 95 { break } // 0/1/_
                            i += 1
                        }
                        captures.append(Capture(start: start, end: i, name: "number"))
                        continue
                    }
                    if n1 == 111 || n1 == 79 { // o/O
                        i += 2
                        while i < count {
                            let c = bytes[i]
                            if (c < 48 || c > 55), c != 95 { break } // 0-7/_
                            i += 1
                        }
                        captures.append(Capture(start: start, end: i, name: "number"))
                        continue
                    }
                }

                // Decimal / float / exponent (very permissive).
                i += 1
                while i < count {
                    let c = bytes[i]
                    if isDigit(c) || c == 95 { // _
                        i += 1
                        continue
                    }
                    if c == 46, i + 1 < count, isDigit(bytes[i + 1]) { // .<digit>
                        i += 2
                        while i < count, isDigit(bytes[i]) || bytes[i] == 95 { i += 1 }
                        continue
                    }
                    if (c == 101 || c == 69), i + 1 < count { // e/E
                        i += 1
                        if i < count, bytes[i] == 43 || bytes[i] == 45 { i += 1 } // +/-.
                        while i < count, isDigit(bytes[i]) || bytes[i] == 95 { i += 1 }
                        continue
                    }
                    break
                }
                captures.append(Capture(start: start, end: i, name: "number"))
                continue
            }

            // Identifiers / Keywords
            if isIdentifierStart(b) {
                let start = i
                i += 1
                while i < count, isIdentifierContinue(bytes[i]) { i += 1 }
                let word = String(decoding: bytes[start..<i], as: UTF8.self)
                if fallbackKeywords.contains(word) {
                    captures.append(Capture(start: start, end: i, name: "keyword"))
                }
                continue
            }

            i += 1
        }

        captures.sort { lhs, rhs in
            if lhs.start == rhs.start {
                return lhs.end > rhs.end
            }
            return lhs.start < rhs.start
        }
        return captures
    }

    static func loadQuery(named name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "scm", subdirectory: "TreeSitterQueries"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func compileQuery(_ query: String, language: OpaquePointer) -> OpaquePointer? {
        let bytes = Array(query.utf8CString)
        var errorOffset: UInt32 = 0
        var errorType = TSQueryError(0)
        let length = UInt32(max(bytes.count - 1, 0))
        return bytes.withUnsafeBufferPointer { buffer in
            ts_query_new(language, buffer.baseAddress, length, &errorOffset, &errorType)
        }
    }

    static func renderPlain(code: String, showLineNumbers: Bool) -> String {
        let data = code.data(using: .utf8) ?? Data()
        return renderHighlighted(data: data, captures: [], showLineNumbers: showLineNumbers)
    }

    static func renderHighlighted(data: Data, captures: [Capture], showLineNumbers: Bool) -> String {
        var lines: [String] = [""]
        var currentIndex = 0

        for capture in captures {
            if capture.start < currentIndex {
                continue
            }

            if capture.start > currentIndex {
                let plainSegment = data.subdata(in: currentIndex..<capture.start)
                appendSegment(plainSegment, className: nil, lines: &lines)
            }

            let tokenSegment = data.subdata(in: capture.start..<capture.end)
            appendSegment(tokenSegment, className: mapCaptureToClass(capture.name), lines: &lines)
            currentIndex = capture.end
        }

        if currentIndex < data.count {
            let remaining = data.subdata(in: currentIndex..<data.count)
            appendSegment(remaining, className: nil, lines: &lines)
        }

        if showLineNumbers {
            return lines.enumerated().map { index, line in
                let lineNumber = index + 1
                return "<div class=\"line\"><span class=\"ln\">\(lineNumber)</span><span class=\"code-line\">\(line)</span></div>"
            }.joined()
        } else {
            let joined = lines.joined(separator: "\n")
            return "<pre class=\"code\"><code>\(joined)</code></pre>"
        }
    }

    static func appendSegment(_ data: Data, className: String?, lines: inout [String]) {
        let text = String(decoding: data, as: UTF8.self)
        let parts = text.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, part) in parts.enumerated() {
            if index > 0 {
                lines.append("")
            }
            let escaped = escapeHTML(String(part))
            if let className, !className.isEmpty {
                lines[lines.count - 1] += "<span class=\"\(className)\">\(escaped)</span>"
            } else {
                lines[lines.count - 1] += escaped
            }
        }
    }

    static func escapeHTML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        return escaped
    }

    static func mapCaptureToClass(_ name: String) -> String {
        let lower = name.lowercased()

        if lower.contains("comment") {
            return "tok-comment"
        }
        if lower.contains("string") || lower.contains("regex") {
            return "tok-string"
        }
        if lower.contains("number") || lower.contains("float") || lower.contains("integer") {
            return "tok-number"
        }
        if lower.contains("keyword") || lower.contains("conditional") || lower.contains("repeat") || lower.contains("operator") {
            return "tok-keyword"
        }
        if lower.contains("type") || lower.contains("class") || lower.contains("struct") {
            return "tok-type"
        }
        if lower.contains("function") || lower.contains("method") || lower.contains("call") {
            return "tok-function"
        }
        if lower.contains("property") || lower.contains("field") || lower.contains("variable") {
            return "tok-property"
        }
        if lower.contains("constant") || lower.contains("boolean") {
            return "tok-constant"
        }

        return "tok-identifier"
    }
}
