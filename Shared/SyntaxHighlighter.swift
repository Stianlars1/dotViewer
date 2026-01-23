import Foundation
import SwiftUI
import AppKit
import HighlightSwift
import os

/// Unified syntax highlighter that uses FastSyntaxHighlighter for supported languages,
/// falling back to HighlightSwift for languages without dedicated fast support.
struct SyntaxHighlighter: Sendable {
    private let fastHighlighter = FastSyntaxHighlighter()
    private let highlight = Highlight()

    // MARK: - Theme Color Cache

    /// Cached syntax colors to avoid MainActor.run overhead on every file.
    /// PERFORMANCE: Saves 10-30ms per file by avoiding main thread hop.
    private struct ColorCacheState: Sendable {
        var colors: SyntaxColors?
        var theme: String?
        var appearanceIsDark: Bool?
    }
    private static let colorCache = OSAllocatedUnfairLock(initialState: ColorCacheState())

    /// Highlight code with the most appropriate highlighter for the language
    /// - Parameters:
    ///   - code: Source code to highlight
    ///   - language: Language identifier (e.g., "swift", "javascript")
    /// - Returns: Attributed string with syntax highlighting
    func highlight(code: String, language: String?) async throws -> AttributedString {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fastSupported = FastSyntaxHighlighter.isSupported(language)
        perfLog("[dotViewer PERF] SyntaxHighlighter.highlight START - language: %@, codeLen: %d chars, fastSupported: %@", language ?? "nil", code.count, fastSupported ? "YES" : "NO")

        // Try FastSyntaxHighlighter first for supported languages (native Swift, fast)
        if fastSupported {
            let colorStart = CFAbsoluteTimeGetCurrent()

            let currentTheme = SharedSettings.shared.selectedTheme

            // Get current appearance (thread-safe in macOS 11+)
            let appearance = NSAppearance.currentDrawing()
            let systemIsDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

            // Thread-safe cache access via OSAllocatedUnfairLock
            let colors: SyntaxColors = Self.colorCache.withLock { state in
                if let cached = state.colors,
                   state.theme == currentTheme,
                   state.appearanceIsDark == systemIsDark {
                    perfLog("[dotViewer PERF] [SH +%.3fs] ThemeManager.syntaxColors: CACHED", CFAbsoluteTimeGetCurrent() - startTime)
                    return cached
                }
                let computed = SyntaxColors.forTheme(currentTheme, systemIsDark: systemIsDark)
                state.colors = computed
                state.theme = currentTheme
                state.appearanceIsDark = systemIsDark
                perfLog("[dotViewer PERF] [SH +%.3fs] ThemeManager.syntaxColors: computed, now cached", CFAbsoluteTimeGetCurrent() - startTime)
                return computed
            }

            let highlightStart = CFAbsoluteTimeGetCurrent()
            let result = fastHighlighter.highlight(code: code, language: language, colors: colors)
            perfLog("[dotViewer PERF] [SH +%.3fs] FastSyntaxHighlighter.highlight took: %.3fs", CFAbsoluteTimeGetCurrent() - startTime, CFAbsoluteTimeGetCurrent() - highlightStart)
            perfLog("[dotViewer PERF] SyntaxHighlighter.highlight DONE - total: %.3fs, path: Fast", CFAbsoluteTimeGetCurrent() - startTime)
            return result
        }

        // Fall back to HighlightSwift for unsupported languages
        perfLog("[dotViewer PERF] [SH +%.3fs] falling back to HighlightSwift", CFAbsoluteTimeGetCurrent() - startTime)
        let fallbackStart = CFAbsoluteTimeGetCurrent()
        let result = try await highlightWithFallback(code: code, language: language)
        perfLog("[dotViewer PERF] [SH +%.3fs] HighlightSwift fallback took: %.3fs", CFAbsoluteTimeGetCurrent() - startTime, CFAbsoluteTimeGetCurrent() - fallbackStart)
        perfLog("[dotViewer PERF] SyntaxHighlighter.highlight DONE - total: %.3fs, path: HighlightSwift", CFAbsoluteTimeGetCurrent() - startTime)
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
                perfLog("[dotViewer PERF] [HS] using .languageAlias(%@)", lang)
            } else {
                perfLog("[dotViewer PERF] [HS] WARNING: No language detected, using plaintext to avoid auto-detection")
                mode = .languageAlias("plaintext")
            }
            perfLog("[dotViewer PERF] highlightWithFallback called - language: %@, mode: languageAlias", language ?? "nil")

            // Get colors based on user's theme setting
            let colorStart = CFAbsoluteTimeGetCurrent()
            let colors = resolveColors()
            perfLog("[dotViewer PERF] [HS +%.3fs] resolveColors took: %.3fs", CFAbsoluteTimeGetCurrent() - fallbackStart, CFAbsoluteTimeGetCurrent() - colorStart)

            let requestStart = CFAbsoluteTimeGetCurrent()
            let result = try await highlight.request(code, mode: mode, colors: colors)
            perfLog("[dotViewer PERF] [HS +%.3fs] highlight.request took: %.3fs", CFAbsoluteTimeGetCurrent() - fallbackStart, CFAbsoluteTimeGetCurrent() - requestStart)

            // Convert SwiftUI foregroundColor attributes to AppKit foregroundColor
            // so colors survive RTF cache serialization (SwiftUI attrs are lost in NSAttributedString bridge)
            return convertToAppKitColors(result.attributedText)
        } catch {
            perfLog("[dotViewer PERF] [HS] ERROR: %@, returning plain text", error.localizedDescription)
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

    /// Convert SwiftUI foregroundColor attributes to AppKit foregroundColor.
    /// SwiftUI-scope attributes are lost when bridging to NSAttributedString (for RTF cache),
    /// so we must use AppKit-scope attributes to preserve colors across cache round-trips.
    private func convertToAppKitColors(_ input: AttributedString) -> AttributedString {
        var result = input
        for run in input.runs {
            if let swiftUIColor = run.foregroundColor {
                result[run.range].appKit.foregroundColor = NSColor(swiftUIColor)
                result[run.range].foregroundColor = nil
            }
        }
        return result
    }
}
