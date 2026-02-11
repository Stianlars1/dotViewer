import XCTest
@testable import Shared

final class MarkdownRendererTests: XCTestCase {

    // MARK: - Headings

    func testATXHeadings() {
        let html = MarkdownRenderer.renderHTML(from: "# Hello")
        XCTAssertTrue(html.contains("<h1"))
        XCTAssertTrue(html.contains("Hello"))
        XCTAssertTrue(html.contains("</h1>"))
    }

    func testH2Heading() {
        let html = MarkdownRenderer.renderHTML(from: "## World")
        XCTAssertTrue(html.contains("<h2"))
        XCTAssertTrue(html.contains("World"))
    }

    func testH6Heading() {
        let html = MarkdownRenderer.renderHTML(from: "###### Deep")
        XCTAssertTrue(html.contains("<h6"))
        XCTAssertTrue(html.contains("Deep"))
    }

    func testSetextHeadingH1() {
        let md = "Title\n====="
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("<h1>"))
        XCTAssertTrue(html.contains("Title"))
    }

    func testSetextHeadingH2() {
        let md = "Subtitle\n--------"
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("<h2>"))
        XCTAssertTrue(html.contains("Subtitle"))
    }

    // MARK: - Inline Formatting

    func testBoldWithAsterisks() {
        let html = MarkdownRenderer.renderHTML(from: "**bold text**")
        XCTAssertTrue(html.contains("<strong>bold text</strong>"))
    }

    func testItalicWithAsterisks() {
        let html = MarkdownRenderer.renderHTML(from: "*italic text*")
        XCTAssertTrue(html.contains("<em>italic text</em>"))
    }

    func testBoldItalic() {
        let html = MarkdownRenderer.renderHTML(from: "***bold italic***")
        XCTAssertTrue(html.contains("<strong><em>bold italic</em></strong>"))
    }

    func testInlineCode() {
        let html = MarkdownRenderer.renderHTML(from: "Use `code` here")
        XCTAssertTrue(html.contains("<code>code</code>"))
    }

    func testStrikethrough() {
        let html = MarkdownRenderer.renderHTML(from: "~~deleted~~")
        XCTAssertTrue(html.contains("<del>deleted</del>"))
    }

    // MARK: - Links and Images

    func testLink() {
        let html = MarkdownRenderer.renderHTML(from: "[Google](https://google.com)")
        XCTAssertTrue(html.contains("<a href=\"https://google.com\">"))
        XCTAssertTrue(html.contains("Google"))
    }

    func testImage() {
        let html = MarkdownRenderer.renderHTML(from: "![Alt text](image.png)")
        XCTAssertTrue(html.contains("<img src=\"image.png\" alt=\"Alt text\">"))
    }

    func testAutoLink() {
        let html = MarkdownRenderer.renderHTML(from: "Visit https://example.com today")
        XCTAssertTrue(html.contains("<a href=\"https://example.com\">"))
    }

    // MARK: - Code Blocks

    func testFencedCodeBlock() {
        let md = """
        ```swift
        let x = 42
        ```
        """
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("<pre>"))
        XCTAssertTrue(html.contains("<code"))
        XCTAssertTrue(html.contains("language-swift"))
        XCTAssertTrue(html.contains("let x = 42"))
    }

    func testFencedCodeBlockWithTildes() {
        let md = """
        ~~~python
        print("hello")
        ~~~
        """
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("<pre>"))
        XCTAssertTrue(html.contains("language-python"))
    }

    func testCodeBlockEscapesHTML() {
        let md = """
        ```
        <div>test</div>
        ```
        """
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("&lt;div&gt;"))
    }

    // MARK: - Lists

    func testUnorderedList() {
        let md = "- item 1\n- item 2\n- item 3"
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<li>"))
        XCTAssertTrue(html.contains("item 1"))
        XCTAssertTrue(html.contains("item 2"))
    }

    func testOrderedList() {
        let md = "1. first\n2. second\n3. third"
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("<li>"))
        XCTAssertTrue(html.contains("first"))
    }

    func testTaskList() {
        let md = "- [x] done\n- [ ] todo"
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("task-item"))
        XCTAssertTrue(html.contains("checked"))
    }

    // MARK: - Tables

    func testSimpleTable() {
        let md = "| A | B |\n| --- | --- |\n| 1 | 2 |"
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<th>"))
        XCTAssertTrue(html.contains("<td>"))
        XCTAssertTrue(html.contains("A"))
        XCTAssertTrue(html.contains("1"))
    }

    func testTableWithAlignment() {
        let md = "| Left | Center | Right |\n| :--- | :---: | ---: |\n| a | b | c |"
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("text-align:left"))
        XCTAssertTrue(html.contains("text-align:center"))
        XCTAssertTrue(html.contains("text-align:right"))
    }

    // MARK: - Blockquotes

    func testBlockquote() {
        let html = MarkdownRenderer.renderHTML(from: "> quoted text")
        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("quoted text"))
    }

    // MARK: - Horizontal Rules

    func testHorizontalRule() {
        let html = MarkdownRenderer.renderHTML(from: "---")
        XCTAssertTrue(html.contains("<hr>"))
    }

    func testHorizontalRuleWithAsterisks() {
        let html = MarkdownRenderer.renderHTML(from: "***")
        XCTAssertTrue(html.contains("<hr>"))
    }

    // MARK: - Paragraphs

    func testParagraph() {
        let html = MarkdownRenderer.renderHTML(from: "Hello world")
        XCTAssertTrue(html.contains("<p>"))
        XCTAssertTrue(html.contains("Hello world"))
    }

    // MARK: - HTML Escaping

    func testHTMLEscapingInCodeBlock() {
        // Code blocks should escape HTML entities
        let md = "```\n<div>test</div>\n```"
        let html = MarkdownRenderer.renderHTML(from: md)
        XCTAssertTrue(html.contains("&lt;div&gt;"))
    }

    func testAmpersandEscapingInParagraph() {
        let html = MarkdownRenderer.renderHTML(from: "A & B")
        XCTAssertTrue(html.contains("&amp;"))
    }

    // MARK: - TOC Generation

    func testTOCGenerationWithMultipleHeadings() {
        let md = "# First\n## Second\n### Third"
        let toc = MarkdownRenderer.generateTOC(from: md)
        XCTAssertNotNil(toc)
        XCTAssertTrue(toc!.contains("First"))
        XCTAssertTrue(toc!.contains("Second"))
        XCTAssertTrue(toc!.contains("Third"))
    }

    func testTOCReturnsNilForSingleHeading() {
        let md = "# Only One"
        let toc = MarkdownRenderer.generateTOC(from: md)
        XCTAssertNil(toc, "TOC should be nil when there are fewer than 2 headings")
    }

    func testTOCIgnoresCodeBlocks() {
        let md = "# Real Heading\n```\n# Not a heading\n```\n## Another Heading"
        let toc = MarkdownRenderer.generateTOC(from: md)
        XCTAssertNotNil(toc)
        XCTAssertTrue(toc!.contains("Real Heading"))
        XCTAssertFalse(toc!.contains("Not a heading"))
    }
}
