import XCTest
import Shared

final class GnuplotHighlightingTests: XCTestCase {
    func testCommandsOptionsAndUnicodeStringsUseGnuplotGrammar() {
        let highlighter = TreeSitterHighlighter(languages: [("gnuplot", tree_sitter_gnuplot())]) { name in
            guard let url = Bundle(for: Self.self).url(forResource: name, withExtension: "scm") else { return nil }
            return try? String(contentsOf: url, encoding: .utf8)
        }
        let code = "set title \"ÆØÅ\"\nset lmargin at screen 0.1\nsplot sin(x*y)\npause 1\nclear\nreset\nplot for [i=1:3] sin(i*x)\n"
        let bytes = Array(code.utf8)
        let tokens = (highlighter.extractTokens(code: code, language: "gnuplot") ?? []).map {
            (String(decoding: bytes[$0.s..<$0.e], as: UTF8.self), $0.c)
        }
        for word in ["set", "splot", "pause", "clear", "reset", "for"] {
            XCTAssertTrue(tokens.contains { $0.0 == word && $0.1 == "keyword" }, word)
        }
        XCTAssertTrue(tokens.contains { $0.0 == "\"ÆØÅ\"" && $0.1 == "string" })
        XCTAssertTrue(tokens.contains { $0.0 == "lmargin" && $0.1 == "attribute" })
    }

    func testAmbiguousGPRequiresEvidenceOrExplicitOverride() {
        let url = URL(fileURLWithPath: "/tmp/math.gp")
        let pari = "f(x) = x^2;\nplot(x=0,1,f(x))\n"
        XCTAssertEqual(FileLanguageResolver.resolve(url: url, key: "gp", sample: pari, customMappings: []).id, "plaintext")
        XCTAssertEqual(FileLanguageResolver.resolve(url: url, key: "gp", sample: "plot sin(x)", customMappings: []).id, "gnuplot")
        let override = CustomExtension(extensionName: "gp", displayName: "Gnuplot", highlightLanguage: "gnuplot")
        XCTAssertEqual(FileLanguageResolver.resolve(url: url, key: "gp", sample: pari, customMappings: [override]).id, "gnuplot")
        XCTAssertFalse(GnuplotSourceDetector.matches("# plot sin(x)\nprint(\"set title hello\")"))
        XCTAssertTrue(HighlightLanguage.all.contains { $0.id == "gnuplot" && $0.hasTreeSitterGrammar })
        for ext in ["gpi", "gpl", "plt", "plot", "dem"] {
            XCTAssertNotEqual(FileTypeRegistry.shared.fileType(for: ext)?.id, "gnuplot")
        }
    }
}
