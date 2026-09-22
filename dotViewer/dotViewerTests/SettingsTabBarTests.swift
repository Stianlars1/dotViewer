import XCTest
import SwiftUI
import AppKit

/// Regression tests for the settings-header tab row (issue #31).
///
/// On macOS 15.7.7 (reported on a macMini8,1) mouse clicks on the Markdown and Settings sub-tabs
/// never selected them, while Tab + Space did. It does not reproduce on macOS 26, so these tests
/// cannot prove the original bug is gone — they pin down the two things the fix relies on:
/// a real mouse click reaches the selection in both layouts, and the scroll view is only
/// present when the row actually overflows.
@MainActor
final class SettingsTabBarTests: XCTestCase {

    private let tabs: [SettingsTab] = [
        .init(id: "appearance", label: "Appearance", icon: "paintpalette"),
        .init(id: "window", label: "Window", icon: "macwindow"),
        .init(id: "limits", label: "Limits", icon: "speedometer"),
    ]

    func testTabsFitWithoutScrollView() {
        let harness = makeHarness(width: 900)
        defer { harness.window.close() }

        XCTAssertTrue(scrollViews(in: harness.window.contentView).isEmpty,
                      "A row that fits must not sit inside a scroll view")
    }

    func testNarrowWindowFallsBackToScrollView() {
        let harness = makeHarness(width: 180)
        defer { harness.window.close() }

        XCTAssertFalse(scrollViews(in: harness.window.contentView).isEmpty,
                       "An overflowing row should scroll instead of wrapping or clipping")
    }

    func testMouseClicksSelectEveryTab() {
        let harness = makeHarness(width: 900)
        defer { harness.window.close() }

        XCTAssertEqual(clickAcrossRow(harness), tabs.map(\.id))
    }

    func testMouseClicksSelectVisibleTabsWhenScrolling() {
        let harness = makeHarness(width: 180)
        defer { harness.window.close() }

        let reached = clickAcrossRow(harness)
        XCTAssertEqual(Array(reached.prefix(2)), ["appearance", "window"],
                       "Tabs visible in the scrolling fallback must still take clicks")
    }

    // MARK: - Harness

    private final class SelectionBox {
        var value: String
        init(_ value: String) { self.value = value }
    }

    private struct Harness {
        let window: NSWindow
        let selection: SelectionBox
    }

    private func makeHarness(width: CGFloat) -> Harness {
        let selection = SelectionBox(tabs[0].id)
        let binding = Binding(get: { selection.value }, set: { selection.value = $0 })
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsTabBar(tabs: tabs, selection: binding))
        // SwiftUI only hit-tests a window that is ordered in; park it off every screen.
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
        window.orderFrontRegardless()
        window.contentView?.layoutSubtreeIfNeeded()
        window.display()
        pumpRunLoop()
        return Harness(window: window, selection: selection)
    }

    /// Clicks left to right along the row's vertical centre with synthesised mouse events and
    /// returns the tab ids in the order a click first selected them. Geometry-free on purpose:
    /// tab widths depend on the system font, and the selected tab turns semibold.
    private func clickAcrossRow(_ harness: Harness) -> [String] {
        guard let content = harness.window.contentView else { return [] }
        var reached: [String] = []
        var x: CGFloat = 1
        while x < content.bounds.width {
            harness.selection.value = ""
            click(at: NSPoint(x: x, y: content.bounds.midY), in: harness.window)
            let selected = harness.selection.value
            if !selected.isEmpty, !reached.contains(selected) {
                reached.append(selected)
            }
            x += 6
        }
        return reached
    }

    private func click(at point: NSPoint, in window: NSWindow) {
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            guard let event = NSEvent.mouseEvent(
                with: type,
                location: point,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: type == .leftMouseDown ? 1 : 0
            ) else { continue }
            window.sendEvent(event)
        }
        pumpRunLoop()
    }

    private func pumpRunLoop() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    }

    private func scrollViews(in view: NSView?) -> [NSScrollView] {
        guard let view else { return [] }
        let own = (view as? NSScrollView).map { [$0] } ?? []
        return own + view.subviews.flatMap { scrollViews(in: $0) }
    }
}
