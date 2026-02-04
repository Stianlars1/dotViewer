import Foundation

public enum FileTypeResolution {
    /// Returns the best registry key to use for a URL.
    ///
    /// This intentionally handles:
    /// - multi-dot dotfiles like `.env.local` (key: `env.local`)
    /// - filename-based types like `Dockerfile.dev` (key: `dockerfile`)
    public static func bestKey(for url: URL, registry: FileTypeRegistry = .shared) -> String {
        let pathExt = url.pathExtension.lowercased()
        let fileName = url.lastPathComponent.lowercased()
        let fileNameNoLeadingDot = fileName.hasPrefix(".") ? String(fileName.dropFirst()) : fileName

        var candidates: [String] = []
        candidates.reserveCapacity(3)

        if !pathExt.isEmpty {
            candidates.append(pathExt)
        }

        if !fileNameNoLeadingDot.isEmpty {
            candidates.append(fileNameNoLeadingDot)
        }

        if let dotIndex = fileNameNoLeadingDot.firstIndex(of: ".") {
            let prefix = String(fileNameNoLeadingDot[..<dotIndex])
            if !prefix.isEmpty {
                candidates.append(prefix)
            }
        }

        for candidate in candidates {
            if registry.highlightLanguage(for: candidate) != nil || registry.fileType(for: candidate) != nil {
                return candidate
            }
        }

        return !pathExt.isEmpty ? pathExt : fileNameNoLeadingDot
    }
}

