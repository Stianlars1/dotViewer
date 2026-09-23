import AppKit
import SwiftUI

/// ⌘F search and the ⌥Space panel, and the two permissions they depend on.
///
/// Both features need **Accessibility** to see their keystrokes (Quick Look never delivers keys to a
/// preview — see `SearchKeyInterceptor`), and ⌥Space also needs **Automation** to ask Finder which
/// file is selected. Users conflate the two, so each gets its own status row, in one place.
/// This pane is the only place the Accessibility prompt is raised.
struct ShortcutsPane: View {
    @Environment(SettingsModel.self) private var model

    @State private var hasAccessibility = SearchKeyInterceptor.hasAccessibility()
    @State private var isSearchActive = SearchKeyInterceptor.shared.isRunning
    @State private var hasAutomation = FinderSelection.isAutomationGranted

    // Both permissions are granted in System Settings, so there is no callback to observe.
    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        @Bindable var model = model
        Form {
            SettingsSection("Find in preview") {
                Toggle(isOn: $model.showSearchButton) {
                    SettingsLabel("Find button in preview", description: "Adds a search button to the preview header.")
                }
                .settingsAnchor(.findButton)

                // ⌘F is gated on the find button: with no search bar on screen it would swallow keys.
                if model.showSearchButton {
                    SettingsStatusRow(
                        isOK: isSearchActive,
                        title: isSearchActive ? "⌘F search is on" : "⌘F search is off",
                        description: isSearchActive
                            ? "Press ⌘F in a Quick Look preview to search it."
                            : "Needs Accessibility access — see Permissions."
                    ) { EmptyView() }
                    .settingsAnchor(.findShortcut)
                }
            }

            SettingsSection("⌥Space preview") {
                Toggle(isOn: $model.previewPanelEnabled) {
                    SettingsLabel(
                        "Preview with ⌥Space",
                        description: "Opens dotViewer's own preview of the file selected in Finder, for types macOS won't send to Quick Look, such as .ts."
                    )
                }
                .settingsAnchor(.spacePanel)

                if model.previewPanelEnabled {
                    let isReady = hasAccessibility && hasAutomation
                    SettingsStatusRow(
                        isOK: isReady,
                        title: isReady ? "⌥Space is ready" : "⌥Space needs permissions",
                        description: isReady ? nil : "Grant the permissions below."
                    ) { EmptyView() }
                }
            }

            Section {
                SettingsStatusRow(
                    isOK: hasAccessibility,
                    title: "Accessibility",
                    description: "Lets dotViewer see ⌘F and ⌥Space."
                ) {
                    if !hasAccessibility {
                        Button("Grant Access…") {
                            // Raises the system prompt; the user still confirms in System Settings.
                            _ = SearchKeyInterceptor.hasAccessibility(prompt: true)
                        }
                        .controlSize(.small)
                        openSettingsButton(anchor: "Privacy_Accessibility")
                    }
                }
                .settingsAnchor(.accessibilityPermission)

                // Shown whenever the permission is missing: the confusing case is the one where System
                // Settings already shows dotViewer as enabled. See PermissionTroubleshooting.
                if !hasAccessibility {
                    PermissionTroubleshooting(kind: .accessibility)
                }

                SettingsStatusRow(
                    isOK: hasAutomation,
                    title: "Finder",
                    description: "Tells dotViewer which file is selected for ⌥Space. Nothing in Finder changes."
                ) {
                    if !hasAutomation {
                        Button("Grant Access…") {
                            // Fires the system prompt. macOS remembers a denial, so this is only
                            // ever reached from an explicit button press.
                            if FinderSelection.automationPermission(prompting: true) == noErr {
                                hasAutomation = true
                            }
                        }
                        .controlSize(.small)
                        openSettingsButton(anchor: "Privacy_Automation")
                    }
                }
                .settingsAnchor(.finderPermission)

                if !hasAutomation {
                    PermissionTroubleshooting(kind: .automation)
                }
            } header: {
                Text("Permissions")
                    .appFontWhenScaled(.headline)
            } footer: {
                Text("Keystrokes are read only after ⌘F or ⌥Space, never stored, and never leave this Mac.")
                    .appFontWhenScaled(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .settingsPaneStyle()
        .onReceive(poll) { _ in refreshPermissions() }
    }

    private func openSettingsButton(anchor: String) -> some View {
        Button("Open Settings") {
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
                return
            }
            NSWorkspace.shared.open(url)
        }
        .buttonStyle(.link)
    }

    private func refreshPermissions() {
        let trusted = SearchKeyInterceptor.hasAccessibility()
        if trusted != hasAccessibility { hasAccessibility = trusted }
        // Permission can be granted while the app is running — start the tap without a relaunch.
        if trusted, !SearchKeyInterceptor.shared.isRunning {
            SearchKeyInterceptor.shared.start()
        }
        let running = SearchKeyInterceptor.shared.isRunning
        if running != isSearchActive { isSearchActive = running }

        // Apple Event permission checks talk to a system daemon and can block, so they run off the
        // main thread and cannot stutter the window.
        Task.detached {
            let automation = FinderSelection.isAutomationGranted
            await MainActor.run {
                if automation != hasAutomation { hasAutomation = automation }
            }
        }
    }
}
