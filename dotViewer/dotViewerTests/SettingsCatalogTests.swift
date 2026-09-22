import XCTest

/// The catalog backs Settings search and the row anchors search scrolls to, so every setting must
/// have exactly one entry and every pane must be reachable.
final class SettingsCatalogTests: XCTestCase {
    func testEverySettingIDHasExactlyOneEntry() {
        let ids = SettingsCatalog.entries.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate catalog entries")
        XCTAssertEqual(Set(ids), Set(SettingID.allCases), "Every SettingID needs a catalog entry")
    }

    func testEveryPaneHasSettings() {
        for pane in SettingsPane.allCases {
            XCTAssertFalse(SettingsCatalog.entries.filter { $0.pane == pane }.isEmpty, "\(pane) has no entries")
        }
    }

    func testGroupsCoverEveryPaneOnce() {
        XCTAssertEqual(SettingsPane.groups.flatMap { $0 }, SettingsPane.allCases)
    }

    func testSearchMatchesTitlesCaseInsensitively() {
        XCTAssertTrue(SettingsCatalog.search("WRAP LONG").map(\.id).contains(.wordWrap))
    }

    func testSearchMatchesKeywords() {
        XCTAssertTrue(SettingsCatalog.search("dark").map(\.id).contains(.theme))
        XCTAssertTrue(SettingsCatalog.search("option space").map(\.id).contains(.spacePanel))
    }

    func testSearchIgnoresDiacritics() {
        XCTAssertTrue(SettingsCatalog.search("thème").map(\.id).contains(.theme))
    }

    func testEveryTokenMustMatch() {
        let ids = SettingsCatalog.search("cache size").map(\.id)
        XCTAssertTrue(ids.contains(.cacheSize))
        XCTAssertFalse(ids.contains(.fontSize), "\"size\" alone must not match when \"cache\" does not")
    }

    func testTitleMatchesComeBeforeKeywordMatches() {
        // "raw" is in two titles and, in pane order, first matches "Open Markdown as" by keyword.
        XCTAssertEqual(
            SettingsCatalog.search("raw").map(\.id),
            [.markdownRawHighlighting, .markdownRawAlignment, .markdownDefaultMode, .codeWidth]
        )
    }

    func testBlankQueryReturnsNothing() {
        XCTAssertTrue(SettingsCatalog.search("   ").isEmpty)
    }
}
