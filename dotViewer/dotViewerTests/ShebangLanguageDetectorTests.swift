import XCTest
@testable import Shared

final class ShebangLanguageDetectorTests: XCTestCase {
    func testDetectsEnvPythonShebang() {
        let match = ShebangLanguageDetector.detect(in: "#!/usr/bin/env python3\nprint('hi')\n")
        XCTAssertEqual(match?.languageId, "python")
        XCTAssertEqual(match?.displayName, "Python")
    }

    func testDetectsShellShebang() {
        let match = ShebangLanguageDetector.detect(in: "#!/bin/sh\necho hi\n")
        XCTAssertEqual(match?.languageId, "bash")
        XCTAssertEqual(match?.displayName, "Shell Script")
    }
}
