import Shared
import SwiftUI

struct AppearancePane: View {
    @Environment(SettingsModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    /// Enumerating installed fonts and testing each for fixed pitch is slow; do it once.
    private static let codeFamilies = PreviewFontMenu.codeFontFamilies

    var body: some View {
        @Bindable var model = model
        Form {
            SettingsSection("Theme") {
                ThemePreview(
                    theme: model.theme,
                    fontFamily: model.codeFontFamily,
                    fontSize: model.fontSize,
                    isDark: colorScheme == .dark
                )

                Picker(selection: $model.theme) {
                    ForEach(ThemePalette.selectableThemes) { theme in
                        Text(theme.title).tag(theme.id)
                    }
                } label: {
                    SettingsLabel("Theme")
                }
                .settingsAnchor(.theme)
            }

            SettingsSection("Code") {
                LabeledContent {
                    SettingsFontPicker(
                        selection: $model.codeFontFamily,
                        families: Self.codeFamilies,
                        defaultFamily: PreviewFontFamily.defaultCodeFamily
                    )
                } label: {
                    SettingsLabel("Font", description: "Code previews, Markdown's raw view and Finder thumbnails.")
                }
                .settingsAnchor(.codeFont)

                SettingsSliderRow("Font size", value: $model.fontSize, in: 10...24, step: 1) { "\(Int($0)) pt" }
                    .settingsAnchor(.fontSize)

                Toggle(isOn: $model.showLineNumbers) {
                    SettingsLabel("Line numbers")
                }
                .settingsAnchor(.lineNumbers)

                Toggle(isOn: $model.wordWrap) {
                    SettingsLabel("Wrap long lines", description: "Instead of scrolling sideways.")
                }
                .settingsAnchor(.wordWrap)
            }

            SettingsSection("This app") {
                Picker(selection: $model.interfaceTextSize) {
                    ForEach(AppUIFontSizePreset.allCases) { preset in
                        Text(preset.title).tag(preset.rawValue)
                    }
                } label: {
                    SettingsLabel("Interface text size", description: "Text in dotViewer's own windows, not in previews.")
                }
                .settingsAnchor(.interfaceTextSize)
            }
        }
        .settingsPaneStyle()
    }
}

/// A live sample of the chosen theme, font and size — what used to be a separate "Theme" tab, now
/// right above the picker it previews.
private struct ThemePreview: View {
    let theme: String
    let fontFamily: String
    let fontSize: Double
    let isDark: Bool

    var body: some View {
        let palette = ThemePalette.palette(for: theme, systemIsDark: isDark)
        let keyword = Color(hex: palette.keyword)
        let plain = Color(hex: palette.text)

        // Code is `verbatim`: a literal `Text` is Markdown, which would eat the backslash in `\(name)`.
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: "// Preview of your theme")
                .foregroundStyle(Color(hex: palette.comment))
            Text("""
                \(Text(verbatim: "func ").foregroundStyle(keyword))\
                \(Text(verbatim: "greet").foregroundStyle(Color(hex: palette.function)))\
                \(Text(verbatim: "(name: ").foregroundStyle(plain))\
                \(Text(verbatim: "String").foregroundStyle(Color(hex: palette.type)))\
                \(Text(verbatim: ") -> ").foregroundStyle(plain))\
                \(Text(verbatim: "String").foregroundStyle(Color(hex: palette.type)))\
                \(Text(verbatim: " {").foregroundStyle(plain))
                """)
            Text("""
                \(Text(verbatim: "    return ").foregroundStyle(keyword))\
                \(Text(verbatim: "\"Hello, \\(name)!\"").foregroundStyle(Color(hex: palette.string)))
                """)
            Text(verbatim: "}")
                .foregroundStyle(plain)
        }
        .font(Font(PreviewFontResolver.codeFont(familyName: fontFamily, size: fontSize)))
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: palette.background), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Theme preview")
    }
}
