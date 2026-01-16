use once_cell::sync::Lazy;
use syntect::highlighting::{FontStyle, Style, ThemeSet};
use syntect::parsing::SyntaxSet;
use syntect::easy::HighlightLines;

// Pre-load syntax and theme sets at startup for performance
static SYNTAX_SET: Lazy<SyntaxSet> = Lazy::new(|| SyntaxSet::load_defaults_newlines());
static THEME_SET: Lazy<ThemeSet> = Lazy::new(ThemeSet::load_defaults);

/// A span of highlighted text with color and style information
#[derive(uniffi::Record)]
pub struct HighlightedSpan {
    /// The text content of this span
    pub text: String,
    /// Foreground color as hex string like "#FF0000"
    pub foreground: String,
    /// Background color as hex string (usually transparent)
    pub background: String,
    /// Font style: 0=normal, 1=bold, 2=italic, 3=bold+italic, 4=underline
    pub font_style: u8,
}

/// Result of highlighting a piece of code
#[derive(uniffi::Record)]
pub struct HighlightResult {
    /// All highlighted spans in order
    pub spans: Vec<HighlightedSpan>,
    /// Theme background color as hex string
    pub background: String,
}

/// Convert a syntect Style's color to hex string
fn color_to_hex(color: syntect::highlighting::Color) -> String {
    format!("#{:02X}{:02X}{:02X}", color.r, color.g, color.b)
}

/// Convert font style flags to a single u8 value
fn font_style_to_u8(style: FontStyle) -> u8 {
    let mut result: u8 = 0;
    if style.contains(FontStyle::BOLD) {
        result |= 1;
    }
    if style.contains(FontStyle::ITALIC) {
        result |= 2;
    }
    if style.contains(FontStyle::UNDERLINE) {
        result |= 4;
    }
    result
}

/// Highlight source code with syntax coloring
///
/// # Arguments
/// * `code` - The source code to highlight
/// * `language` - Language name or file extension (e.g., "swift", "rs", "python")
/// * `theme` - Theme name (e.g., "base16-ocean.dark", "InspiredGitHub")
///
/// # Returns
/// A HighlightResult containing colored spans and background color
#[uniffi::export]
pub fn highlight_code(code: &str, language: &str, theme: &str) -> HighlightResult {
    // Find syntax by name or extension
    let syntax = SYNTAX_SET
        .find_syntax_by_name(language)
        .or_else(|| SYNTAX_SET.find_syntax_by_extension(language))
        .or_else(|| SYNTAX_SET.find_syntax_by_extension(&language.to_lowercase()))
        .unwrap_or_else(|| SYNTAX_SET.find_syntax_plain_text());

    // Get theme, falling back to base16-ocean.dark
    let theme_obj = THEME_SET
        .themes
        .get(theme)
        .or_else(|| THEME_SET.themes.get("base16-ocean.dark"))
        .expect("base16-ocean.dark theme should always exist");

    // Get background color from theme
    let background = theme_obj
        .settings
        .background
        .map(|c| color_to_hex(c))
        .unwrap_or_else(|| "#1e1e1e".to_string());

    let mut highlighter = HighlightLines::new(syntax, theme_obj);
    let mut spans = Vec::new();

    for line in code.lines() {
        // Get highlighted ranges for this line
        let ranges: Vec<(Style, &str)> = highlighter
            .highlight_line(line, &SYNTAX_SET)
            .unwrap_or_default();

        for (style, text) in ranges {
            spans.push(HighlightedSpan {
                text: text.to_string(),
                foreground: color_to_hex(style.foreground),
                background: color_to_hex(style.background),
                font_style: font_style_to_u8(style.font_style),
            });
        }

        // Add newline after each line (except we handle this in display)
        spans.push(HighlightedSpan {
            text: "\n".to_string(),
            foreground: color_to_hex(theme_obj.settings.foreground.unwrap_or(syntect::highlighting::Color { r: 255, g: 255, b: 255, a: 255 })),
            background: background.clone(),
            font_style: 0,
        });
    }

    HighlightResult { spans, background }
}

/// Get list of available language names
#[uniffi::export]
pub fn get_available_languages() -> Vec<String> {
    SYNTAX_SET
        .syntaxes()
        .iter()
        .map(|s| s.name.clone())
        .collect()
}

/// Get list of available theme names
#[uniffi::export]
pub fn get_available_themes() -> Vec<String> {
    THEME_SET.themes.keys().cloned().collect()
}

/// Get background color for a given theme
#[uniffi::export]
pub fn get_theme_background(theme: &str) -> String {
    THEME_SET
        .themes
        .get(theme)
        .and_then(|t| t.settings.background)
        .map(|c| color_to_hex(c))
        .unwrap_or_else(|| "#1e1e1e".to_string())
}

/// Map dotViewer app theme names to Syntect theme names
///
/// dotViewer themes from ThemeManager.swift:
/// - auto, atomOneLight, atomOneDark, github, githubDark
/// - xcode, xcodeDark, solarizedLight, solarizedDark, tokyoNight, blackout
///
/// Syntect default themes:
/// - base16-ocean.dark, base16-ocean.light, base16-mocha.dark
/// - InspiredGitHub, base16-eighties.dark
/// - Solarized (dark), Solarized (light)
#[uniffi::export]
pub fn map_dotviewer_theme(app_theme: &str) -> String {
    match app_theme {
        // Light themes
        "atomOneLight" => "base16-ocean.light".to_string(),
        "github" => "InspiredGitHub".to_string(),
        "xcode" => "base16-ocean.light".to_string(),
        "solarizedLight" => "Solarized (light)".to_string(),

        // Dark themes
        "atomOneDark" => "base16-ocean.dark".to_string(),
        "githubDark" => "base16-ocean.dark".to_string(),
        "xcodeDark" => "base16-eighties.dark".to_string(),
        "solarizedDark" => "Solarized (dark)".to_string(),
        "tokyoNight" => "base16-ocean.dark".to_string(),
        "blackout" => "base16-mocha.dark".to_string(),

        // Auto or default - use dark theme as default
        "auto" | _ => "base16-ocean.dark".to_string(),
    }
}

/// Highlight code using a dotViewer app theme name
///
/// This is a convenience function that maps dotViewer theme names to Syntect themes
/// and then performs highlighting.
#[uniffi::export]
pub fn highlight_code_with_app_theme(code: &str, language: &str, app_theme: &str) -> HighlightResult {
    let syntect_theme = map_dotviewer_theme(app_theme);
    highlight_code(code, language, &syntect_theme)
}

/// Get the background color for a dotViewer app theme
#[uniffi::export]
pub fn get_app_theme_background(app_theme: &str) -> String {
    let syntect_theme = map_dotviewer_theme(app_theme);
    get_theme_background(&syntect_theme)
}

// UniFFI scaffolding - generates the FFI bindings
uniffi::setup_scaffolding!();

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_highlight_rust_code() {
        let code = "fn main() {}";
        let result = highlight_code(code, "Rust", "base16-ocean.dark");

        assert!(!result.spans.is_empty(), "Should produce spans");
        assert!(!result.background.is_empty(), "Should have background color");

        // Check that "fn" keyword is highlighted
        let has_fn = result.spans.iter().any(|s| s.text.contains("fn"));
        assert!(has_fn, "Should contain 'fn' keyword");
    }

    #[test]
    fn test_get_available_languages() {
        let languages = get_available_languages();
        assert!(!languages.is_empty(), "Should have languages");
        assert!(languages.iter().any(|l| l == "Rust"), "Should include Rust");
        // Check for common languages (syntect may have different naming)
        assert!(languages.len() > 50, "Should have many languages (has {})", languages.len());
    }

    #[test]
    fn test_highlight_swift_code() {
        // Test Swift code highlighting (by extension since name may vary)
        let code = "func hello() { print(\"Hello\") }";
        let result = highlight_code(code, "swift", "base16-ocean.dark");

        assert!(!result.spans.is_empty(), "Should produce spans for Swift code");
        // Check that "func" keyword is somewhere in the output
        let has_func = result.spans.iter().any(|s| s.text.contains("func"));
        assert!(has_func, "Should contain 'func' keyword");
    }

    #[test]
    fn test_get_available_themes() {
        let themes = get_available_themes();
        assert!(!themes.is_empty(), "Should have themes");
        assert!(themes.iter().any(|t| t == "base16-ocean.dark"), "Should include base16-ocean.dark");
    }

    #[test]
    fn test_plain_text_fallback() {
        let code = "hello world";
        let result = highlight_code(code, "nonexistent_language", "base16-ocean.dark");

        assert!(!result.spans.is_empty(), "Should still produce spans for unknown language");
    }

    #[test]
    fn test_theme_mapping() {
        // Test light themes
        assert_eq!(map_dotviewer_theme("atomOneLight"), "base16-ocean.light");
        assert_eq!(map_dotviewer_theme("github"), "InspiredGitHub");
        assert_eq!(map_dotviewer_theme("solarizedLight"), "Solarized (light)");

        // Test dark themes
        assert_eq!(map_dotviewer_theme("atomOneDark"), "base16-ocean.dark");
        assert_eq!(map_dotviewer_theme("solarizedDark"), "Solarized (dark)");
        assert_eq!(map_dotviewer_theme("blackout"), "base16-mocha.dark");

        // Test auto/default
        assert_eq!(map_dotviewer_theme("auto"), "base16-ocean.dark");
        assert_eq!(map_dotviewer_theme("unknown_theme"), "base16-ocean.dark");
    }

    #[test]
    fn test_highlight_with_app_theme() {
        let code = "fn main() {}";

        // Test with dotViewer theme names
        let result_dark = highlight_code_with_app_theme(code, "Rust", "atomOneDark");
        assert!(!result_dark.spans.is_empty(), "Should produce spans with app theme");
        assert!(!result_dark.background.is_empty(), "Should have background");

        let result_light = highlight_code_with_app_theme(code, "Rust", "atomOneLight");
        assert!(!result_light.spans.is_empty(), "Should produce spans with light theme");

        // Background colors should be different for dark vs light themes
        assert_ne!(result_dark.background, result_light.background,
            "Dark and light themes should have different backgrounds");
    }

    #[test]
    fn test_app_theme_background() {
        // Dark themes should have dark backgrounds
        let dark_bg = get_app_theme_background("atomOneDark");
        assert!(dark_bg.starts_with("#"), "Background should be hex color");

        // Light themes should have light backgrounds
        let light_bg = get_app_theme_background("atomOneLight");
        assert!(light_bg.starts_with("#"), "Background should be hex color");

        // They should be different
        assert_ne!(dark_bg, light_bg, "Dark and light backgrounds should differ");
    }
}
