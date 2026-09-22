import XCTest
import SwiftUI
import AppKit

/// Real mouse clicks must reach the Settings sidebar.
///
/// The Settings window replaced the custom tab bar in which clicks were lost on macOS 15 on an
/// Intel Mac (issue #31). These tests keep the method that caught that class of bug: host the view
/// in an ordered-in window and deliver synthesised mouse-down/up events, rather than calling the
/// selection binding directly.
@MainActor
final class SettingsSidebarTests: XCTestCase {

    func testMouseClicksSelectEveryPaneInOrder() {
        let harness = makeHarness(query: "")
        defer { harness.window.close() }

        XCTAssertEqual(clickDownSidebar(harness), SettingsPane.allCases)
    }

    func testClickingASearchResultOpensThatSetting() {
        let harness = makeHarness(query: "wrap long")
        defer { harness.window.close() }

        _ = clickDownSidebar(harness)
        XCTAssertEqual(harness.state.opened.first?.id, .wordWrap)
        XCTAssertEqual(harness.state.opened.first?.pane, .appearance)
    }

    // MARK: - Harness

    private final class State {
        var selection: SettingsPane?
        var opened: [SettingsEntry] = []
    }

    private struct Harness {
        let window: NSWindow
        let state: State
    }

    private func makeHarness(query: String) -> Harness {
        let state = State()
        let binding = Binding(get: { state.selection }, set: { state.selection = $0 })
        let sidebar = SettingsSidebar(selection: binding, query: query) { state.opened.append($0) }
            .frame(width: 220, height: 420)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 420),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: sidebar)
        // SwiftUI only hit-tests a window that is ordered in; park it off every screen.
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
        window.orderFrontRegardless()
        window.contentView?.layoutSubtreeIfNeeded()
        window.display()
        pumpRunLoop()
        return Harness(window: window, state: state)
    }

    /// Clicks top to bottom down the sidebar's horizontal centre and returns the panes in the order
    /// a click first selected them. Geometry-free: row heights depend on the system font.
    private func clickDownSidebar(_ harness: Harness) -> [SettingsPane] {
        guard let content = harness.window.contentView else { return [] }
        var reached: [SettingsPane] = []
        var y = content.bounds.height - 2
        while y > 0 {
            harness.state.selection = nil
            click(at: NSPoint(x: content.bounds.midX, y: y), in: harness.window)
            if let pane = harness.state.selection, !reached.contains(pane) {
                reached.append(pane)
            }
            y -= 5
        }
        return reached
    }

    /// A sidebar row is an `NSTableView` row, and `NSTableView.mouseDown(with:)` runs its own
    /// tracking loop that pulls the matching mouse-up from the event queue. So the up is posted to
    /// the queue first and the down delivered after; delivering them one after another would leave
    /// the tracking loop waiting forever. If nothing consumed the up, it is delivered by hand.
    private func click(at point: NSPoint, in window: NSWindow) {
        guard let down = mouseEvent(.leftMouseDown, at: point, in: window),
              let up = mouseEvent(.leftMouseUp, at: point, in: window) else { return }
        NSApp.postEvent(up, atStart: false)
        window.sendEvent(down)
        if let pending = NSApp.nextEvent(matching: .leftMouseUp, until: Date(), inMode: .default, dequeue: true) {
            window.sendEvent(pending)
        }
        pumpRunLoop()
    }

    private func mouseEvent(_ type: NSEvent.EventType, at point: NSPoint, in window: NSWindow) -> NSEvent? {
        NSEvent.mouseEvent(
            with: type,
            location: point,
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: type == .leftMouseDown ? 1 : 0
        )
    }

    private func pumpRunLoop() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    }
}
