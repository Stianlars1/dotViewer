import XCTest
import Shared

final class PreviewHTMLBuilderTests: XCTestCase {
    func testCodeViewAutoWidthIsUncapped() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1280,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 980,
            renderedHTML: nil
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains("max-width: none;"))
        XCTAssertTrue(html.contains("margin: 0;"))
    }

    func testCodeViewCustomWidthAppliesConfiguredMaxWidth() {
        let info = makeInfo(
            codeContentWidthMode: "custom",
            codeContentCustomMaxWidth: 1280,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 980,
            renderedHTML: nil
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains("max-width: 1280px;"))
        XCTAssertTrue(html.contains("margin: 0 auto;"))
    }

    func testRenderedViewAutoWidthUsesDefaultWidth() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1280,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 1200,
            renderedHTML: "<h1>Title</h1>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains(".rendered-view"))
        XCTAssertTrue(html.contains("max-width: 900px;"))
    }

    func testRenderedViewCustomWidthUsesConfiguredWidth() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1280,
            markdownRenderedWidthMode: "custom",
            markdownRenderedCustomMaxWidth: 1440,
            renderedHTML: "<h1>Title</h1>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains("max-width: 1440px;"))
    }

    private func makeInfo(
        codeContentWidthMode: String,
        codeContentCustomMaxWidth: Int,
        markdownRenderedWidthMode: String,
        markdownRenderedCustomMaxWidth: Int,
        renderedHTML: String?
    ) -> PreviewInfo {
        PreviewInfo(
            title: "test.swift",
            language: "Swift",
            lineCount: 1,
            fileSizeBytes: 42,
            isTruncated: false,
            showTruncationWarning: true,
            showHeader: true,
            isSensitive: false,
            rawText: "print(\"hello\")",
            rawHTML: "<pre class=\"code\">print(\"hello\")</pre>",
            renderedHTML: renderedHTML,
            codeFontSize: 13,
            codeContentWidthMode: codeContentWidthMode,
            codeContentCustomMaxWidth: codeContentCustomMaxWidth,
            defaultMarkdownMode: "raw",
            markdownRenderFontSize: 14,
            markdownRenderedWidthMode: markdownRenderedWidthMode,
            markdownRenderedCustomMaxWidth: markdownRenderedCustomMaxWidth,
            markdownShowInlineImages: true,
            markdownCustomCSS: "",
            markdownCustomCSSOverride: false,
            themeName: "atomOneLight",
            showUnknownTextWarning: false,
            showBinaryWarning: false,
            systemIsDark: false,
            wordWrap: false,
            markdownShowTOC: false,
            markdownTOCDefaultOpen: false,
            copyBehavior: "off",
            showSearchButton: false,
            includeLineNumbersInCopy: false,
            sourceDirectory: "/tmp"
        )
    }
}
