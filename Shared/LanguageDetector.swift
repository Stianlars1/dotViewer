import Foundation

struct LanguageDetector {

    /// Files that should explicitly skip syntax highlighting (history files, binary-ish text, etc.)
    /// These files are large, have no meaningful syntax, and would slow down HighlightSwift
    static let skipHighlightingFiles: Set<String> = [
        // Vim/editor history
        ".viminfo",
        ".viminf~",
        ".netrwhist",
        // Shell history
        ".bash_history",
        ".zsh_history",
        ".sh_history",
        ".history",
        ".lesshst",
        ".psql_history",
        ".mysql_history",
        ".sqlite_history",
        ".irb_history",
        ".pry_history",
        ".node_repl_history",
        ".python_history",
        // Other history/cache files
        ".wget-hsts",
        ".recently-used",
    ]

    /// Maps file extensions to highlight.js language identifiers
    static let extensionMap: [String: String] = [
        // JavaScript/TypeScript
        "js": "javascript",
        "mjs": "javascript",
        "cjs": "javascript",
        "jsx": "javascript",
        "ts": "typescript",
        "mts": "typescript",
        "cts": "typescript",
        "tsx": "typescript",

        // Web
        "html": "xml",
        "htm": "xml",
        "xhtml": "xml",
        "xml": "xml",
        "svg": "xml",
        "css": "css",
        "scss": "scss",
        "sass": "scss",
        "less": "less",

        // Data formats
        "json": "json",
        "yaml": "yaml",
        "yml": "yaml",
        "toml": "ini",
        "ini": "ini",
        "conf": "ini",
        "cfg": "ini",
        "plist": "xml",
        "entitlements": "xml",
        "xcconfig": "ini",        // Key-value format
        "xcscheme": "xml",
        "xcworkspacedata": "xml",
        "pbxproj": "ini",         // Actually a weird plist/ini hybrid, ini works better
        "storyboard": "xml",
        "xib": "xml",
        "strings": "ini",         // Key = "Value" format
        "stringsdict": "xml",     // XML plist format
        "intentdefinition": "xml",
        "xcdatamodel": "xml",
        "playground": "xml",      // The contents.xcplayground is XML

        // Systems languages
        "swift": "swift",
        "go": "go",
        "rs": "rust",
        "c": "c",
        "h": "c",
        "cpp": "cpp",
        "cc": "cpp",
        "cxx": "cpp",
        "hpp": "cpp",
        "hxx": "cpp",
        "m": "objectivec",
        "mm": "objectivec",

        // JVM
        "java": "java",
        "kt": "kotlin",
        "kts": "kotlin",
        "scala": "scala",
        "groovy": "groovy",
        "gradle": "groovy",

        // Scripting
        "py": "python",
        "pyw": "python",
        "rb": "ruby",
        "php": "php",
        "pl": "perl",
        "pm": "perl",
        "lua": "lua",
        "r": "r",

        // Shell
        "sh": "bash",
        "bash": "bash",
        "zsh": "bash",
        "zsh-theme": "bash",
        "fish": "bash",
        "ps1": "powershell",
        "psm1": "powershell",

        // Markdown
        "md": "markdown",
        "markdown": "markdown",
        "mdx": "markdown",

        // Other
        "sql": "sql",
        "graphql": "graphql",
        "gql": "graphql",
        "prisma": "prisma",
        "dockerfile": "dockerfile",
        "makefile": "makefile",
        "cmake": "cmake",
        "vue": "xml",
        "svelte": "xml",
        "astro": "xml",

        // Config files
        "env": "properties",
        "properties": "properties",
        "gitignore": "bash",
        "gitattributes": "bash",
        "editorconfig": "ini",
        "prettierrc": "json",
        "eslintrc": "json",
        "babelrc": "json",

        // Misc
        "diff": "diff",
        "patch": "diff",
        "log": "plaintext",
        "txt": "plaintext",
    ]

    /// Maps dotfile names to highlight.js language identifiers
    static let dotfileMap: [String: String] = [
        // Git
        ".gitconfig": "ini",
        ".gitignore": "bash",
        ".gitattributes": "bash",
        ".gitmodules": "ini",

        // Shell profiles
        ".bashrc": "bash",
        ".bash_profile": "bash",
        ".bash_aliases": "bash",
        ".bash_logout": "bash",
        ".zshrc": "bash",
        ".zshenv": "bash",
        ".zprofile": "bash",
        ".zlogin": "bash",
        ".zlogout": "bash",
        ".profile": "bash",
        ".inputrc": "bash",

        // Environment
        ".env": "properties",
        ".env.local": "properties",
        ".env.development": "properties",
        ".env.production": "properties",
        ".env.test": "properties",
        ".env.example": "properties",

        // Editor configs
        ".editorconfig": "ini",
        ".prettierrc": "json",
        ".prettierignore": "bash",
        ".eslintrc": "json",
        ".eslintignore": "bash",
        ".stylelintrc": "json",
        ".stylelintignore": "bash",

        // Docker
        ".dockerignore": "bash",
        "Dockerfile": "dockerfile",
        "docker-compose.yml": "yaml",
        "docker-compose.yaml": "yaml",

        // Node/npm
        ".npmrc": "ini",
        ".nvmrc": "ini",
        ".node-version": "ini",
        ".yarnrc": "yaml",
        ".npmignore": "bash",
        ".yarnrc.yml": "yaml",
        "package.json": "json",
        "package-lock.json": "json",
        "tsconfig.json": "json",
        "jsconfig.json": "json",

        // Ruby
        ".ruby-version": "ini",
        ".ruby-gemset": "ini",
        ".gemrc": "yaml",
        "Gemfile": "ruby",
        "Rakefile": "ruby",

        // Python
        ".python-version": "ini",
        "requirements.txt": "properties",
        "Pipfile": "toml",
        "pyproject.toml": "toml",

        // SSH
        "config": "plaintext",
        "known_hosts": "plaintext",
        "authorized_keys": "plaintext",

        // Vim
        ".vimrc": "vim",
        ".gvimrc": "vim",
        ".exrc": "vim",

        // Other
        ".htaccess": "apache",
        ".mailmap": "ini",
        "Makefile": "makefile",
        "CMakeLists.txt": "cmake",
        "Brewfile": "ruby",
        "Procfile": "yaml",
        "Vagrantfile": "ruby",

        // Additional ignore files
        ".bzrignore": "bash",
        ".cvsignore": "bash",
        ".hgignore": "bash",
        ".vscodeignore": "bash",

        // Ruby/Fastlane build tools
        "Podfile": "ruby",
        "Fastfile": "ruby",
        "Appfile": "ruby",
        "Matchfile": "ruby",
        "Snapfile": "ruby",
        "Scanfile": "ruby",
        "Gymfile": "ruby",
        "Deliverfile": "ruby",
    ]

    /// Detect the language for a given file URL
    static func detect(for url: URL) -> String? {
        let filename = url.lastPathComponent
        let ext = url.pathExtension.lowercased()

        // Skip highlighting entirely for known problematic files (history files, etc.)
        // Return "plaintext" to signal explicit skip in PreviewContentView
        if skipHighlightingFiles.contains(filename) {
            return "plaintext"
        }

        // First, check if it's a known dotfile by exact filename
        if let language = dotfileMap[filename] {
            return language
        }

        // Check if it's a dotfile (starts with .)
        if filename.hasPrefix(".") {
            // Try to extract extension from dotfile (e.g., .eslintrc.json -> json)
            let components = filename.components(separatedBy: ".")
            if components.count > 2, let lastExt = components.last {
                if let language = extensionMap[lastExt.lowercased()] {
                    return language
                }
            }

            // Check for known patterns
            if filename.contains("rc") || filename.contains("config") {
                return "ini"
            }
            if filename.contains("ignore") {
                return "bash"
            }

            // Default for dotfiles - try to detect from content
            return nil
        }

        // Check file extension
        if !ext.isEmpty, let language = extensionMap[ext] {
            return language
        }

        // Special case: files without extension but known names
        let lowercaseName = filename.lowercased()
        if let language = dotfileMap[filename] ?? dotfileMap[lowercaseName] {
            return language
        }

        // Check for shebang in content (would need async read)
        // For now, return nil to let highlight.js auto-detect
        return nil
    }

    /// Detect language from shebang line
    static func detectFromShebang(_ content: String) -> String? {
        guard content.hasPrefix("#!") else { return nil }

        let firstLine = String(content.prefix(while: { $0 != "\n" }))

        if firstLine.contains("python") { return "python" }
        if firstLine.contains("ruby") { return "ruby" }
        if firstLine.contains("perl") { return "perl" }
        if firstLine.contains("node") { return "javascript" }
        if firstLine.contains("bash") { return "bash" }
        if firstLine.contains("zsh") { return "bash" }
        if firstLine.contains("/sh") { return "bash" }
        if firstLine.contains("php") { return "php" }

        return nil
    }

    /// Content-based language detection as fallback for unknown files
    /// Analyzes the first 500 characters to detect common file formats
    static func detectFromContent(_ content: String) -> String? {
        let sample = String(content.prefix(500))
        let trimmed = sample.trimmingCharacters(in: .whitespacesAndNewlines)

        // JSON detection (starts with { or [)
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            // Additional check: must contain quotes and colons for objects
            if trimmed.hasPrefix("{") && trimmed.contains(":") && trimmed.contains("\"") {
                return "json"
            }
            if trimmed.hasPrefix("[") {
                return "json"
            }
        }

        // XML/HTML detection
        if trimmed.contains("<?xml") || trimmed.contains("<!DOCTYPE") {
            return "xml"
        }
        if trimmed.hasPrefix("<") && trimmed.contains("</") {
            return "xml"
        }

        // INI detection ([section] headers)
        // Check for lines starting with [ and ending with ]
        let lines = sample.components(separatedBy: .newlines)
        let hasIniSection = lines.contains { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            return t.hasPrefix("[") && t.hasSuffix("]") && t.count > 2
        }
        let hasKeyValue = lines.contains { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            return t.contains("=") && !t.hasPrefix("#") && !t.hasPrefix(";")
        }
        if hasIniSection && hasKeyValue {
            return "ini"
        }

        // YAML detection (key: value at start of lines, no braces)
        // Must have key: pattern but not be JSON-like
        let hasYamlPattern = lines.contains { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty && !t.hasPrefix("#") else { return false }
            // Look for "key:" or "key: value" pattern
            let parts = t.split(separator: ":", maxSplits: 1)
            if parts.count >= 1 {
                let key = String(parts[0])
                // Key should be alphanumeric/underscore, no quotes
                return key.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
            }
            return false
        }
        if hasYamlPattern && !trimmed.contains("{") && !trimmed.hasPrefix("[") {
            // Additional check: multiple key: patterns
            let keyColonCount = lines.filter { line in
                let t = line.trimmingCharacters(in: .whitespaces)
                return t.contains(":") && !t.hasPrefix("#")
            }.count
            if keyColonCount >= 2 {
                return "yaml"
            }
        }

        // Shell script indicators (common commands at line start)
        let shellPatterns = ["export ", "alias ", "source ", "echo ", "if [", "for ", "while ", "case ", "function ", "#!/"]
        for pattern in shellPatterns {
            if lines.contains(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix(pattern) }) {
                return "bash"
            }
        }

        // Properties file detection (key=value without sections)
        if hasKeyValue && !hasIniSection {
            let kvCount = lines.filter { line in
                let t = line.trimmingCharacters(in: .whitespaces)
                return t.contains("=") && !t.hasPrefix("#") && !t.hasPrefix(";")
            }.count
            if kvCount >= 2 {
                return "properties"
            }
        }

        return nil  // True fallback - show as plain text
    }

    /// Get human-readable language name
    static func displayName(for language: String?) -> String {
        guard let lang = language else { return "Plain Text" }

        let displayNames: [String: String] = [
            "javascript": "JavaScript",
            "typescript": "TypeScript",
            "python": "Python",
            "swift": "Swift",
            "go": "Go",
            "rust": "Rust",
            "ruby": "Ruby",
            "php": "PHP",
            "java": "Java",
            "kotlin": "Kotlin",
            "scala": "Scala",
            "c": "C",
            "cpp": "C++",
            "objectivec": "Objective-C",
            "csharp": "C#",
            "bash": "Shell",
            "powershell": "PowerShell",
            "sql": "SQL",
            "html": "HTML",
            "xml": "XML",
            "css": "CSS",
            "scss": "SCSS",
            "json": "JSON",
            "yaml": "YAML",
            "markdown": "Markdown",
            "dockerfile": "Dockerfile",
            "graphql": "GraphQL",
            "ini": "INI",
            "properties": "Properties",
            "plaintext": "Plain Text",
            "vim": "Vim Script",
            "makefile": "Makefile",
        ]

        return displayNames[lang] ?? lang.capitalized
    }
}
