import SwiftUI

/// Opens the Settings window, and shows the shortcut that does the same from anywhere in the app.
struct SettingsFooterLink: View {
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        SettingsLink {
            // In a narrow sidebar with large text the shortcut goes before "Settings" would wrap.
            ViewThatFits(in: .horizontal) {
                label(showingShortcut: true)
                label(showingShortcut: false)
            }
            // 10 + 10 puts the icon and title on the same leading edges as the sidebar rows above.
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open Settings (⌘,)")
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }

    private func label(showingShortcut: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "gearshape")
                .frame(width: 18 * textScale)
            Text("Settings")
                .lineLimit(1)
            Spacer(minLength: 8)
            if showingShortcut {
                Text("⌘,")
                    .appFont(.caption, design: .monospaced)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.quaternary))
            }
        }
    }
}
