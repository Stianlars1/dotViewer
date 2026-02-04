import Foundation

public enum SensitiveFileDetector {
    private static let sensitiveNames: Set<String> = [
        ".env",
        ".env.local",
        ".env.development",
        ".env.production",
        ".env.staging",
        ".npmrc",
        ".pypirc",
        ".netrc",
        ".aws",
        ".ssh",
        "id_rsa",
        "id_ed25519",
        ".git-credentials",
        ".htpasswd"
    ]

    public static func isSensitive(url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        if sensitiveNames.contains(name) {
            return true
        }
        if name.hasPrefix(".env.") {
            return true
        }
        return false
    }
}
