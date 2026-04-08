import Foundation

public enum FileTypeResolution {
    /// Returns the best registry key to use for a URL.
    ///
    /// Resolution order (most specific first):
    /// 1. Full filename without leading dot  (e.g. `env.local`, `eslintrc.json`, `docker-compose.yml`)
    /// 2. Dotfile/multi-dot prefix segments  (e.g. `eslintrc` from `eslintrc.json`)
    /// 3. Path extension                     (e.g. `json`, `yml`, `js`)
    /// 4. Intermediate dot segments          (e.g. `json` from `claude.json.backup.1770685742797`)
    ///
    /// This ensures chained dotfiles like `.eslintrc.json` resolve to "eslintrc" (ESLint config)
    /// rather than generic "json", while normal single-dot files like `sample.conf`
    /// keep their real extension instead of resolving to generic basename aliases like "sample".
    /// Multi-dot files like `.claude.json.backup.xxx` resolve to "json" (first known intermediate segment).
    public static func bestKey(for url: URL, registry: FileTypeRegistry = .shared) -> String {
        let pathExt = url.pathExtension.lowercased()
        let fileName = url.lastPathComponent.lowercased()
        let fileNameNoLeadingDot = fileName.hasPrefix(".") ? String(fileName.dropFirst()) : fileName
        let dotCount = fileNameNoLeadingDot.filter { $0 == "." }.count
        let shouldTryPrefixes = fileName.hasPrefix(".") || dotCount > 1

        // Build candidates from most specific to least specific
        var candidates: [String] = []
        candidates.reserveCapacity(10)

        // 1. Full name (e.g. "env.local", "eslintrc.json", "docker-compose.override.yml")
        if !fileNameNoLeadingDot.isEmpty {
            candidates.append(fileNameNoLeadingDot)
        }

        // 2. Dotfiles and multi-dot files keep progressive prefix lookup.
        if shouldTryPrefixes {
            // ".eslintrc.json" → "eslintrc"
            // "docker-compose.override.yml" → "docker-compose.override" → "docker-compose"
            var remaining = fileNameNoLeadingDot
            while let lastDot = remaining.lastIndex(of: ".") {
                remaining = String(remaining[..<lastDot])
                if !remaining.isEmpty {
                    candidates.append(remaining)
                }
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

        // 4. Intermediate dot segments for multi-dot filenames (right to left)
        //    "claude.json.backup.1770685742797" → try "backup", "json"
        //    Skips first segment (filename base) and last (already tried as pathExtension)
        let segments = fileNameNoLeadingDot.split(separator: ".").map { String($0) }
        if segments.count > 2 {
            for i in stride(from: segments.count - 2, through: 1, by: -1) {
                let seg = segments[i]
                if registry.highlightLanguage(for: seg) != nil || registry.fileType(for: seg) != nil {
                    return seg
                }
            }
        }

        // No match — return extension if available, otherwise full name
        return !pathExt.isEmpty ? pathExt : fileNameNoLeadingDot
    }
}
