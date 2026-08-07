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
        WindowGroup {
            ContentView()
                .appUIFontSizing(appUIFontSizePreset)
        }
    }
}

private let searchBridgeLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "App")
