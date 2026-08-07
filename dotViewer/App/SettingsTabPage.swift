import SwiftUI

struct SettingsTab: Identifiable, Hashable {
    let id: String
    let label: String
    let icon: String
}

/// Always-visible row of tabs across the top of a settings screen.
///
/// Deliberately not `TabView`: on macOS a `TabView` inside the detail pane collapses its tabs into
/// a single popup button, so choosing a section meant opening a menu first. The point of splitting
/// these pages up was to make every section reachable at a glance.
struct SettingsTabBar: View {
    let tabs: [SettingsTab]
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tabs) { tab in
                    Button {
                        selection = tab.id
                    } label: {
                        Label(tab.label, systemImage: tab.icon)
                            .font(.system(size: 12, weight: selection == tab.id ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selection == tab.id ? Color.accentColor.opacity(0.18) : .clear)
                            )
                            .foregroundStyle(selection == tab.id ? Color.accentColor : .secondary)
                            .contentShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == tab.id ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        // Horizontal scrolling is the overflow behaviour for narrow windows; the row never wraps
        // or collapses, so the tabs stay where the user last saw them.
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// Chrome for the content area below the tab bar: scrolls independently, stays top-aligned.
    func settingsTabPage() -> some View {
        ScrollView {
            self
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
