import XCTest
@testable import Shared

final class FileTypeRegistryTests: XCTestCase {
    let registry = FileTypeRegistry.shared

    // MARK: - Extension → Language

    func testCommonExtensionResolvesToLanguage() {
        XCTAssertEqual(registry.highlightLanguage(for: "swift"), "swift")
        XCTAssertEqual(registry.highlightLanguage(for: "py"), "python")
        XCTAssertEqual(registry.highlightLanguage(for: "js"), "javascript")
        XCTAssertEqual(registry.highlightLanguage(for: "rs"), "rust")
        XCTAssertEqual(registry.highlightLanguage(for: "go"), "go")
        XCTAssertEqual(registry.highlightLanguage(for: "json"), "json")
        XCTAssertEqual(registry.highlightLanguage(for: "yaml"), "yaml")
        XCTAssertEqual(registry.highlightLanguage(for: "md"), "markdown")
    }

    func testCaseInsensitiveExtensionLookup() {
        XCTAssertEqual(registry.highlightLanguage(for: "Swift"), "swift")
        XCTAssertEqual(registry.highlightLanguage(for: "PY"), "python")
        XCTAssertEqual(registry.highlightLanguage(for: "JSON"), "json")
    }

    func testUnknownExtensionReturnsNil() {
        XCTAssertNil(registry.highlightLanguage(for: "zzzzz_unknown"))
    }

    // MARK: - Aliases

    func testShellAliasesResolveToBash() {
        // sh, zsh, etc. should resolve to bash via aliases
        let result = registry.highlightLanguage(for: "sh")
        XCTAssertNotNil(result)
        // The exact value depends on JSON vs legacy, but should be bash
        XCTAssertEqual(result, "bash")
    }

    func testYmlResolvesToYaml() {
        XCTAssertEqual(registry.highlightLanguage(for: "yml"), "yaml")
    }

    // MARK: - Filename Resolution

    func testFilenameResolution() {
        // Dotfile filenames stored without leading dot in the lookup map
        let makefile = registry.fileType(for: "makefile")
        XCTAssertNotNil(makefile)
    }

    // MARK: - File Type by ID

    func testFileTypeById() {
        let swift = registry.fileType(byId: "swift")
        XCTAssertNotNil(swift)
        XCTAssertEqual(swift?.displayName, "Swift")
    }

    func testUnknownIdReturnsNil() {
        XCTAssertNil(registry.fileType(byId: "nonexistent_language_999"))
    }

    // MARK: - Built-in Types

    func testBuiltInTypesNotEmpty() {
        XCTAssertFalse(registry.builtInTypes.isEmpty)
        XCTAssertGreaterThan(registry.builtInTypes.count, 50)
    }

    func testNoDuplicateIds() {
        let ids = registry.builtInTypes.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Duplicate IDs found: \(ids.filter { id in ids.filter { $0 == id }.count > 1 })")
    }

    // MARK: - Display Name

    func testDisplayNameForKnownExtension() {
        let name = registry.displayName(for: "swift")
        XCTAssertNotNil(name)
        XCTAssertEqual(name, "Swift")
    }

    // MARK: - Search

    func testSearchReturnsResults() {
        let results = registry.search("python")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains(where: { $0.id == "python" }))
    }

    func testSearchEmptyQueryReturnsAll() {
        let results = registry.search("")
        XCTAssertEqual(results.count, registry.builtInTypes.count)
    }

    // MARK: - Categories

    func testTypesByCategoryCoversAllCategories() {
        let grouped = registry.typesByCategory()
        // Should have at least a few categories populated
        XCTAssertGreaterThan(grouped.keys.count, 3)
    }
}
