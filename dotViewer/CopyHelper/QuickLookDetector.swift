import AppKit
import CoreGraphics

enum QuickLookDetector {
    /// Known bundle identifiers for Quick Look processes
    private static let quickLookBundleIDs: Set<String> = [
        "com.apple.quicklook.QuickLookUIService",
        "com.apple.QuickLookUIService",
        "com.apple.quicklook.ui",
    ]

    /// Check whether a Quick Look preview window is currently visible.
    static func isQuickLookVisible() -> Bool {
        let frontApp = NSWorkspace.shared.frontmostApplication

        // Case 1: Quick Look service itself is frontmost
        if let bundleID = frontApp?.bundleIdentifier,
           quickLookBundleIDs.contains(bundleID) {
            return true
        }

        // Case 2: Finder is frontmost — check for a QuickLookUIService window
        if frontApp?.bundleIdentifier == "com.apple.finder" {
            return hasQuickLookWindow()
        }

        return false
    }

    /// Use CGWindowListCopyWindowInfo to detect a visible Quick Look overlay window.
    private static func hasQuickLookWindow() -> Bool {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }

        for info in windowList {
            guard let ownerName = info[kCGWindowOwnerName as String] as? String else { continue }

            if ownerName.contains("QuickLookUIService") || ownerName.contains("Quick Look") {
                let layer = info[kCGWindowLayer as String] as? Int ?? -1
                if layer == 0 {
                    return true
                }
            }
        }
        return false
    }
}
