import Shared
import SwiftUI

struct MarkdownPane: View {
    @Environment(SettingsModel.self) private var model

    private static let renderedFamilies = PreviewFontMenu.renderedFontFamilies

    var body: some View {
        @Bindable var model = model
        Form {
            Section("Opening") {
                Picker(selection: $model.markdownDefaultMode) {
                    Text("Rendered").tag("rendered")
                    Text("Raw").tag("raw")
                } label: {
                    SettingsLabel("Open Markdown as")
                }
                .pickerStyle(.segmented)
                .settingsAnchor(.markdownDefaultMode)

                Toggle(isOn: $model.markdownRawHighlighting) {
                    SettingsLabel("Highlight syntax in raw view")
                }
                .settingsAnchor(.markdownRawHighlighting)

                Toggle(isOn: $model.markdownShowImages) {
                    SettingsLabel("Show images", description: "Inline images in rendered Markdown.")
                }
                .settingsAnchor(.markdownInlineImages)
            }

            Section("Table of contents") {
                Toggle(isOn: $model.markdownShowTOC) {
                    SettingsLabel("Table of contents button", description: "Adds a contents button to the rendered header.")
                }
                .settingsAnchor(.markdownTOC)

                Toggle(isOn: $model.markdownTOCOpen) {
                    SettingsLabel("Open by default")
                }
                .disabled(!model.markdownShowTOC)
                .settingsAnchor(.markdownTOCOpen)
            }

            Section("Rendered text") {
                LabeledContent {
                    SettingsFontPicker(
                        selection: $model.markdownFont,
                        families: Self.renderedFamilies,
                        defaultFamily: PreviewFontFamily.defaultMarkdownRenderedFamily
                    )
                } label: {
                    SettingsLabel("Font", description: "Prose in rendered Markdown. Inline code keeps the code font.")
                }
                .settingsAnchor(.markdownFont)

                Toggle(isOn: $model.syncFontSizes) {
                    SettingsLabel("Match code font size")
                }
                .settingsAnchor(.markdownMatchCodeSize)

                SettingsSliderRow(
                    "Font size",
                    description: model.syncFontSizes ? "Follows the code font size in Appearance." : nil,
                    value: $model.markdownFontSize,
                    in: 10...24,
                    step: 1
                ) { "\(Int($0)) pt" }
                .disabled(model.syncFontSizes)
                .settingsAnchor(.markdownFontSize)

                Picker(selection: $model.markdownWidthMode) {
                    Text("Auto").tag("auto")
                    Text("Custom").tag("custom")
                } label: {
                    SettingsLabel(
                        "Width",
                        description: model.markdownWidthMode == "auto" ? "The built-in reading width." : nil
                    )
                }
                .pickerStyle(.segmented)
                .settingsAnchor(.markdownWidth)

                if model.markdownWidthMode == "custom" {
                    SettingsSliderRow(
                        "Maximum width",
                        value: $model.markdownMaxWidth.asDouble,
                        in: 480...2400,
                        step: 10
                    ) { "\(Int($0)) px" }
                }

                Picker(selection: $model.markdownAlignment) {
                    Text("Left").tag("left")
                    Text("Center").tag("center")
                    Text("Right").tag("right")
                } label: {
                    SettingsLabel("Alignment")
                }
                .pickerStyle(.segmented)
                .settingsAnchor(.markdownAlignment)
            }

            Section {
                Toggle(isOn: $model.customCSSReplacesBuiltIn) {
                    SettingsLabel("Replace built-in styles")
                }
                .settingsAnchor(.markdownCustomCSS)

                TextEditor(text: $model.customCSS)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .frame(minHeight: 160)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
                    .accessibilityLabel("Custom CSS")
            } header: {
                Text("Custom CSS")
            } footer: {
                Text("Off: your CSS is added after the built-in styles. On: only your CSS is used.")
                    .foregroundStyle(.secondary)
            }
        }
        .settingsPaneStyle()
    }
}
