import Shared
import SwiftUI

struct WindowPane: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            SettingsSection("Quick Look window") {
                Picker(selection: $model.windowSizeMode) {
                    Text("Fixed").tag("fixed")
                    Text("Auto").tag("auto")
                    Text("Aspect ratio").tag("aspect")
                    Text("Fit content").tag("contentFixed")
                    Text("Remember").tag("remember")
                } label: {
                    SettingsLabel("Size", description: sizeModeDescription)
                }
                .settingsAnchor(.windowSizeMode)

                switch model.windowSizeMode {
                case "fixed":
                    widthRow(title: "Width", value: $model.windowFixedWidth)
                        .settingsAnchor(.windowDimensions)
                    SettingsSliderRow("Height", value: $model.windowFixedHeight.asDouble, in: 220...1400, step: 10) {
                        "\(Int($0)) px"
                    }
                case "contentFixed":
                    widthRow(title: "Width", value: $model.windowFixedWidth)
                        .settingsAnchor(.windowDimensions)
                    SettingsSliderRow("Maximum height", value: $model.windowFixedHeight.asDouble, in: 220...1400, step: 10) {
                        "\(Int($0)) px"
                    }
                case "aspect":
                    Picker(selection: $model.windowAspectRatio) {
                        ForEach(PreviewSizing.AspectRatio.allKeys, id: \.self) { key in
                            Text(key).tag(key)
                        }
                    } label: {
                        SettingsLabel("Ratio")
                    }
                    .pickerStyle(.segmented)
                    .settingsAnchor(.windowDimensions)
                    widthRow(title: "Base width", value: $model.windowAspectBaseWidth)
                case "remember":
                    LabeledContent {
                        HStack(spacing: 8) {
                            Button("Reset") { model.resetRememberedWindowSize() }
                            Button("Save as Fixed") { model.saveRememberedSizeAsFixed() }
                        }
                        .controlSize(.small)
                    } label: {
                        SettingsLabel("Remembered size")
                    }
                    .settingsAnchor(.windowDimensions)
                default:
                    EmptyView()
                }
            }

            Section {
                Picker(selection: $model.codeWidthMode) {
                    Text("Auto").tag("auto")
                    Text("Custom").tag("custom")
                } label: {
                    SettingsLabel("Width")
                }
                .pickerStyle(.segmented)
                .settingsAnchor(.codeWidth)

                if model.codeWidthMode == "custom" {
                    SettingsSliderRow("Maximum width", value: $model.codeMaxWidth.asDouble, in: 480...2400, step: 10) {
                        "\(Int($0)) px"
                    }
                }

                alignmentPicker(title: "Code alignment", selection: $model.codeAlignment)
                    .settingsAnchor(.codeAlignment)
                alignmentPicker(title: "Markdown raw alignment", selection: $model.markdownRawAlignment)
                    .settingsAnchor(.markdownRawAlignment)
            } header: {
                Text("Code and raw text")
                    .appFontWhenScaled(.headline)
            } footer: {
                Text("Applies to code files and Markdown's raw view.")
                    .appFontWhenScaled(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .settingsPaneStyle()
    }

    private var sizeModeDescription: String {
        switch model.windowSizeMode {
        case "auto":
            return "Sized to the file's content, at least 700×420 so small files don't open tiny."
        case "remember":
            return "Reuses the size dotViewer last requested. macOS doesn't report your own resizing."
        case "aspect":
            let ratio = PreviewSizing.AspectRatio.from(key: model.windowAspectRatio)
            let height = Int(ratio.heightForWidth(CGFloat(model.windowAspectBaseWidth)))
            return "Every preview opens at \(model.windowAspectBaseWidth)×\(height) (\(model.windowAspectRatio))."
        case "contentFixed":
            return "Fixed width; the height follows the content up to the maximum."
        default:
            return "Every preview opens at the same size. You can still resize the window."
        }
    }

    private func widthRow(title: String, value: Binding<Int>) -> some View {
        SettingsSliderRow(title, value: value.asDouble, in: 420...1600, step: 10) { "\(Int($0)) px" }
    }

    private func alignmentPicker(title: String, selection: Binding<String>) -> some View {
        Picker(selection: selection) {
            Text("Left").tag("left")
            Text("Center").tag("center")
            Text("Right").tag("right")
        } label: {
            SettingsLabel(title)
        }
        .pickerStyle(.segmented)
    }
}
