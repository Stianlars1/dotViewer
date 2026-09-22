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
        // The scroll view is only the overflow fallback for windows too narrow for the row.
        // Issue #31: on macOS 15 (reported on an Intel Mac mini) mouse clicks on these tabs never
        // arrived while they sat inside the horizontal ScrollView, yet Tab + Space still worked.
        // Whenever the row fits — the usual case — it is laid out plainly, with no scroll view in
        // the click path at all. `ViewThatFits` falls back to its last child when nothing fits.
        ViewThatFits(in: .horizontal) {
            tabRow
            ScrollView(.horizontal, showsIndicators: false) {
                tabRow
            }
        }
        // The row never wraps or collapses, so the tabs stay where the user last saw them.
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tabRow: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                SettingsTabButton(tab: tab, selection: $selection)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

/// A single tab in the settings header row.
///
/// Issue #31 (macMini8,1, macOS 15.7.7): mouse clicks on these tabs never selected them, while
/// Tab + Space did — so the action was fine and the click was lost before reaching it. We could
/// not reproduce it on macOS 26, so the root cause is unconfirmed; these are cheap, defensive
/// mitigations layered on top of keeping the row out of the scroll view (see `SettingsTabBar`):
///   1. `.contentShape(Rectangle())` — the whole padded region is hittable, not just the pill.
///   2. `.simultaneousGesture(TapGesture())` — a second, independent route from a click to the
///      selection, in case the button's own tap loses gesture arbitration. Assigning the same
///      value twice is a no-op, so the redundancy is harmless.
struct SettingsTabButton: View {
    let tab: SettingsTab
    @Binding var selection: String

    private var isSelected: Bool { selection == tab.id }

    var body: some View {
        Button {
            selection = tab.id
        } label: {
            Label(tab.label, systemImage: tab.icon)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor.opacity(0.18) : .clear)
                )
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            selection = tab.id
        })
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
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
