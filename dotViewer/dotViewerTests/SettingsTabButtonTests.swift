import XCTest
import SwiftUI
import AppKit

/// Regression tests for the settings-header tab strip.
///
/// Guards issue #31 (Intel Mac / macOS 15.7.7): tabs in Markdown and Settings sub-pages could not
/// be clicked with the mouse. Keyboard navigation (Tab + Space) worked, which pointed at a
/// SwiftUI hit-testing failure — the horizontal `ScrollView`'s pan gesture recogniser was
/// swallowing the click before the `Button(.plain)` inside it ever saw a tap. The fix in
/// `SettingsTabPage.swift` pairs the button with a `.simultaneousGesture(TapGesture())` and moves
/// the hit shape to a plain `Rectangle` so the selection binding still updates even when pan
/// arbitration wins.
///
/// These tests exercise the observable side of that fix: hosting the row in an off-screen window,
/// walking to the AppKit buttons SwiftUI creates, and confirming a `performClick` on each button
/// updates the shared selection binding. We deliberately do NOT try to synthesise a full mouse
/// event through the gesture arbiter — that's flakier than it's worth in headless XCTest — but
/// the wiring these tests protect is the same wiring the production `.simultaneousGesture` hooks
/// into.
final class SettingsTabButtonTests: XCTestCase {

    // MARK: - Model surface

    func testSettingsTabIsHashableAndIdentifiable() {
        let a = SettingsTab(id: "one", label: "One", icon: "1.circle")
        let b = SettingsTab(id: "one", label: "One Long Label", icon: "1.square")
        let c = SettingsTab(id: "two", label: "Two", icon: "2.circle")

        // Identifiable + Hashable are keyed off `id` — matches how `ForEach` diffs the row.
        XCTAssertEqual(a.id, b.id)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(Set([a, b, c]).count, 2)
    }

    // MARK: - Selection binding

    func testClickingEachTabUpdatesSelectionBinding() throws {
        let tabs: [SettingsTab] = [
            .init(id: "one", label: "One", icon: "1.circle"),
            .init(id: "two", label: "Two", icon: "2.circle"),
            .init(id: "three", label: "Three", icon: "3.circle"),
        ]

        let harness = makeHostedTabBar(tabs: tabs, initialSelection: tabs[0].id)
        let buttons = collectButtons(in: harness.hostingView)

        // SwiftUI can add hidden helper buttons; require at least one per tab and click in order.
        try XCTSkipUnless(buttons.count >= tabs.count, "Expected at least one NSButton per tab; SwiftUI produced \(buttons.count)")

        for (index, tab) in tabs.enumerated() {
            harness.selection.value = "___placeholder___"
            buttons[index].performClick(nil)
            XCTAssertEqual(
                harness.selection.value,
                tab.id,
                "Clicking the button at index \(index) should select tab \(tab.id)"
            )
        }
    }

    func testTabButtonBindingHelperReflectsSelection() {
        // Belt-and-braces coverage for `SettingsTabButton` on its own — protects against the
        // wiring being lost during a future refactor of `SettingsTabBar`.
        let box = SelectionBox("other")
        let binding = Binding<String>(
            get: { box.value },
            set: { box.value = $0 }
        )
        let tab = SettingsTab(id: "markdownPreviewSection", label: "Preview", icon: "doc.richtext")
        let hosting = NSHostingView(rootView: SettingsTabButton(tab: tab, selection: binding))
        hosting.frame = NSRect(x: 0, y: 0, width: 200, height: 40)
        hosting.layoutSubtreeIfNeeded()

        collectButtons(in: hosting).first?.performClick(nil)
        XCTAssertEqual(box.value, "markdownPreviewSection")
    }

    // MARK: - Test harness

    private struct SelectionHarness {
        let hostingView: NSHostingView<SettingsTabBar>
        let selection: SelectionBox
        let window: NSWindow
    }

    private final class SelectionBox {
        var value: String
        init(_ value: String) { self.value = value }
    }

    private func makeHostedTabBar(tabs: [SettingsTab], initialSelection: String) -> SelectionHarness {
        let box = SelectionBox(initialSelection)
        let binding = Binding<String>(
            get: { box.value },
            set: { box.value = $0 }
        )
        let view = SettingsTabBar(tabs: tabs, selection: binding)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 800, height: 60)
        hosting.layoutSubtreeIfNeeded()

        // Attaching to a window ensures hit-testing walks the real responder chain.
        let window = NSWindow(
            contentRect: hosting.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hosting
        window.layoutIfNeeded()

        return SelectionHarness(hostingView: hosting, selection: box, window: window)
    }

    private func collectButtons(in view: NSView) -> [NSButton] {
        var out: [NSButton] = []
        var stack: [NSView] = view.subviews.reversed()
        // Depth-first, preserving on-screen order (left → right) so index matches tab order.
        while let next = stack.popLast() {
            if let button = next as? NSButton {
                out.append(button)
            }
            stack.append(contentsOf: next.subviews.reversed())
        }
        return out
    }
}
