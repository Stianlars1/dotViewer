import SwiftUI

enum AppUIFontSizePreset: String, CaseIterable, Identifiable {
    case system
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "XX Large"
        case .xxxLarge: return "XXX Large"
        }
    }

    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system: return nil
        case .xSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .xLarge
        case .xxLarge: return .xxLarge
        case .xxxLarge: return .xxxLarge
        }
    }

    static func from(rawValue: String) -> AppUIFontSizePreset {
        AppUIFontSizePreset(rawValue: rawValue) ?? .system
    }
}

private struct AppUIFontSizeModifier: ViewModifier {
    let preset: AppUIFontSizePreset

    @ViewBuilder
    func body(content: Content) -> some View {
        if let dynamicTypeSize = preset.dynamicTypeSize {
            content.dynamicTypeSize(dynamicTypeSize)
        } else {
            content
        }
    }
}

extension View {
    func appUIFontSizing(_ rawPreset: String) -> some View {
        modifier(AppUIFontSizeModifier(preset: AppUIFontSizePreset.from(rawValue: rawPreset)))
    }
}
