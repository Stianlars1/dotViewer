import Foundation

public enum ManPageRenderer {
    public static let supportedExtensions: Set<String> = [
        "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "man", "mdoc", "roff", "nroff", "troff",
    ]

    public static func shouldRender(url: URL, mimeType: String, key: String, text: String) -> Bool {
        if supportedExtensions.contains(url.pathExtension.lowercased()) || supportedExtensions.contains(key) {
            return true
        }

        if mimeType == "text/troff" {
            return true
        }

        let firstLines = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .prefix(8)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        return firstLines.contains { line in
            line.hasPrefix(".TH ")
                || line.hasPrefix(".Dd ")
                || line.hasPrefix(".Dt ")
                || line.hasPrefix(".Sh ")
                || line.hasPrefix(".Nm ")
        }
    }

    public static func renderHTML(url: URL) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mandoc")
        process.arguments = ["-Thtml", url.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        let outputPipe = process.standardOutput as? Pipe
        let data = outputPipe?.fileHandleForReading.readDataToEndOfFile() ?? Data()
        process.waitUntilExit()

        guard process.terminationStatus == 0,
              let html = String(data: data, encoding: .utf8),
              let body = extractBody(from: html)
        else {
            return nil
        }

        return "<div class=\"manpage-preview\">\(body)</div>"
    }

    private static func extractBody(from html: String) -> String? {
        guard let bodyStart = html.range(of: "<body>"),
              let bodyEnd = html.range(of: "</body>")
        else {
            return nil
        }

        return String(html[bodyStart.upperBound..<bodyEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
