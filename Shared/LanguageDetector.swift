import Foundation

struct LanguageDetector {

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
        "gitignore": "plaintext",
        "gitattributes": "plaintext",
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
        ".gitignore": "plaintext",
        ".gitattributes": "plaintext",
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
        ".prettierignore": "plaintext",
        ".eslintrc": "json",
        ".eslintignore": "plaintext",
        ".stylelintrc": "json",

        // Docker
        ".dockerignore": "plaintext",
        "Dockerfile": "dockerfile",
        "docker-compose.yml": "yaml",
        "docker-compose.yaml": "yaml",

        // Node/npm
        ".npmrc": "ini",
        ".nvmrc": "plaintext",
        ".node-version": "plaintext",
        ".yarnrc": "yaml",
        ".yarnrc.yml": "yaml",
        "package.json": "json",
        "package-lock.json": "json",
        "tsconfig.json": "json",
        "jsconfig.json": "json",

        // Ruby
        ".ruby-version": "plaintext",
        ".ruby-gemset": "plaintext",
        ".gemrc": "yaml",
        "Gemfile": "ruby",
        "Rakefile": "ruby",

        // Python
        ".python-version": "plaintext",
        "requirements.txt": "plaintext",
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
        ".mailmap": "plaintext",
        "Makefile": "makefile",
        "CMakeLists.txt": "cmake",
        "Brewfile": "ruby",
        "Procfile": "yaml",
        "Vagrantfile": "ruby",
    ]

    /// Detect the language for a given file URL
    static func detect(for url: URL) -> String? {
        let filename = url.lastPathComponent
        let ext = url.pathExtension.lowercased()

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
                return "plaintext"
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
