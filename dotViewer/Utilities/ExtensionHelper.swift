import SwiftUI
import os.log

private let extensionLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "ExtensionHelper")

@MainActor
final class ExtensionHelper: ObservableObject {
    static let shared = ExtensionHelper()

    private init() {}

    func openExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?Quick%20Look") {
            NSWorkspace.shared.open(url)
            extensionLogger.info("Opened extension settings")
        }
    }
}
