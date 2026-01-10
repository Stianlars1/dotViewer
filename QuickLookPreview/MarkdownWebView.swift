import SwiftUI
import WebKit

/// WKWebView-based markdown renderer with full HTML, table, and image support
struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?
    let fontSize: Double

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isTextInteractionEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Disable zoom and scroll bounce for cleaner preview
        webView.allowsMagnification = false

        // Set transparent background initially
        webView.setValue(false, forKey: "drawsBackground")

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        // Prevent navigation to external links
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    NSWorkspace.shared.open(url)
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }

    private func loadMarkedJS() -> String {
        // Try to load from bundle resources
        guard let url = Bundle.main.url(forResource: "marked.min", withExtension: "js", subdirectory: "Resources"),
              let js = try? String(contentsOf: url, encoding: .utf8) else {
            // Fallback: return empty string (will show raw markdown)
            return ""
        }
        return js
    }

    private func generateHTML() -> String {
        let css = MarkdownStyles.css(
            for: ThemeManager.shared.selectedTheme,
            fontSize: fontSize,
            isDark: isDarkTheme
        )

        let markedJS = loadMarkedJS()

        // Escape markdown for JavaScript template literal
        let escapedMarkdown = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
            \(css)
            </style>
        </head>
        <body>
            <div id="content"></div>
            <script>
            \(markedJS)
            </script>
            <script>
                marked.setOptions({
                    gfm: true,
                    breaks: true,
                    headerIds: true,
                    mangle: false
                });
                document.getElementById('content').innerHTML = marked.parse(`\(escapedMarkdown)`);
            </script>
        </body>
        </html>
        """
    }

    private var isDarkTheme: Bool {
        let theme = ThemeManager.shared.selectedTheme
        return theme.contains("Dark") || theme == "tokyoNight" || theme == "blackout" ||
               (theme == "auto" && ThemeManager.shared.systemAppearanceIsDark)
    }
}

// MARK: - Marked.js Library (loaded from Resources)

/// Marked.js library is loaded from QuickLookPreview/Resources/marked.min.js
/// Source: https://github.com/markedjs/marked (MIT License)
