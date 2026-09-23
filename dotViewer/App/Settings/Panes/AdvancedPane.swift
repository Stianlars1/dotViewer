import AppKit
import SwiftUI

struct AdvancedPane: View {
    @Environment(SettingsModel.self) private var model
    @State private var didClearCache = false

    var body: some View {
        @Bindable var model = model
        Form {
            SettingsSection("Preview cache") {
                Toggle(isOn: $model.previewCacheEnabled) {
                    SettingsLabel("Cache rendered previews", description: "Reuses a preview when you reopen the same file soon after.")
                }
                .settingsAnchor(.previewCache)

                SettingsSliderRow("Keep previews for", value: $model.cacheTTLSeconds.asDouble, in: 5...600, step: 5) {
                    "\(Int($0)) s"
                }
                .disabled(!model.previewCacheEnabled)
                .settingsAnchor(.cacheLifetime)

                SettingsSliderRow("Size limit", value: $model.cacheMaxMB.asDouble, in: 10...500, step: 10) {
                    "\(Int($0)) MB"
                }
                .disabled(!model.previewCacheEnabled)
                .settingsAnchor(.cacheSize)

                LabeledContent {
                    Button("Clear Cache") {
                        model.clearPreviewCache()
                        didClearCache = true
                    }
                } label: {
                    SettingsLabel(
                        "Cached previews",
                        description: didClearCache ? "Cleared. Previews render fresh next time." : nil
                    )
                }
                .settingsAnchor(.clearCache)
            }

            SettingsSection("Diagnostics") {
                Toggle(isOn: $model.performanceLogging) {
                    SettingsLabel("Performance logging", description: "Writes preview timings to the system log.")
                }
                .settingsAnchor(.performanceLogging)
            }

            SettingsSection("Uninstall") {
                LabeledContent {
                    Button("Uninstall…", role: .destructive) { Self.uninstall() }
                } label: {
                    SettingsLabel("Uninstall dotViewer", description: "Moves dotViewer to the Trash and quits.")
                }
                .settingsAnchor(.uninstall)
            }
        }
        .settingsPaneStyle()
    }

    private static func uninstall() {
        let alert = NSAlert()
        alert.messageText = "Uninstall dotViewer?"
        alert.informativeText = "This moves dotViewer to the Trash. You can restore it from the Trash if needed."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try FileManager.default.trashItem(at: Bundle.main.bundleURL, resultingItemURL: nil)
            NSApplication.shared.terminate(nil)
        } catch {
            let failure = NSAlert()
            failure.messageText = "Couldn't Uninstall"
            failure.informativeText = "dotViewer couldn't be moved to the Trash: \(error.localizedDescription)"
            failure.alertStyle = .critical
            failure.runModal()
        }
    }
}
