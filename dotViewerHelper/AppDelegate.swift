import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Listen for open file requests from Quick Look extension via Distributed Notification
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleOpenFileRequest(_:)),
            name: NSNotification.Name("com.stianlars1.dotviewer.openFile"),
            object: nil
        )
    }

    @objc func handleOpenFileRequest(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let path = userInfo["path"] as? String else {
            return
        }

        let url = URL(fileURLWithPath: path)
        let bundleId = userInfo["bundleId"] as? String

        openFile(url: url, withBundleIdentifier: bundleId)
    }

    private func openFile(url: URL, withBundleIdentifier bundleId: String?) {
        if let bundleId = bundleId,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            // Open with preferred app
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true

            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: config) { _, error in
                if let error = error {
                    // Fallback to system default if preferred app fails
                    NSLog("[dotViewerHelper] Preferred app failed: \(error.localizedDescription), using default")
                    NSWorkspace.shared.open(url)
                }
            }
        } else {
            // Open with system default app
            NSWorkspace.shared.open(url)
        }
    }
}
