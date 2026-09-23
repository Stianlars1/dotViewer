import XCTest

final class StaleWindowFramesTests: XCTestCase {
    func testRemovesOnlyTheOldPerBuildFrameKeys() throws {
        let suite = "dotViewerTests.StaleWindowFrames.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let stale = [
            "NSWindow Frame SwiftUI.ModifiedContent<dotViewer.ContentView, dotViewer.(unknown context at $10a3c8f40).AppUIFontSizeModifier>-1-AppWindow-1",
            "NSWindow Frame SwiftUI.ModifiedContent<dotViewer.ContentView, dotViewer.(unknown context at $1047d2a10).AppUIFontSizeModifier>-1-AppWindow-1",
        ]
        let kept = ["NSWindow Frame main-AppWindow-1", "NSWindow Frame com_apple_SwiftUI_Settings_window", "selectedTheme"]
        for key in stale + kept { defaults.set("414 246 900 652 0 0 1728 1084 ", forKey: key) }

        StaleWindowFrames.remove(from: defaults)

        for key in stale { XCTAssertNil(defaults.object(forKey: key), key) }
        for key in kept { XCTAssertNotNil(defaults.object(forKey: key), key) }
    }
}
