import SwiftUI

struct GeneralPane: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section("Preview") {
                Toggle(isOn: $model.showFileInfoHeader) {
                    SettingsLabel(
                        "File info header",
                        description: "Filename, language, line count and size above the preview."
                    )
                }
                .settingsAnchor(.fileInfoHeader)
            }

            Section("Unknown file types") {
                Toggle(isOn: $model.previewUnknownFiles) {
                    SettingsLabel(
                        "Preview unknown file types",
                        description: "Tries files that open in dotViewer even when their extension isn't in the built-in list."
                    )
                }
                .settingsAnchor(.previewUnknownFiles)

                Toggle(isOn: $model.forceTextForUnknown) {
                    SettingsLabel(
                        "Show unknown text as plain text",
                        description: "Readable files without a useful text type open as plain text."
                    )
                }
                .settingsAnchor(.forceTextForUnknown)
            }

            Section("Large files") {
                SettingsSliderRow(
                    "Maximum file size",
                    description: "Larger files are cut off in the preview.",
                    value: $model.maxFileSizeKB,
                    in: 10...500,
                    step: 10
                ) { "\(Int($0)) KB" }
                .settingsAnchor(.maxFileSize)

                Toggle(isOn: $model.showTruncationWarning) {
                    SettingsLabel("Truncation warning", description: "Shows a notice when a preview is cut off.")
                }
                .settingsAnchor(.truncationWarning)
            }
        }
        .settingsPaneStyle()
    }
}
