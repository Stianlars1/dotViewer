import Foundation

/// Generates theme-aware CSS for markdown rendering in WKWebView
enum MarkdownStyles {

    /// Generate CSS for the given theme and font size
    static func css(for theme: String, fontSize: Double, isDark: Bool) -> String {
        let colors = themeColors(for: theme, isDark: isDark)

        return """
        :root {
            --bg-color: \(colors.background);
            --text-color: \(colors.text);
            --heading-color: \(colors.heading);
            --code-bg: \(colors.codeBackground);
            --code-text: \(colors.codeText);
            --link-color: \(colors.link);
            --border-color: \(colors.border);
            --blockquote-color: \(colors.blockquote);
            --font-size: \(fontSize)px;
        }

        * {
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
            font-size: var(--font-size);
            line-height: 1.6;
            color: var(--text-color);
            background: var(--bg-color);
            padding: 24px 32px;
            margin: 0;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }

        #content {
            max-width: 900px;
            margin: 0 auto;
        }

        /* Headings */
        h1, h2, h3, h4, h5, h6 {
            color: var(--heading-color);
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }

        h1 {
            font-size: 2em;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 0.3em;
        }

        h2 {
            font-size: 1.5em;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 0.3em;
        }

        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: 0.875em; }
        h6 { font-size: 0.85em; opacity: 0.8; }

        /* Paragraphs */
        p {
            margin-top: 0;
            margin-bottom: 16px;
        }

        /* Links */
        a {
            color: var(--link-color);
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        /* Inline code */
        code {
            font-family: "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;
            background: var(--code-bg);
            color: var(--code-text);
            padding: 0.2em 0.4em;
            border-radius: 4px;
            font-size: 0.9em;
        }

        /* Code blocks */
        pre {
            background: var(--code-bg);
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            margin: 16px 0;
        }

        pre code {
            background: none;
            padding: 0;
            border-radius: 0;
            font-size: 0.875em;
            line-height: 1.45;
        }

        /* Blockquotes */
        blockquote {
            border-left: 4px solid var(--border-color);
            margin: 16px 0;
            padding: 0 16px;
            color: var(--blockquote-color);
        }

        blockquote > :first-child {
            margin-top: 0;
        }

        blockquote > :last-child {
            margin-bottom: 0;
        }

        /* Lists */
        ul, ol {
            padding-left: 2em;
            margin-top: 0;
            margin-bottom: 16px;
        }

        li {
            margin-bottom: 4px;
        }

        li > p {
            margin-top: 16px;
        }

        li + li {
            margin-top: 4px;
        }

        /* Task lists */
        ul.contains-task-list {
            list-style-type: none;
            padding-left: 0;
        }

        .task-list-item {
            position: relative;
            padding-left: 28px;
        }

        input[type="checkbox"] {
            margin-right: 8px;
            position: absolute;
            left: 0;
            top: 0.3em;
        }

        /* Tables */
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 16px 0;
            overflow: auto;
        }

        th, td {
            border: 1px solid var(--border-color);
            padding: 8px 12px;
            text-align: left;
        }

        th {
            background: var(--code-bg);
            font-weight: 600;
        }

        tr:nth-child(even) {
            background: var(--code-bg);
            opacity: 0.7;
        }

        /* Images */
        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 16px auto;
            border-radius: 4px;
        }

        /* Horizontal rule */
        hr {
            border: none;
            border-top: 2px solid var(--border-color);
            margin: 24px 0;
        }

        /* Strong and emphasis */
        strong {
            font-weight: 600;
        }

        em {
            font-style: italic;
        }

        /* Strikethrough */
        del {
            text-decoration: line-through;
            opacity: 0.7;
        }

        /* Keyboard */
        kbd {
            display: inline-block;
            padding: 3px 5px;
            font-family: "SF Mono", Menlo, Consolas, monospace;
            font-size: 0.85em;
            line-height: 1;
            color: var(--text-color);
            background: var(--code-bg);
            border: 1px solid var(--border-color);
            border-radius: 3px;
            box-shadow: inset 0 -1px 0 var(--border-color);
        }

        /* Definition lists */
        dl {
            margin: 16px 0;
        }

        dt {
            font-weight: 600;
            margin-top: 16px;
        }

        dd {
            margin-left: 2em;
            margin-bottom: 8px;
        }

        /* Center aligned content (HTML) */
        [align="center"] {
            text-align: center;
        }

        [align="right"] {
            text-align: right;
        }

        /* Abbreviations */
        abbr[title] {
            border-bottom: 1px dotted;
            cursor: help;
        }

        /* Details/Summary */
        details {
            margin: 16px 0;
        }

        summary {
            cursor: pointer;
            font-weight: 600;
        }

        /* Mark/highlight */
        mark {
            background: #fff3cd;
            padding: 0.1em 0.2em;
            border-radius: 2px;
        }
        """
    }

    // MARK: - Theme Colors

    private struct ThemeColors {
        let background: String
        let text: String
        let heading: String
        let codeBackground: String
        let codeText: String
        let link: String
        let border: String
        let blockquote: String
    }

    private static func themeColors(for theme: String, isDark: Bool) -> ThemeColors {
        switch theme {
        case "atomOneLight":
            return ThemeColors(
                background: "#fafafa",
                text: "#383a42",
                heading: "#383a42",
                codeBackground: "#f0f0f0",
                codeText: "#383a42",
                link: "#4078c0",
                border: "#e1e4e8",
                blockquote: "#6a737d"
            )

        case "atomOneDark":
            return ThemeColors(
                background: "#282c34",
                text: "#abb2bf",
                heading: "#e5c07b",
                codeBackground: "#2c313a",
                codeText: "#abb2bf",
                link: "#61afef",
                border: "#3e4451",
                blockquote: "#7f848e"
            )

        case "github":
            return ThemeColors(
                background: "#ffffff",
                text: "#24292e",
                heading: "#24292e",
                codeBackground: "#f6f8fa",
                codeText: "#24292e",
                link: "#0366d6",
                border: "#e1e4e8",
                blockquote: "#6a737d"
            )

        case "githubDark":
            return ThemeColors(
                background: "#0d1117",
                text: "#c9d1d9",
                heading: "#c9d1d9",
                codeBackground: "#161b22",
                codeText: "#c9d1d9",
                link: "#58a6ff",
                border: "#30363d",
                blockquote: "#8b949e"
            )

        case "xcode":
            return ThemeColors(
                background: "#ffffff",
                text: "#000000",
                heading: "#000000",
                codeBackground: "#f4f4f4",
                codeText: "#000000",
                link: "#0070c9",
                border: "#d1d1d6",
                blockquote: "#6e6e73"
            )

        case "xcodeDark":
            return ThemeColors(
                background: "#1f1f24",
                text: "#ffffff",
                heading: "#ffffff",
                codeBackground: "#2c2c31",
                codeText: "#ffffff",
                link: "#6ac4ff",
                border: "#48484a",
                blockquote: "#98989f"
            )

        case "solarizedLight":
            return ThemeColors(
                background: "#fdf6e3",
                text: "#657b83",
                heading: "#073642",
                codeBackground: "#eee8d5",
                codeText: "#657b83",
                link: "#268bd2",
                border: "#eee8d5",
                blockquote: "#93a1a1"
            )

        case "solarizedDark":
            return ThemeColors(
                background: "#002b36",
                text: "#839496",
                heading: "#93a1a1",
                codeBackground: "#073642",
                codeText: "#839496",
                link: "#268bd2",
                border: "#073642",
                blockquote: "#586e75"
            )

        case "tokyoNight":
            return ThemeColors(
                background: "#1a1b26",
                text: "#a9b1d6",
                heading: "#c0caf5",
                codeBackground: "#24283b",
                codeText: "#a9b1d6",
                link: "#7aa2f7",
                border: "#3b4261",
                blockquote: "#565f89"
            )

        case "blackout":
            // Typora Blackout-inspired theme
            return ThemeColors(
                background: "#1e1e1e",
                text: "#c6c5b8",
                heading: "#e0dfd3",
                codeBackground: "#292929",
                codeText: "#d4d4d4",
                link: "#ff9100",
                border: "#404040",
                blockquote: "#8c8b80"
            )

        case "auto":
            // Auto mode - use dark or light based on system
            if isDark {
                return themeColors(for: "atomOneDark", isDark: true)
            } else {
                return themeColors(for: "atomOneLight", isDark: false)
            }

        default:
            // Fallback to light theme
            return themeColors(for: "atomOneLight", isDark: false)
        }
    }
}
