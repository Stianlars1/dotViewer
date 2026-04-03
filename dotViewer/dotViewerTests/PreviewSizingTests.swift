import XCTest
@testable import Shared

final class PreviewSizingTests: XCTestCase {
    func testAutoSizingUsesCompactWidthForShortFiles() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 3,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "auto",
            fixedWidth: 900,
            fixedHeight: 700
        )

        XCTAssertEqual(size.width, 420)
        XCTAssertGreaterThanOrEqual(size.height, 160)
    }

    func testAutoSizingUsesWideWidthForLongerFiles() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 20,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "auto",
            fixedWidth: 900,
            fixedHeight: 700
        )

        XCTAssertEqual(size.width, 700)
    }

    func testFixedSizingUsesConfiguredDimensions() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 200,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "fixed",
            fixedWidth: 960,
            fixedHeight: 720
        )

        XCTAssertEqual(size.width, 960)
        XCTAssertEqual(size.height, 720)
    }

    func testFixedSizingClampsOutOfRangeDimensions() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 200,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "fixed",
            fixedWidth: 9999,
            fixedHeight: 100
        )

        XCTAssertEqual(size.width, 1600)
        XCTAssertEqual(size.height, 220)
    }
}
