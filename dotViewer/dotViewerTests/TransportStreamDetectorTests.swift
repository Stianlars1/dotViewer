import XCTest
@testable import Shared

final class TransportStreamDetectorTests: XCTestCase {

    // MARK: - Sync Pattern Detection

    func testValidTransportStreamSyncPattern() {
        // MPEG-TS packets start with 0x47, each 188 bytes apart
        var data = Data(count: 188 * 3)
        data[0] = 0x47
        data[188] = 0x47
        data[376] = 0x47
        XCTAssertTrue(TransportStreamDetector.matchesTransportStreamSyncPattern(data: data))
    }

    func testInvalidSyncPattern_FirstByteWrong() {
        var data = Data(count: 188 * 3)
        data[0] = 0x00  // Not 0x47
        data[188] = 0x47
        data[376] = 0x47
        XCTAssertFalse(TransportStreamDetector.matchesTransportStreamSyncPattern(data: data))
    }

    func testInvalidSyncPattern_SecondByteWrong() {
        var data = Data(count: 188 * 3)
        data[0] = 0x47
        data[188] = 0x00  // Not 0x47
        data[376] = 0x47
        XCTAssertFalse(TransportStreamDetector.matchesTransportStreamSyncPattern(data: data))
    }

    func testInvalidSyncPattern_ThirdByteWrong() {
        var data = Data(count: 188 * 3)
        data[0] = 0x47
        data[188] = 0x47
        data[376] = 0x00  // Not 0x47
        XCTAssertFalse(TransportStreamDetector.matchesTransportStreamSyncPattern(data: data))
    }

    func testTooShortData() {
        // Less than 3 packets (188 * 3 = 564 bytes)
        let data = Data(count: 188 * 2)
        XCTAssertFalse(TransportStreamDetector.matchesTransportStreamSyncPattern(data: data))
    }

    func testEmptyData() {
        let data = Data()
        XCTAssertFalse(TransportStreamDetector.matchesTransportStreamSyncPattern(data: data))
    }

    func testTypescriptFileContent() {
        // TypeScript source code should not match TS sync pattern
        let tsCode = "const greeting: string = 'hello world';\nconsole.log(greeting);\n"
        let data = Data(tsCode.utf8)
        XCTAssertFalse(TransportStreamDetector.matchesTransportStreamSyncPattern(data: data))
    }

    func testRandomBinaryData() {
        // Random binary data without 0x47 sync bytes
        var data = Data(count: 188 * 4)
        for i in 0..<data.count {
            data[i] = UInt8(i % 256)
        }
        // This may or may not have 0x47 at the right positions — replace sync positions
        data[0] = 0xFF
        data[188] = 0xFF
        data[376] = 0xFF
        XCTAssertFalse(TransportStreamDetector.matchesTransportStreamSyncPattern(data: data))
    }

    // MARK: - MIME-based Detection

    func testVideoMimeIsCandidate() {
        let url = URL(fileURLWithPath: "/tmp/test.ts")
        XCTAssertTrue(TransportStreamDetector.isTransportStreamCandidate(url: url, mimeType: "video/mp2t"))
    }

    func testTextMimeIsNotCandidate() {
        let url = URL(fileURLWithPath: "/tmp/test.swift")
        XCTAssertFalse(TransportStreamDetector.isTransportStreamCandidate(url: url, mimeType: "text/plain"))
    }

    func testNilMimeWithNonTsExtension() {
        let url = URL(fileURLWithPath: "/tmp/test.swift")
        XCTAssertFalse(TransportStreamDetector.isTransportStreamCandidate(url: url, mimeType: nil))
    }
}
