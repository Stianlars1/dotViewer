import Foundation
import SwiftUI

/// High-performance pure Swift syntax highlighter using regex-based pattern matching.
/// This replaces the slow JavaScriptCore-based HighlightSwift for common languages.
/// Target: <100ms for files up to 2000 lines at 140 BPM navigation.
struct FastSyntaxHighlighter: Sendable {

    // MARK: - Supported Languages

    /// Languages with dedicated fast highlighting support
    static let supportedLanguages: Set<String> = [
        "swift",
        "javascript", "js", "jsx",
        "typescript", "ts", "tsx",
        "python", "py",
        "rust", "rs",
        "go", "golang",
        "json",
        "yaml", "yml",
        "bash", "shell", "sh", "zsh",
        "html", "xml", "plist",
        "css", "scss", "sass",
        "c", "cpp", "c++", "h", "hpp",
        "java", "kotlin", "kt",
        "ruby", "rb",
        "php",
        "sql",
        "markdown", "md"
    ]

    /// Check if a language has fast highlighting support
    static func isSupported(_ language: String?) -> Bool {
        guard let lang = language?.lowercased() else { return false }
        return supportedLanguages.contains(lang)
    }

    // MARK: - Pre-compiled Regex Patterns (Static to avoid recompilation)

    // SAFETY NOTE: These regex patterns use `try!` because:
    // 1. All patterns are compile-time string literals that have been tested
    // 2. Pattern compilation failure would indicate a programming error, not a runtime condition
    // 3. These are static constants initialized once at app launch
    // 4. If any pattern fails, the app should crash immediately during development
    //    rather than silently failing later during syntax highlighting
    //
    // If modifying these patterns, test compilation in a playground first.

    // Comments
    private static let lineCommentRegex = try! NSRegularExpression(pattern: "//[^\n]*")
    private static let blockCommentRegex = try! NSRegularExpression(pattern: "/\\*[\\s\\S]*?\\*/")
    private static let hashCommentRegex = try! NSRegularExpression(pattern: "#[^\n]*")
    private static let htmlCommentRegex = try! NSRegularExpression(pattern: "<!--[\\s\\S]*?-->")

    // Strings
    private static let doubleStringRegex = try! NSRegularExpression(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"")
    private static let singleStringRegex = try! NSRegularExpression(pattern: "'(?:[^'\\\\]|\\\\.)*'")
    private static let backtickStringRegex = try! NSRegularExpression(pattern: "`(?:[^`\\\\]|\\\\.)*`")
    private static let tripleDoubleStringRegex = try! NSRegularExpression(pattern: "\"\"\"[\\s\\S]*?\"\"\"")
    private static let tripleSingleStringRegex = try! NSRegularExpression(pattern: "'''[\\s\\S]*?'''")

    // Numbers
    private static let numberRegex = try! NSRegularExpression(pattern: "\\b\\d+\\.?\\d*(?:[eE][+-]?\\d+)?\\b")
    private static let hexNumberRegex = try! NSRegularExpression(pattern: "\\b0[xX][0-9a-fA-F]+\\b")

    // HTML/XML specific
    private static let htmlTagRegex = try! NSRegularExpression(pattern: "</?\\w+[^>]*>")
    private static let htmlAttributeRegex = try! NSRegularExpression(pattern: "\\b\\w+(?==)")

    // JSON specific
    private static let jsonKeyRegex = try! NSRegularExpression(pattern: "\"[^\"]+\"(?=\\s*:)")

    // MARK: - Keyword Pattern Cache

    /// Cache for pre-compiled keyword/type/builtin regex patterns per language.
    /// Key format: "\(language ?? "unknown")_\(wordsHashValue)"
    /// PERFORMANCE: Avoids recompiling regex patterns on every file (saves 20-50ms per file)
    private static var keywordPatternCache: [String: NSRegularExpression] = [:]
    private static let patternCacheLock = NSLock()

    // MARK: - Data File Detection

    /// Languages that are data formats - should skip expensive HTML tag highlighting
    private static let dataLanguages: Set<String> = [
        "json", "yaml", "yml", "toml", "plist", "xml", "csv", "ini", "conf", "config"
    ]

    /// Check if a file is a data format that should skip HTML tag highlighting.
    /// PERFORMANCE: Skipping HTML tag regex saves 100-250ms for data files with many tags.
    private static func isDataFormat(_ language: String?) -> Bool {
        guard let lang = language?.lowercased() else { return false }
        return dataLanguages.contains(lang)
    }

    // MARK: - Index Mapping for O(1) Lookups

    private struct IndexMapping {
        let utf16ToChar: [Int]
        let attrIndices: [AttributedString.Index]
    }

    private func buildIndexMapping(code: String, attributed: AttributedString) -> IndexMapping {
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

        // Build AttributedString index array in O(n) using characters collection
        // PERFORMANCE FIX: Previous code used `attributed.index(afterCharacter:)` which is O(n)
        // per call, resulting in O(n²) total. Using `characters.index(after:)` is O(1) per call.
        var attrIndices: [AttributedString.Index] = []
        let charCount = attributed.characters.count
        attrIndices.reserveCapacity(charCount + 1)
        var currentIndex = attributed.startIndex
        for _ in 0..<charCount {
            attrIndices.append(currentIndex)
            currentIndex = attributed.characters.index(after: currentIndex)
        }
        attrIndices.append(attributed.endIndex)

        return IndexMapping(utf16ToChar: utf16ToChar, attrIndices: attrIndices)
    }

    // MARK: - Main Highlight Function

    /// Highlight code synchronously using pattern matching
    /// - Parameters:
    ///   - code: Source code to highlight
    ///   - language: Language identifier
    ///   - colors: Syntax colors to use
    /// - Returns: Attributed string with syntax highlighting
    func highlight(code: String, language: String?, colors: SyntaxColors) -> AttributedString {
        let totalStart = CFAbsoluteTimeGetCurrent()
        perfLog("[dotViewer PERF] FastSyntaxHighlighter.highlight START - codeLen: %d chars, language: %@", code.count, language ?? "nil")

        var result = AttributedString(code)
        result.foregroundColor = Color(nsColor: colors.text)

        // Build index mapping for efficient attribute application
        var sectionStart = CFAbsoluteTimeGetCurrent()
        let mapping = buildIndexMapping(code: code, attributed: result)
        let codeNS = code as NSString
        perfLog("[dotViewer PERF] [Fast +%.3fs] index mapping: %.3fs", CFAbsoluteTimeGetCurrent() - totalStart, CFAbsoluteTimeGetCurrent() - sectionStart)

        // Get language-specific patterns
        sectionStart = CFAbsoluteTimeGetCurrent()
        let patterns = languagePatterns(for: language)
        perfLog("[dotViewer PERF] [Fast +%.3fs] languagePatterns: %.3fs (keywords: %d, types: %d, builtins: %d)", CFAbsoluteTimeGetCurrent() - totalStart, CFAbsoluteTimeGetCurrent() - sectionStart, patterns.keywords.count, patterns.types.count, patterns.builtins.count)

        // Apply highlighting in order (more specific patterns first)

        // 1. Multi-line strings (before single-line strings)
        sectionStart = CFAbsoluteTimeGetCurrent()
        if patterns.supportsMultilineStrings {
            applyHighlight(regex: Self.tripleDoubleStringRegex, to: &result, code: codeNS, mapping: mapping, color: colors.string)
            applyHighlight(regex: Self.tripleSingleStringRegex, to: &result, code: codeNS, mapping: mapping, color: colors.string)
        }
        let multilineTime = CFAbsoluteTimeGetCurrent() - sectionStart

        // 2. Comments (before strings to handle commented strings correctly)
        sectionStart = CFAbsoluteTimeGetCurrent()
        if patterns.supportsLineComments {
            applyHighlight(regex: Self.lineCommentRegex, to: &result, code: codeNS, mapping: mapping, color: colors.comment)
        }
        if patterns.supportsBlockComments {
            applyHighlight(regex: Self.blockCommentRegex, to: &result, code: codeNS, mapping: mapping, color: colors.comment)
        }
        if patterns.supportsHashComments {
            applyHighlight(regex: Self.hashCommentRegex, to: &result, code: codeNS, mapping: mapping, color: colors.comment)
        }
        if patterns.supportsHtmlComments {
            applyHighlight(regex: Self.htmlCommentRegex, to: &result, code: codeNS, mapping: mapping, color: colors.comment)
        }
        perfLog("[dotViewer PERF] [Fast +%.3fs] comments: %.3fs", CFAbsoluteTimeGetCurrent() - totalStart, CFAbsoluteTimeGetCurrent() - sectionStart)

        // 3. Strings
        sectionStart = CFAbsoluteTimeGetCurrent()
        applyHighlight(regex: Self.doubleStringRegex, to: &result, code: codeNS, mapping: mapping, color: colors.string)
        applyHighlight(regex: Self.singleStringRegex, to: &result, code: codeNS, mapping: mapping, color: colors.string)
        if patterns.supportsBacktickStrings {
            applyHighlight(regex: Self.backtickStringRegex, to: &result, code: codeNS, mapping: mapping, color: colors.string)
        }
        perfLog("[dotViewer PERF] [Fast +%.3fs] strings: %.3fs (multiline was: %.3fs)", CFAbsoluteTimeGetCurrent() - totalStart, CFAbsoluteTimeGetCurrent() - sectionStart, multilineTime)

        // 4. Numbers
        sectionStart = CFAbsoluteTimeGetCurrent()
        applyHighlight(regex: Self.hexNumberRegex, to: &result, code: codeNS, mapping: mapping, color: colors.number)
        applyHighlight(regex: Self.numberRegex, to: &result, code: codeNS, mapping: mapping, color: colors.number)
        perfLog("[dotViewer PERF] [Fast +%.3fs] numbers: %.3fs", CFAbsoluteTimeGetCurrent() - totalStart, CFAbsoluteTimeGetCurrent() - sectionStart)

        // 5. Language-specific patterns
        sectionStart = CFAbsoluteTimeGetCurrent()
        // Skip HTML tag highlighting for data formats (JSON, YAML, XML, plist, TOML, etc.)
        // PERFORMANCE: Saves 100-250ms for data files by avoiding expensive regex on thousands of tags
        let skipHtmlTags = patterns.isXmlDataMode || Self.isDataFormat(language)
        if patterns.supportsHtmlTags && !skipHtmlTags {
            applyHighlight(regex: Self.htmlTagRegex, to: &result, code: codeNS, mapping: mapping, color: colors.keyword)
            applyHighlight(regex: Self.htmlAttributeRegex, to: &result, code: codeNS, mapping: mapping, color: colors.type)
        }

        if patterns.supportsJsonKeys {
            applyHighlight(regex: Self.jsonKeyRegex, to: &result, code: codeNS, mapping: mapping, color: colors.keyword)
        }
        perfLog("[dotViewer PERF] [Fast +%.3fs] language-specific (html/json): %.3fs, skipHtmlTags: %@", CFAbsoluteTimeGetCurrent() - totalStart, CFAbsoluteTimeGetCurrent() - sectionStart, skipHtmlTags ? "YES" : "NO")

        // 6. Keywords - single-pass highlighting using alternation pattern O(n) instead of O(n × keywords)
        // Uses cached regex patterns per language for 95%+ savings on subsequent files
        sectionStart = CFAbsoluteTimeGetCurrent()
        highlightWords(in: &result, code: codeNS, words: patterns.keywords, mapping: mapping, color: colors.keyword, language: language)
        perfLog("[dotViewer PERF] [Fast +%.3fs] keywords (%d): %.3fs [single-pass, cached]", CFAbsoluteTimeGetCurrent() - totalStart, patterns.keywords.count, CFAbsoluteTimeGetCurrent() - sectionStart)

        // 7. Types - single-pass highlighting using alternation pattern O(n) instead of O(n × types)
        sectionStart = CFAbsoluteTimeGetCurrent()
        highlightWords(in: &result, code: codeNS, words: patterns.types, mapping: mapping, color: colors.type, language: language)
        perfLog("[dotViewer PERF] [Fast +%.3fs] types (%d): %.3fs [single-pass, cached]", CFAbsoluteTimeGetCurrent() - totalStart, patterns.types.count, CFAbsoluteTimeGetCurrent() - sectionStart)

        // 8. Built-in functions - single-pass highlighting using alternation pattern O(n) instead of O(n × builtins)
        sectionStart = CFAbsoluteTimeGetCurrent()
        highlightWords(in: &result, code: codeNS, words: patterns.builtins, mapping: mapping, color: colors.function, language: language)
        perfLog("[dotViewer PERF] [Fast +%.3fs] builtins (%d): %.3fs [single-pass, cached]", CFAbsoluteTimeGetCurrent() - totalStart, patterns.builtins.count, CFAbsoluteTimeGetCurrent() - sectionStart)

        perfLog("[dotViewer PERF] FastSyntaxHighlighter.highlight DONE - total: %.3fs", CFAbsoluteTimeGetCurrent() - totalStart)
        return result
    }

    // MARK: - Pattern Application

    private func applyHighlight(regex: NSRegularExpression, to attributed: inout AttributedString, code: NSString, mapping: IndexMapping, color: NSColor) {
        let matches = regex.matches(in: code as String, options: [], range: NSRange(location: 0, length: code.length))
        let swiftUIColor = Color(nsColor: color)

        for match in matches {
            let loc = match.range.location
            let end = loc + match.range.length

            guard loc < mapping.utf16ToChar.count && end <= mapping.utf16ToChar.count else { continue }

            let startChar = mapping.utf16ToChar[loc]
            let endChar = mapping.utf16ToChar[end]

            guard startChar < mapping.attrIndices.count && endChar < mapping.attrIndices.count else { continue }

            attributed[mapping.attrIndices[startChar]..<mapping.attrIndices[endChar]].foregroundColor = swiftUIColor
        }
    }

    /// Highlight a set of words in a single pass using alternation pattern.
    /// This is O(n) instead of O(n × words) when highlighting individually.
    /// Pattern: \b(word1|word2|word3|...)\b
    /// PERFORMANCE: Uses cached pre-compiled patterns per language (saves 20-50ms per file)
    ///
    /// Thread Safety: Uses NSLock with withLock { } for automatic unlock on all exit paths.
    /// The lock protects keywordPatternCache which is shared across highlighting operations.
    private func highlightWords(in attributed: inout AttributedString, code: NSString, words: Set<String>, mapping: IndexMapping, color: NSColor, language: String?) {
        guard !words.isEmpty else { return }

        // Create cache key using language and words hash for uniqueness
        let cacheKey = "\(language ?? "unknown")_\(words.hashValue)"

        // Check cache first (short critical section)
        let cachedRegex: NSRegularExpression? = Self.patternCacheLock.withLock {
            Self.keywordPatternCache[cacheKey]
        }

        let regex: NSRegularExpression
        if let cached = cachedRegex {
            regex = cached
        } else {
            // Build pattern outside lock (expensive operation)
            let sortedWords = words.sorted()
            let escapedWords = sortedWords.map { NSRegularExpression.escapedPattern(for: $0) }
            let pattern = "\\b(\(escapedWords.joined(separator: "|")))\\b"

            guard let newRegex = try? NSRegularExpression(pattern: pattern) else { return }
            regex = newRegex

            // Cache the compiled pattern (short critical section)
            Self.patternCacheLock.withLock {
                Self.keywordPatternCache[cacheKey] = regex
            }
        }

        applyHighlight(regex: regex, to: &attributed, code: code, mapping: mapping, color: color)
    }

    private func highlightWord(in attributed: inout AttributedString, code: NSString, word: String, mapping: IndexMapping, color: NSColor) {
        let escapedWord = NSRegularExpression.escapedPattern(for: word)
        guard let regex = try? NSRegularExpression(pattern: "\\b\(escapedWord)\\b") else { return }
        applyHighlight(regex: regex, to: &attributed, code: code, mapping: mapping, color: color)
    }

    // MARK: - Language Patterns

    private struct LanguagePatterns {
        var keywords: Set<String> = []
        var types: Set<String> = []
        var builtins: Set<String> = []
        var supportsLineComments: Bool = true
        var supportsBlockComments: Bool = true
        var supportsHashComments: Bool = false
        var supportsHtmlComments: Bool = false
        var supportsBacktickStrings: Bool = false
        var supportsMultilineStrings: Bool = false
        var supportsHtmlTags: Bool = false
        var supportsJsonKeys: Bool = false
        /// XML data mode: skip expensive HTML tag regex for data files (plist, config, etc.)
        /// This provides ~230ms savings for large XML files like Info.plist
        var isXmlDataMode: Bool = false
    }

    private func languagePatterns(for language: String?) -> LanguagePatterns {
        guard let lang = language?.lowercased() else {
            return genericPatterns()
        }

        switch lang {
        case "swift":
            return swiftPatterns()
        case "javascript", "js", "jsx":
            return javascriptPatterns()
        case "typescript", "ts", "tsx":
            return typescriptPatterns()
        case "python", "py":
            return pythonPatterns()
        case "rust", "rs":
            return rustPatterns()
        case "go", "golang":
            return goPatterns()
        case "json":
            return jsonPatterns()
        case "yaml", "yml":
            return yamlPatterns()
        case "bash", "shell", "sh", "zsh":
            return bashPatterns()
        case "html":
            return htmlPatterns()
        case "xml", "plist":
            return xmlDataPatterns()
        case "css", "scss", "sass":
            return cssPatterns()
        case "c", "cpp", "c++", "h", "hpp":
            return cppPatterns()
        case "java":
            return javaPatterns()
        case "kotlin", "kt":
            return kotlinPatterns()
        case "ruby", "rb":
            return rubyPatterns()
        case "php":
            return phpPatterns()
        case "sql":
            return sqlPatterns()
        case "markdown", "md":
            return markdownPatterns()
        default:
            return genericPatterns()
        }
    }

    // MARK: - Language-Specific Patterns

    private func swiftPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["func", "let", "var", "if", "else", "guard", "return", "import", "class", "struct", "enum", "protocol", "extension", "private", "public", "internal", "fileprivate", "static", "final", "override", "init", "deinit", "self", "super", "nil", "true", "false", "for", "while", "repeat", "switch", "case", "default", "break", "continue", "fallthrough", "where", "in", "do", "try", "catch", "throw", "throws", "rethrows", "defer", "as", "is", "async", "await", "actor", "nonisolated", "isolated", "some", "any", "typealias", "associatedtype", "inout", "mutating", "nonmutating", "convenience", "required", "lazy", "weak", "unowned", "willSet", "didSet", "get", "set", "open", "package"]
        p.types = ["String", "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "Double", "Float", "Float16", "Bool", "Array", "Dictionary", "Set", "Optional", "Result", "Error", "Never", "Void", "Any", "AnyObject", "Self", "View", "Color", "Text", "Button", "Image", "VStack", "HStack", "ZStack", "ForEach", "List", "NavigationView", "NavigationStack", "NavigationLink", "ScrollView", "LazyVStack", "LazyHStack", "GeometryReader", "Spacer", "Divider", "URL", "Data", "Date", "UUID", "Range", "ClosedRange", "Substring", "Character", "CGFloat", "CGPoint", "CGSize", "CGRect", "NSColor", "NSFont", "AttributedString", "Task", "MainActor", "Sendable"]
        p.builtins = ["print", "debugPrint", "dump", "fatalError", "precondition", "preconditionFailure", "assert", "assertionFailure", "min", "max", "abs", "stride", "zip", "sequence", "repeatElement", "type"]
        p.supportsBacktickStrings = false
        p.supportsMultilineStrings = true
        return p
    }

    private func javascriptPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["function", "const", "let", "var", "if", "else", "return", "import", "export", "from", "default", "class", "extends", "new", "this", "super", "null", "undefined", "true", "false", "for", "while", "do", "switch", "case", "break", "continue", "try", "catch", "throw", "finally", "async", "await", "yield", "of", "in", "typeof", "instanceof", "void", "delete", "debugger", "with", "static", "get", "set"]
        p.types = ["Object", "Array", "String", "Number", "Boolean", "Function", "Symbol", "BigInt", "Map", "Set", "WeakMap", "WeakSet", "Promise", "Proxy", "Reflect", "Date", "RegExp", "Error", "TypeError", "RangeError", "SyntaxError", "JSON", "Math", "Intl", "ArrayBuffer", "DataView", "Int8Array", "Uint8Array", "Float32Array", "Float64Array"]
        p.builtins = ["console", "window", "document", "navigator", "location", "history", "localStorage", "sessionStorage", "fetch", "setTimeout", "setInterval", "clearTimeout", "clearInterval", "requestAnimationFrame", "alert", "confirm", "prompt", "parseInt", "parseFloat", "isNaN", "isFinite", "encodeURI", "decodeURI", "encodeURIComponent", "decodeURIComponent", "eval", "require", "module", "exports", "process", "global", "__dirname", "__filename"]
        p.supportsBacktickStrings = true
        return p
    }

    private func typescriptPatterns() -> LanguagePatterns {
        var p = javascriptPatterns()
        p.keywords.formUnion(["interface", "type", "enum", "implements", "private", "public", "protected", "readonly", "abstract", "as", "is", "keyof", "infer", "extends", "never", "unknown", "any", "void", "declare", "namespace", "module", "require", "export", "import", "asserts", "satisfies"])
        p.types.formUnion(["string", "number", "boolean", "object", "any", "void", "never", "unknown", "null", "undefined", "Record", "Partial", "Required", "Readonly", "Pick", "Omit", "Exclude", "Extract", "NonNullable", "Parameters", "ReturnType", "InstanceType", "ThisType", "Awaited"])
        return p
    }

    private func pythonPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["def", "class", "if", "elif", "else", "return", "import", "from", "as", "try", "except", "finally", "raise", "with", "for", "while", "break", "continue", "pass", "lambda", "yield", "global", "nonlocal", "assert", "del", "in", "is", "not", "and", "or", "True", "False", "None", "self", "cls", "async", "await", "match", "case"]
        p.types = ["str", "int", "float", "bool", "list", "dict", "tuple", "set", "frozenset", "bytes", "bytearray", "memoryview", "type", "object", "complex", "range", "slice", "property", "classmethod", "staticmethod", "super"]
        p.builtins = ["print", "len", "range", "enumerate", "zip", "map", "filter", "sorted", "reversed", "sum", "min", "max", "abs", "round", "pow", "divmod", "all", "any", "iter", "next", "open", "input", "repr", "str", "int", "float", "bool", "list", "dict", "set", "tuple", "type", "isinstance", "issubclass", "hasattr", "getattr", "setattr", "delattr", "callable", "exec", "eval", "compile", "globals", "locals", "vars", "dir", "help", "id", "hash", "format", "ord", "chr", "bin", "oct", "hex", "ascii"]
        p.supportsLineComments = false
        p.supportsBlockComments = false
        p.supportsHashComments = true
        p.supportsMultilineStrings = true
        return p
    }

    private func rustPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["fn", "let", "mut", "const", "if", "else", "match", "return", "use", "mod", "pub", "crate", "self", "super", "struct", "enum", "impl", "trait", "for", "while", "loop", "break", "continue", "move", "ref", "static", "unsafe", "async", "await", "dyn", "where", "as", "in", "true", "false", "extern", "type", "macro_rules"]
        p.types = ["i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128", "usize", "f32", "f64", "bool", "char", "str", "String", "Vec", "Option", "Result", "Box", "Rc", "Arc", "Cell", "RefCell", "Mutex", "RwLock", "HashMap", "HashSet", "BTreeMap", "BTreeSet", "VecDeque", "LinkedList", "BinaryHeap", "Cow", "Pin", "PhantomData", "Self"]
        p.builtins = ["Some", "None", "Ok", "Err", "println", "print", "eprintln", "eprint", "format", "panic", "assert", "assert_eq", "assert_ne", "debug_assert", "todo", "unimplemented", "unreachable", "vec", "include_str", "include_bytes", "env", "option_env", "concat", "stringify", "file", "line", "column", "module_path"]
        return p
    }

    private func goPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["func", "var", "const", "if", "else", "return", "import", "package", "type", "struct", "interface", "for", "range", "switch", "case", "default", "break", "continue", "go", "select", "chan", "defer", "map", "make", "new", "nil", "true", "false", "fallthrough", "goto"]
        p.types = ["string", "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "uintptr", "float32", "float64", "complex64", "complex128", "bool", "byte", "rune", "error", "any"]
        p.builtins = ["append", "cap", "close", "complex", "copy", "delete", "imag", "len", "make", "new", "panic", "print", "println", "real", "recover"]
        p.supportsBacktickStrings = true
        return p
    }

    private func jsonPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["true", "false", "null"]
        p.supportsLineComments = false
        p.supportsBlockComments = false
        p.supportsJsonKeys = true
        return p
    }

    private func yamlPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["true", "false", "null", "yes", "no", "on", "off"]
        p.supportsLineComments = false
        p.supportsBlockComments = false
        p.supportsHashComments = true
        return p
    }

    private func bashPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac", "in", "function", "return", "exit", "break", "continue", "local", "export", "readonly", "declare", "typeset", "unset", "shift", "set", "source", "alias", "unalias", "trap", "eval", "exec", "select", "until", "coproc", "time"]
        p.builtins = ["echo", "printf", "read", "cd", "pwd", "pushd", "popd", "dirs", "let", "test", "true", "false", "getopts", "hash", "type", "ulimit", "umask", "wait", "kill", "jobs", "fg", "bg", "disown", "suspend", "logout", "history", "fc", "bind", "builtin", "caller", "command", "compgen", "complete", "compopt", "enable", "help", "mapfile", "readarray", "shopt"]
        p.supportsLineComments = false
        p.supportsBlockComments = false
        p.supportsHashComments = true
        p.supportsBacktickStrings = true
        return p
    }

    private func htmlPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.supportsLineComments = false
        p.supportsBlockComments = false
        p.supportsHtmlComments = true
        p.supportsHtmlTags = true
        return p
    }

    /// XML data mode patterns - for data files like plist, config, SOAP, etc.
    /// Skips expensive HTML tag regex (~230ms savings) since these are data files, not markup.
    /// Keeps comment, string, and number highlighting for readability.
    private func xmlDataPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.supportsLineComments = false
        p.supportsBlockComments = false
        p.supportsHtmlComments = true  // Keep XML comment highlighting
        p.supportsHtmlTags = true      // Flag is set, but...
        p.isXmlDataMode = true         // ...this flag skips the expensive tag regex
        return p
    }

    private func cssPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["important", "inherit", "initial", "unset", "revert", "none", "auto", "block", "inline", "flex", "grid", "absolute", "relative", "fixed", "sticky", "static", "hidden", "visible", "scroll", "solid", "dashed", "dotted", "double", "groove", "ridge", "inset", "outset", "transparent", "currentColor"]
        p.types = ["px", "em", "rem", "vh", "vw", "vmin", "vmax", "ch", "ex", "cm", "mm", "in", "pt", "pc", "deg", "rad", "grad", "turn", "s", "ms", "Hz", "kHz", "dpi", "dpcm", "dppx", "fr"]
        p.builtins = ["rgb", "rgba", "hsl", "hsla", "hwb", "lab", "lch", "oklch", "oklab", "color", "url", "calc", "min", "max", "clamp", "var", "attr", "counter", "counters", "linear-gradient", "radial-gradient", "conic-gradient", "repeating-linear-gradient", "repeating-radial-gradient", "image", "image-set", "cross-fade", "element", "env", "fit-content", "minmax", "repeat", "translate", "translateX", "translateY", "translateZ", "translate3d", "rotate", "rotateX", "rotateY", "rotateZ", "rotate3d", "scale", "scaleX", "scaleY", "scaleZ", "scale3d", "skew", "skewX", "skewY", "matrix", "matrix3d", "perspective", "blur", "brightness", "contrast", "drop-shadow", "grayscale", "hue-rotate", "invert", "opacity", "saturate", "sepia"]
        p.supportsLineComments = false
        return p
    }

    private func cppPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["auto", "break", "case", "catch", "class", "const", "constexpr", "consteval", "constinit", "continue", "default", "delete", "do", "else", "enum", "explicit", "export", "extern", "false", "for", "friend", "goto", "if", "inline", "mutable", "namespace", "new", "noexcept", "nullptr", "operator", "private", "protected", "public", "register", "return", "sizeof", "static", "static_assert", "static_cast", "struct", "switch", "template", "this", "throw", "true", "try", "typedef", "typeid", "typename", "union", "using", "virtual", "volatile", "while", "alignas", "alignof", "and", "and_eq", "asm", "bitand", "bitor", "compl", "concept", "co_await", "co_return", "co_yield", "decltype", "dynamic_cast", "final", "not", "not_eq", "or", "or_eq", "override", "reinterpret_cast", "requires", "xor", "xor_eq"]
        p.types = ["void", "bool", "char", "char8_t", "char16_t", "char32_t", "wchar_t", "short", "int", "long", "float", "double", "signed", "unsigned", "size_t", "ptrdiff_t", "intptr_t", "uintptr_t", "int8_t", "int16_t", "int32_t", "int64_t", "uint8_t", "uint16_t", "uint32_t", "uint64_t", "string", "vector", "map", "unordered_map", "set", "unordered_set", "list", "deque", "array", "pair", "tuple", "optional", "variant", "any", "shared_ptr", "unique_ptr", "weak_ptr", "span", "string_view"]
        p.builtins = ["std", "cout", "cin", "cerr", "clog", "endl", "printf", "scanf", "malloc", "free", "realloc", "calloc", "memcpy", "memmove", "memset", "strlen", "strcpy", "strcat", "strcmp", "assert", "sizeof", "alignof", "offsetof", "NULL"]
        return p
    }

    private func javaPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class", "const", "continue", "default", "do", "double", "else", "enum", "extends", "final", "finally", "float", "for", "goto", "if", "implements", "import", "instanceof", "int", "interface", "long", "native", "new", "null", "package", "private", "protected", "public", "return", "short", "static", "strictfp", "super", "switch", "synchronized", "this", "throw", "throws", "transient", "try", "void", "volatile", "while", "true", "false", "var", "yield", "record", "sealed", "non-sealed", "permits"]
        p.types = ["String", "Integer", "Long", "Double", "Float", "Boolean", "Character", "Byte", "Short", "Object", "Class", "System", "Math", "StringBuilder", "StringBuffer", "Array", "Arrays", "List", "ArrayList", "LinkedList", "Set", "HashSet", "TreeSet", "Map", "HashMap", "TreeMap", "LinkedHashMap", "Queue", "Deque", "Stack", "Vector", "Optional", "Stream", "Collector", "Collectors", "Comparator", "Iterator", "Iterable", "Exception", "Error", "RuntimeException", "Throwable", "Thread", "Runnable", "Callable", "Future", "CompletableFuture"]
        p.builtins = ["println", "print", "printf", "format", "equals", "hashCode", "toString", "compareTo", "clone", "finalize", "getClass", "notify", "notifyAll", "wait", "length", "size", "isEmpty", "contains", "get", "set", "add", "remove", "clear", "stream", "filter", "map", "reduce", "collect", "forEach", "sorted", "distinct", "limit", "skip", "anyMatch", "allMatch", "noneMatch", "findFirst", "findAny", "count", "min", "max", "sum", "average"]
        return p
    }

    private func kotlinPatterns() -> LanguagePatterns {
        var p = javaPatterns()
        p.keywords.formUnion(["fun", "val", "var", "when", "is", "in", "out", "object", "companion", "init", "constructor", "data", "inner", "open", "override", "lateinit", "by", "lazy", "inline", "noinline", "crossinline", "reified", "suspend", "tailrec", "operator", "infix", "external", "annotation", "expect", "actual", "typealias", "it", "where"])
        p.types.formUnion(["Any", "Unit", "Nothing", "Int", "Long", "Short", "Byte", "Float", "Double", "Char", "Boolean", "String", "Array", "IntArray", "LongArray", "ShortArray", "ByteArray", "FloatArray", "DoubleArray", "CharArray", "BooleanArray", "List", "MutableList", "Set", "MutableSet", "Map", "MutableMap", "Sequence", "Pair", "Triple", "Lazy", "Regex", "MatchResult", "MatchGroup"])
        return p
    }

    private func rubyPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["def", "class", "module", "if", "elsif", "else", "unless", "case", "when", "while", "until", "for", "do", "end", "begin", "rescue", "raise", "ensure", "retry", "return", "yield", "break", "next", "redo", "super", "self", "nil", "true", "false", "and", "or", "not", "in", "then", "alias", "defined?", "undef", "__FILE__", "__LINE__", "__ENCODING__", "BEGIN", "END", "attr_reader", "attr_writer", "attr_accessor", "private", "protected", "public", "include", "extend", "prepend", "require", "require_relative", "load", "autoload", "lambda", "proc", "loop"]
        p.types = ["String", "Integer", "Float", "Array", "Hash", "Symbol", "Range", "Regexp", "Time", "Date", "DateTime", "File", "Dir", "IO", "Exception", "StandardError", "RuntimeError", "TypeError", "ArgumentError", "NameError", "NoMethodError", "Class", "Module", "Object", "BasicObject", "Kernel", "Numeric", "TrueClass", "FalseClass", "NilClass", "Proc", "Method", "Binding", "Thread", "Fiber", "Enumerator", "Struct", "OpenStruct"]
        p.builtins = ["puts", "print", "p", "pp", "gets", "chomp", "to_s", "to_i", "to_f", "to_a", "to_h", "to_sym", "inspect", "class", "methods", "respond_to?", "is_a?", "kind_of?", "instance_of?", "nil?", "empty?", "blank?", "present?", "each", "map", "select", "reject", "find", "detect", "any?", "all?", "none?", "one?", "count", "size", "length", "first", "last", "take", "drop", "compact", "flatten", "uniq", "sort", "reverse", "join", "split", "strip", "chomp", "gsub", "sub", "match", "scan", "include?", "start_with?", "end_with?", "upcase", "downcase", "capitalize", "titleize", "pluralize", "singularize", "camelize", "underscore"]
        p.supportsHashComments = true
        return p
    }

    private func phpPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["abstract", "and", "array", "as", "break", "callable", "case", "catch", "class", "clone", "const", "continue", "declare", "default", "do", "echo", "else", "elseif", "empty", "enddeclare", "endfor", "endforeach", "endif", "endswitch", "endwhile", "eval", "exit", "extends", "final", "finally", "fn", "for", "foreach", "function", "global", "goto", "if", "implements", "include", "include_once", "instanceof", "insteadof", "interface", "isset", "list", "match", "namespace", "new", "or", "print", "private", "protected", "public", "readonly", "require", "require_once", "return", "static", "switch", "throw", "trait", "try", "unset", "use", "var", "while", "xor", "yield", "true", "false", "null", "self", "parent"]
        p.types = ["string", "int", "integer", "float", "double", "bool", "boolean", "array", "object", "callable", "iterable", "void", "mixed", "never", "null", "resource", "stdClass", "Exception", "Error", "TypeError", "ArgumentCountError", "ArithmeticError", "DivisionByZeroError", "ParseError", "Throwable", "Iterator", "IteratorAggregate", "Traversable", "ArrayAccess", "Serializable", "Closure", "Generator", "DateTime", "DateTimeImmutable", "DateInterval", "DatePeriod"]
        p.builtins = ["echo", "print", "print_r", "var_dump", "var_export", "isset", "unset", "empty", "is_null", "is_array", "is_string", "is_int", "is_float", "is_bool", "is_object", "is_callable", "is_numeric", "count", "sizeof", "strlen", "strpos", "strstr", "str_replace", "substr", "trim", "ltrim", "rtrim", "strtolower", "strtoupper", "ucfirst", "ucwords", "explode", "implode", "join", "array_push", "array_pop", "array_shift", "array_unshift", "array_merge", "array_map", "array_filter", "array_reduce", "array_keys", "array_values", "in_array", "array_search", "sort", "rsort", "asort", "arsort", "ksort", "krsort", "usort", "uasort", "uksort", "json_encode", "json_decode", "file_get_contents", "file_put_contents", "file_exists", "is_file", "is_dir", "mkdir", "rmdir", "unlink", "rename", "copy", "move_uploaded_file", "date", "time", "strtotime", "mktime", "preg_match", "preg_match_all", "preg_replace", "preg_split", "header", "setcookie", "session_start", "session_destroy"]
        p.supportsHashComments = true
        return p
    }

    private func sqlPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN", "BETWEEN", "LIKE", "IS", "NULL", "AS", "ON", "JOIN", "INNER", "LEFT", "RIGHT", "OUTER", "FULL", "CROSS", "NATURAL", "USING", "ORDER", "BY", "ASC", "DESC", "NULLS", "FIRST", "LAST", "GROUP", "HAVING", "DISTINCT", "ALL", "UNION", "INTERSECT", "EXCEPT", "LIMIT", "OFFSET", "FETCH", "NEXT", "ROWS", "ONLY", "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE", "CREATE", "ALTER", "DROP", "TABLE", "INDEX", "VIEW", "DATABASE", "SCHEMA", "IF", "EXISTS", "CASCADE", "RESTRICT", "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "UNIQUE", "CHECK", "DEFAULT", "CONSTRAINT", "AUTO_INCREMENT", "IDENTITY", "SERIAL", "NOT NULL", "WITH", "RECURSIVE", "CASE", "WHEN", "THEN", "ELSE", "END", "CAST", "CONVERT", "COALESCE", "NULLIF", "GREATEST", "LEAST", "EXISTS", "ANY", "SOME", "TRUE", "FALSE", "UNKNOWN"]
        // SQL keywords are case-insensitive, add lowercase versions
        let lowercaseKeywords = p.keywords.map { $0.lowercased() }
        p.keywords.formUnion(lowercaseKeywords)
        p.types = ["INT", "INTEGER", "SMALLINT", "BIGINT", "DECIMAL", "NUMERIC", "FLOAT", "REAL", "DOUBLE", "PRECISION", "CHAR", "VARCHAR", "TEXT", "CLOB", "BLOB", "BINARY", "VARBINARY", "DATE", "TIME", "TIMESTAMP", "DATETIME", "INTERVAL", "BOOLEAN", "BOOL", "SERIAL", "UUID", "JSON", "JSONB", "XML", "ARRAY", "ENUM", "SET"]
        let lowercaseTypes = p.types.map { $0.lowercased() }
        p.types.formUnion(lowercaseTypes)
        p.builtins = ["COUNT", "SUM", "AVG", "MIN", "MAX", "ABS", "ROUND", "CEIL", "CEILING", "FLOOR", "TRUNC", "TRUNCATE", "MOD", "POWER", "SQRT", "EXP", "LOG", "LN", "LOG10", "SIGN", "RANDOM", "RAND", "LENGTH", "LEN", "CHAR_LENGTH", "CHARACTER_LENGTH", "UPPER", "LOWER", "INITCAP", "TRIM", "LTRIM", "RTRIM", "LPAD", "RPAD", "LEFT", "RIGHT", "SUBSTRING", "SUBSTR", "REPLACE", "TRANSLATE", "CONCAT", "CONCAT_WS", "POSITION", "LOCATE", "INSTR", "REVERSE", "REPEAT", "SPACE", "ASCII", "CHR", "CHAR", "NOW", "CURRENT_DATE", "CURRENT_TIME", "CURRENT_TIMESTAMP", "LOCALTIME", "LOCALTIMESTAMP", "DATE_PART", "EXTRACT", "DATE_TRUNC", "DATE_ADD", "DATE_SUB", "DATEDIFF", "DATEADD", "YEAR", "MONTH", "DAY", "HOUR", "MINUTE", "SECOND", "TO_DATE", "TO_CHAR", "TO_NUMBER", "CAST", "CONVERT", "COALESCE", "NULLIF", "NVL", "NVL2", "DECODE", "IIF", "IFNULL", "IF", "CASE", "ROW_NUMBER", "RANK", "DENSE_RANK", "NTILE", "LAG", "LEAD", "FIRST_VALUE", "LAST_VALUE", "NTH_VALUE", "OVER", "PARTITION", "WINDOW"]
        let lowercaseBuiltins = p.builtins.map { $0.lowercased() }
        p.builtins.formUnion(lowercaseBuiltins)
        p.supportsLineComments = true  // -- comments
        return p
    }

    private func markdownPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        // Markdown doesn't really have "keywords" in the traditional sense
        // The highlighting is handled by specific markdown highlighting logic elsewhere
        p.supportsLineComments = false
        p.supportsBlockComments = false
        p.supportsHtmlComments = true
        p.supportsHtmlTags = true
        return p
    }

    private func genericPatterns() -> LanguagePatterns {
        var p = LanguagePatterns()
        p.keywords = ["function", "func", "def", "fn", "class", "struct", "enum", "interface", "trait", "if", "else", "elif", "elsif", "return", "import", "export", "from", "const", "let", "var", "val", "for", "while", "do", "switch", "case", "match", "when", "break", "continue", "try", "catch", "throw", "finally", "true", "false", "null", "nil", "None", "undefined", "self", "this", "new", "public", "private", "protected", "static", "void", "async", "await", "yield"]
        p.types = ["String", "Int", "Integer", "Float", "Double", "Bool", "Boolean", "Array", "List", "Map", "Dict", "Dictionary", "Set", "Object", "Any", "Error", "Exception", "Result", "Option", "Optional"]
        return p
    }
}

// MARK: - Syntax Colors

/// Theme-aware syntax colors for highlighting.
/// Uses NSColor instead of SwiftUI.Color for proper NSKeyedArchiver serialization
/// (SwiftUI.Color is not archivable, causing disk cache failures).
struct SyntaxColors: Sendable {
    let keyword: NSColor
    let string: NSColor
    let comment: NSColor
    let number: NSColor
    let type: NSColor
    let function: NSColor
    let variable: NSColor
    let text: NSColor

    /// Create syntax colors for a given theme
    static func forTheme(_ theme: String, systemIsDark: Bool) -> SyntaxColors {
        let effectiveTheme: String
        if theme == "auto" {
            effectiveTheme = systemIsDark ? "atomOneDark" : "atomOneLight"
        } else {
            effectiveTheme = theme
        }

        switch effectiveTheme {
        case "atomOneLight":
            return SyntaxColors(
                keyword: NSColor(red: 0.65, green: 0.15, blue: 0.64, alpha: 1.0),  // #a626a4
                string: NSColor(red: 0.31, green: 0.63, blue: 0.31, alpha: 1.0),   // #50a14f
                comment: NSColor(red: 0.63, green: 0.63, blue: 0.65, alpha: 1.0),  // #a0a1a7
                number: NSColor(red: 0.72, green: 0.42, blue: 0.09, alpha: 1.0),   // #b76b01
                type: NSColor(red: 0.78, green: 0.56, blue: 0.09, alpha: 1.0),     // #c18401
                function: NSColor(red: 0.25, green: 0.47, blue: 0.95, alpha: 1.0), // #4078f2
                variable: NSColor(red: 0.90, green: 0.34, blue: 0.34, alpha: 1.0), // #e45649
                text: NSColor(red: 0.22, green: 0.23, blue: 0.26, alpha: 1.0)      // #383a42
            )

        case "atomOneDark", "blackout":
            return SyntaxColors(
                keyword: NSColor(red: 0.78, green: 0.47, blue: 0.87, alpha: 1.0),  // #c678dd
                string: NSColor(red: 0.60, green: 0.76, blue: 0.47, alpha: 1.0),   // #98c379
                comment: NSColor(red: 0.36, green: 0.39, blue: 0.44, alpha: 1.0),  // #5c6370
                number: NSColor(red: 0.82, green: 0.60, blue: 0.40, alpha: 1.0),   // #d19a66
                type: NSColor(red: 0.90, green: 0.75, blue: 0.48, alpha: 1.0),     // #e5c07b
                function: NSColor(red: 0.38, green: 0.69, blue: 0.94, alpha: 1.0), // #61afef
                variable: NSColor(red: 0.88, green: 0.42, blue: 0.45, alpha: 1.0), // #e06c75
                text: NSColor(red: 0.67, green: 0.70, blue: 0.75, alpha: 1.0)      // #abb2bf
            )

        case "github":
            return SyntaxColors(
                keyword: NSColor(red: 0.84, green: 0.23, blue: 0.29, alpha: 1.0),  // #d73a49
                string: NSColor(red: 0.01, green: 0.18, blue: 0.39, alpha: 1.0),   // #032f62
                comment: NSColor(red: 0.42, green: 0.45, blue: 0.49, alpha: 1.0),  // #6a737d
                number: NSColor(red: 0.00, green: 0.36, blue: 0.60, alpha: 1.0),   // #005cc5
                type: NSColor(red: 0.42, green: 0.30, blue: 0.65, alpha: 1.0),     // #6f42c1
                function: NSColor(red: 0.42, green: 0.30, blue: 0.65, alpha: 1.0), // #6f42c1
                variable: NSColor(red: 0.14, green: 0.16, blue: 0.18, alpha: 1.0), // #24292e
                text: NSColor(red: 0.14, green: 0.16, blue: 0.18, alpha: 1.0)      // #24292e
            )

        case "githubDark":
            return SyntaxColors(
                keyword: NSColor(red: 1.00, green: 0.48, blue: 0.45, alpha: 1.0),  // #ff7b72
                string: NSColor(red: 0.65, green: 0.84, blue: 1.00, alpha: 1.0),   // #a5d6ff
                comment: NSColor(red: 0.55, green: 0.58, blue: 0.62, alpha: 1.0),  // #8b949e
                number: NSColor(red: 0.47, green: 0.81, blue: 1.00, alpha: 1.0),   // #79c0ff
                type: NSColor(red: 0.49, green: 0.80, blue: 0.55, alpha: 1.0),     // #7ee787
                function: NSColor(red: 0.85, green: 0.74, blue: 1.00, alpha: 1.0), // #d2a8ff
                variable: NSColor(red: 0.79, green: 0.82, blue: 0.85, alpha: 1.0), // #c9d1d9
                text: NSColor(red: 0.79, green: 0.82, blue: 0.85, alpha: 1.0)      // #c9d1d9
            )

        case "xcode":
            return SyntaxColors(
                keyword: NSColor(red: 0.61, green: 0.14, blue: 0.58, alpha: 1.0),  // #9b2393
                string: NSColor(red: 0.77, green: 0.10, blue: 0.09, alpha: 1.0),   // #c41a16
                comment: NSColor(red: 0.36, green: 0.42, blue: 0.47, alpha: 1.0),  // #5d6c79
                number: NSColor(red: 0.11, green: 0.00, blue: 0.81, alpha: 1.0),   // #1c00cf
                type: NSColor(red: 0.44, green: 0.26, blue: 0.57, alpha: 1.0),     // #703daa
                function: NSColor(red: 0.20, green: 0.34, blue: 0.46, alpha: 1.0), // #326d74
                variable: NSColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.0), // #000000
                text: NSColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.0)      // #000000
            )

        case "xcodeDark":
            return SyntaxColors(
                keyword: NSColor(red: 0.99, green: 0.37, blue: 0.64, alpha: 1.0),  // #fc5fa3
                string: NSColor(red: 0.99, green: 0.42, blue: 0.36, alpha: 1.0),   // #fc6a5d
                comment: NSColor(red: 0.50, green: 0.55, blue: 0.60, alpha: 1.0),  // #7f8c98
                number: NSColor(red: 0.82, green: 0.78, blue: 0.53, alpha: 1.0),   // #d0c887
                type: NSColor(red: 0.36, green: 0.85, blue: 0.76, alpha: 1.0),     // #5dd8c8
                function: NSColor(red: 0.40, green: 0.60, blue: 1.00, alpha: 1.0), // #6699ff
                variable: NSColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0), // #ffffff
                text: NSColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0)      // #ffffff
            )

        case "solarizedLight":
            return SyntaxColors(
                keyword: NSColor(red: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),  // #859900
                string: NSColor(red: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),   // #2aa198
                comment: NSColor(red: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),  // #93a1a1
                number: NSColor(red: 0.82, green: 0.43, blue: 0.12, alpha: 1.0),   // #cb4b16
                type: NSColor(red: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),     // #b58900
                function: NSColor(red: 0.15, green: 0.55, blue: 0.82, alpha: 1.0), // #268bd2
                variable: NSColor(red: 0.83, green: 0.21, blue: 0.51, alpha: 1.0), // #d33682
                text: NSColor(red: 0.40, green: 0.48, blue: 0.51, alpha: 1.0)      // #657b83
            )

        case "solarizedDark":
            return SyntaxColors(
                keyword: NSColor(red: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),  // #859900
                string: NSColor(red: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),   // #2aa198
                comment: NSColor(red: 0.35, green: 0.43, blue: 0.46, alpha: 1.0),  // #586e75
                number: NSColor(red: 0.82, green: 0.43, blue: 0.12, alpha: 1.0),   // #cb4b16
                type: NSColor(red: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),     // #b58900
                function: NSColor(red: 0.15, green: 0.55, blue: 0.82, alpha: 1.0), // #268bd2
                variable: NSColor(red: 0.83, green: 0.21, blue: 0.51, alpha: 1.0), // #d33682
                text: NSColor(red: 0.51, green: 0.58, blue: 0.59, alpha: 1.0)      // #839496
            )

        case "tokyoNight":
            return SyntaxColors(
                keyword: NSColor(red: 0.73, green: 0.60, blue: 0.97, alpha: 1.0),  // #bb9af7
                string: NSColor(red: 0.62, green: 0.81, blue: 0.42, alpha: 1.0),   // #9ece6a
                comment: NSColor(red: 0.34, green: 0.37, blue: 0.54, alpha: 1.0),  // #565f89
                number: NSColor(red: 1.00, green: 0.62, blue: 0.47, alpha: 1.0),   // #ff9e64
                type: NSColor(red: 0.17, green: 0.80, blue: 0.87, alpha: 1.0),     // #2ac3de
                function: NSColor(red: 0.48, green: 0.64, blue: 0.97, alpha: 1.0), // #7aa2f7
                variable: NSColor(red: 0.78, green: 0.52, blue: 0.93, alpha: 1.0), // #c678dd
                text: NSColor(red: 0.66, green: 0.69, blue: 0.84, alpha: 1.0)      // #a9b1d6
            )

        default:
            // Default to Atom One Light
            return SyntaxColors.forTheme("atomOneLight", systemIsDark: false)
        }
    }
}
