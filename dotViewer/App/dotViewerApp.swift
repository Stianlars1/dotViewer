import SwiftUI
import Shared

@main
struct dotViewerApp: App {
    @StateObject private var copyHelperManager = CopyHelperManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(copyHelperManager)
                .onAppear {
                    if SharedSettings.shared.copyHelperEnabled {
                        copyHelperManager.launch()
                    }
                }
        }
    }
}
