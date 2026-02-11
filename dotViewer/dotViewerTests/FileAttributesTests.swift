import XCTest
@testable import Shared

final class FileAttributesTests: XCTestCase {

    // MARK: - looksTextual (static method is private, test via attributes)
    // Since looksTextual is private, we test it indirectly through file-based tests.
    // We create temp files with known content and verify FileAttributes.attributes().

    func testTextFileIsTextual() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).txt")
        let content = "Hello, world!\nThis is a test file.\nLine 3.\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let attrs = FileAttributes.attributes(for: url)
        XCTAssertNotNil(attrs)
        XCTAssertTrue(attrs!.looksTextual)
    }

    func testBinaryFileIsNotTextual() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).bin")
        // Write data with null bytes — should be detected as binary
        var data = Data(repeating: 0x00, count: 100)
        data[0] = 0x89  // PNG magic
        data[1] = 0x50
        data[2] = 0x4E
        data[3] = 0x47
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let attrs = FileAttributes.attributes(for: url)
        XCTAssertNotNil(attrs)
        XCTAssertFalse(attrs!.looksTextual)
    }

    func testEmptyFileIsTextual() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).txt")
        try Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let attrs = FileAttributes.attributes(for: url)
        XCTAssertNotNil(attrs)
        XCTAssertTrue(attrs!.looksTextual)
    }

    func testUTF8WithBOM() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).txt")
        var data = Data([0xEF, 0xBB, 0xBF])  // UTF-8 BOM
        data.append("Hello UTF-8 BOM".data(using: .utf8)!)
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let attrs = FileAttributes.attributes(for: url)
        XCTAssertNotNil(attrs)
        XCTAssertTrue(attrs!.looksTextual)
    }

    func testDSStoreIsRejected() {
        let url = URL(fileURLWithPath: "/tmp/.DS_Store")
        let attrs = FileAttributes.attributes(for: url)
        XCTAssertNil(attrs)
    }

    func testSwiftSourceFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).swift")
        let content = "import Foundation\n\nlet x = 42\nprint(x)\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let attrs = FileAttributes.attributes(for: url)
        XCTAssertNotNil(attrs)
        XCTAssertTrue(attrs!.looksTextual)
    }

    func testManyControlCharsIsNotTextual() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).dat")
        // Create data with >5% control characters (but no null bytes)
        var data = Data()
        for _ in 0..<100 {
            data.append(0x01)  // SOH control char
        }
        for _ in 0..<100 {
            data.append(0x41)  // 'A'
        }
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let attrs = FileAttributes.attributes(for: url)
        XCTAssertNotNil(attrs)
        // 50% control chars — well above 5% threshold
        XCTAssertFalse(attrs!.looksTextual)
    }
}
