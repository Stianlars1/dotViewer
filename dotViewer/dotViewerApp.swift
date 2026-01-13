import SwiftUI
import ServiceManagement

@main
struct dotViewerApp: App {

    init() {
        registerHelperIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }

    /// Registers the dotViewerHelper as a login item so it can handle "Open in Editor"
    /// requests from the Quick Look extension (which is sandboxed and cannot open apps directly).
    private func registerHelperIfNeeded() {
        if #available(macOS 13.0, *) {
            let helperBundleId = "com.stianlars1.dotViewer.helper"
            let service = SMAppService.loginItem(identifier: helperBundleId)

            // Only register if not already enabled
            if service.status != .enabled {
                do {
                    try service.register()
                } catch {
                    // Registration may fail if user denied permission previously
                    // or if helper is not properly embedded. Log for debugging.
                    print("[dotViewerApp] Failed to register helper: \(error.localizedDescription)")
                }
            }
        }
        // For macOS 12 and earlier, SMAppService is not available.
        // The helper would need to use the older SMLoginItemSetEnabled API,
        // but since this app likely targets newer macOS versions, we skip that.
    }
}
