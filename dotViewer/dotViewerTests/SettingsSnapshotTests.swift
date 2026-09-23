import XCTest
import SwiftUI
import AppKit

/// Renders every Settings pane in light and dark, the search results and the main window's sidebar
/// footer to PNG files for visual review — no install needed, so nothing touches the release in
/// /Applications.
///
/// Skipped unless `DV_SNAPSHOT_DIR` is set:
///
///     TEST_RUNNER_DV_SNAPSHOT_DIR=/tmp/shots xcodebuild … test \
///         -only-testing:dotViewerTests/SettingsSnapshotTests
///
/// The sidebar and pane are composed side by side rather than hosted in the real
/// `NavigationSplitView`: offscreen, the split view's layer-backed columns do not draw into a
/// cached bitmap, while plain `NSHostingView` content does. Window chrome and sidebar material are
/// therefore missing from these images; row layout, spacing and controls are exactly the app's.
@MainActor
final class SettingsSnapshotTests: XCTestCase {
    func testRenderEveryPane() throws {
        guard let path = ProcessInfo.processInfo.environment["DV_SNAPSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("Set DV_SNAPSHOT_DIR to render Settings snapshots")
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for (appearance, suffix) in [(NSAppearance.Name.aqua, "light"), (.darkAqua, "dark")] {
            for pane in SettingsPane.allCases {
                let image = try render(SettingsSample(pane: pane, query: ""), appearance: appearance)
                try image.write(to: folder.appendingPathComponent("settings-\(pane.rawValue)-\(suffix).png"))
            }
            // The longest pane, whole, to check what the window's default height scrolls past.
            let markdown = try render(SettingsSample(pane: .markdown, query: "", height: 1_300), appearance: appearance)
            try markdown.write(to: folder.appendingPathComponent("settings-markdown-full-\(suffix).png"))
            let search = try render(
                SettingsSample(pane: .appearance, query: "wrap", highlighted: .wordWrap),
                appearance: appearance
            )
            try search.write(to: folder.appendingPathComponent("settings-search-\(suffix).png"))
            let footer = try render(MainSidebarSample(), appearance: appearance)
            try footer.write(to: folder.appendingPathComponent("main-sidebar-\(suffix).png"))
        }
    }

    /// The Appearance pane and the main window's two views at four Interface text sizes (KI-020).
    func testRenderTextSizes() throws {
        guard let path = ProcessInfo.processInfo.environment["DV_SNAPSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("Set DV_SNAPSHOT_DIR to render Settings snapshots")
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for preset in [AppUIFontSizePreset.xSmall, .system, .large, .xxxLarge] {
            let settings = try render(
                SettingsSample(pane: .appearance, query: "").appUIFontSizing(preset.rawValue),
                appearance: .aqua
            )
            try settings.write(to: folder.appendingPathComponent("text-\(preset.rawValue)-settings.png"))
            let status = try render(MainWindowSample(detail: StatusView()).appUIFontSizing(preset.rawValue), appearance: .aqua)
            try status.write(to: folder.appendingPathComponent("text-\(preset.rawValue)-status.png"))
            let types = try render(MainWindowSample(detail: FileTypesView()).appUIFontSizing(preset.rawValue), appearance: .aqua)
            try types.write(to: folder.appendingPathComponent("text-\(preset.rawValue)-filetypes.png"))
        }
    }

    private func render<V: View>(_ view: V, appearance: NSAppearance.Name) throws -> Data {
        let host = NSHostingView(rootView: view)
        let size = host.fittingSize
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: appearance)
        window.contentView = host
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
        window.orderFrontRegardless()
        defer { window.close() }
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))

        host.layoutSubtreeIfNeeded()
        let rep = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        return try XCTUnwrap(rep.representation(using: .png, properties: [:]))
    }
}

/// The Settings window's two columns, side by side, at the window's default size.
private struct SettingsSample: View {
    let pane: SettingsPane
    let query: String
    var height: CGFloat = 660
    var highlighted: SettingID?
    @State private var model = SettingsModel()

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: .constant(pane), query: query) { _ in }
                .frame(width: 210)
                .background(.background.secondary)
            Divider()
            SettingsPaneView(pane: pane)
                .environment(model)
                .environment(\.highlightedSetting, highlighted)
        }
        .frame(width: 820, height: height)
    }
}

/// The main window's sidebar as `ContentView` builds it, for the footer. Selectable like the real
/// one: a sidebar list without a selection draws its rows dimmed.
private struct MainSidebarSample: View {
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        List(selection: .constant("Status")) {
            Label("Status", systemImage: "checkmark.circle").appFontWhenScaled().tag("Status")
            Label("File Types", systemImage: "doc.text").appFontWhenScaled().tag("File Types")
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) { SettingsFooterLink() }
        .frame(width: 200 * max(1, textScale), height: 260)
        .background(.background.secondary)
    }
}

/// The main window's sidebar and one of its views, side by side, at the window's minimum size.
private struct MainWindowSample<Detail: View>: View {
    let detail: Detail

    var body: some View {
        HStack(spacing: 0) {
            MainSidebarSample()
                .frame(height: 640)
            Divider()
            detail
        }
        .frame(width: 900, height: 640)
    }
}
