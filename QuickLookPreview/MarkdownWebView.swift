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
        // Use Coordinator.self (a class) to find the extension's bundle
        // Note: Bundle.main points to main app, not the extension!
        // MarkdownWebView is a struct, so we can't use Bundle(for: Self.self)
        let bundle = Bundle(for: Coordinator.self)

        guard let url = bundle.url(forResource: "marked.min", withExtension: "js") else {
            print("[MarkdownWebView] ERROR: Could not find marked.min.js")
            print("[MarkdownWebView] Bundle: \(bundle.bundleIdentifier ?? "unknown")")
            print("[MarkdownWebView] Path: \(bundle.bundlePath)")
            return ""
        }

        guard let js = try? String(contentsOf: url, encoding: .utf8) else {
            print("[MarkdownWebView] ERROR: Could not read marked.min.js from \(url)")
            return ""
        }

        print("[MarkdownWebView] ✅ Loaded marked.js (\(js.count) chars) from \(bundle.bundleIdentifier ?? "bundle")")
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

        // If marked.js failed to load, show error message instead
        if markedJS.isEmpty {
            return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro', sans-serif;
                    padding: 20px;
                    background: #fff;
                    color: #333;
                }
                .error {
                    color: #ff3b30;
                    padding: 20px;
                    background: #fff3cd;
                    border-radius: 8px;
                    border: 1px solid #ffb020;
                    margin-bottom: 20px;
                }
                pre {
                    background: #f5f5f5;
                    padding: 15px;
                    border-radius: 6px;
                    overflow-x: auto;
                    white-space: pre-wrap;
                    font-family: 'SF Mono', Menlo, monospace;
                    font-size: 13px;
                }
                </style>
            </head>
            <body>
                <div class="error">
                    <h2>⚠️ Markdown Rendering Failed</h2>
                    <p>The marked.js library failed to load from the bundle.</p>
                    <p>Showing raw markdown instead.</p>
                </div>
                <pre>\(escapedMarkdown)</pre>
            </body>
            </html>
            """
        }

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
                // Check if marked.js loaded successfully
                if (typeof marked === 'undefined') {
                    document.getElementById('content').innerHTML =
                        '<div style="color: #ff3b30; padding: 20px; background: #fff3cd; border-radius: 8px; border: 1px solid #ffb020;">' +
                        '<h2>⚠️ Markdown Rendering Failed</h2>' +
                        '<p>The marked.js library failed to initialize.</p>' +
                        '<p>Showing raw markdown instead.</p>' +
                        '</div><pre>' + `\(escapedMarkdown)` + '</pre>';
                } else {
                    marked.setOptions({
                        gfm: true,
                        breaks: true,
                        headerIds: true,
                        mangle: false
                    });
                    document.getElementById('content').innerHTML = marked.parse(`\(escapedMarkdown)`);
                }
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
