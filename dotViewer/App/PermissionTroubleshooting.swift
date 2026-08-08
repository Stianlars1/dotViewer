import AppKit
import SwiftUI

/// Explains the one permission failure users cannot diagnose on their own.
///
/// macOS keys TCC grants to an app's **code signature**, not its path. When the signature changes —
/// replacing a locally built copy with a release download, or any re-signing — the existing grant
/// stops applying, but the old entry stays in the System Settings list *still showing as enabled*.
/// The result is a flat contradiction: `AXIsProcessTrustedWithOptions` reports not-trusted while
/// System Settings shows a ticked box.
///
/// Worse, the "Grant Access…" button cannot fix it. Once an entry exists for the app, asking to
/// prompt is a no-op — no dialog appears and nothing changes. The entry has to be removed and
/// re-added. There is no API to read TCC and detect this, so the remedy is shown whenever the
/// permission is missing rather than only when it is stale.
struct PermissionTroubleshooting: View {
    enum Kind {
        case accessibility
        case automation

        var paneName: String {
            switch self {
            case .accessibility: return "Accessibility"
            case .automation: return "Automation"
            }
        }

        var settingsAnchor: String {
            switch self {
            case .accessibility: return "Privacy_Accessibility"
            case .automation: return "Privacy_Automation"
            }
        }
    }

    let kind: Kind

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open \(kind.paneName) Settings") {
                    guard let url = URL(
                        string: "x-apple.systempreferences:com.apple.preference.security?\(kind.settingsAnchor)"
                    ) else { return }
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.link)
            }
            .padding(.top, 4)
        } label: {
            Text("Already granted, but still not working?")
                .font(.caption)
        }
    }

    private var explanation: String {
        switch kind {
        case .accessibility:
            return """
            macOS ties this permission to the app's code signature, not its location. If you \
            previously ran a development build of dotViewer, or replaced the app in place, System \
            Settings can still list dotViewer as enabled while macOS treats the new copy as a \
            different app. Turning the switch off and on again does not clear it.

            Fix it by removing the entry and adding it back: open Privacy & Security → \
            Accessibility, select dotViewer, click −, then click + and choose \
            /Applications/dotViewer.app. Quit and reopen dotViewer afterwards.
            """
        case .automation:
            return """
            macOS ties this permission to the app's code signature, not its location. If you \
            previously ran a development build of dotViewer, or replaced the app in place, the \
            existing Finder entry no longer applies to the new copy.

            Fix it by opening Privacy & Security → Automation, expanding dotViewer, and switching \
            Finder off and then on again. If dotViewer is not listed, press ⌥Space once in Finder \
            to make macOS ask. Quit and reopen dotViewer afterwards.
            """
        }
    }
}
