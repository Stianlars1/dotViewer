import Foundation

public struct PreviewInfo {
    public let title: String
    public let language: String
    public let lineCount: Int
    public let fileSizeBytes: Int
    public let isTruncated: Bool
    public let showTruncationWarning: Bool
    public let showHeader: Bool
    public let isSensitive: Bool
    public let rawText: String
    public let rawHTML: String
    public let renderedHTML: String?
    public let codeFontSize: Double
    public let defaultMarkdownMode: String
    public let markdownRenderFontSize: Double
    public let markdownShowInlineImages: Bool
    public let markdownCustomCSS: String
    public let markdownCustomCSSOverride: Bool
    public let themeName: String
    public let showUnknownTextWarning: Bool
    public let showBinaryWarning: Bool
    public let systemIsDark: Bool
    public let wordWrap: Bool
    public let markdownShowTOC: Bool

    public init(
        title: String,
        language: String,
        lineCount: Int,
        fileSizeBytes: Int,
        isTruncated: Bool,
        showTruncationWarning: Bool,
        showHeader: Bool,
        isSensitive: Bool,
        rawText: String,
        rawHTML: String,
        renderedHTML: String?,
        codeFontSize: Double,
        defaultMarkdownMode: String,
        markdownRenderFontSize: Double,
        markdownShowInlineImages: Bool,
        markdownCustomCSS: String,
        markdownCustomCSSOverride: Bool,
        themeName: String,
        showUnknownTextWarning: Bool,
        showBinaryWarning: Bool,
        systemIsDark: Bool = false,
        wordWrap: Bool = false,
        markdownShowTOC: Bool = false
    ) {
        self.title = title
        self.language = language
        self.lineCount = lineCount
        self.fileSizeBytes = fileSizeBytes
        self.isTruncated = isTruncated
        self.showTruncationWarning = showTruncationWarning
        self.showHeader = showHeader
        self.isSensitive = isSensitive
        self.rawText = rawText
        self.rawHTML = rawHTML
        self.renderedHTML = renderedHTML
        self.codeFontSize = codeFontSize
        self.defaultMarkdownMode = defaultMarkdownMode
        self.markdownRenderFontSize = markdownRenderFontSize
        self.markdownShowInlineImages = markdownShowInlineImages
        self.markdownCustomCSS = markdownCustomCSS
        self.markdownCustomCSSOverride = markdownCustomCSSOverride
        self.themeName = themeName
        self.showUnknownTextWarning = showUnknownTextWarning
        self.showBinaryWarning = showBinaryWarning
        self.systemIsDark = systemIsDark
        self.wordWrap = wordWrap
        self.markdownShowTOC = markdownShowTOC
    }
}

public enum PreviewHTMLBuilder {
    public static func buildHTML(info: PreviewInfo, palette: ThemePalette) -> String {
        let header = info.showHeader ? buildHeader(info: info, palette: palette) : ""
        let warnings = buildWarnings(info: info)
        let defaultRendered = info.defaultMarkdownMode == "rendered"
        let rawStyle = info.renderedHTML != nil && defaultRendered ? " style=\"display:none;\"" : ""
        let renderedStyle = info.renderedHTML != nil && !defaultRendered ? " style=\"display:none;\"" : ""
        let rawSection = "<div id=\"raw-view\" class=\"code-view\"\(rawStyle)>\(info.rawHTML)</div>"
        let renderedSection = info.renderedHTML != nil
            ? "<div id=\"rendered-view\" class=\"rendered-view\"\(renderedStyle)>\(info.renderedHTML!)</div>"
            : ""

        let tocHTML: String
        if info.renderedHTML != nil && info.markdownShowTOC {
            tocHTML = MarkdownRenderer.generateTOC(from: info.rawText) ?? ""
        } else {
            tocHTML = ""
        }
        let tocSection = tocHTML.isEmpty ? "" : """
        <aside id="toc-panel" class="toc-sidebar" style="display:none;">
          <div class="toc-header">
            <span class="toc-title">Contents</span>
          </div>
          <div class="toc-content">\(tocHTML)</div>
        </aside>
        """

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <style>
          \(buildCSS(info: info, palette: palette))
          </style>
        </head>
        <body>
          \(header)
          \(warnings)
          <div class="main-layout">
            \(tocSection)
            <div class="content">
              \(rawSection)
              \(renderedSection)
            </div>
          </div>
          <div id="toast" class="toast">Copied</div>
          <textarea id="raw-source" class="hidden">\(escapeHTML(info.rawText))</textarea>
          <script>
          \(buildScript(defaultMode: info.defaultMarkdownMode, hasRendered: info.renderedHTML != nil))
          </script>
        </body>
        </html>
        """
    }

    private static func buildHeader(info: PreviewInfo, palette: ThemePalette) -> String {
        let sizeText = ByteCountFormatter.string(fromByteCount: Int64(info.fileSizeBytes), countStyle: .file)
        let lineText = "\(info.lineCount) lines"
        let markdownToggle = info.renderedHTML != nil ? buildMarkdownToggle(defaultMode: info.defaultMarkdownMode) : ""
        let tocToggle = info.renderedHTML != nil ? buildTOCToggle(showTOC: info.markdownShowTOC) : ""
        return """
        <div class="header">
          <div class="header-left">
            <span class="badge">\(info.language)</span>
            <span class="meta">\(lineText) • \(sizeText)</span>
          </div>
          <div class="header-right">
            \(markdownToggle)
            \(tocToggle)
            <button class="icon-button" id="copy-button" title="Copy to clipboard" aria-label="Copy to clipboard">
              <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                <path d="M16 4a2 2 0 0 1 2 2v8.5a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h7zm0 1.5H9a.5.5 0 0 0-.5.5v8.5a.5.5 0 0 0 .5.5h7a.5.5 0 0 0 .5-.5V6a.5.5 0 0 0-.5-.5z"/>
                <path d="M7 8H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h7a2 2 0 0 0 2-2v-1h-1.5v1a.5.5 0 0 1-.5.5H6a.5.5 0 0 1-.5-.5v-8A.5.5 0 0 1 6 9h1V8z"/>
              </svg>
            </button>
          </div>
        </div>
        """
    }

    private static func buildWarnings(info: PreviewInfo) -> String {
        var banners: [String] = []

        if info.isSensitive {
            banners.append("<div class=\"banner warning\">Sensitive file detected — handle with care.</div>")
        }

        if info.showUnknownTextWarning {
            banners.append("<div class=\"banner neutral\">Unknown type — showing as text.</div>")
        }

        if info.showBinaryWarning {
            banners.append("<div class=\"banner warning\">Binary or unknown type — preview may be unreliable.</div>")
        }

        if info.isTruncated && info.showTruncationWarning {
            banners.append("<div class=\"banner info\">Preview truncated to the maximum file size.</div>")
        }

        return banners.joined()
    }

    private static func buildMarkdownToggle(defaultMode: String) -> String {
        let rawActive = defaultMode == "rendered" ? "" : "active"
        let renderedActive = defaultMode == "rendered" ? "active" : ""
        return """
        <div class="toggle-bar header-toggle">
          <button class="toggle-button \(rawActive)" data-mode="raw">RAW</button>
          <button class="toggle-button \(renderedActive)" data-mode="rendered">RENDERED</button>
        </div>
        """
    }

    private static func buildTOCToggle(showTOC: Bool) -> String {
        return """
        <button class="icon-button toc-toggle active" id="toc-toggle" title="Table of Contents" aria-label="Toggle table of contents">
          <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
            <path d="M3 4h18v2H3V4zm0 7h12v2H3v-2zm0 7h18v2H3v-2zm14-7h4v2h-4v-2z"/>
          </svg>
        </button>
        """
    }

    private static func buildCSS(info: PreviewInfo, palette: ThemePalette) -> String {
        let codeFontSize = Int(info.codeFontSize)
        let renderFontSize = Int(info.markdownRenderFontSize)
        let inlineImagesCSS = info.markdownShowInlineImages
            ? ""
            : ".rendered-view img { display: none; }"
        let customCSS = info.markdownCustomCSS.trimmingCharacters(in: .whitespacesAndNewlines)
        if info.markdownCustomCSSOverride && !customCSS.isEmpty {
            return customCSS
        }

        func cssVariables(for palette: ThemePalette) -> String {
            """
              --bg: \(palette.background);
              --text: \(palette.text);
              --comment: \(palette.comment);
              --keyword: \(palette.keyword);
              --string: \(palette.string);
              --number: \(palette.number);
              --type: \(palette.type);
              --function: \(palette.function);
              --property: \(palette.property);
              --punctuation: \(palette.punctuation);
              --accent: \(palette.accent);
              --tag: \(palette.tag);
              --attribute: \(palette.attribute);
              --escape: \(palette.escape);
              --builtin: \(palette.builtin);
              --namespace: \(palette.namespace);
              --parameter: \(palette.parameter);
              --heading: \(palette.isDark ? palette.type : palette.text);
              --gutter: \(palette.isDark ? "#3B3F51" : "#C0C4CC");
              --header: \(palette.isDark ? "#1F232B" : "#F2F3F5");
              --surface: \(palette.isDark ? "#1E222A" : "#F5F7FA");
              --surface-strong: \(palette.isDark ? "#2B303B" : "#E9EDF2");
              --border: \(palette.isDark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.08)");
              --link: \(palette.accent);
            """
        }

        let basePalette = info.themeName == "auto"
            ? (info.systemIsDark ? ThemePalette.atomOneDark : ThemePalette.atomOneLight)
            : palette
        var baseCSS = """
        :root {
        \(cssVariables(for: basePalette))
        }

        *, *::before, *::after {
          box-sizing: border-box;
        }

        html, body {
          width: 100%;
          height: 100%;
        }

        body {
          margin: 0;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: var(--bg);
          color: var(--text);
          -webkit-font-smoothing: antialiased;
          -moz-osx-font-smoothing: grayscale;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }

        .main-layout {
          display: flex;
          flex: 1;
          min-height: 0;
          overflow: hidden;
        }

        .header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 8px 12px;
          background: var(--header);
          border-bottom: 1px solid rgba(0,0,0,0.08);
          position: sticky;
          top: 0;
          z-index: 2;
        }

        .header-right {
          display: inline-flex;
          align-items: center;
          gap: 6px;
        }

        .badge {
          background: rgba(0,122,255,0.2);
          color: var(--accent);
          padding: 2px 6px;
          border-radius: 999px;
          font-size: 11px;
          font-weight: 600;
          margin-right: 6px;
        }

        .meta {
          font-size: 11px;
          color: var(--comment);
        }

        .icon-button {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          background: transparent;
          border: 1px solid transparent;
          border-radius: 8px;
          cursor: pointer;
          width: 26px;
          height: 26px;
          padding: 0;
          color: var(--text);
        }

        .icon-button svg {
          width: 16px;
          height: 16px;
          fill: currentColor;
        }

        .icon-button:hover {
          background: var(--surface-strong);
          border-color: var(--border);
        }

        .icon-button:active {
          transform: scale(0.98);
        }

        .banner {
          margin: 10px 12px 0;
          padding: 8px 10px;
          border-radius: 8px;
          font-size: 12px;
        }

        .banner.warning {
          background: rgba(255,59,48,0.15);
          color: #FF3B30;
        }

        .banner.info {
          background: rgba(0,122,255,0.15);
          color: var(--accent);
        }

        .banner.neutral {
          background: var(--surface-strong);
          color: var(--text);
          border: 1px solid var(--border);
        }

        .content {
          flex: 1;
          min-width: 0;
          padding: 12px;
          background: var(--bg);
          overflow-y: auto;
        }

        .toggle-bar {
          display: inline-flex;
          background: rgba(127,127,127,0.2);
          border-radius: 10px;
          padding: 2px;
        }

        .header-toggle {
          margin-right: 2px;
        }

        .toggle-button {
          border: none;
          background: transparent;
          color: var(--text);
          padding: 4px 8px;
          border-radius: 8px;
          font-size: 11px;
          cursor: pointer;
        }

        .toggle-button.active {
          background: var(--accent);
          color: white;
        }

        .code-view {
          font-family: "SF Mono", Menlo, Monaco, monospace;
          font-size: \(codeFontSize)px;
          color: var(--text);
          line-height: 1.45;
        }

        .line {
          display: flex;
        }

        .ln {
          width: 32px;
          text-align: right;
          padding-right: 8px;
          color: var(--gutter);
          user-select: none;
          font-size: 11px;
        }

        .code-line {
          white-space: \(info.wordWrap ? "pre-wrap" : "pre");
          \(info.wordWrap ? "word-break: break-word; overflow-wrap: break-word;" : "")
          flex: 1;
        }

        pre.code {
          white-space: \(info.wordWrap ? "pre-wrap" : "pre");
          \(info.wordWrap ? "word-break: break-word; overflow-wrap: break-word;" : "")
          margin: 0;
        }

        .tok-comment { color: var(--comment); }
        .tok-keyword { color: var(--keyword); }
        .tok-string { color: var(--string); }
        .tok-number { color: var(--number); }
        .tok-type { color: var(--type); }
        .tok-function { color: var(--function); }
        .tok-property { color: var(--property); }
        .tok-constant { color: var(--number); }
        .tok-identifier { color: var(--text); }
        .tok-punctuation { color: var(--punctuation); }
        .tok-tag { color: var(--tag); }
        .tok-attribute { color: var(--attribute); }
        .tok-escape { color: var(--escape); }
        .tok-builtin { color: var(--builtin); font-style: italic; }
        .tok-namespace { color: var(--namespace); }
        .tok-parameter { color: var(--parameter); font-style: italic; }

        .rendered-view {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
          line-height: 1.7;
          font-size: \(renderFontSize)px;
          color: var(--text);
          background: transparent;
          border: none;
          box-shadow: none;
          max-width: 900px;
          margin: 0 auto;
          padding: 24px 32px;
        }

        /* Typora-inspired Typography */
        .rendered-view h1,
        .rendered-view h2,
        .rendered-view h3,
        .rendered-view h4,
        .rendered-view h5,
        .rendered-view h6 {
          color: var(--heading);
          font-weight: 600;
          line-height: 1.25;
          margin-top: 24px;
          margin-bottom: 12px;
          letter-spacing: -0.02em;
        }

        .rendered-view h1 {
          font-size: 2em;
          font-weight: 700;
          margin-top: 0.67em;
          padding-bottom: 0.3em;
          border-bottom: 1px solid var(--border);
        }

        .rendered-view h2 {
          font-size: 1.5em;
          font-weight: 700;
          margin-top: 1.5em;
          padding-bottom: 0.3em;
          border-bottom: 1px solid var(--border);
        }

        .rendered-view h3 {
          font-size: 1.25em;
          margin-top: 1.25em;
        }

        .rendered-view h4 {
          font-size: 1em;
        }

        .rendered-view h5 {
          font-size: 0.875em;
          font-weight: 600;
        }

        .rendered-view h6 {
          font-size: 0.85em;
          font-weight: 600;
          opacity: 0.8;
        }

        .rendered-view p {
          margin-top: 0;
          margin-bottom: 12px;
        }

        .rendered-view a {
          color: var(--link);
          text-decoration: none;
        }

        .rendered-view a:hover {
          text-decoration: underline;
        }

        /* Inline code */
        .rendered-view code {
          font-family: "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;
          font-size: 0.9em;
          background: var(--surface);
          color: var(--accent);
          padding: 0.2em 0.4em;
          border-radius: 4px;
        }

        /* Code blocks */
        .rendered-view pre {
          background: var(--surface);
          padding: 16px;
          border-radius: 6px;
          border-left: 3px solid var(--accent);
          overflow-x: auto;
          margin: 16px 0;
          line-height: 1.45;
          position: relative;
        }

        .rendered-view pre code {
          background: none;
          border: none;
          padding: 0;
          border-radius: 0;
          color: var(--text);
          font-size: 0.875em;
        }

        .rendered-view pre .code-lang {
          position: absolute;
          top: 6px;
          right: 10px;
          font-size: 0.75em;
          color: var(--comment);
          font-family: -apple-system, BlinkMacSystemFont, sans-serif;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          user-select: none;
          opacity: 0.7;
        }

        /* Blockquotes */
        .rendered-view blockquote {
          border-left: 4px solid var(--accent);
          margin: 16px 0;
          padding: 4px 16px;
          color: var(--comment);
          background: var(--surface);
          border-radius: 0 4px 4px 0;
        }

        .rendered-view blockquote > :first-child {
          margin-top: 0;
        }

        .rendered-view blockquote > :last-child {
          margin-bottom: 0;
        }

        /* Lists */
        .rendered-view ul,
        .rendered-view ol {
          padding-left: 2em;
          margin-top: 0;
          margin-bottom: 16px;
        }

        .rendered-view li {
          margin-bottom: 2px;
        }

        .rendered-view li + li {
          margin-top: 2px;
        }

        .rendered-view li > p {
          margin-top: 16px;
        }

        .rendered-view ul ul,
        .rendered-view ol ol,
        .rendered-view ul ol,
        .rendered-view ol ul {
          margin-top: 4px;
          margin-bottom: 4px;
        }

        /* Task list items */
        .rendered-view .task-item {
          list-style: none;
          margin-left: -1.4em;
        }

        .rendered-view .task-item input[type="checkbox"] {
          margin-right: 0.4em;
          vertical-align: middle;
          accent-color: var(--accent);
        }

        /* Tables */
        .rendered-view table {
          border-collapse: collapse;
          width: 100%;
          margin: 16px 0;
          overflow: auto;
        }

        .rendered-view th,
        .rendered-view td {
          border: 1px solid var(--border);
          padding: 8px 12px;
          text-align: left;
        }

        .rendered-view th {
          font-weight: 600;
          background: var(--surface);
        }

        .rendered-view tr:nth-child(even) {
          background: var(--surface);
        }

        /* Images */
        .rendered-view img {
          max-width: 100%;
          height: auto;
          display: block;
          margin: 16px auto;
          border-radius: 4px;
        }

        /* Horizontal rule */
        .rendered-view hr {
          border: none;
          border-top: 1px solid var(--border);
          margin: 24px 0;
        }

        /* Details/Summary */
        .rendered-view details {
          margin: 16px 0;
        }

        .rendered-view summary {
          cursor: pointer;
          font-weight: 600;
        }

        /* Text formatting */
        .rendered-view strong {
          font-weight: 700;
          color: var(--text);
        }

        .rendered-view em {
          font-style: italic;
        }

        .rendered-view del {
          text-decoration: line-through;
          opacity: 0.7;
        }

        .rendered-view mark {
          background: rgba(255, 200, 0, 0.3);
          color: inherit;
          padding: 0.1em 0.2em;
          border-radius: 2px;
        }

        /* Keyboard shortcuts */
        .rendered-view kbd {
          font-family: "SF Mono", Menlo, monospace;
          font-size: 0.85em;
          padding: 2px 6px;
          border: 1px solid var(--border);
          border-bottom-width: 2px;
          border-radius: 4px;
          background: var(--surface);
          color: var(--text);
          white-space: nowrap;
        }

        /* Definition lists */
        .rendered-view dl {
          margin: 1em 0;
        }

        .rendered-view dt {
          font-weight: 600;
          margin-top: 0.8em;
        }

        .rendered-view dd {
          margin-left: 1.5em;
          margin-bottom: 0.5em;
        }

        /* Abbreviations */
        .rendered-view abbr[title] {
          text-decoration: underline dotted;
          cursor: help;
        }

        /* Align support */
        .rendered-view [align="center"] {
          text-align: center;
        }

        .rendered-view [align="right"] {
          text-align: right;
        }

        .hidden {
          display: none;
        }

        .toast {
          position: fixed;
          right: 12px;
          bottom: 12px;
          padding: 6px 10px;
          border-radius: 8px;
          background: var(--surface-strong);
          color: var(--text);
          border: 1px solid var(--border);
          font-size: 12px;
          opacity: 0;
          transform: translateY(6px);
          transition: opacity 0.2s ease, transform 0.2s ease;
          pointer-events: none;
        }

        .toast.show {
          opacity: 1;
          transform: translateY(0);
        }

        .toc-sidebar {
          width: 220px;
          flex-shrink: 0;
          background: var(--surface);
          border-right: 1px solid var(--border);
          overflow-y: auto;
          font-size: 13px;
        }

        .toc-header {
          padding: 10px 12px;
          font-size: 11px;
          font-weight: 600;
          color: var(--comment);
          text-transform: uppercase;
          letter-spacing: 0.05em;
          border-bottom: 1px solid var(--border);
          position: sticky;
          top: 0;
          background: var(--surface);
        }

        .toc-content {
          padding: 6px 0;
        }

        .toc-content ul {
          list-style: none;
          margin: 0;
          padding: 0;
        }

        .toc-content li {
          margin: 0;
        }

        .toc-content a {
          display: block;
          padding: 3px 10px 3px 12px;
          color: var(--text);
          text-decoration: none;
          font-size: 12px;
          line-height: 1.4;
          transition: background 0.15s ease, color 0.15s ease;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .toc-content a:hover {
          background: var(--surface-strong);
          color: var(--accent);
        }

        .toc-content .toc-h1 a { font-weight: 600; }
        .toc-content .toc-h2 a { padding-left: 22px; }
        .toc-content .toc-h3 a { padding-left: 34px; font-size: 11px; }
        .toc-content .toc-h4 a { padding-left: 44px; font-size: 11px; opacity: 0.8; }
        .toc-content .toc-h5 a { padding-left: 54px; font-size: 11px; opacity: 0.7; }
        .toc-content .toc-h6 a { padding-left: 64px; font-size: 11px; opacity: 0.6; }

        .toc-toggle.active {
          background: var(--surface-strong);
          border-color: var(--border);
        }
        """
        if info.themeName == "auto" {
            let darkPalette = ThemePalette.atomOneDark
            baseCSS += """

            @media (prefers-color-scheme: dark) {
              :root {
            \(cssVariables(for: darkPalette))
              }
            }
            """
        }
        if !inlineImagesCSS.isEmpty {
            baseCSS += "\n" + inlineImagesCSS
        }
        if !customCSS.isEmpty {
            baseCSS += "\n" + customCSS
        }
        return baseCSS
    }

    private static func buildScript(defaultMode: String, hasRendered: Bool) -> String {
        guard hasRendered else {
            return """
            const copyButton = document.getElementById('copy-button');
            const toast = document.getElementById('toast');
            let toastTimer = null;

            function showToast(message) {
              if (!toast) return;
              toast.textContent = message;
              toast.classList.add('show');
              if (toastTimer) clearTimeout(toastTimer);
              toastTimer = setTimeout(() => toast.classList.remove('show'), 1200);
            }

            function writeClipboard(text) {
              if (navigator.clipboard && navigator.clipboard.writeText) {
                return navigator.clipboard.writeText(text);
              }
              return new Promise(resolve => {
                const textarea = document.createElement('textarea');
                textarea.value = text;
                textarea.style.position = 'fixed';
                textarea.style.opacity = '0';
                document.body.appendChild(textarea);
                textarea.focus();
                textarea.select();
                try { document.execCommand('copy'); } catch (e) {}
                document.body.removeChild(textarea);
                resolve();
              });
            }

            copyButton?.addEventListener('click', () => {
              const sel = window.getSelection().toString();
              if (sel.length > 0) {
                writeClipboard(sel).then(() => showToast('Copied selection'));
              } else {
                const text = document.getElementById('raw-source')?.value || '';
                writeClipboard(text).then(() => showToast('Copied'));
              }
            });

            document.addEventListener('copy', function(e) {
              const sel = window.getSelection().toString();
              if (sel.length > 0) {
                e.clipboardData.setData('text/plain', sel);
                e.preventDefault();
                showToast('Copied selection');
              }
            });

            document.addEventListener('selectionchange', () => {
              const sel = window.getSelection().toString();
              if (copyButton) {
                copyButton.title = sel.length > 0 ? 'Copy selection' : 'Copy to clipboard';
              }
            });
            """
        }

        return """
        const rawView = document.getElementById('raw-view');
        const renderedView = document.getElementById('rendered-view');
        const buttons = document.querySelectorAll('.toggle-button');
        const copyButton = document.getElementById('copy-button');
        const toast = document.getElementById('toast');
        let toastTimer = null;
        let currentMode = '\(defaultMode == "rendered" ? "rendered" : "raw")';

        function showToast(message) {
          if (!toast) return;
          toast.textContent = message;
          toast.classList.add('show');
          if (toastTimer) clearTimeout(toastTimer);
          toastTimer = setTimeout(() => toast.classList.remove('show'), 1200);
        }

        function writeClipboard(text) {
          if (navigator.clipboard && navigator.clipboard.writeText) {
            return navigator.clipboard.writeText(text);
          }
          return new Promise(resolve => {
            const textarea = document.createElement('textarea');
            textarea.value = text;
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';
            document.body.appendChild(textarea);
            textarea.focus();
            textarea.select();
            try { document.execCommand('copy'); } catch (e) {}
            document.body.removeChild(textarea);
            resolve();
          });
        }

        function setMode(mode) {
          currentMode = mode;
          buttons.forEach(btn => {
            const isActive = btn.dataset.mode === mode;
            btn.classList.toggle('active', isActive);
          });

          if (mode === 'rendered') {
            if (rawView) rawView.style.display = 'none';
            if (renderedView) renderedView.style.display = 'block';
          } else {
            if (rawView) rawView.style.display = 'block';
            if (renderedView) renderedView.style.display = 'none';
          }

          const tocPanel = document.getElementById('toc-panel');
          const tocToggle = document.getElementById('toc-toggle');
          if (tocToggle) {
            tocToggle.style.display = mode === 'rendered' ? '' : 'none';
          }
          if (tocPanel) {
            tocPanel.style.display = mode === 'rendered' && tocToggle?.classList.contains('active') ? 'block' : 'none';
          }
        }

        buttons.forEach(btn => {
          btn.addEventListener('click', () => setMode(btn.dataset.mode));
        });

        setMode(currentMode);

        const tocToggle = document.getElementById('toc-toggle');
        const tocPanel = document.getElementById('toc-panel');

        if (tocToggle && tocPanel) {
          tocToggle.addEventListener('click', function() {
            if (currentMode !== 'rendered') return;
            const isVisible = tocPanel.style.display !== 'none';
            tocPanel.style.display = isVisible ? 'none' : 'block';
            tocToggle.classList.toggle('active', !isVisible);
          });

          tocPanel.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
              e.preventDefault();
              const targetId = e.target.getAttribute('href').substring(1);
              const target = document.getElementById(targetId);
              if (target) {
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
              }
            }
          });
        }

        copyButton?.addEventListener('click', () => {
          const sel = window.getSelection().toString();
          if (sel.length > 0) {
            writeClipboard(sel).then(() => showToast('Copied selection'));
          } else {
            let text = '';
            if (currentMode === 'rendered' && renderedView) {
              text = renderedView.innerText || '';
            } else {
              text = document.getElementById('raw-source')?.value || '';
            }
            writeClipboard(text).then(() => showToast('Copied'));
          }
        });

        document.addEventListener('copy', function(e) {
          const sel = window.getSelection().toString();
          if (sel.length > 0) {
            e.clipboardData.setData('text/plain', sel);
            e.preventDefault();
            showToast('Copied selection');
          }
        });

        document.addEventListener('selectionchange', () => {
          const sel = window.getSelection().toString();
          if (copyButton) {
            copyButton.title = sel.length > 0 ? 'Copy selection' : 'Copy to clipboard';
          }
        });
        """
    }

    private static func escapeHTML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        return escaped
    }
}
