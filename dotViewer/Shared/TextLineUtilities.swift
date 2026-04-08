import Foundation

public enum TextLineUtilities {
    public static func displayLines(in text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if normalized.hasSuffix("\n"), !lines.isEmpty {
            lines.removeLast()
        }
        return lines
    }

    public static func lineCount(in text: String) -> Int {
        displayLines(in: text).count
    }

    public static func lines(forDisplayFrom text: String) -> [String] {
        displayLines(in: text)
    }

    public static func visualLineCount(in text: String) -> Int {
        lineCount(in: text)
    }
}
