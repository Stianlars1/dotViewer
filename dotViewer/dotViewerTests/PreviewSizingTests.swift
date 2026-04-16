import XCTest
@testable import Shared

final class PreviewSizingTests: XCTestCase {

    // MARK: - Auto mode

    func testAutoSizingNeverDropsBelowMinimums() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 1,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "auto",
            fixedWidth: 900,
            fixedHeight: 700
        )

        XCTAssertEqual(size.width, 700)
        XCTAssertGreaterThanOrEqual(size.height, 420)
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

    func testAutoSizingCapsAt1000Height() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 500,
            fontSize: 14,
            showHeader: true,
            windowSizeMode: "auto",
            fixedWidth: 700,
            fixedHeight: 560
        )

        XCTAssertEqual(size.height, 1000)
    }

    // MARK: - Fixed mode

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

    // MARK: - Remember mode

    func testRememberSizingReturnsLastDimensions() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 2,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "remember",
            fixedWidth: 700,
            fixedHeight: 560,
            lastWidth: 1024,
            lastHeight: 768
        )

        XCTAssertEqual(size.width, 1024)
        XCTAssertEqual(size.height, 768)
    }

    func testRememberSizingClampsOutOfRange() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 2,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "remember",
            fixedWidth: 700,
            fixedHeight: 560,
            lastWidth: 200,
            lastHeight: 9000
        )

        XCTAssertEqual(size.width, 420)
        XCTAssertEqual(size.height, 1400)
    }

    func testRememberSizingIgnoresContentForSmallFiles() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 1,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "remember",
            fixedWidth: 700,
            fixedHeight: 560,
            lastWidth: 900,
            lastHeight: 650
        )

        XCTAssertEqual(size.width, 900)
        XCTAssertEqual(size.height, 650)
    }

    // MARK: - Aspect ratio mode

    func testAspectRatio16x10() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 50,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "aspect",
            fixedWidth: 700,
            fixedHeight: 560,
            aspectRatioKey: "16:10",
            aspectBaseWidth: 800
        )

        XCTAssertEqual(size.width, 800)
        XCTAssertEqual(size.height, 500) // 800 * 10/16 = 500
    }

    func testAspectRatio16x9() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 50,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "aspect",
            fixedWidth: 700,
            fixedHeight: 560,
            aspectRatioKey: "16:9",
            aspectBaseWidth: 960
        )

        XCTAssertEqual(size.width, 960)
        XCTAssertEqual(size.height, 540) // 960 * 9/16 = 540
    }

    func testAspectRatio4x3() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 50,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "aspect",
            fixedWidth: 700,
            fixedHeight: 560,
            aspectRatioKey: "4:3",
            aspectBaseWidth: 800
        )

        XCTAssertEqual(size.width, 800)
        XCTAssertEqual(size.height, 600) // 800 * 3/4 = 600
    }

    func testAspectRatio1x1() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 50,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "aspect",
            fixedWidth: 700,
            fixedHeight: 560,
            aspectRatioKey: "1:1",
            aspectBaseWidth: 700
        )

        XCTAssertEqual(size.width, 700)
        XCTAssertEqual(size.height, 700)
    }

    func testAspectRatioClampsSmallBaseWidth() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 50,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "aspect",
            fixedWidth: 700,
            fixedHeight: 560,
            aspectRatioKey: "16:10",
            aspectBaseWidth: 100
        )

        XCTAssertEqual(size.width, 420) // clamped
    }

    func testAspectRatioHeightClampedToMax() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 50,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "aspect",
            fixedWidth: 700,
            fixedHeight: 560,
            aspectRatioKey: "1:1",
            aspectBaseWidth: 1600
        )

        XCTAssertEqual(size.width, 1600)
        XCTAssertEqual(size.height, 1400) // 1600 clamped to 1400
    }

    // MARK: - Content-fixed mode

    func testContentFixedUsesFixedWidth() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 10,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "contentFixed",
            fixedWidth: 900,
            fixedHeight: 800
        )

        XCTAssertEqual(size.width, 900)
    }

    func testContentFixedHeightAdaptsToContent() {
        let sizeShort = PreviewSizing.initialContentSize(
            lineCount: 5,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "contentFixed",
            fixedWidth: 700,
            fixedHeight: 800
        )

        let sizeLong = PreviewSizing.initialContentSize(
            lineCount: 100,
            fontSize: 13,
            showHeader: true,
            windowSizeMode: "contentFixed",
            fixedWidth: 700,
            fixedHeight: 800
        )

        XCTAssertLessThan(sizeShort.height, sizeLong.height)
    }

    func testContentFixedHeightNeverExceedsMax() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 500,
            fontSize: 14,
            showHeader: true,
            windowSizeMode: "contentFixed",
            fixedWidth: 700,
            fixedHeight: 600
        )

        XCTAssertLessThanOrEqual(size.height, 600)
    }

    func testContentFixedHeightNeverBelowMinimum() {
        let size = PreviewSizing.initialContentSize(
            lineCount: 1,
            fontSize: 13,
            showHeader: false,
            windowSizeMode: "contentFixed",
            fixedWidth: 700,
            fixedHeight: 800
        )

        XCTAssertGreaterThanOrEqual(size.height, 220)
    }

    // MARK: - AspectRatio struct

    func testAspectRatioFromKey() {
        let r = PreviewSizing.AspectRatio.from(key: "3:2")
        XCTAssertEqual(r.widthFactor, 3)
        XCTAssertEqual(r.heightFactor, 2)
    }

    func testAspectRatioUnknownKeyDefaultsTo16x10() {
        let r = PreviewSizing.AspectRatio.from(key: "unknown")
        XCTAssertEqual(r.widthFactor, 16)
        XCTAssertEqual(r.heightFactor, 10)
    }
}
