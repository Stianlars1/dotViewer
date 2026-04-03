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
        XCTAssertTrue(html.contains("margin: 0 auto 0 0;"))
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
        XCTAssertTrue(html.contains("margin: 0 auto 0 0;"))
    }

    func testCodeViewCenterAlignmentAppliesCenteredMargin() {
        let info = makeInfo(
            codeContentWidthMode: "custom",
            codeContentCustomMaxWidth: 1280,
            codeContentAlignment: "center",
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 980,
            renderedHTML: nil
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains("margin: 0 auto;"))
    }

    func testCodeViewRightAlignmentAppliesRightAnchoredMargin() {
        let info = makeInfo(
            codeContentWidthMode: "custom",
            codeContentCustomMaxWidth: 1280,
            codeContentAlignment: "right",
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 980,
            renderedHTML: nil
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains("margin: 0 0 0 auto;"))
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

    func testRenderedViewLeftAlignmentAppliesLeftAnchoredMargin() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1280,
            markdownRenderedWidthMode: "custom",
            markdownRenderedCustomMaxWidth: 1440,
            markdownRenderedContentAlignment: "left",
            renderedHTML: "<h1>Title</h1>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains(".rendered-view"))
        XCTAssertTrue(html.contains("margin: 0 auto 0 0;"))
    }

    func testRenderedViewIncludesFrontmatterStyles() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1280,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 1200,
            renderedHTML: "<div class=\"frontmatter\" data-format=\"yaml\"></div>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains(".rendered-view .frontmatter {"))
        XCTAssertTrue(html.contains(".rendered-view .frontmatter-row {"))
        XCTAssertTrue(html.contains(".rendered-view .frontmatter-key {"))
        XCTAssertTrue(html.contains(".rendered-view .frontmatter-value,"))
    }

    func testRenderedHorizontalRuleUsesContentWidth() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1280,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 1200,
            renderedHTML: "<hr>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        guard let hrStart = html.range(of: ".rendered-view hr {") else {
            return XCTFail("Missing rendered hr CSS block")
        }
        let hrBlock = String(html[hrStart.lowerBound...].prefix(220))

        XCTAssertTrue(hrBlock.contains("margin: 32px 0;"))
        XCTAssertTrue(hrBlock.contains("width: 100%;"))
        XCTAssertTrue(hrBlock.contains("max-width: 100%;"))
        XCTAssertFalse(html.contains("max-width: 80%;"))
    }

    func testMarkdownRawAlignmentOverridesCodeAlignment() {
        let info = makeInfo(
            codeContentWidthMode: "custom",
            codeContentCustomMaxWidth: 1280,
            codeContentAlignment: "center",
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 980,
            markdownRawContentAlignment: "right",
            renderedHTML: "<h1>Title</h1>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneLight)

        XCTAssertTrue(html.contains("#raw-view[data-language=\"markdown\"]"))
        XCTAssertTrue(html.contains("margin: 0 0 0 auto;"))
    }

    func testRenderedBootstrapUsesSafeInitPhases() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1200,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 900,
            renderedHTML: "<h1 id=\"title\">Title</h1>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneDark)

        XCTAssertTrue(html.contains("function safeInit(name, fn)"))
        XCTAssertTrue(html.contains("window.__dotviewerInitErrors = window.__dotviewerInitErrors || [];"))
        XCTAssertTrue(html.contains("safeInit('initCoreModeToggle', initCoreModeToggle);"))
        XCTAssertTrue(html.contains("safeInit('initTOCControls', initTOCControls);"))
        XCTAssertTrue(html.contains("safeInit('initCopyControls', initCopyControls);"))
        XCTAssertTrue(html.contains("safeInit('initRenderedLinkCopy', initRenderedLinkCopy);"))
        XCTAssertTrue(html.contains("safeInit('initLineHighlight', initLineHighlight);"))
        XCTAssertTrue(html.contains("safeInit('initSearch', initSearch);"))
        XCTAssertTrue(html.contains("safeInit('initCopyBehavior', initCopyBehavior);"))
    }

    func testRenderedBootstrapInitializesCoreModeBeforeOptionalPhases() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1200,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 900,
            renderedHTML: "<h1 id=\"title\">Title</h1>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneDark)

        guard
            let coreRange = html.range(of: "safeInit('initCoreModeToggle', initCoreModeToggle);"),
            let tocRange = html.range(of: "safeInit('initTOCControls', initTOCControls);"),
            let copyRange = html.range(of: "safeInit('initCopyControls', initCopyControls);")
        else {
            return XCTFail("Expected init phase markers to exist")
        }

        XCTAssertLessThan(coreRange.lowerBound, tocRange.lowerBound)
        XCTAssertLessThan(tocRange.lowerBound, copyRange.lowerBound)
        XCTAssertTrue(html.contains("function initCoreModeToggle()"))
        XCTAssertTrue(html.contains("setMode(currentMode);"))
    }

    func testRenderedBootstrapContainsNoOptionalChainingToken() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1200,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 900,
            renderedHTML: "<h1 id=\"title\">Title</h1>"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.atomOneDark)

        XCTAssertFalse(html.contains("?."))
    }

    func testTOCDisabledOmitsTOCDOMButKeepsSafeBootstrap() {
        let info = PreviewInfo(
            title: "README.md",
            language: "Markdown",
            lineCount: 3,
            fileSizeBytes: 100,
            isTruncated: false,
            showTruncationWarning: false,
            showHeader: true,
            isSensitive: false,
            rawText: "# Title\n\n## Subtitle",
            rawHTML: "<div class=\"line\"><span class=\"code-line\"># Title</span></div>",
            renderedHTML: "<h1 id=\"title\">Title</h1><h2 id=\"subtitle\">Subtitle</h2>",
            codeFontSize: 13,
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1200,
            codeContentAlignment: "left",
            defaultMarkdownMode: "rendered",
            markdownRenderFontSize: 14,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 900,
            markdownRawContentAlignment: "left",
            markdownRenderedContentAlignment: "center",
            markdownShowInlineImages: true,
            markdownCustomCSS: "",
            markdownCustomCSSOverride: false,
            themeName: "githubDark",
            showUnknownTextWarning: false,
            showBinaryWarning: false,
            systemIsDark: true,
            wordWrap: false,
            markdownShowTOC: false,
            markdownTOCDefaultOpen: true,
            copyBehavior: "off",
            showSearchButton: false,
            includeLineNumbersInCopy: false,
            sourceDirectory: "/tmp"
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.githubDark)

        XCTAssertFalse(html.contains("id=\"toc-panel\""))
        XCTAssertFalse(html.contains("id=\"toc-toggle\""))
        XCTAssertTrue(html.contains("safeInit('initCoreModeToggle', initCoreModeToggle);"))
    }

    func testSystemThemeIncludesDarkMediaQueryForPairedPalette() {
        let info = makeInfo(
            codeContentWidthMode: "auto",
            codeContentCustomMaxWidth: 1200,
            markdownRenderedWidthMode: "auto",
            markdownRenderedCustomMaxWidth: 900,
            themeName: "githubAuto",
            renderedHTML: nil
        )

        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: ThemePalette.githubLight)

        XCTAssertTrue(html.contains("@media (prefers-color-scheme: dark)"))
        XCTAssertTrue(html.contains("--bg: #FFFFFF;"))
        XCTAssertTrue(html.contains("--bg: #0D1117;"))
    }

    private func makeInfo(
        codeContentWidthMode: String,
        codeContentCustomMaxWidth: Int,
        codeContentAlignment: String = "left",
        markdownRenderedWidthMode: String,
        markdownRenderedCustomMaxWidth: Int,
        markdownRawContentAlignment: String = "left",
        markdownRenderedContentAlignment: String = "center",
        themeName: String = "atomOneLight",
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
            codeContentAlignment: codeContentAlignment,
            defaultMarkdownMode: "raw",
            markdownRenderFontSize: 14,
            markdownRenderedWidthMode: markdownRenderedWidthMode,
            markdownRenderedCustomMaxWidth: markdownRenderedCustomMaxWidth,
            markdownRawContentAlignment: markdownRawContentAlignment,
            markdownRenderedContentAlignment: markdownRenderedContentAlignment,
            markdownShowInlineImages: true,
            markdownCustomCSS: "",
            markdownCustomCSSOverride: false,
            themeName: themeName,
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
