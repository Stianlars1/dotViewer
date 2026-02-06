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
        wordWrap: Bool = false
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
          <div class="content">
            \(rawSection)
            \(renderedSection)
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
        return """
        <div class="header">
          <div class="header-left">
            <span class="badge">\(info.language)</span>
            <span class="meta">\(lineText) • \(sizeText)</span>
          </div>
          <div class="header-right">
            \(markdownToggle)
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

        html, body {
          width: 100%;
          height: 100%;
        }

        body {
          margin: 0;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: var(--bg);
          color: var(--text);
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
          padding: 12px;
          background: var(--bg);
          border: none;
          box-shadow: none;
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
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          line-height: 1.6;
          font-size: \(renderFontSize)px;
          color: var(--text);
          background: transparent;
          border: none;
          box-shadow: none;
        }

        .rendered-view h1,
        .rendered-view h2,
        .rendered-view h3,
        .rendered-view h4,
        .rendered-view h5,
        .rendered-view h6 {
          color: var(--text);
          margin-top: 1.2em;
          margin-bottom: 0.5em;
        }

        .rendered-view h1,
        .rendered-view h2 {
          border-bottom: 1px solid var(--border);
          padding-bottom: 6px;
        }

        .rendered-view a {
          color: var(--link);
          text-decoration: none;
        }

        .rendered-view a:hover {
          text-decoration: underline;
        }

        .rendered-view code {
          font-family: "SF Mono", Menlo, Monaco, monospace;
          background: var(--surface);
          color: var(--text);
          padding: 2px 6px;
          border-radius: 6px;
        }

        .rendered-view pre {
          background: var(--surface);
          padding: 12px;
          border-radius: 8px;
          overflow-x: auto;
          border: 1px solid var(--border);
        }

        .rendered-view pre code {
          background: transparent;
          padding: 0;
        }

        .rendered-view blockquote {
          border-left: 3px solid var(--border);
          margin: 1em 0;
          padding: 0.25em 0.75em;
          color: var(--comment);
        }

        .rendered-view table {
          border-collapse: collapse;
        }

        .rendered-view th,
        .rendered-view td {
          border: 1px solid var(--border);
          padding: 6px 10px;
        }

        .rendered-view img {
          max-width: 100%;
          height: auto;
        }

        .rendered-view p { margin: 1em 0; line-height: 1.6; }
        .rendered-view ul, .rendered-view ol { margin: 1em 0; padding-left: 2em; }
        .rendered-view li { margin: 0.3em 0; }
        .rendered-view li > p { margin: 0.5em 0; }
        .rendered-view hr { border: none; border-top: 1px solid var(--border); margin: 1.5em 0; }
        .rendered-view details { margin: 1em 0; }
        .rendered-view summary { cursor: pointer; font-weight: 600; }
        .rendered-view strong { font-weight: 700; }
        .rendered-view em { font-style: italic; }
        .rendered-view del { text-decoration: line-through; }
        .rendered-view mark { background: rgba(255, 200, 0, 0.3); color: inherit; }

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
              const text = document.getElementById('raw-source')?.value || '';
              writeClipboard(text).then(() => showToast('Copied'));
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
          // Header (and toggle) can be disabled via user settings. In that case, we must still
          // switch the visible view without assuming buttons exist.
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
        }

        buttons.forEach(btn => {
          btn.addEventListener('click', () => setMode(btn.dataset.mode));
        });

        setMode(currentMode);

        copyButton?.addEventListener('click', () => {
          let text = '';
          if (currentMode === 'rendered' && renderedView) {
            text = renderedView.innerText || '';
          } else {
            text = document.getElementById('raw-source')?.value || '';
          }
          writeClipboard(text).then(() => showToast('Copied'));
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
