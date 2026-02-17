import SwiftUI
import Shared

@main
struct dotViewerApp: App {
    @AppStorage("appUIFontSizePreset", store: UserDefaults(suiteName: SharedSettings.appGroupId))
    private var appUIFontSizePreset: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appUIFontSizing(appUIFontSizePreset)
        }
    }
}
