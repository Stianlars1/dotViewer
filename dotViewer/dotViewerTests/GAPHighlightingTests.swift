import XCTest
import Shared

final class GAPHighlightingTests: XCTestCase {
    private func highlighter() -> TreeSitterHighlighter {
        return TreeSitterHighlighter(languages: [("gap", tree_sitter_gap()), ("gaptst", tree_sitter_gaptst()), ("xml", tree_sitter_xml()), ("json", tree_sitter_json())]) { name in
            guard let url = Bundle(for: GAPHighlightingTests.self).url(forResource: name, withExtension: "scm") else { return nil }
            return try? String(contentsOf: url, encoding: .utf8)
        }
    }

    private func pieces(_ code: String, language: String) -> [(String, String)] {
        let bytes = Array(code.utf8)
        return (highlighter().extractTokens(code: code, language: language) ?? []).map {
            (String(decoding: bytes[$0.s..<$0.e], as: UTF8.self), $0.c)
        }
    }

    func testGAPKeywordsAndFunctionsUseGrammar() {
        let tokens = pieces("if Size(G) = 6 then Print(\"ÆØÅ\"); fi;", language: "gap")
        XCTAssertTrue(tokens.contains { $0 == "fi" && $1 == "keyword" })
        XCTAssertTrue(tokens.contains { $0 == "then" && $1 == "keyword" })
        XCTAssertTrue(tokens.contains { $0 == "Size" && $1 == "function" })
        XCTAssertTrue(tokens.contains { $0 == "\"ÆØÅ\"" && $1 == "string" })
    }

    func testTestInputHighlightedButExpectedOutputIsPlain() {
        let code = "# unicode ÆØÅ\ngap> if true then Print(\"ok\"); fi;\nif true then 42\n"
        let tokens = highlighter().extractTokens(code: code, language: "gaptst") ?? []
        let outputStart = code.utf8.count - "if true then 42\n".utf8.count
        XCTAssertTrue(pieces(code, language: "gaptst").contains { $0 == "fi" && $1 == "keyword" })
        XCTAssertFalse(tokens.contains { $0.s >= outputStart })
    }

    func testMultilineTestFunctionPreservesByteOffsetsAndHTML() {
        let code = "gap> f := function(x)\n> return \"ÆØÅ\";\n> end;\nfunction( x ) ... end\ngap> f(1);\n\"ÆØÅ\""
        let tokens = pieces(code, language: "gaptst")
        XCTAssertTrue(tokens.contains { $0 == "return" && $1 == "keyword" })
        XCTAssertTrue(tokens.contains { $0 == "end" && $1 == "keyword" })
        let html = highlighter().highlight(code: code, language: "gaptst", showLineNumbers: false) ?? ""
        XCTAssertTrue(html.contains("tok-keyword\">return</span>"))
        XCTAssertTrue(html.contains("ÆØÅ"))
        XCTAssertTrue(html.contains("function( x ) ... end"))
    }

    func testOutputOnlyTranscriptDoesNotUseGenericKeywordFallback() {
        XCTAssertTrue(pieces("if true then 42", language: "gaptst").isEmpty)
    }

    func testCancellationReturnsNoPartialResult() {
        XCTAssertNil(highlighter().extractTokens(code: "gap> 1+1;\n2", language: "gaptst", shouldCancel: { true }))
    }
    func testDirectiveExpressionsAreHighlightedIndependently() {
        let source = "#@exec Print(\"ÆØÅ\");\n#@if true\ngap> 1 + 1;\n2\n#@fi\n"
        let tokens = pieces(source, language: "gaptst")
        XCTAssertTrue(tokens.contains { $0 == "Print" && $1 == "function" })
        XCTAssertTrue(tokens.contains { $0 == "true" && $1 == "builtin" })
    }

    func testCancellationDuringInjectionDiscardsPartialCaptures() {
        var checks = 0
        let result = highlighter().extractTokens(code: "gap> f := function(x)\n> return x;\n> end;\n", language: "gaptst") {
            checks += 1
            return checks >= 5
        }
        XCTAssertNil(result)
    }

    func testExistingXMLAndJSONStillUseGrammar() {
        XCTAssertTrue(pieces("<name key=\"value\">ÆØÅ</name>", language: "xml").contains { $0 == "name" && $1 == "tag" })
        XCTAssertTrue(pieces("{\"value\": 42}", language: "json").contains { $0 == "42" && $1 == "number" })
    }

    func testEmptyThumbnailTokensPreservePlainExpectedOutput() {
        let palette = ThemePalette.palette(for: "github-light", systemIsDark: false)
        let lines = ["if true then 42", "ÆØÅ"]
        let converted = TreeSitterTokenConverter.convert(tokens: [], lines: lines, palette: palette)
        XCTAssertEqual(converted.map { $0.map(\.text).joined() }, lines)
        XCTAssertTrue(converted.flatMap { $0 }.allSatisfy { !$0.isBold && !$0.isItalic })
    }

    func testMultilineStringCaptureDoesNotCoverContinuationPromptOrOutput() {
        let code = "gap> s := \"Æ\\\n> Ø\";\n\"ÆØ\"\n"
        let tokens = highlighter().extractTokens(code: code, language: "gaptst") ?? []
        let promptStart = "gap> s := \"Æ\\\n".utf8.count
        let promptEnd = promptStart + 2
        let overlapping = tokens.filter { $0.s < promptEnd && $0.e > promptStart }
        XCTAssertEqual(overlapping.count, 1)
        XCTAssertEqual(overlapping.first?.c, "keyword")
        XCTAssertEqual(overlapping.first?.s, promptStart)
        XCTAssertEqual(overlapping.first?.e, promptEnd)
        let outputStart = code.utf8.count - "\"ÆØ\"\n".utf8.count
        XCTAssertFalse(tokens.contains { $0.e > outputStart })
        XCTAssertTrue(tokens.contains { $0.c == "string" })
    }

}
