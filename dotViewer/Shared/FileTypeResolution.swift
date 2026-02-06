import Foundation

public enum FileTypeResolution {
    /// Returns the best registry key to use for a URL.
    ///
    /// Resolution order (most specific first):
    /// 1. Full filename without leading dot  (e.g. `env.local`, `eslintrc.json`, `docker-compose.yml`)
    /// 2. Progressive prefix segments        (e.g. `eslintrc` from `eslintrc.json`)
    /// 3. Path extension                     (e.g. `json`, `yml`, `js`)
    ///
    /// This ensures chained dotfiles like `.eslintrc.json` resolve to "eslintrc" (ESLint config)
    /// rather than generic "json", while `.env.staging` resolves to "env" (Environment).
    public static func bestKey(for url: URL, registry: FileTypeRegistry = .shared) -> String {
        let pathExt = url.pathExtension.lowercased()
        let fileName = url.lastPathComponent.lowercased()
        let fileNameNoLeadingDot = fileName.hasPrefix(".") ? String(fileName.dropFirst()) : fileName

        // Build candidates from most specific to least specific
        var candidates: [String] = []
        candidates.reserveCapacity(6)

        // 1. Full name (e.g. "env.local", "eslintrc.json", "docker-compose.override.yml")
        if !fileNameNoLeadingDot.isEmpty {
            candidates.append(fileNameNoLeadingDot)
        }

        // 2. Progressive prefixes by stripping trailing segments
        //    "docker-compose.override.yml" → "docker-compose.override" → "docker-compose"
        var remaining = fileNameNoLeadingDot
        while let lastDot = remaining.lastIndex(of: ".") {
            remaining = String(remaining[..<lastDot])
            if !remaining.isEmpty {
                candidates.append(remaining)
            }
        }

        // 3. Bare path extension last (e.g. "json", "yml", "js")
        if !pathExt.isEmpty {
            candidates.append(pathExt)
        }

        // Return first match
        for candidate in candidates {
            if registry.highlightLanguage(for: candidate) != nil || registry.fileType(for: candidate) != nil {
                return candidate
            }
        }

        // No match — return extension if available, otherwise full name
        return !pathExt.isEmpty ? pathExt : fileNameNoLeadingDot
    }
}
