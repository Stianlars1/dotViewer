import Foundation
import SwiftUI
import HighlightSwift

/// Unified syntax highlighter that uses FastSyntaxHighlighter for supported languages,
/// falling back to HighlightSwift for languages without dedicated fast support.
struct SyntaxHighlighter: Sendable {
    private let fastHighlighter = FastSyntaxHighlighter()
    private let highlight = Highlight()

    /// Highlight code with the most appropriate highlighter for the language
    /// - Parameters:
    ///   - code: Source code to highlight
    ///   - language: Language identifier (e.g., "swift", "javascript")
    /// - Returns: Attributed string with syntax highlighting
    func highlight(code: String, language: String?) async throws -> AttributedString {
        // Try FastSyntaxHighlighter first for supported languages (native Swift, fast)
        if FastSyntaxHighlighter.isSupported(language) {
            let colors = await MainActor.run {
                ThemeManager.shared.syntaxColors
            }
            return fastHighlighter.highlight(code: code, language: language, colors: colors)
        }

        // Fall back to HighlightSwift for unsupported languages
        return try await highlightWithFallback(code: code, language: language)
    }

    /// Fallback highlighting using HighlightSwift (JavaScriptCore-based)
    private func highlightWithFallback(code: String, language: String?) async throws -> AttributedString {
        do {
            // Determine the highlight mode
            let mode: HighlightMode
            if let lang = language {
                mode = .languageAlias(lang)
            } else {
                mode = .automatic
            }

            // Get colors based on user's theme setting
            let colors = resolveColors()

            let result = try await highlight.request(code, mode: mode, colors: colors)

            return result.attributedText
        } catch {
            // Fallback: return plain text with monospace font
            let fontSize = SharedSettings.shared.fontSize
            var plainText = AttributedString(code)
            plainText.font = .system(size: fontSize, design: .monospaced)
            return plainText
        }
    }

    private func resolveColors() -> HighlightColors {
        let theme = SharedSettings.shared.selectedTheme

        switch theme {
        case "atomOneLight":
            return .light(.atomOne)
        case "atomOneDark":
            return .dark(.atomOne)
        case "github":
            return .light(.github)
        case "githubDark":
            return .dark(.github)
        case "xcode":
            return .light(.xcode)
        case "xcodeDark":
            return .dark(.xcode)
        case "solarizedLight":
            return .light(.solarized)
        case "solarizedDark":
            return .dark(.solarized)
        case "tokyoNight":
            return .dark(.tokyoNight)
        case "blackout":
            return .dark(.atomOne) // Blackout uses Atom One Dark syntax colors
        case "auto":
            return systemIsDark ? .dark(.atomOne) : .light(.atomOne)
        default:
            return .light(.atomOne)
        }
    }

    private var systemIsDark: Bool {
        if let appearance = NSApp?.effectiveAppearance {
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return false
    }
}
