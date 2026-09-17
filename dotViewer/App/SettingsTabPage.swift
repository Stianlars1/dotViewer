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
                    SettingsTabButton(tab: tab, selection: $selection)
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

/// A single tab in the settings header row.
///
/// Extracted from the `ForEach` inline closure so the click-path is explicit — and so the
/// belt-and-braces hit-testing workaround below has one home instead of being duplicated per
/// call site.
///
/// The workaround exists because of a real, reproducible SwiftUI bug on Intel Macs
/// (issue #31, seen on macMini8,1 / macOS 15.7.7): `Button(.plain)` nested inside a
/// `ScrollView(.horizontal)` sometimes never fires on mouse click. Keyboard navigation
/// (Tab + Space) works, which is the giveaway — the button's action is fine, the pan gesture
/// recognizer on the scroll view is eating the tap before the button ever sees it. The three
/// mitigations here are all cheap and all pull in different directions so the click reaches
/// the selection binding regardless of which recognizer wins:
///   1. `.contentShape(Rectangle())` on the outer button — makes the whole padded region
///      hittable, not just the rounded pill's visible fill.
///   2. `.contentShape(Rectangle())` on the label — belt for anyone who reads the label
///      before the button chrome.
///   3. `.simultaneousGesture(TapGesture())` — runs in parallel with the scroll view's pan,
///      so even if the Button's own tap recognizer loses arbitration the selection still
///      updates. Assigning the same value twice is a no-op, so the redundancy is harmless.
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
