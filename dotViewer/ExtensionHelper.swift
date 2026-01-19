import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "ExtensionHelper")

/// Helper for extension-related actions (sandbox-compatible)
@MainActor
final class ExtensionHelper: ObservableObject {
    static let shared = ExtensionHelper()

    private init() {}

    /// Opens System Settings to the Extensions pane
    func openExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
            logger.info("Opened extension settings")
        }
    }
}
