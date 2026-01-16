import Foundation
import SwiftUI
import HighlightSwift

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let settings = SharedSettings.shared

    @Published var selectedTheme: String {
        didSet { settings.selectedTheme = selectedTheme }
    }

    @Published var fontSize: Double {
        didSet { settings.fontSize = fontSize }
    }

    @Published var showLineNumbers: Bool {
        didSet { settings.showLineNumbers = showLineNumbers }
    }

    private init() {
        // Initialize from SharedSettings
        self.selectedTheme = settings.selectedTheme
        self.fontSize = settings.fontSize
        self.showLineNumbers = settings.showLineNumbers
    }

    /// Refresh settings from shared storage (useful when extension updates settings)
    func refresh() {
        selectedTheme = settings.selectedTheme
        fontSize = settings.fontSize
        showLineNumbers = settings.showLineNumbers
    }

    /// Get the current HighlightColors based on user preference and system appearance
    var currentHighlightColors: HighlightColors {
        switch selectedTheme {
        case "auto":
            return systemAppearanceIsDark ? .dark(.atomOne) : .light(.atomOne)
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
        default:
            return .light(.atomOne)
        }
    }

    /// Get background color for the current theme
    var backgroundColor: Color {
        switch selectedTheme {
        case "auto":
            return systemAppearanceIsDark ? Color(hex: "#282c34") : Color(hex: "#fafafa")
        case "atomOneLight":
            return Color(hex: "#fafafa")
        case "atomOneDark":
            return Color(hex: "#282c34")
        case "github":
            return Color(hex: "#ffffff")
        case "githubDark":
            return Color(hex: "#0d1117")
        case "xcode":
            return Color(hex: "#ffffff")
        case "xcodeDark":
            return Color(hex: "#1f1f24")
        case "solarizedLight":
            return Color(hex: "#fdf6e3")
        case "solarizedDark":
            return Color(hex: "#002b36")
        case "tokyoNight":
            return Color(hex: "#1a1b26")
        case "blackout":
            return Color(hex: "#1e1e1e") // Typora Blackout background
        default:
            return Color(nsColor: .textBackgroundColor)
        }
    }

    /// Get text color for the current theme
    var textColor: Color {
        switch selectedTheme {
        case "auto":
            return systemAppearanceIsDark ? Color(hex: "#abb2bf") : Color(hex: "#383a42")
        case "atomOneLight":
            return Color(hex: "#383a42")
        case "atomOneDark":
            return Color(hex: "#abb2bf")
        case "github":
            return Color(hex: "#24292e")
        case "githubDark":
            return Color(hex: "#c9d1d9")
        case "xcode":
            return Color(hex: "#000000")
        case "xcodeDark":
            return Color(hex: "#ffffff")
        case "solarizedLight":
            return Color(hex: "#657b83")
        case "solarizedDark":
            return Color(hex: "#839496")
        case "tokyoNight":
            return Color(hex: "#a9b1d6")
        case "blackout":
            return Color(hex: "#e0e0e0") // Bright neutral gray for better contrast
        default:
            return Color(nsColor: .textColor)
        }
    }

    /// Check if system is in dark mode
    var systemAppearanceIsDark: Bool {
        if let appearance = NSApp?.effectiveAppearance {
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return false
    }

    /// Get human-readable theme name
    var currentThemeName: String {
        switch selectedTheme {
        case "auto": return "Auto (System)"
        case "atomOneLight": return "Atom One Light"
        case "atomOneDark": return "Atom One Dark"
        case "github": return "GitHub"
        case "githubDark": return "GitHub Dark"
        case "xcode": return "Xcode"
        case "xcodeDark": return "Xcode Dark"
        case "solarizedLight": return "Solarized Light"
        case "solarizedDark": return "Solarized Dark"
        case "tokyoNight": return "Tokyo Night"
        case "blackout": return "Blackout"
        default: return selectedTheme
        }
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
