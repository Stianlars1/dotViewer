import Foundation
import AppKit

public enum MarkdownRenderer {
    public static func renderHTML(from markdown: String) -> String {
        do {
            let attributed = try AttributedString(markdown: markdown, options: .init(interpretedSyntax: .full))
            let nsAttributed = NSAttributedString(attributed)
            let range = NSRange(location: 0, length: nsAttributed.length)
            let data = try nsAttributed.data(from: range, documentAttributes: [
                .documentType: NSAttributedString.DocumentType.html
            ])
            let html = String(data: data, encoding: .utf8) ?? ""
            let body = extractBody(from: html)
            return sanitize(body)
        } catch {
            return "<pre>\(escapeHTML(markdown))</pre>"
        }
    }

    private static func extractBody(from html: String) -> String {
        guard let bodyStart = html.range(of: "<body>"),
              let bodyEnd = html.range(of: "</body>")
        else { return html }
        let body = html[bodyStart.upperBound..<bodyEnd.lowerBound]
        return String(body)
    }

    private static func sanitize(_ html: String) -> String {
        var sanitized = html
        let styleRegexes = [
            #"(?i)\sstyle="[^"]*""#,
            #"(?i)\sstyle='[^']*'"#
        ]
        for pattern in styleRegexes {
            sanitized = sanitized.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        sanitized = sanitized.replacingOccurrences(of: #"(?i)</?font[^>]*>"#, with: "", options: .regularExpression)
        return sanitized
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
