import Foundation

public enum PlainTextRenderer {
    public static func render(code: String, showLineNumbers: Bool) -> String {
        let data = code.data(using: .utf8) ?? Data()
        return TreeSitterFallbackRenderer.renderPlain(data: data, showLineNumbers: showLineNumbers)
    }
}

private enum TreeSitterFallbackRenderer {
    static func renderPlain(data: Data, showLineNumbers: Bool) -> String {
        let text = String(decoding: data, as: UTF8.self)
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { escapeHTML(String($0)) }

        if showLineNumbers {
            return lines.enumerated().map { index, line in
                let lineNumber = index + 1
                return "<div class=\"line\"><span class=\"ln\">\(lineNumber)</span><span class=\"code-line\">\(line)</span></div>"
            }.joined()
        } else {
            let joined = lines.joined(separator: "\n")
            return "<pre class=\"code\"><code>\(joined)</code></pre>"
        }
    }

    static func escapeHTML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        return escaped
    }
}
