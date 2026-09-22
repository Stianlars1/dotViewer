import Foundation

/// The panes of the Settings window, in sidebar order.
enum SettingsPane: String, CaseIterable, Identifiable, Hashable {
    case general, appearance, markdown, window, copy, shortcuts, advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .markdown: "Markdown"
        case .window: "Window"
        case .copy: "Copy"
        case .shortcuts: "Shortcuts"
        case .advanced: "Advanced"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .markdown: "doc.richtext"
        case .window: "macwindow"
        case .copy: "doc.on.doc"
        case .shortcuts: "keyboard"
        case .advanced: "wrench.and.screwdriver"
        }
    }

    /// Sidebar groups, separated by space like System Settings: how previews look, how you interact
    /// with them, then maintenance. Future Updates and Privacy panes join the last group.
    static let groups: [[SettingsPane]] = [
        [.general, .appearance, .markdown, .window],
        [.copy, .shortcuts],
        [.advanced],
    ]
}
