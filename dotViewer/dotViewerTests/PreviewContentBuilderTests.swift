import XCTest
@testable import Shared

/// Covers the pipeline both front-ends share: the Quick Look extension and the ⌥Space panel.
///
/// The cases that matter most here are the ones Quick Look can never reach — an unregistered
/// extension gets a `dyn.*` UTI and is never routed to the extension, and `.ts` is claimed by the
/// system as a transport stream. The panel exists for exactly those, so `build` has to render them.
final class PreviewContentBuilderTests: XCTestCase {

    private var directory: URL!
    private var cacheWasEnabled: Bool!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("dotViewerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // SharedSettings is backed by real (possibly App Group) defaults, so anything changed here
        // has to be put back — a test run must not leave the user's preferences altered.
        cacheWasEnabled = SharedSettings.shared.previewCacheEnabled
        SharedSettings.shared.previewCacheEnabled = false
    }

    override func tearDownWithError() throws {
        SharedSettings.shared.previewCacheEnabled = cacheWasEnabled
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    private func makeFile(_ name: String, _ contents: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func makeBinaryFile(_ name: String, _ bytes: Data) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try bytes.write(to: url)
        return url
    }

    private func render(_ outcome: PreviewOutcome, file: StaticString = #filePath, line: UInt = #line) throws -> PreviewRender {
        guard case .rendered(let render) = outcome else {
            XCTFail("Expected .rendered, got \(outcome)", file: file, line: line)
            throw XCTSkip("not rendered")
        }
        return render
    }

    // MARK: - Files Quick Look cannot route

    /// The whole reason the ⌥Space panel exists: `.foo` never reaches the Quick Look extension
    /// because macOS assigns it a dynamic UTI, but the panel must still render it.
    func testUnregisteredExtensionStillRenders() async throws {
        let url = try makeFile("notes.foo", "alpha\nbeta\ngamma\n")
        let outcome = await PreviewContentBuilder.build(for: url, systemIsDark: false)
        let render = try render(outcome)
        XCTAssertTrue(render.html.contains("alpha"))
        XCTAssertEqual(render.title, "notes.foo")
    }

    /// `.ts` resolves to public.mpeg-2-transport-stream, so the extension route is closed. Text
    /// content must still render rather than being mistaken for video.
    func testTypeScriptSourceRenders() async throws {
        let url = try makeFile("app.ts", "export const answer: number = 42;\n")
        let outcome = await PreviewContentBuilder.build(for: url, systemIsDark: false)
        let render = try render(outcome)
        XCTAssertTrue(render.html.contains("answer"))
    }

    /// The other half of the `.ts` split: a real transport stream must be handed back, not drawn
    /// as text.
    func testTransportStreamFallsBackToSystem() async throws {
        var bytes = Data(count: 188 * 3)
        bytes[0] = 0x47
        bytes[188] = 0x47
        bytes[376] = 0x47
        let url = try makeBinaryFile("video.ts", bytes)
        let outcome = await PreviewContentBuilder.build(for: url, systemIsDark: false)
        guard case .systemFallback = outcome else {
            return XCTFail("Transport stream should fall back to the system renderer")
        }
    }

    // MARK: - Ordinary routing

    func testKnownSourceFileRenders() async throws {
        let url = try makeFile("main.swift", "let greeting = \"hello\"\n")
        let render = try render(await PreviewContentBuilder.build(for: url, systemIsDark: false))
        XCTAssertTrue(render.html.contains("greeting"))
        XCTAssertEqual(render.title, "main.swift")
        XCTAssertGreaterThan(render.lineCount, 0)
    }

    func testMarkdownProducesRenderedSection() async throws {
        let url = try makeFile("README.md", "# Title\n\nSome prose.\n")
        let render = try render(await PreviewContentBuilder.build(for: url, systemIsDark: false))
        XCTAssertTrue(render.html.contains("rendered-view"), "markdown should carry a rendered mode")
    }

    // MARK: - Front-end differences

    /// The panel handles ⌘F itself, so it asks for the search bar regardless of the Quick Look
    /// "Show Find in Preview" preference — which defaults to off.
    func testForceSearchUIEmitsSearchBarWhenSettingIsOff() async throws {
        let wasOn = SharedSettings.shared.showSearchButton
        SharedSettings.shared.showSearchButton = false
        defer { SharedSettings.shared.showSearchButton = wasOn }

        let url = try makeFile("main.swift", "let x = 1\n")

        let without = try render(await PreviewContentBuilder.build(for: url, systemIsDark: false))
        XCTAssertFalse(without.html.contains("id=\"search-bar\""))

        let with = try render(await PreviewContentBuilder.build(
            for: url,
            systemIsDark: false,
            forceSearchUI: true
        ))
        XCTAssertTrue(with.html.contains("id=\"search-bar\""))
    }

    /// A real window receives keys on its own. Subscribing it to the loopback bridge would make the
    /// event tap swallow keystrokes the panel is already handling.
    func testSearchBridgeClientOmittedWhenDisabled() async throws {
        let url = try makeFile("main.swift", "let x = 1\n")
        let render = try render(await PreviewContentBuilder.build(
            for: url,
            systemIsDark: false,
            enableSearchBridge: false,
            forceSearchUI: true
        ))
        XCTAssertFalse(render.html.contains("EventSource"), "panel pages must not open the bridge")
        XCTAssertTrue(render.html.contains("__dvSearch"), "but the search API itself must remain")
    }
}
