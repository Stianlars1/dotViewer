import AppKit
import Foundation
import os.log

private let selectionLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "FinderSelection")

/// Reads what is selected in Finder, so ⌥Space knows which file to preview.
///
/// AppleScript rather than the Accessibility API: AX gives us the *displayed* row titles, which are
/// localised, truncated and stripped of extensions depending on the user's Finder settings — none of
/// which reconstructs a file path. Finder's scripting dictionary hands back real aliases.
///
/// This needs Automation permission, which is a separate TCC grant from the Accessibility permission
/// the event tap already requires. `automationPermission(prompting:)` probes it without asking.
enum FinderSelection {
    enum Failure: Error, Equatable {
        /// Automation access to Finder was denied or never granted.
        case notPermitted
        case finderNotRunning
        case noSelection
        /// Selected, but not a file we can read from disk (a search result, a network item).
        case notAFile
        case scriptFailed(String)
    }

    private static let finderBundleId = "com.apple.finder"

    /// The frontmost Finder window's first selected item.
    ///
    /// Must be called on the main thread — `NSAppleScript` is not thread-safe.
    @MainActor
    static func frontmostSelectedFile() -> Result<URL, Failure> {
        guard isFinderRunning else { return .failure(.finderNotRunning) }

        // `as alias` fails on items with no on-disk location (Recents entries, some search hits),
        // which is why the POSIX path is taken inside the tell block rather than resolved after.
        let source = """
        tell application "Finder"
            set theSelection to selection
            if (count of theSelection) is 0 then return ""
            return POSIX path of (item 1 of theSelection as alias)
        end tell
        """

        guard let script = NSAppleScript(source: source) else {
            return .failure(.scriptFailed("could not compile"))
        }

        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let code = (errorInfo[NSAppleScript.errorNumber] as? Int) ?? 0
            let message = (errorInfo[NSAppleScript.errorMessage] as? String) ?? "unknown"
            // -1743 is errAEEventNotPermitted: the user has not granted Automation for Finder.
            if code == -1743 || code == -600 {
                selectionLogger.info("Finder selection unavailable: not permitted")
                return .failure(.notPermitted)
            }
            selectionLogger.error("Finder selection script failed (\(code, privacy: .public)): \(message, privacy: .public)")
            return .failure(.scriptFailed(message))
        }

        guard let path = result.stringValue, !path.isEmpty else {
            return .failure(.noSelection)
        }

        let url = URL(fileURLWithPath: path)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue
        else {
            return .failure(.notAFile)
        }

        return .success(url)
    }

    static var isFinderRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: finderBundleId).isEmpty
    }

    static var isFinderFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == finderBundleId
    }

    /// Whether this process may drive Finder.
    ///
    /// - Parameter prompting: pass `true` only in response to the user asking for the feature. With
    ///   `false` this is a silent probe, which is what a settings status row wants — the system
    ///   remembers a denial, so a stray prompt burns the one chance to ask.
    static func automationPermission(prompting: Bool) -> OSStatus {
        let target = NSAppleEventDescriptor(bundleIdentifier: finderBundleId)
        guard let descriptor = target.aeDesc else { return OSStatus(procNotFound) }
        return AEDeterminePermissionToAutomateTarget(
            descriptor,
            typeWildCard,
            typeWildCard,
            prompting
        )
    }

    static var isAutomationGranted: Bool {
        automationPermission(prompting: false) == noErr
    }
}
