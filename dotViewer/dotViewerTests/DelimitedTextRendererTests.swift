import XCTest
@testable import Shared

final class DelimitedTextRendererTests: XCTestCase {
    func testCSVPreviewBuildsTableMarkup() {
        let preview = DelimitedTextRenderer.preview(
            text: "name,role\nStian,Developer\nVictor,Tester\n",
            kind: .csv
        )

        XCTAssertNotNil(preview)
        XCTAssertEqual(preview?.rowCount, 3)
        XCTAssertEqual(preview?.columnCount, 2)
        XCTAssertTrue(preview?.html.contains("<th>name</th>") == true)
        XCTAssertTrue(preview?.html.contains("<td>Tester</td>") == true)
    }

    func testTSVPreviewHandlesQuotedFields() {
        let preview = DelimitedTextRenderer.preview(
            text: "name\tnotes\nStian\t\"writes\tand tests\"\n",
            kind: .tsv
        )

        XCTAssertNotNil(preview)
        XCTAssertTrue(preview?.html.contains("writes\tand tests") == true)
    }
}
