import XCTest
@testable import Shared

final class ThemePaletteTests: XCTestCase {

    // MARK: - All Themes

    static let allThemes: [ThemePalette] = [
        .atomOneLight, .atomOneDark,
        .githubLight, .githubDark,
        .xcodeLight, .xcodeDark,
        .solarizedLight, .solarizedDark,
        .tokyoNight, .blackout,
    ]

    static let themeNames: [String] = [
        "atomOneLight", "atomOneDark",
        "githubLight", "githubDark",
        "xcodeLight", "xcodeDark",
        "solarizedLight", "solarizedDark",
        "tokyoNight", "blackout",
    ]

    // MARK: - Token Coverage

    func testAllThemesHaveNonEmptyColorsForAllTokens() {
        for theme in Self.allThemes {
            for token in TokenType.allCases {
                let hex = theme.hex(for: token)
                XCTAssertFalse(hex.isEmpty, "\(theme.name) has empty color for \(token.rawValue)")
                XCTAssertTrue(hex.hasPrefix("#"), "\(theme.name) color for \(token.rawValue) doesn't start with #: \(hex)")
            }
        }
    }

    func testAllThemesHaveValidHexColors() {
        let hexPattern = try! NSRegularExpression(pattern: "^#[0-9A-Fa-f]{6}$")

        for theme in Self.allThemes {
            let colors = [
                ("background", theme.background),
                ("text", theme.text),
                ("comment", theme.comment),
                ("keyword", theme.keyword),
                ("string", theme.string),
                ("number", theme.number),
                ("type", theme.type),
                ("function", theme.function),
                ("property", theme.property),
                ("punctuation", theme.punctuation),
                ("accent", theme.accent),
                ("tag", theme.tag),
                ("attribute", theme.attribute),
                ("escape", theme.escape),
                ("builtin", theme.builtin),
                ("namespace", theme.namespace),
                ("parameter", theme.parameter),
            ]
            for (name, color) in colors {
                let range = NSRange(color.startIndex..., in: color)
                XCTAssertNotNil(
                    hexPattern.firstMatch(in: color, range: range),
                    "\(theme.name).\(name) is not valid hex: '\(color)'"
                )
            }
        }
    }

    // MARK: - Dark/Light Classification

    func testLightThemesAreLight() {
        XCTAssertFalse(ThemePalette.atomOneLight.isDark)
        XCTAssertFalse(ThemePalette.githubLight.isDark)
        XCTAssertFalse(ThemePalette.xcodeLight.isDark)
        XCTAssertFalse(ThemePalette.solarizedLight.isDark)
    }

    func testDarkThemesAreDark() {
        XCTAssertTrue(ThemePalette.atomOneDark.isDark)
        XCTAssertTrue(ThemePalette.githubDark.isDark)
        XCTAssertTrue(ThemePalette.xcodeDark.isDark)
        XCTAssertTrue(ThemePalette.solarizedDark.isDark)
        XCTAssertTrue(ThemePalette.tokyoNight.isDark)
        XCTAssertTrue(ThemePalette.blackout.isDark)
    }

    // MARK: - Palette Selection

    func testPaletteForAutoThemeDark() {
        let palette = ThemePalette.palette(for: "auto", systemIsDark: true)
        XCTAssertTrue(palette.isDark)
        XCTAssertEqual(palette.name, ThemePalette.atomOneDark.name)
    }

    func testPaletteForAutoThemeLight() {
        let palette = ThemePalette.palette(for: "auto", systemIsDark: false)
        XCTAssertFalse(palette.isDark)
        XCTAssertEqual(palette.name, ThemePalette.atomOneLight.name)
    }

    func testPaletteForSpecificTheme() {
        for name in Self.themeNames {
            let palette = ThemePalette.palette(for: name, systemIsDark: false)
            XCTAssertFalse(palette.name.isEmpty, "Theme '\(name)' returned empty palette name")
        }
    }

    func testPaletteForUnknownThemeFallsBack() {
        let palette = ThemePalette.palette(for: "nonexistent", systemIsDark: true)
        XCTAssertTrue(palette.isDark)
        XCTAssertEqual(palette.name, ThemePalette.atomOneDark.name)
    }

    // MARK: - TokenType Enum

    func testTokenTypeAllCasesNotEmpty() {
        XCTAssertGreaterThan(TokenType.allCases.count, 10)
    }

    func testSemanticAliases() {
        let theme = ThemePalette.atomOneDark
        // constant uses number color
        XCTAssertEqual(theme.hex(for: .constant), theme.number)
        // identifier uses text color
        XCTAssertEqual(theme.hex(for: .identifier), theme.text)
    }
}
