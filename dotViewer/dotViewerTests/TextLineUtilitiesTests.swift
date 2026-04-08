import XCTest
@testable import Shared

final class TextLineUtilitiesTests: XCTestCase {
    func testTrailingRecordTerminatorDoesNotAddPhantomLine() {
        XCTAssertEqual(TextLineUtilities.visualLineCount(in: "1\n2\n3\n"), 3)
        XCTAssertEqual(TextLineUtilities.lines(forDisplayFrom: "1\n2\n3\n"), ["1", "2", "3"])
    }

    func testDoubleTrailingNewlineKeepsIntentionalBlankLine() {
        XCTAssertEqual(TextLineUtilities.visualLineCount(in: "1\n2\n\n"), 3)
        XCTAssertEqual(TextLineUtilities.lines(forDisplayFrom: "1\n2\n\n"), ["1", "2", ""])
    }

    func testCRLFInputNormalizesToDisplayLines() {
        XCTAssertEqual(TextLineUtilities.visualLineCount(in: "a\r\nb\r\n"), 2)
        XCTAssertEqual(TextLineUtilities.lines(forDisplayFrom: "a\r\nb\r\n"), ["a", "b"])
    }

    func testEmptyFileHasZeroLines() {
        XCTAssertEqual(TextLineUtilities.visualLineCount(in: ""), 0)
        XCTAssertTrue(TextLineUtilities.lines(forDisplayFrom: "").isEmpty)
    }
}
