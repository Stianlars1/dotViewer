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
    @Environment(\.appTextScale) private var textScale

    /// Larger text widens the sidebar; smaller text leaves it as it is.
    private var sidebarScale: CGFloat { max(1, textScale) }

    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .appFontWhenScaled()
                    .tag(item)
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) { SettingsFooterLink() }
            .navigationSplitViewColumnWidth(min: 160 * sidebarScale, ideal: 180 * sidebarScale, max: 220 * sidebarScale)
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

#Preview {
    ContentView()
}
