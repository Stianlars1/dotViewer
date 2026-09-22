import XCTest
import SwiftUI
import AppKit

/// The Settings sidebar must get the width it asks for, with no sidebar toggle.
///
/// `.toolbar(removing: .sidebarToggle)` placed after `.navigationSplitViewColumnWidth` silently
/// drops the column width: the sidebar came up at 140 pt instead of 190–260, cutting off search
/// results. Found by hand in the installed 1.5.8 build; this pins the working order.
@MainActor
final class SettingsWindowLayoutTests: XCTestCase {
    func testSidebarGetsItsColumnWidthWithoutAToggle() throws {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 620),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: SettingsWindow())
        window.setContentSize(NSSize(width: 780, height: 620))
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
        window.orderFrontRegardless()
        defer { window.close() }
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))

        let split = try XCTUnwrap(firstSplitView(in: window.contentView), "No split view in the Settings window")
        let sidebarWidth = try XCTUnwrap(split.arrangedSubviews.first).frame.width
        XCTAssertGreaterThanOrEqual(sidebarWidth, 190, "Sidebar is \(sidebarWidth) pt; the column width was dropped")

        let toolbarIDs = window.toolbar?.items.map(\.itemIdentifier.rawValue) ?? []
        XCTAssertFalse(
            toolbarIDs.contains { $0.localizedCaseInsensitiveContains("sidebar") },
            "Settings should have no sidebar toggle: \(toolbarIDs)"
        )
    }

    private func firstSplitView(in view: NSView?) -> NSSplitView? {
        guard let view else { return nil }
        if let split = view as? NSSplitView { return split }
        for subview in view.subviews {
            if let split = firstSplitView(in: subview) { return split }
        }
        return nil
    }
}
