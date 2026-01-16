import Foundation
import SwiftUI
import HighlightSwift

struct SyntaxHighlighter: Sendable {
    private let highlight = Highlight()

    func highlight(code: String, language: String?) async throws -> AttributedString {
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
