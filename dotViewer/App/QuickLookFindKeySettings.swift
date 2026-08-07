import AppKit
import Shared
import SwiftUI

/// Controls for the ⌘F-in-Quick-Look feature.
///
/// This is the only place the Accessibility prompt is raised — asking at launch would be an
/// unexplained permission request, and the permission is meaningless until the user wants the
/// feature. See `SearchKeyInterceptor` for why Accessibility is required at all.
struct QuickLookFindKeySettings: View {
    @State private var isTrusted = SearchKeyInterceptor.hasAccessibility()
    @State private var isRunning = SearchKeyInterceptor.shared.isRunning

    // The system grants Accessibility outside the app, so there is no callback to observe.
    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: isRunning ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(isRunning ? .green : .secondary)
                Text(isRunning ? "⌘F search is active" : "⌘F search needs Accessibility access")
            }

            Text("Quick Look does not deliver keyboard input to previews — pressing a key hands it to Finder, which jumps to another file. Accessibility access lets dotViewer capture ⌘F and what you type and send it to the open preview. Keystrokes are only read after you press ⌘F, are never stored or sent anywhere, and go only to the preview on this Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                if !isTrusted {
                    Button("Grant Access…") {
                        // Raises the system prompt; the user still confirms in System Settings.
                        _ = SearchKeyInterceptor.hasAccessibility(prompt: true)
                    }
                }
                Button("Open Privacy Settings") {
                    guard let url = URL(
                        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                    ) else { return }
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.link)
            }
        }
        .onReceive(poll) { _ in
            let trusted = SearchKeyInterceptor.hasAccessibility()
            if trusted != isTrusted { isTrusted = trusted }
            // Permission can be granted while the app is running — pick it up without a relaunch.
            if trusted, !SearchKeyInterceptor.shared.isRunning {
                SearchKeyInterceptor.shared.start()
            }
            let running = SearchKeyInterceptor.shared.isRunning
            if running != isRunning { isRunning = running }
        }
    }
}
