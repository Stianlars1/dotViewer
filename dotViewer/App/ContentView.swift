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

#Preview {
    ContentView()
}
