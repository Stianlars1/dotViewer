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

    func testCustomerReportedDynamicExtensionsResolveToBuiltIns() {
        XCTAssertEqual(registry.highlightLanguage(for: "cue"), "plaintext")
        XCTAssertEqual(registry.displayName(for: "cue"), "CUE / Cue Sheet")

        XCTAssertEqual(registry.highlightLanguage(for: "csv"), "plaintext")
        XCTAssertEqual(registry.displayName(for: "csv"), "CSV")
        XCTAssertEqual(registry.highlightLanguage(for: "tsv"), "plaintext")
        XCTAssertEqual(registry.displayName(for: "tsv"), "TSV")
        XCTAssertEqual(registry.highlightLanguage(for: "conf"), "ini")
        XCTAssertEqual(registry.displayName(for: "conf"), "INI")

        XCTAssertEqual(registry.highlightLanguage(for: "1"), "plaintext")
        XCTAssertEqual(registry.highlightLanguage(for: "man"), "plaintext")
        XCTAssertEqual(registry.highlightLanguage(for: "mdoc"), "plaintext")
        XCTAssertEqual(registry.highlightLanguage(for: "2"), "plaintext")
        XCTAssertEqual(registry.highlightLanguage(for: "9"), "plaintext")
        XCTAssertEqual(registry.displayName(for: "1"), "Man Page")
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

    // MARK: - Issue #25 — GPX routes to the XML renderer

    func testGpxExtensionResolvesToXml() {
        XCTAssertEqual(registry.highlightLanguage(for: "gpx"), "xml")
        XCTAssertEqual(registry.highlightLanguage(for: "GPX"), "xml",
                       "GPX lookup must be case-insensitive")
    }

    func testGpxDisplayName() {
        // We surface .gpx under the shared XML display name so Finder shows
        // a familiar type label instead of the generic "GPX Document".
        XCTAssertEqual(registry.displayName(for: "gpx"), "XML")
    }

    func testGpxFileTypeInBuiltIns() {
        // The XML entry that owns .gpx must still be reachable by id.
        let xml = registry.fileType(byId: "xml")
        XCTAssertNotNil(xml)
        XCTAssertTrue(xml?.extensions.contains("gpx") == true,
                      "XML entry should list gpx among its extensions")
    }

    // MARK: - Issue #29 — Gnuplot script routing

    func testGnuplotPrimaryExtensionsResolve() {
        // gnuplot script files come with several accepted extensions; every
        // one must land on the Gnuplot registry entry and be highlighted with
        // the bash grammar (see FileTypeRegistry aliases). The reporter of
        // #29 specifically asked for .gp and .gnuplot to be pre-configured;
        // the rest come from the wider gnuplot ecosystem (docs, gallery,
        // third-party grammars).
        for ext in ["gp", "gnuplot", "gnu", "gpi", "plt", "plot", "dem"] {
            XCTAssertEqual(registry.highlightLanguage(for: ext), "bash",
                           "\(ext) should highlight with the bash grammar")
            XCTAssertEqual(registry.displayName(for: ext), "Gnuplot",
                           "\(ext) should show as Gnuplot in the badge")
        }
    }

    func testGnuplotExtensionsCaseInsensitive() {
        // Uppercase extensions are common on Windows-shared files and in
        // documentation. The registry is case-insensitive by contract; make
        // that explicit for the new entry.
        XCTAssertEqual(registry.highlightLanguage(for: "GP"), "bash")
        XCTAssertEqual(registry.highlightLanguage(for: "PLT"), "bash")
        XCTAssertEqual(registry.displayName(for: "Gnuplot"), "Gnuplot")
    }

    func testGnuplotFilenamesResolve() {
        // gnuplot reads gnuplotrc / .gnuplot / .gnuplot_history at startup.
        // The registry stores filenames with the leading dot stripped, so
        // lookups happen through the same extension map.
        XCTAssertEqual(registry.highlightLanguage(for: "gnuplotrc"), "bash")
        XCTAssertEqual(registry.highlightLanguage(for: "gnuplot_history"), "bash")
        XCTAssertEqual(registry.displayName(for: "gnuplotrc"), "Gnuplot")
    }

    func testGnuplotEntryInBuiltIns() {
        // The registry must expose gnuplot by id for the Settings language
        // picker and any future custom-mapping flows.
        let gp = registry.fileType(byId: "gnuplot")
        XCTAssertNotNil(gp)
        XCTAssertEqual(gp?.displayName, "Gnuplot")
        for ext in ["gp", "gnuplot", "gnu", "gpi", "plt", "plot", "dem"] {
            XCTAssertTrue(gp?.extensions.contains(ext) == true,
                          "Gnuplot entry is missing extension \(ext)")
        }
        XCTAssertTrue(gp?.filenames.contains("gnuplotrc") == true)
        XCTAssertTrue(gp?.filenames.contains(".gnuplot") == true)
        XCTAssertTrue(gp?.filenames.contains(".gnuplot_history") == true)
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
