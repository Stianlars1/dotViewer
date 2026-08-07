import AppKit
import Shared
import SwiftUI

/// Controls for the ⌥Space preview panel.
///
/// The panel needs two separate grants and users conflate them, so each gets its own row with its
/// own state: **Accessibility** to see the ⌥Space keystroke at all (shared with ⌘F search), and
/// **Automation** to ask Finder which file is selected.
struct PreviewPanelSettings: View {
    @AppStorage("previewPanelEnabled", store: UserDefaults(suiteName: SharedSettings.appGroupId))
    private var previewPanelEnabled: Bool = true

    @State private var hasAccessibility = SearchKeyInterceptor.hasAccessibility()
    @State private var hasAutomation = FinderSelection.isAutomationGranted

    // Both permissions are granted outside the app, so there is nothing to observe.
    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    private var isReady: Bool { previewPanelEnabled && hasAccessibility && hasAutomation }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Preview with ⌥Space in Finder", isOn: $previewPanelEnabled)

            Text("Opens dotViewer's own preview window for the selected file. Space is left alone — Quick Look keeps handling every file it already handles. Use this for types macOS will not route to a Quick Look extension, such as .ts, which the system claims as a video format.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if previewPanelEnabled {
                Divider()

                permissionRow(
                    granted: hasAccessibility,
                    grantedText: "Accessibility access granted",
                    missingText: "Accessibility access needed — to receive ⌥Space",
                    explanation: "Lets dotViewer see the ⌥Space shortcut. Shared with ⌘F search; no other keys are read.",
                    action: hasAccessibility ? nil : ("Grant Access…", {
                        _ = SearchKeyInterceptor.hasAccessibility(prompt: true)
                    }),
                    settingsAnchor: "Privacy_Accessibility"
                )

                permissionRow(
                    granted: hasAutomation,
                    grantedText: "Finder access granted",
                    missingText: "Finder access needed — to see which file is selected",
                    explanation: "dotViewer asks Finder for the selected file's location. Nothing in Finder is changed.",
                    action: hasAutomation ? nil : ("Grant Access…", {
                        // Fires the system prompt. macOS remembers a denial, so this is only ever
                        // reached from an explicit button press.
                        if FinderSelection.automationPermission(prompting: true) == noErr {
                            hasAutomation = true
                        }
                    }),
                    settingsAnchor: "Privacy_Automation"
                )

                if isReady {
                    Label("⌥Space is ready to use", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
        }
        .onReceive(poll) { _ in
            let accessibility = SearchKeyInterceptor.hasAccessibility()
            if accessibility != hasAccessibility { hasAccessibility = accessibility }
            // The tap is what delivers ⌥Space; pick the permission up without a relaunch.
            if accessibility, !SearchKeyInterceptor.shared.isRunning {
                SearchKeyInterceptor.shared.start()
            }
            // Apple Event permission checks talk to the system daemon and can block. Off the main
            // thread, so a slow response cannot stutter the settings window.
            Task.detached {
                let automation = FinderSelection.isAutomationGranted
                await MainActor.run {
                    if automation != hasAutomation { hasAutomation = automation }
                }
            }
        }
    }

    @ViewBuilder
    private func permissionRow(
        granted: Bool,
        grantedText: String,
        missingText: String,
        explanation: String,
        action: (String, () -> Void)?,
        settingsAnchor: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(granted ? .green : .secondary)
                Text(granted ? grantedText : missingText)
            }

            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !granted {
                HStack {
                    if let action {
                        Button(action.0) { action.1() }
                    }
                    Button("Open Privacy Settings") {
                        guard let url = URL(
                            string: "x-apple.systempreferences:com.apple.preference.security?\(settingsAnchor)"
                        ) else { return }
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.link)
                }
            }
        }
    }
}
