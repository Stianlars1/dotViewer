import XCTest
@testable import Shared

final class FileLanguageResolverTests: XCTestCase {
    private func resolve(_ sample: String, name: String = "group.gd", mappings: [CustomExtension] = []) -> ResolvedFileLanguage {
        let url = URL(fileURLWithPath: "/tmp/" + name)
        return FileLanguageResolver.resolve(url: url, key: FileTypeResolution.bestKey(for: url), sample: sample, customMappings: mappings)
    }

    func testGAPDeclarationDetectedWithoutTakingGodotExtension() {
        XCTAssertEqual(resolve("# declarations\nDeclareGlobalFunction(\"ReviewGroup\");").id, "gap")
        XCTAssertEqual(resolve("DeclareCategory(\"IsReviewGroup\", IsGroup);").displayName, "GAP")
        XCTAssertEqual(FileTypeRegistry.shared.fileType(for: "gd")?.id, "gdscript")
    }

    func testGAPAssignmentsAndTerminatorsDetected() {
        XCTAssertEqual(resolve("f := function(x)\nreturn x;\nend;").id, "gap")
    }

    func testGodotAndAmbiguousContentKeepExistingLanguage() {
        for source in ["extends Node\nfunc f():\n    return 1", "var x := 1", "# DeclareGlobalFunction(\"x\");", "\"\"\"\nDeclareCategory(\"X\", IsGroup);\n\"\"\"", "x = 'DeclareCategory(\"X\", IsGroup);'", "Print(1);", ""] {
            XCTAssertEqual(resolve(source).id, "python", source)
            XCTAssertEqual(resolve(source).displayName, "GDScript", source)
        }
    }

    func testGodotSignatureWinsOverGAPLookingFunctionCall() {
        XCTAssertEqual(resolve("extends Node\nDeclareGlobalFunction(\"x\");").id, "python")
    }

    func testExplicitPlainTextOverrideWins() {
        let custom = CustomExtension(extensionName: "gd", displayName: "My text", highlightLanguage: "plaintext")
        XCTAssertEqual(resolve("DeclareCategory(\"X\", IsGroup);", mappings: [custom]), ResolvedFileLanguage(id: "plaintext", displayName: "My text", isCustomMapping: true))
    }

    func testFilenameOverrideWinsOverExtension() {
        let ext = CustomExtension(extensionName: "gd", displayName: "GAP", highlightLanguage: "gap")
        let file = CustomExtension(extensionName: "", displayName: "Special", highlightLanguage: "plaintext", filenameMatch: "GROUP.GD")
        XCTAssertEqual(resolve("DeclareCategory(\"X\", IsGroup);", mappings: [ext, file]).displayName, "Special")
    }

    func testRegistryRoutesNewTypesAndDotfileGPX() {
        for name in ["source.g", "source.gi"] { XCTAssertEqual(resolve("", name: name).id, "gap") }
        XCTAssertEqual(resolve("", name: "sample.tst").id, "gaptst")
        for name in ["route.gpx", ".gpx", "ROUTE.GPX"] { XCTAssertEqual(resolve("", name: name).id, "xml") }
    }
    func testExtensionlessFilenameOverrideIsExplicit() {
        let mapping = CustomExtension(extensionName: "", displayName: "Plain script", highlightLanguage: "plaintext", filenameMatch: "myscript")
        let resolved = resolve("#!/usr/bin/python3\nprint(1)", name: "myscript", mappings: [mapping])
        XCTAssertEqual(resolved.id, "plaintext")
        XCTAssertTrue(resolved.isCustomMapping)
    }

}
