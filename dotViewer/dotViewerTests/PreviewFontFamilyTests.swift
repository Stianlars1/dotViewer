import XCTest
import Shared

final class PreviewFontFamilyTests: XCTestCase {
    func testSanitizedFontFamilyKeepsNormalFamilyNames() {
        XCTAssertEqual(
            PreviewFontFamily.sanitized("New York", fallback: "System"),
            "New York"
        )
        XCTAssertEqual(
            PreviewFontFamily.sanitized("JetBrains Mono NL", fallback: "SF Mono"),
            "JetBrains Mono NL"
        )
    }

    func testSanitizedFontFamilyRemovesCSSInjectionCharacters() {
        XCTAssertEqual(
            PreviewFontFamily.sanitized("Menlo\"; color:red;", fallback: "SF Mono"),
            "Menlo colorred"
        )
    }

    func testCodeCSSStackQuotesPreferredFontAndKeepsFallbacks() {
        XCTAssertEqual(
            PreviewFontFamily.codeCSSStack(for: "JetBrains Mono"),
            "\"JetBrains Mono\", \"SF Mono\", Menlo, Monaco, Consolas, \"Liberation Mono\", monospace"
        )
    }

    func testMarkdownSystemFontUsesSystemStack() {
        XCTAssertEqual(
            PreviewFontFamily.markdownCSSStack(for: "System"),
            "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Helvetica, Arial, sans-serif"
        )
    }

    func testPreviewCacheKeyChangesWhenFontFamiliesChange() {
        let url = URL(fileURLWithPath: "/tmp/example.swift")
        let base = PreviewCacheKey(
            url: url,
            fileSize: 42,
            mtime: 1,
            showLineNumbers: true,
            codeFontSize: 13,
            codeFontFamilyName: "SF Mono",
            markdownUseSyntaxHighlightInRaw: true,
            allowUnknown: true,
            forceTextForUnknown: true,
            languageId: "swift",
            theme: "auto",
            showHeader: true,
            markdownDefaultMode: "raw",
            markdownRenderFontSize: 13,
            markdownRenderedFontFamilyName: "System",
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 900,
            markdownShowInlineImages: true,
            markdownCustomCSS: "",
            markdownCustomCSSOverride: false,
            markdownTOCDefaultOpen: true,
            includeLineNumbersInCopy: false,
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1200,
            codeContentAlignment: "left",
            markdownRawContentAlignment: "left",
            markdownRenderedContentAlignment: "center",
            wordWrap: false
        )
        let custom = PreviewCacheKey(
            url: url,
            fileSize: 42,
            mtime: 1,
            showLineNumbers: true,
            codeFontSize: 13,
            codeFontFamilyName: "Menlo",
            markdownUseSyntaxHighlightInRaw: true,
            allowUnknown: true,
            forceTextForUnknown: true,
            languageId: "swift",
            theme: "auto",
            showHeader: true,
            markdownDefaultMode: "raw",
            markdownRenderFontSize: 13,
            markdownRenderedFontFamilyName: "New York",
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 900,
            markdownShowInlineImages: true,
            markdownCustomCSS: "",
            markdownCustomCSSOverride: false,
            markdownTOCDefaultOpen: true,
            includeLineNumbersInCopy: false,
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1200,
            codeContentAlignment: "left",
            markdownRawContentAlignment: "left",
            markdownRenderedContentAlignment: "center",
            wordWrap: false
        )

        XCTAssertNotEqual(base.rawKey, custom.rawKey)
    }
}
