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
        let startTime = CFAbsoluteTimeGetCurrent()
        let fastSupported = FastSyntaxHighlighter.isSupported(language)
        NSLog("[dotViewer PERF] SyntaxHighlighter.highlight START - language: %@, codeLen: %d chars, fastSupported: %@", language ?? "nil", code.count, fastSupported ? "YES" : "NO")

        // Try FastSyntaxHighlighter first for supported languages (native Swift, fast)
        if fastSupported {
            let colorStart = CFAbsoluteTimeGetCurrent()
            let colors = await MainActor.run {
                ThemeManager.shared.syntaxColors
            }
            NSLog("[dotViewer PERF] [SH +%.3fs] ThemeManager.syntaxColors took: %.3fs", CFAbsoluteTimeGetCurrent() - startTime, CFAbsoluteTimeGetCurrent() - colorStart)

            let highlightStart = CFAbsoluteTimeGetCurrent()
            let result = fastHighlighter.highlight(code: code, language: language, colors: colors)
            NSLog("[dotViewer PERF] [SH +%.3fs] FastSyntaxHighlighter.highlight took: %.3fs", CFAbsoluteTimeGetCurrent() - startTime, CFAbsoluteTimeGetCurrent() - highlightStart)
            NSLog("[dotViewer PERF] SyntaxHighlighter.highlight DONE - total: %.3fs, path: Fast", CFAbsoluteTimeGetCurrent() - startTime)
            return result
        }

        // Fall back to HighlightSwift for unsupported languages
        NSLog("[dotViewer PERF] [SH +%.3fs] falling back to HighlightSwift", CFAbsoluteTimeGetCurrent() - startTime)
        let fallbackStart = CFAbsoluteTimeGetCurrent()
        let result = try await highlightWithFallback(code: code, language: language)
        NSLog("[dotViewer PERF] [SH +%.3fs] HighlightSwift fallback took: %.3fs", CFAbsoluteTimeGetCurrent() - startTime, CFAbsoluteTimeGetCurrent() - fallbackStart)
        NSLog("[dotViewer PERF] SyntaxHighlighter.highlight DONE - total: %.3fs, path: HighlightSwift", CFAbsoluteTimeGetCurrent() - startTime)
        return result
    }

    /// Fallback highlighting using HighlightSwift (JavaScriptCore-based)
    private func highlightWithFallback(code: String, language: String?) async throws -> AttributedString {
        let fallbackStart = CFAbsoluteTimeGetCurrent()
        do {
            // Determine the highlight mode
            // NEVER use .automatic - it runs multiple parsers and is 40-60% slower
            // If we don't know the language, use plaintext to avoid auto-detection overhead
            let mode: HighlightMode
            if let lang = language {
                mode = .languageAlias(lang)
                NSLog("[dotViewer PERF] [HS] using .languageAlias(%@)", lang)
            } else {
                NSLog("[dotViewer PERF] [HS] WARNING: No language detected, using plaintext to avoid auto-detection")
                mode = .languageAlias("plaintext")
            }
            NSLog("[dotViewer PERF] highlightWithFallback called - language: %@, mode: languageAlias", language ?? "nil")

            // Get colors based on user's theme setting
            let colorStart = CFAbsoluteTimeGetCurrent()
            let colors = resolveColors()
            NSLog("[dotViewer PERF] [HS +%.3fs] resolveColors took: %.3fs", CFAbsoluteTimeGetCurrent() - fallbackStart, CFAbsoluteTimeGetCurrent() - colorStart)

            let requestStart = CFAbsoluteTimeGetCurrent()
            let result = try await highlight.request(code, mode: mode, colors: colors)
            NSLog("[dotViewer PERF] [HS +%.3fs] highlight.request took: %.3fs", CFAbsoluteTimeGetCurrent() - fallbackStart, CFAbsoluteTimeGetCurrent() - requestStart)

            return result.attributedText
        } catch {
            NSLog("[dotViewer PERF] [HS] ERROR: %@, returning plain text", error.localizedDescription)
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
