import SwiftUI

/// Opens the Settings window, and shows the shortcut that does the same from anywhere in the app.
struct SettingsFooterLink: View {
    var body: some View {
        SettingsLink {
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .frame(width: 18)
                Text("Settings")
                Spacer(minLength: 8)
                Text("⌘,")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.quaternary))
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
}
