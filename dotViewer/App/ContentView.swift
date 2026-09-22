import SwiftUI

private enum NavigationItem: String, CaseIterable, Identifiable {
    case status = "Status"
    case fileTypes = "File Types"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .status: return "checkmark.circle"
        case .fileTypes: return "doc.text"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: NavigationItem = .status

    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) { SettingsFooterLink() }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            switch selectedItem {
            case .status:
                StatusView()
            case .fileTypes:
                FileTypesView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

/// Opens the Settings window, and shows the shortcut that does the same from anywhere in the app.
private struct SettingsFooterLink: View {
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
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open Settings (⌘,)")
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
}

#Preview {
    ContentView()
}
