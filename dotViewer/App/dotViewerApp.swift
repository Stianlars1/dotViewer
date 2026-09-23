import SwiftUI
import os.log
import Shared

@main
struct dotViewerApp: App {
    @AppStorage("appUIFontSizePreset", store: UserDefaults(suiteName: SharedSettings.appGroupId))
    private var appUIFontSizePreset: String = "system"

    init() {
        // The code font picker used to allow proportional faces; clear any that got stored.
        PreviewFontMenu.migrateInvalidCodeFontIfNeeded()
        StaleWindowFrames.remove()

        // Quick Look previews cannot receive keyboard input, so search queries are pushed to them
        // over a loopback connection instead. The preview only subscribes if this is running.
        do {
            try SearchBridgeServer.shared.start()
        } catch {
            searchBridgeLogger.error(
                "Could not start search bridge: \(error.localizedDescription, privacy: .public)")
        }

        // Deliberately does not prompt. If Accessibility was granted previously the tap comes up
        // silently; otherwise the feature stays off until the user enables it in Settings, which is
        // where the prompt belongs.
        SearchKeyInterceptor.shared.start()
    }

    var body: some Scene {
        // Named, so the window's saved frame survives updates: an unnamed WindowGroup's autosave
        // key includes its content's type name, which for a private modifier holds a per-build address.
        WindowGroup(id: "main") {
            ContentView()
                .appUIFontSizing(appUIFontSizePreset)
        }

        // A Settings scene is what gives the app menu its "Settings…" item and ⌘,. It ignores the
        // content's ideal size (it opened at 900 × 532), so the first size is set here.
        Settings {
            SettingsWindow()
                .appUIFontSizing(appUIFontSizePreset)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 780, height: 620)
    }
}

private let searchBridgeLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "App")
