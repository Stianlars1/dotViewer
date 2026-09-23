import SwiftUI

// The Interface text size setting. macOS ignores `dynamicTypeSize` — its text styles have fixed
// sizes (body is 13 pt at every Dynamic Type size) — so the app scales its fonts itself:
//
// - `appUIFontSizing(_:)` on each window's root sets the chosen body size as the window's font,
//   which reaches all text without a style of its own: Form labels, section headers, values.
// - `appFont(_:)` replaces `font(_:)` for styled text and scales the style's size by the same factor.
// - `appFontWhenScaled(_:)` is for text the system styles itself: List rows, which get their font
//   from the List instead of the window, and Form section headers and footers, which the window's
//   font would otherwise turn into plain body text.
//
// Controls keep their native size, as they do with macOS's own per-app text size. At the default
// size every one of these leaves the system's fonts exactly as they are.

enum AppUIFontSizePreset: String, CaseIterable, Identifiable {
    // The raw values are what the App Group settings store; `system` is the default. Declared in
    // menu order, smallest first.
    case xSmall
    case small
    case system
    case large
    case xLarge
    case xxLarge
    case xxxLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .system: return "Default"
        case .large: return "Large"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "XX Large"
        case .xxxLarge: return "XXX Large"
        }
    }

    /// The body text size, in points. macOS's own is 13.
    var bodyPointSize: CGFloat {
        switch self {
        case .xSmall: return 11
        case .small: return 12
        case .system: return 13
        case .large: return 15
        case .xLarge: return 17
        case .xxLarge: return 19
        case .xxxLarge: return 21
        }
    }

    /// What every text style's size is multiplied by.
    var scale: CGFloat { bodyPointSize / Self.system.bodyPointSize }

    /// Unknown values read as the default, and so does `medium`: it was a separate option that
    /// SharedSettings no longer accepts.
    static func from(rawValue: String) -> AppUIFontSizePreset {
        AppUIFontSizePreset(rawValue: rawValue) ?? .system
    }
}

extension EnvironmentValues {
    /// How much the Interface text size setting scales text; 1 at the default size.
    @Entry var appTextScale: CGFloat = 1
}

extension Font.TextStyle {
    /// This style's size and weight on macOS, where they are fixed. They match
    /// `NSFont.preferredFont(forTextStyle:)` (AppUIFontSizingTests checks the sizes).
    var macOSMetrics: (size: CGFloat, weight: Font.Weight) {
        switch self {
        case .largeTitle: return (26, .regular)
        case .title: return (22, .regular)
        case .title2: return (17, .regular)
        case .title3: return (15, .regular)
        case .headline: return (13, .bold)
        case .subheadline: return (11, .regular)
        case .body: return (13, .regular)
        case .callout: return (12, .regular)
        case .footnote: return (10, .regular)
        case .caption: return (10, .regular)
        case .caption2: return (10, .medium)
        default: return (13, .regular)
        }
    }
}

private struct AppUIFontSizeModifier: ViewModifier {
    let preset: AppUIFontSizePreset

    func body(content: Content) -> some View {
        content
            .environment(\.appTextScale, preset.scale)
            .font(preset == .system ? nil : .system(size: preset.bodyPointSize))
    }
}

private struct AppFontModifier: ViewModifier {
    let style: Font.TextStyle
    let design: Font.Design?
    @Environment(\.appTextScale) private var scale

    func body(content: Content) -> some View {
        content.font(font)
    }

    private var font: Font {
        guard scale != 1 else { return .system(style, design: design) }
        let metrics = style.macOSMetrics
        return .system(size: metrics.size * scale, weight: metrics.weight, design: design)
    }
}

private struct AppSizedFontModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    @Environment(\.appTextScale) private var scale

    func body(content: Content) -> some View {
        content.font(.system(size: size * scale, weight: weight))
    }
}

private struct AppFontWhenScaledModifier: ViewModifier {
    let style: Font.TextStyle
    @Environment(\.appTextScale) private var scale

    func body(content: Content) -> some View {
        // Rewrites the font only when scaled, so at the default size the system's own styling stays:
        // a sidebar row's font follows the macOS sidebar size setting, a section header is bold.
        content.transformEnvironment(\.font) { [scale, style] font in
            guard scale != 1 else { return }
            let metrics = style.macOSMetrics
            font = .system(size: metrics.size * scale, weight: metrics.weight)
        }
    }
}

extension View {
    /// Applies the Interface text size setting (an `AppUIFontSizePreset` raw value) to a window.
    func appUIFontSizing(_ rawPreset: String) -> some View {
        modifier(AppUIFontSizeModifier(preset: AppUIFontSizePreset.from(rawValue: rawPreset)))
    }

    /// `font(.system(style, design: design))`, scaled by the Interface text size setting.
    func appFont(_ style: Font.TextStyle, design: Font.Design? = nil) -> some View {
        modifier(AppFontModifier(style: style, design: design))
    }

    /// `font(.system(size: size, weight: weight))`, scaled by the Interface text size setting.
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(AppSizedFontModifier(size: size, weight: weight))
    }

    /// Leaves the font the system gives this text at the default size and uses `style`, scaled, at
    /// every other: for List rows, which the window's font doesn't reach, and Form section headers
    /// and footers, whose own styling it would replace.
    func appFontWhenScaled(_ style: Font.TextStyle = .body) -> some View {
        modifier(AppFontWhenScaledModifier(style: style))
    }
}
