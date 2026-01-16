import Foundation
import SwiftUI

/// Syntax highlighter using Syntect (Rust-based, fast)
/// Replaces HighlightSwift for better performance
struct SyntaxHighlighter: Sendable {

    /// Highlight code using Syntect
    /// - Parameters:
    ///   - code: The source code to highlight
    ///   - language: Language name or file extension (e.g., "swift", "python")
    /// - Returns: Attributed string with syntax highlighting
    func highlight(code: String, language: String?) async throws -> AttributedString {
        // Get the app theme for highlighting
        let appTheme = SharedSettings.shared.selectedTheme
        let fontSize = SharedSettings.shared.fontSize

        // Map language to Syntect-compatible format
        let syntectLanguage = mapLanguage(language)

        // Call Syntect via UniFFI bindings
        let result = highlightCodeWithAppTheme(
            code: code,
            language: syntectLanguage,
            appTheme: appTheme
        )

        // Convert HighlightResult spans to AttributedString
        return convertToAttributedString(result, fontSize: fontSize)
    }

    private func mapLanguage(_ language: String?) -> String {
        guard let lang = language?.lowercased() else { return "txt" }

        // Map common language names to Syntect-compatible names/extensions
        let mapping: [String: String] = [
            // Shell
            "bash": "sh",
            "shell": "sh",
            "zsh": "sh",

            // JavaScript variants
            "javascript": "js",
            "typescript": "ts",
            "jsx": "jsx",
            "tsx": "tsx",

            // Python
            "python": "py",

            // Ruby
            "ruby": "rb",

            // Config files
            "yaml": "yaml",
            "yml": "yaml",
            "toml": "toml",
            "json": "json",

            // Markup
            "markdown": "md",
            "html": "html",
            "xml": "xml",
            "css": "css",
            "scss": "scss",

            // Systems languages
            "swift": "swift",
            "rust": "rs",
            "go": "go",
            "c": "c",
            "cpp": "cpp",
            "c++": "cpp",
            "objc": "m",
            "objective-c": "m",

            // JVM
            "java": "java",
            "kotlin": "kt",
            "scala": "scala",

            // .NET
            "csharp": "cs",
            "c#": "cs",
            "fsharp": "fs",
            "f#": "fs",

            // Other
            "sql": "sql",
            "dockerfile": "dockerfile",
            "makefile": "makefile",
            "cmake": "cmake",
            "lua": "lua",
            "perl": "pl",
            "php": "php",
            "r": "r",
            "haskell": "hs",
            "elixir": "ex",
            "erlang": "erl",
            "clojure": "clj",
            "vim": "vim",
            "diff": "diff",
            "ini": "ini",
            "properties": "properties",
            "plaintext": "txt",
        ]

        return mapping[lang] ?? lang
    }

    private func convertToAttributedString(_ result: HighlightResult, fontSize: Double) -> AttributedString {
        var attributedString = AttributedString()

        for span in result.spans {
            var attrs = AttributeContainer()

            // Parse hex color to SwiftUI Color
            if let color = parseHexColor(span.foreground) {
                attrs.foregroundColor = color
            }

            // Apply font with style modifiers
            let isBold = (span.fontStyle & 1) != 0
            let isItalic = (span.fontStyle & 2) != 0

            if isBold && isItalic {
                attrs.font = .system(size: fontSize, design: .monospaced).bold().italic()
            } else if isBold {
                attrs.font = .system(size: fontSize, design: .monospaced).bold()
            } else if isItalic {
                attrs.font = .system(size: fontSize, design: .monospaced).italic()
            } else {
                attrs.font = .system(size: fontSize, design: .monospaced)
            }

            var spanAttr = AttributedString(span.text)
            spanAttr.mergeAttributes(attrs)
            attributedString.append(spanAttr)
        }

        return attributedString
    }

    /// Parse hex color string (#RRGGBB) to SwiftUI Color
    private func parseHexColor(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }

        guard hexSanitized.count == 6 else { return nil }

        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}
