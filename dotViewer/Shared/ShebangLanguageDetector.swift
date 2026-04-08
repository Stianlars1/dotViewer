import Foundation

public struct ShebangMatch: Sendable {
    public let languageId: String
    public let displayName: String

    public init(languageId: String, displayName: String) {
        self.languageId = languageId
        self.displayName = displayName
    }
}

public enum ShebangLanguageDetector {
    public static func detect(url: URL, maxBytes: Int = 1024) -> ShebangMatch? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        let data = handle.readData(ofLength: maxBytes)
        try? handle.close()
        let text = String(decoding: data, as: UTF8.self)
        return detect(in: text)
    }

    public static func detect(in text: String) -> ShebangMatch? {
        guard let firstLine = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first else {
            return nil
        }

        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("#!") else { return nil }

        let command = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        guard !command.isEmpty else { return nil }

        let components = command.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let executable = resolveExecutable(from: components) else { return nil }

        switch executable.lowercased() {
        case "sh", "bash", "zsh", "ksh", "csh", "tcsh", "fish", "dash", "ash":
            return ShebangMatch(languageId: "bash", displayName: "Shell Script")
        case "python", "python2", "python3", "pypy", "pypy3":
            return ShebangMatch(languageId: "python", displayName: "Python")
        case "node", "nodejs", "deno", "bun":
            return ShebangMatch(languageId: "javascript", displayName: "JavaScript")
        case "ruby", "jruby":
            return ShebangMatch(languageId: "ruby", displayName: "Ruby")
        case "perl", "perl5":
            return ShebangMatch(languageId: "perl", displayName: "Perl")
        case "php":
            return ShebangMatch(languageId: "php", displayName: "PHP")
        case "lua":
            return ShebangMatch(languageId: "lua", displayName: "Lua")
        case "swift":
            return ShebangMatch(languageId: "swift", displayName: "Swift")
        case "pwsh", "powershell":
            return ShebangMatch(languageId: "powershell", displayName: "PowerShell")
        case "rscript":
            return ShebangMatch(languageId: "r", displayName: "R")
        default:
            return nil
        }
    }

    private static func resolveExecutable(from components: [String]) -> String? {
        guard let first = components.first else { return nil }
        let firstName = URL(fileURLWithPath: first).lastPathComponent.lowercased()

        if firstName != "env" {
            return firstName
        }

        for candidate in components.dropFirst() {
            if candidate.hasPrefix("-") || candidate.contains("=") {
                continue
            }
            return URL(fileURLWithPath: candidate).lastPathComponent
        }

        return nil
    }
}
