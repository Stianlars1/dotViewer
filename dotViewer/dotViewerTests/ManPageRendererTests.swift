import XCTest
@testable import Shared

final class ManPageRendererTests: XCTestCase {
    func testShouldRenderByExtension() {
        let url = URL(fileURLWithPath: "/tmp/sample.mdoc")
        XCTAssertTrue(ManPageRenderer.shouldRender(url: url, mimeType: "text/plain", key: "mdoc", text: ""))
    }

    func testShouldRenderByTroffMimeType() {
        let url = URL(fileURLWithPath: "/tmp/sample")
        XCTAssertTrue(ManPageRenderer.shouldRender(url: url, mimeType: "text/troff", key: "", text: ""))
    }

    func testShouldRenderByMacroMarkers() {
        let url = URL(fileURLWithPath: "/tmp/sample")
        let source = ".Dd April 5, 2026\n.Dt TEST 1\n.Os\n.Sh NAME\n.Nm test\n"
        XCTAssertTrue(ManPageRenderer.shouldRender(url: url, mimeType: "text/plain", key: "", text: source))
    }
}
