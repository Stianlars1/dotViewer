import XCTest
@testable import Shared

final class PlistConverterTests: XCTestCase {

    // MARK: - isPropertyList

    func testPlistExtensionIsPropertyList() {
        let url = URL(fileURLWithPath: "/tmp/test.plist")
        XCTAssertTrue(PlistConverter.isPropertyList(url: url))
    }

    func testNonPlistExtensionIsNotPropertyList() {
        let url = URL(fileURLWithPath: "/tmp/test.json")
        XCTAssertFalse(PlistConverter.isPropertyList(url: url))
    }

    func testSwiftExtensionIsNotPropertyList() {
        let url = URL(fileURLWithPath: "/tmp/test.swift")
        XCTAssertFalse(PlistConverter.isPropertyList(url: url))
    }

    // MARK: - isBinaryPlist

    func testBinaryPlistMagicDetected() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).plist")
        // bplist00 header
        var data = Data([0x62, 0x70, 0x6c, 0x69, 0x73, 0x74, 0x30, 0x30])
        data.append(Data(repeating: 0x00, count: 100))
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertTrue(PlistConverter.isBinaryPlist(url: url))
    }

    func testXMLPlistIsNotBinary() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).plist")
        let xmlPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>test</key>
            <string>value</string>
        </dict>
        </plist>
        """
        try xmlPlist.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertFalse(PlistConverter.isBinaryPlist(url: url))
    }

    func testNonexistentFileIsNotBinaryPlist() {
        let url = URL(fileURLWithPath: "/tmp/nonexistent_file_\(UUID().uuidString).plist")
        XCTAssertFalse(PlistConverter.isBinaryPlist(url: url))
    }

    // MARK: - Binary Plist Conversion

    func testConvertBinaryPlistToXML() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("test_\(UUID().uuidString).plist")

        // Create a valid binary plist using plutil
        let xmlPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Name</key>
            <string>Test</string>
        </dict>
        </plist>
        """
        try xmlPlist.write(to: url, atomically: true, encoding: .utf8)

        // Convert to binary using plutil
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/plutil")
        process.arguments = ["-convert", "binary1", url.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            XCTFail("plutil conversion to binary failed")
            return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        // Verify it's now binary
        XCTAssertTrue(PlistConverter.isBinaryPlist(url: url))

        // Convert back to XML using our code
        let result = PlistConverter.convertBinaryPlistToXML(at: url, maxBytes: 10000)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.text.contains("Name"))
        XCTAssertTrue(result!.text.contains("Test"))
        XCTAssertFalse(result!.isTruncated)
    }
}
