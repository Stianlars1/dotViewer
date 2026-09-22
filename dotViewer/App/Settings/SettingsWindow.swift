import SwiftUI

/// The Settings window (⌘,): panes in a sidebar, the selected pane on the right, search on top.
///
/// The sidebar is a native `List` — the same control as the main window's sidebar — rather than
/// the custom tab row it replaces, whose clicks were lost on macOS 15 on an Intel Mac (#31).
struct SettingsWindow: View {
    @AppStorage("settingsSelectedPane") private var storedPane = SettingsPane.general.rawValue
    @State private var selection: SettingsPane?
    @State private var query = ""
    @State private var highlighted: SettingID?
    @State private var model = SettingsModel()

    var body: some View {
        NavigationSplitView {
            // Order matters: a column width set before `.toolbar(removing:)` is dropped, and the
            // sidebar falls back to 140 pt (SettingsWindowLayoutTests).
            SettingsSidebar(selection: $selection, query: query, onOpen: open)
                .toolbar(removing: .sidebarToggle)
                .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        } detail: {
            let pane = selection ?? .general
            SettingsPaneView(pane: pane)
                .environment(model)
                .environment(\.highlightedSetting, highlighted)
                .navigationTitle(pane.title)
        }
        .searchable(text: $query, placement: .sidebar, prompt: "Search")
        .frame(minWidth: 720, minHeight: 500)
        .onAppear {
            if selection == nil { selection = SettingsPane(rawValue: storedPane) ?? .general }
        }
        .onChange(of: selection) { _, pane in
            if let pane { storedPane = pane.rawValue }
        }
    }

    /// Shows a search result: switches to its pane, then highlights its row for a moment.
    private func open(_ entry: SettingsEntry) {
        selection = entry.pane
        highlighted = entry.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            if highlighted == entry.id { highlighted = nil }
        }
    }
}

/// The pane list, or — while searching — the matching settings.
struct SettingsSidebar: View {
    @Binding var selection: SettingsPane?
    let query: String
    let onOpen: (SettingsEntry) -> Void

    @State private var chosenResult: SettingID?

    var body: some View {
        let results = SettingsCatalog.search(query)
        Group {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                List(selection: $selection) {
                    ForEach(SettingsPane.groups.indices, id: \.self) { index in
                        Section {
                            ForEach(SettingsPane.groups[index]) { pane in
                                Label(pane.title, systemImage: pane.systemImage)
                                    .tag(pane)
                            }
                        }
                    }
                }
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(results, selection: $chosenResult) { entry in
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.title)
                            Text(entry.pane.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: entry.pane.systemImage)
                    }
                    .tag(entry.id)
                }
            }
        }
        .onChange(of: chosenResult) { _, id in
            if let id { onOpen(SettingsCatalog.entry(id)) }
        }
        // A new query starts a new choice, so picking the same setting again still opens it.
        .onChange(of: query) { chosenResult = nil }
    }
}

/// The selected pane. Scrolls to and highlights a setting chosen from search.
struct SettingsPaneView: View {
    let pane: SettingsPane
    @Environment(\.highlightedSetting) private var highlighted

    var body: some View {
        ScrollViewReader { proxy in
            paneContent
                .task(id: highlighted) {
                    guard let highlighted else { return }
                    // Let the newly selected pane lay out before scrolling to one of its rows.
                    try? await Task.sleep(for: .milliseconds(60))
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(highlighted, anchor: .center)
                    }
                }
        }
    }

    @ViewBuilder
    private var paneContent: some View {
        switch pane {
        case .general: GeneralPane()
        case .appearance: AppearancePane()
        case .markdown: MarkdownPane()
        case .window: WindowPane()
        case .copy: CopyPane()
        case .shortcuts: ShortcutsPane()
        case .advanced: AdvancedPane()
        }
    }
}
