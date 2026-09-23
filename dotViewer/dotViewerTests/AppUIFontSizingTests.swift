import XCTest
import SwiftUI
import AppKit

/// The Interface text size setting (KI-020): macOS ignores `dynamicTypeSize`, so the app scales its
/// own fonts. These check that the default size changes nothing and that every other size does.
@MainActor
final class AppUIFontSizingTests: XCTestCase {
    func testPresetsGrowInMenuOrderAroundTheDefault() {
        let sizes = AppUIFontSizePreset.allCases.map(\.bodyPointSize)
        XCTAssertEqual(sizes, sizes.sorted())
        XCTAssertEqual(Set(sizes).count, sizes.count, "two presets with the same size")
        XCTAssertEqual(AppUIFontSizePreset.system.bodyPointSize, 13)
        XCTAssertEqual(AppUIFontSizePreset.system.scale, 1)
        XCTAssertEqual(AppUIFontSizePreset.system.title, "Default")
    }

    func testStoredValuesReadAsPresets() {
        XCTAssertEqual(AppUIFontSizePreset.from(rawValue: "large"), .large)
        XCTAssertEqual(AppUIFontSizePreset.from(rawValue: "xxxLarge"), .xxxLarge)
        // `medium` was an option of its own, the same size as the default.
        XCTAssertEqual(AppUIFontSizePreset.from(rawValue: "medium"), .system)
        XCTAssertEqual(AppUIFontSizePreset.from(rawValue: "huge"), .system)
    }

    func testTextStyleMetricsMatchAppKit() {
        let styles: [(Font.TextStyle, NSFont.TextStyle)] = [
            (.largeTitle, .largeTitle), (.title, .title1), (.title2, .title2), (.title3, .title3),
            (.headline, .headline), (.subheadline, .subheadline), (.body, .body), (.callout, .callout),
            (.footnote, .footnote), (.caption, .caption1), (.caption2, .caption2),
        ]
        for (style, appKitStyle) in styles {
            let font = NSFont.preferredFont(forTextStyle: appKitStyle)
            XCTAssertEqual(style.macOSMetrics.size, font.pointSize, "\(style)")
            let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
            XCTAssertEqual(style.macOSMetrics.weight == .bold, isBold, "\(style)")
        }
    }

    func testDefaultSizeLeavesFontsAsTheSystemSetsThem() {
        XCTAssertEqual(
            size(of: SettingsLabel("Wrap long lines", description: "Instead of scrolling sideways.")
                .appUIFontSizing("system")),
            size(of: SettingsLabel("Wrap long lines", description: "Instead of scrolling sideways."))
        )
        XCTAssertEqual(
            size(of: Text("Caption").appFont(.caption).appUIFontSizing("system")),
            size(of: Text("Caption").font(.caption))
        )
        XCTAssertEqual(
            size(of: Text("⌘,").appFont(.caption, design: .monospaced).appUIFontSizing("system")),
            size(of: Text("⌘,").font(.caption.monospaced()))
        )
    }

    func testEveryLargerPresetMakesTextTaller() {
        // Unstyled text takes the window's font; styled text scales its own style.
        let heights = AppUIFontSizePreset.allCases.map { preset in
            size(of: VStack(alignment: .leading) {
                Text("Interface text size")
                Text("Text in dotViewer's own windows.").appFont(.subheadline)
                Text("dotViewer").appFont(.largeTitle).fontWeight(.bold)
            }
            .appUIFontSizing(preset.rawValue)).height
        }
        XCTAssertEqual(heights, heights.sorted())
        XCTAssertEqual(Set(heights).count, heights.count, "a preset that changes nothing: \(heights)")

        let defaultHeight = size(of: SettingsLabel("Title", description: "Description").appUIFontSizing("system")).height
        let largest = size(of: SettingsLabel("Title", description: "Description").appUIFontSizing("xxxLarge")).height
        XCTAssertEqual(largest / defaultHeight, AppUIFontSizePreset.xxxLarge.scale, accuracy: 0.15)
    }

    func testSizedFontsScaleToo() {
        let icon = { (preset: AppUIFontSizePreset) in
            self.size(of: Image(systemName: "checkmark.circle").appFont(size: 24).appUIFontSizing(preset.rawValue))
        }
        XCTAssertGreaterThan(icon(.xxxLarge).height, icon(.system).height * 1.4)
        XCTAssertLessThan(icon(.xSmall).height, icon(.system).height)
    }

    private func size<V: View>(of view: V) -> CGSize {
        let host = NSHostingView(rootView: view.fixedSize())
        return host.fittingSize
    }
}
