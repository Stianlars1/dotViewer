import SwiftUI

struct CopyPane: View {
    @Environment(SettingsModel.self) private var model

    /// The eight copy presets (KI-009). Quick Look previews never receive a user gesture, so the
    /// preview cannot copy on ⌘C by itself — these are the alternatives.
    private static let presets: [(id: String, title: String, detail: String)] = [
        ("autoCopy", "Auto-copy", "Copies text to the clipboard when you release the mouse after selecting."),
        ("floatingButton", "Floating copy button", "A small Copy button appears next to your selection."),
        ("toastAction", "Toast with copy button", "A notice with a Copy button appears to confirm."),
        ("tapToCopy", "Tap to confirm", "Select text, then click anywhere to copy it."),
        ("holdToCopy", "Hold to copy", "Copies only when you hold the mouse for half a second while selecting."),
        ("shakeToCopy", "Shake to copy", "Select text, then shake the pointer left and right to copy it."),
        ("autoCopyUndo", "Auto-copy with undo", "Copies on selection and offers Undo for three seconds."),
        ("off", "Off", "Nothing is copied automatically. Use the header's copy button or right-click."),
    ]

    var body: some View {
        @Bindable var model = model
        Form {
            SettingsSection("Selecting text") {
                Picker(selection: $model.copyBehavior) {
                    ForEach(Self.presets, id: \.id) { preset in
                        Text(preset.title).tag(preset.id)
                    }
                } label: {
                    SettingsLabel("When you select text", description: presetDetail)
                }
                .settingsAnchor(.copyBehavior)
            }

            SettingsSection("Copied text") {
                Toggle(isOn: $model.includeLineNumbersInCopy) {
                    SettingsLabel(
                        "Include line numbers",
                        description: "Selections and the header's copy button include line numbers."
                    )
                }
                .settingsAnchor(.copyLineNumbers)
            }
        }
        .settingsPaneStyle()
    }

    private var presetDetail: String {
        Self.presets.first { $0.id == model.copyBehavior }?.detail ?? ""
    }
}
