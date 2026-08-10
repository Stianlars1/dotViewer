import AppKit
import Shared
import SwiftUI

/// Explains the one permission failure users cannot diagnose on their own.
///
/// macOS keys TCC grants to an app's **code signature**, not its path or name. Two differently
/// signed copies of dotViewer — a development build and a Developer ID release, say — are separate
/// subjects to TCC despite sharing a bundle identifier, and System Settings lists them under one
/// name. The result is a flat contradiction: `AXIsProcessTrustedWithOptions` reports not-trusted
/// while System Settings shows a ticked box, because the ticked record belongs to the other copy.
///
/// Observed directly on macOS 26.4: with the row switched on, the Developer ID build still logged
/// "Accessibility not granted" across a full relaunch, and requesting the prompt raised the dialog
/// again — macOS did not consider it authorised at all.
///
/// Toggling that row, or removing and re-adding it, can rebind the wrong copy, which is why the
/// remedy offered here is `tccutil reset` for the whole bundle identifier followed by a single
/// fresh grant. The "Grant Access…" button alone cannot resolve it.
///
/// There is no API to read TCC, but the app can remember its own history: `accessibilityGrantSeen`
/// records that the tap really did start once. If it did and the permission is now missing, the
/// grant was invalidated rather than never given — a diagnosis, not a guess — so the view leads
/// with that and opens itself. Otherwise it stays a quiet disclosure, since the ordinary case is
/// simply that the user has not granted the permission yet.
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

        /// The TCC service name differs from the pane name for Automation — the pane says
        /// "Automation", tccutil wants "AppleEvents".
        var resetCommand: String {
            switch self {
            case .accessibility: return "tccutil reset Accessibility com.stianlars1.dotViewer"
            case .automation: return "tccutil reset AppleEvents com.stianlars1.dotViewer"
            }
        }
    }

    let kind: Kind

    @State private var isExpanded: Bool

    /// True when the tap has run before, so the permission was really held and has since been
    /// invalidated. That is a diagnosis rather than a guess, so it leads instead of hiding behind a
    /// disclosure the user has no reason to open.
    private let isKnownStale: Bool

    @State private var didCopy = false
    @State private var copyResetTask: Task<Void, Never>?

    init(kind: Kind) {
        self.kind = kind
        let stale = SharedSettings.shared.accessibilityGrantSeen
        self.isKnownStale = stale
        _isExpanded = State(initialValue: stale)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button("Open \(kind.paneName) Settings") {
                        guard let url = URL(
                            string: "x-apple.systempreferences:com.apple.preference.security?\(kind.settingsAnchor)"
                        ) else { return }
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.link)

                    // Retyping a tccutil invocation by hand is an easy thing to get subtly wrong,
                    // and getting it wrong resets the wrong service.
                    Button(didCopy ? "Copied" : "Copy reset command") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(kind.resetCommand, forType: .string)
                        withAnimation(.easeOut(duration: 0.15)) { didCopy = true }

                        // Reverts so the button stops claiming a copy that happened a while ago.
                        // Cancelling first means a second click restarts the window rather than
                        // being cut short by the previous press's timer.
                        copyResetTask?.cancel()
                        copyResetTask = Task {
                            try? await Task.sleep(for: .seconds(2))
                            guard !Task.isCancelled else { return }
                            withAnimation(.easeOut(duration: 0.15)) { didCopy = false }
                        }
                    }
                    .buttonStyle(.link)
                    .foregroundStyle(didCopy ? Color.green : Color.accentColor)
                }
            }
            .padding(.top, 4)
        } label: {
            if isKnownStale {
                Label(
                    "This permission was working before — macOS invalidated it",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            } else {
                Text("Already granted, but still not working?")
                    .font(.caption)
            }
        }
    }

    private var explanation: String {
        switch kind {
        case .accessibility:
            return """
            macOS ties this permission to the app's code signature, not its name or location. Two \
            differently signed copies — a development build and a release download, say — are \
            separate permissions to macOS, but System Settings lists them under the same name. So \
            the switch next to "dotViewer" can be on while belonging to the other copy, and \
            toggling it, or removing and re-adding it, can rebind the wrong one.

            The reliable fix is to clear every Accessibility record for dotViewer and grant it \
            once, fresh. Run this in Terminal, then reopen dotViewer and press Grant Access:

            tccutil reset Accessibility com.stianlars1.dotViewer
            """
        case .automation:
            return """
            macOS ties this permission to the app's code signature, not its name or location. If \
            you previously ran a development build of dotViewer, the Finder entry you can see may \
            belong to that copy rather than this one.

            Try Privacy & Security → Automation first: expand dotViewer and switch Finder off and \
            on again. If dotViewer is not listed at all, press ⌥Space once in Finder to make macOS \
            ask. If neither works, clear the records and grant once, fresh:

            tccutil reset AppleEvents com.stianlars1.dotViewer
            """
        }
    }
}
