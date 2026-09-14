import Foundation

/// Central registry of all supported file types with O(1) lookup.
public final class FileTypeRegistry: @unchecked Sendable {
    public static let shared = FileTypeRegistry()

    public let builtInTypes: [SupportedFileType]

    private let extensionToType: [String: SupportedFileType]
    private let idToType: [String: SupportedFileType]

    private init() {
        let types = Self.loadDefaultFileTypes() ?? Self.createLegacyBuiltInTypes()
        builtInTypes = types

        var extMap: [String: SupportedFileType] = [:]
        var idMap: [String: SupportedFileType] = [:]

        extMap.reserveCapacity(types.count * 3)
        idMap.reserveCapacity(types.count)

        for type in types {
            idMap[type.id] = type
            for ext in type.extensions {
                let lowered = ext.lowercased()
                if extMap[lowered] == nil {
                    extMap[lowered] = type
                }
            }
            for name in type.filenames {
                let lowered = name.lowercased()
                let trimmed = lowered.hasPrefix(".") ? String(lowered.dropFirst()) : lowered
                if !trimmed.isEmpty {
                    if extMap[trimmed] == nil {
                        extMap[trimmed] = type
                    }
                }
            }
        }

        extensionToType = extMap
        idToType = idMap
    }

    private struct DefaultFileType: Decodable {
        let id: String
        let displayName: String
        let extensions: [String]?
        let filenames: [String]?
        let category: String?
        let highlightLanguage: String?
    }

    private static func loadDefaultFileTypes() -> [SupportedFileType]? {
        guard let url = Bundle(for: FileTypeRegistry.self).url(
            forResource: "DefaultFileTypes",
            withExtension: "json"
        ) else {
            return nil
        }
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([DefaultFileType].self, from: data)
        else {
            return nil
        }

        return decoded.map { item in
            let extensions = (item.extensions ?? []).map { $0.lowercased() }
            let filenames = (item.filenames ?? []).map { $0.lowercased() }
            let category = resolveCategory(for: item, extensions: extensions, filenames: filenames)
            let highlight = resolveHighlightLanguage(for: item, extensions: extensions)
            return SupportedFileType(
                id: item.id,
                displayName: item.displayName,
                extensions: extensions,
                filenames: filenames,
                category: category,
                highlightLanguage: highlight,
                isSystemUTI: false
            )
        }
    }

    private static func resolveCategory(
        for item: DefaultFileType,
        extensions: [String],
        filenames: [String]
    ) -> FileTypeCategory {
        if let raw = item.category?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           let match = FileTypeCategory.allCases.first(where: { category in
               category.rawValue.lowercased() == raw || String(describing: category).lowercased() == raw
           }) {
            return match
        }

        let id = item.id.lowercased()
        let filenameSet = Set(filenames)

        let dotfileNames: Set<String> = [
            // Git
            "gitignore", "gitconfig", "gitattributes", "gitmodules", "gitkeep", "mailmap", "git-extra",
            // Env
            "env", "env.local", "env.development", "env.production", "env.staging", "env.test", "env-extra",
            // Editor
            "editorconfig",
            // Node/Package managers
            "npmrc", "nvmrc", "yarnrc",
            // Docker/Container
            "dockerignore",
            // Shell
            "shellrc", "shell-profile", "zshrc", "bashrc", "profile", "zshenv",
            // Vim
            "vimrc", "viminfo",
            // Terminal
            "inputrc", "dircolors", "hushlogin", "xresources", "screenrc", "tmux-conf",
            // Dev tools - ignore files
            "dev-ignore",
            // Dev configs
            "rcfile", "browserslistrc", "flowconfig", "watchmanconfig",
            "swiftlint", "swiftformat", "clang-config", "rustfmt", "rubocop",
            "python-lint", "pre-commit",
            "commitlint-json", "commitlint-yaml", "nojekyll", "version-files", "terraform-lock",
            // RC file variants
            "babelrc-js", "babelrc-json", "rc-yaml",
            // macOS/Network
            "curlrc", "wgetrc", "netrc", "cfusertextencoding", "gemrc", "irbrc",
            // SSH
            "ssh-config",
            // Markdown/Husky
            "markdownlint", "husky",
            // Env extra
            "env-extra",
            // Chained RC base names
            "swcrc", "nycrc", "releaserc",
            // CI
            "travis", "circleci"
        ]

        if filenameSet.contains(where: { $0.hasPrefix(".") }) || dotfileNames.contains(id) {
            return .dotfiles
        }

        let shellIds: Set<String> = [
            "bash", "sh", "zsh", "ksh", "csh", "tcsh", "fish", "shellscript", "powershell", "ps1", "batch", "cmd"
        ]
        if shellIds.contains(id) {
            return .shellAndTerminal
        }

        let docIds: Set<String> = ["markdown", "rst", "asciidoc", "tex", "latex", "org", "textile"]
        if docIds.contains(id) {
            return .documentation
        }

        let webIds: Set<String> = [
            "html", "css", "scss", "less", "sass", "vue", "svelte", "astro", "jsx", "tsx", "handlebars", "mustache"
        ]
        if webIds.contains(id) {
            return .webDevelopment
        }

        let dataIds: Set<String> = [
            "json", "yaml", "yml", "toml", "xml", "ini", "conf", "properties", "csv", "tsv", "sql", "graphql"
        ]
        if dataIds.contains(id) || extensions.contains(where: dataIds.contains) {
            return .dataFormats
        }

        let scriptingIds: Set<String> = [
            "python", "ruby", "perl", "php", "lua", "r", "julia", "elixir", "erlang", "haskell", "clojure"
        ]
        if scriptingIds.contains(id) {
            return .scripting
        }

        return .systemsLanguages
    }

    private static func resolveHighlightLanguage(
        for item: DefaultFileType,
        extensions: [String]
    ) -> String {
        let lower = item.highlightLanguage?.lowercased() ?? item.id.lowercased()

        let aliases: [String: String] = [
            // Shell variants → bash grammar
            "sh": "bash",
            "shell": "bash",
            "shellscript": "bash",
            "zsh": "bash",
            "ksh": "bash",
            "csh": "bash",
            "tcsh": "bash",
            // Common short names
            "py": "python",
            "js": "javascript",
            "jsx": "javascript",
            "ts": "typescript",
            "md": "markdown",
            "yml": "yaml",
            // JSON highlightLanguage → tree-sitter grammar key
            "csharp": "c_sharp",
            "vimscript": "vim",
            "docker": "dockerfile",
            "fortran77": "fortran",
            "fortran90": "fortran",
            "makefile": "make",
            "pas": "pascal",
            "conf": "ini",
            // Infrastructure / config
            "terraform": "hcl",
            "svg": "xml",
            "bat": "bash",
            "delphi": "pascal",
            "lhs": "haskell",
            "vue": "html",
            "haml": "html",
            "erb": "html",
            // Cross-language aliases (similar-enough syntax)
            "less": "css",
            "sass": "scss",
            "styl": "css",
            "mssql": "sql",
            "tsql": "sql",
            "plperl": "perl",
            "plpython": "python",
            "pltcl": "ini",
            "mxml": "xml",
            "crystal": "ruby",
            "gdscript": "python",
            "lisp": "clojure",
            "coffeescript": "javascript",
            "solidity": "javascript",
        ]

        if let alias = aliases[lower] {
            return alias
        }

        if extensions.contains("mdx") {
            return "markdown"
        }

        return lower.isEmpty ? "plaintext" : lower
    }

    private static func createLegacyBuiltInTypes() -> [SupportedFileType] {
        return [
            // MARK: - Web Development
            SupportedFileType(id: "typescript", displayName: "TypeScript",
                              extensions: ["ts", "cts"],
                              category: .webDevelopment, highlightLanguage: "typescript", isSystemUTI: false),
            SupportedFileType(id: "tsx", displayName: "TypeScript JSX",
                              extensions: ["tsx"],
                              category: .webDevelopment, highlightLanguage: "tsx", isSystemUTI: false),
            SupportedFileType(id: "javascript", displayName: "JavaScript",
                              extensions: ["js", "mjs", "cjs"],
                              category: .webDevelopment, highlightLanguage: "javascript", isSystemUTI: true),
            SupportedFileType(id: "jsx", displayName: "JavaScript JSX",
                              extensions: ["jsx"],
                              category: .webDevelopment, highlightLanguage: "javascript", isSystemUTI: false),
            SupportedFileType(id: "vue", displayName: "Vue",
                              extensions: ["vue"],
                              category: .webDevelopment, highlightLanguage: "html", isSystemUTI: false),
            SupportedFileType(id: "svelte", displayName: "Svelte",
                              extensions: ["svelte"],
                              category: .webDevelopment, highlightLanguage: "html", isSystemUTI: false),
            SupportedFileType(id: "astro", displayName: "Astro",
                              extensions: ["astro"],
                              category: .webDevelopment, highlightLanguage: "html", isSystemUTI: false),
            SupportedFileType(id: "html", displayName: "HTML",
                              extensions: ["html", "htm", "xhtml"],
                              category: .webDevelopment, highlightLanguage: "html", isSystemUTI: true),
            SupportedFileType(id: "css", displayName: "CSS",
                              extensions: ["css"],
                              category: .webDevelopment, highlightLanguage: "css", isSystemUTI: true),
            SupportedFileType(id: "scss", displayName: "SCSS/Sass",
                              extensions: ["scss", "sass"],
                              category: .webDevelopment, highlightLanguage: "scss", isSystemUTI: false),
            SupportedFileType(id: "less", displayName: "Less",
                              extensions: ["less"],
                              category: .webDevelopment, highlightLanguage: "less", isSystemUTI: false),

            // MARK: - Systems Languages
            SupportedFileType(id: "swift", displayName: "Swift",
                              extensions: ["swift"],
                              category: .systemsLanguages, highlightLanguage: "swift", isSystemUTI: true),
            SupportedFileType(id: "c", displayName: "C",
                              extensions: ["c", "h"],
                              category: .systemsLanguages, highlightLanguage: "c", isSystemUTI: true),
            SupportedFileType(id: "cpp", displayName: "C++",
                              extensions: ["cpp", "cc", "cxx", "hpp", "hxx", "mm"],
                              category: .systemsLanguages, highlightLanguage: "cpp", isSystemUTI: true),
            SupportedFileType(id: "objectivec", displayName: "Objective-C",
                              extensions: ["m"],
                              category: .systemsLanguages, highlightLanguage: "objectivec", isSystemUTI: true),
            SupportedFileType(id: "rust", displayName: "Rust",
                              extensions: ["rs"],
                              category: .systemsLanguages, highlightLanguage: "rust", isSystemUTI: false),
            SupportedFileType(id: "go", displayName: "Go",
                              extensions: ["go"],
                              category: .systemsLanguages, highlightLanguage: "go", isSystemUTI: false),
            SupportedFileType(id: "java", displayName: "Java",
                              extensions: ["java"],
                              category: .systemsLanguages, highlightLanguage: "java", isSystemUTI: true),
            SupportedFileType(id: "kotlin", displayName: "Kotlin",
                              extensions: ["kt", "kts"],
                              category: .systemsLanguages, highlightLanguage: "kotlin", isSystemUTI: false),
            SupportedFileType(id: "scala", displayName: "Scala",
                              extensions: ["scala", "sc"],
                              category: .systemsLanguages, highlightLanguage: "scala", isSystemUTI: false),
            SupportedFileType(id: "csharp", displayName: "C#",
                              extensions: ["cs"],
                              category: .systemsLanguages, highlightLanguage: "csharp", isSystemUTI: false),
            SupportedFileType(id: "zig", displayName: "Zig",
                              extensions: ["zig"],
                              category: .systemsLanguages, highlightLanguage: "zig", isSystemUTI: false),

            // MARK: - Scripting
            SupportedFileType(id: "python", displayName: "Python",
                              extensions: ["py", "pyw", "pyi"],
                              category: .scripting, highlightLanguage: "python", isSystemUTI: true),
            SupportedFileType(id: "ruby", displayName: "Ruby",
                              extensions: ["rb", "rake"],
                              category: .scripting, highlightLanguage: "ruby", isSystemUTI: true),
            SupportedFileType(id: "php", displayName: "PHP",
                              extensions: ["php"],
                              category: .scripting, highlightLanguage: "php", isSystemUTI: true),
            SupportedFileType(id: "perl", displayName: "Perl",
                              extensions: ["pl", "pm"],
                              category: .scripting, highlightLanguage: "perl", isSystemUTI: true),
            SupportedFileType(id: "lua", displayName: "Lua",
                              extensions: ["lua"],
                              category: .scripting, highlightLanguage: "lua", isSystemUTI: false),
            SupportedFileType(id: "r", displayName: "R",
                              extensions: ["r", "R"],
                              category: .scripting, highlightLanguage: "r", isSystemUTI: false),
            SupportedFileType(id: "julia", displayName: "Julia",
                              extensions: ["jl"],
                              category: .scripting, highlightLanguage: "julia", isSystemUTI: false),
            SupportedFileType(id: "elixir", displayName: "Elixir",
                              extensions: ["ex", "exs"],
                              category: .scripting, highlightLanguage: "elixir", isSystemUTI: false),
            SupportedFileType(id: "erlang", displayName: "Erlang",
                              extensions: ["erl"],
                              category: .scripting, highlightLanguage: "erlang", isSystemUTI: false),
            SupportedFileType(id: "haskell", displayName: "Haskell",
                              extensions: ["hs"],
                              category: .scripting, highlightLanguage: "haskell", isSystemUTI: false),
            SupportedFileType(id: "clojure", displayName: "Clojure",
                              extensions: ["clj", "cljs", "cljc"],
                              category: .scripting, highlightLanguage: "clojure", isSystemUTI: false),

            // MARK: - Data & Config
            SupportedFileType(id: "json", displayName: "JSON",
                              extensions: ["json", "jsonc"],
                              category: .dataFormats, highlightLanguage: "json", isSystemUTI: true),
            SupportedFileType(id: "yaml", displayName: "YAML",
                              extensions: ["yaml", "yml"],
                              category: .dataFormats, highlightLanguage: "yaml", isSystemUTI: true),
            SupportedFileType(id: "toml", displayName: "TOML",
                              extensions: ["toml"],
                              category: .dataFormats, highlightLanguage: "toml", isSystemUTI: false),
            SupportedFileType(id: "xml", displayName: "XML",
                              extensions: ["xml", "plist", "svg"],
                              category: .dataFormats, highlightLanguage: "xml", isSystemUTI: true),
            SupportedFileType(id: "ini", displayName: "INI/Config",
                              extensions: ["ini", "conf", "cfg", "properties"],
                              category: .dataFormats, highlightLanguage: "ini", isSystemUTI: false),
            SupportedFileType(id: "sql", displayName: "SQL",
                              extensions: ["sql"],
                              category: .dataFormats, highlightLanguage: "sql", isSystemUTI: false),
            SupportedFileType(id: "graphql", displayName: "GraphQL",
                              extensions: ["graphql", "gql"],
                              category: .dataFormats, highlightLanguage: "graphql", isSystemUTI: false),
            SupportedFileType(id: "prisma", displayName: "Prisma",
                              extensions: ["prisma"],
                              category: .dataFormats, highlightLanguage: "prisma", isSystemUTI: false),
            SupportedFileType(id: "protobuf", displayName: "Protocol Buffers",
                              extensions: ["proto"],
                              category: .dataFormats, highlightLanguage: "protobuf", isSystemUTI: false),

            // MARK: - Shell & Terminal
            SupportedFileType(id: "bash", displayName: "Bash",
                              extensions: ["sh", "bash"],
                              category: .shellAndTerminal, highlightLanguage: "bash", isSystemUTI: true),
            SupportedFileType(id: "zsh", displayName: "Zsh",
                              extensions: ["zsh"],
                              category: .shellAndTerminal, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "zsh-theme", displayName: "Zsh Theme",
                              extensions: ["zsh-theme"],
                              category: .shellAndTerminal, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "fish", displayName: "Fish",
                              extensions: ["fish"],
                              category: .shellAndTerminal, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "powershell", displayName: "PowerShell",
                              extensions: ["ps1", "psm1", "psd1"],
                              category: .shellAndTerminal, highlightLanguage: "powershell", isSystemUTI: false),
            SupportedFileType(id: "dockerfile", displayName: "Dockerfile",
                              extensions: ["dockerfile"],
                              category: .shellAndTerminal, highlightLanguage: "dockerfile", isSystemUTI: false),
            SupportedFileType(id: "makefile", displayName: "Makefile",
                              extensions: ["makefile", "make", "mk"],
                              category: .shellAndTerminal, highlightLanguage: "makefile", isSystemUTI: false),

            // MARK: - Documentation
            SupportedFileType(id: "markdown", displayName: "Markdown",
                              extensions: ["md", "markdown"],
                              category: .documentation, highlightLanguage: "markdown", isSystemUTI: true),
            SupportedFileType(id: "mdx", displayName: "MDX",
                              extensions: ["mdx"],
                              category: .documentation, highlightLanguage: "markdown", isSystemUTI: false),
            SupportedFileType(id: "rst", displayName: "reStructuredText",
                              extensions: ["rst"],
                              category: .documentation, highlightLanguage: "plaintext", isSystemUTI: false),
            SupportedFileType(id: "tex", displayName: "LaTeX",
                              extensions: ["tex", "latex"],
                              category: .documentation, highlightLanguage: "latex", isSystemUTI: false),
            SupportedFileType(id: "plaintext", displayName: "Plain Text",
                              extensions: ["txt", "text", "log"],
                              category: .documentation, highlightLanguage: "plaintext", isSystemUTI: true),

            // MARK: - Dotfiles
            SupportedFileType(id: "gitignore", displayName: "Git Ignore",
                              extensions: ["gitignore"],
                              category: .dotfiles, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "gitconfig", displayName: "Git Config",
                              extensions: ["gitconfig", "gitattributes"],
                              category: .dotfiles, highlightLanguage: "ini", isSystemUTI: false),
            SupportedFileType(id: "env", displayName: "Environment",
                              extensions: ["env", "env.local", "env.development", "env.production"],
                              category: .dotfiles, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "editorconfig", displayName: "EditorConfig",
                              extensions: ["editorconfig"],
                              category: .dotfiles, highlightLanguage: "ini", isSystemUTI: false),
            SupportedFileType(id: "npmrc", displayName: "NPM Config",
                              extensions: ["npmrc", "nvmrc", "yarnrc"],
                              category: .dotfiles, highlightLanguage: "ini", isSystemUTI: false),
            SupportedFileType(id: "shellrc", displayName: "Shell Config",
                              extensions: [], filenames: [".zshrc", ".zshenv", ".zprofile", ".bashrc", ".bash_profile", ".bash_logout", ".profile"],
                              category: .dotfiles, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "shell-profile", displayName: "Shell Profile",
                              extensions: [], filenames: [".profile", ".login", ".logout"],
                              category: .dotfiles, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "tmux-conf", displayName: "tmux Config",
                              extensions: [], filenames: [".tmux.conf"],
                              category: .dotfiles, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "dockerignore", displayName: "Docker Ignore",
                              extensions: [], filenames: [".dockerignore", ".containerignore"],
                              category: .dotfiles, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "dev-ignore", displayName: "Dev Ignore Files",
                              extensions: [], filenames: [".prettierignore", ".eslintignore", ".stylelintignore"],
                              category: .dotfiles, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "version-files", displayName: "Version Files",
                              extensions: [], filenames: [".ruby-version", ".python-version", ".node-version", ".nvmrc", ".tool-versions"],
                              category: .dotfiles, highlightLanguage: "plaintext", isSystemUTI: false),
            SupportedFileType(id: "vimrc", displayName: "Vim Config",
                              extensions: [], filenames: [".vimrc", ".viminfo"],
                              category: .dotfiles, highlightLanguage: "plaintext", isSystemUTI: false),

            // MARK: - Common Config Filenames
            SupportedFileType(id: "makefile-file", displayName: "Makefile",
                              extensions: [], filenames: ["Makefile", "GNUmakefile", "makefile"],
                              category: .dataFormats, highlightLanguage: "makefile", isSystemUTI: false),
            SupportedFileType(id: "dockerfile-file", displayName: "Dockerfile",
                              extensions: [], filenames: ["Dockerfile", "Containerfile"],
                              category: .dataFormats, highlightLanguage: "dockerfile", isSystemUTI: false),
            SupportedFileType(id: "gemfile-file", displayName: "Gemfile",
                              extensions: [], filenames: ["Gemfile", "Rakefile", "Vagrantfile", "Brewfile"],
                              category: .dataFormats, highlightLanguage: "ruby", isSystemUTI: false),
            SupportedFileType(id: "procfile-file", displayName: "Procfile",
                              extensions: [], filenames: ["Procfile"],
                              category: .dataFormats, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "license-file", displayName: "License",
                              extensions: [], filenames: ["LICENSE", "LICENSE.md", "LICENSE.txt", "COPYING"],
                              category: .documentation, highlightLanguage: "plaintext", isSystemUTI: false),
            SupportedFileType(id: "changelog-file", displayName: "Changelog",
                              extensions: [], filenames: ["CHANGELOG", "CHANGELOG.md"],
                              category: .documentation, highlightLanguage: "markdown", isSystemUTI: false),
            SupportedFileType(id: "authors-file", displayName: "Authors",
                              extensions: [], filenames: ["AUTHORS", "CONTRIBUTORS"],
                              category: .documentation, highlightLanguage: "plaintext", isSystemUTI: false),
            SupportedFileType(id: "go-mod-file", displayName: "Go Module",
                              extensions: [], filenames: ["go.mod", "go.sum"],
                              category: .dataFormats, highlightLanguage: "go", isSystemUTI: false),
            SupportedFileType(id: "cargo-file", displayName: "Cargo Config",
                              extensions: [], filenames: ["Cargo.toml", "Cargo.lock"],
                              category: .dataFormats, highlightLanguage: "toml", isSystemUTI: false),
            SupportedFileType(id: "package-json-file", displayName: "Package JSON",
                              extensions: [], filenames: ["package.json", "package-lock.json"],
                              category: .dataFormats, highlightLanguage: "json", isSystemUTI: false),
            SupportedFileType(id: "tsconfig-file", displayName: "TypeScript Config",
                              extensions: [], filenames: ["tsconfig.json", "jsconfig.json"],
                              category: .dataFormats, highlightLanguage: "json", isSystemUTI: false),
            SupportedFileType(id: "requirements-file", displayName: "Python Requirements",
                              extensions: [], filenames: ["requirements.txt"],
                              category: .dataFormats, highlightLanguage: "plaintext", isSystemUTI: false),
            SupportedFileType(id: "codeowners", displayName: "CODEOWNERS",
                              extensions: [], filenames: ["CODEOWNERS"],
                              category: .dataFormats, highlightLanguage: "plaintext", isSystemUTI: false),

            // MARK: - Backup & Temp Files
            SupportedFileType(id: "backup", displayName: "Backup File",
                              extensions: ["backup", "bak", "old", "orig", "tmp", "temp", "swp", "swo"],
                              category: .dataFormats, highlightLanguage: "plaintext", isSystemUTI: false),
            SupportedFileType(id: "dist-sample", displayName: "Distribution Sample",
                              extensions: ["dist", "sample", "example", "default", "template"],
                              category: .dataFormats, highlightLanguage: "plaintext", isSystemUTI: false),

            // MARK: - Additional Config Files
            SupportedFileType(id: "rcfile", displayName: "RC Configuration",
                              extensions: ["rc", "prettierrc", "eslintrc", "babelrc", "stylelintrc"],
                              category: .dotfiles, highlightLanguage: "json", isSystemUTI: false),
            SupportedFileType(id: "htaccess", displayName: "Web Server Config",
                              extensions: ["htaccess", "htpasswd"],
                              category: .dotfiles, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "lockfile", displayName: "Lock File",
                              extensions: ["lock"],
                              category: .dataFormats, highlightLanguage: "yaml", isSystemUTI: false),

            // MARK: - Log & Data Files
            SupportedFileType(id: "logfile", displayName: "Log File",
                              extensions: ["logs", "out", "err", "debug"],
                              category: .documentation, highlightLanguage: "plaintext", isSystemUTI: false),
            SupportedFileType(id: "datafile", displayName: "Data File",
                              extensions: ["csv", "tsv", "dat"],
                              category: .dataFormats, highlightLanguage: "plaintext", isSystemUTI: false),

            // MARK: - Additional Systems Languages
            SupportedFileType(id: "nim", displayName: "Nim",
                              extensions: ["nim"],
                              category: .systemsLanguages, highlightLanguage: "nim", isSystemUTI: false),
            SupportedFileType(id: "vlang", displayName: "V",
                              extensions: ["v"],
                              category: .systemsLanguages, highlightLanguage: "v", isSystemUTI: false),
            SupportedFileType(id: "dlang", displayName: "D",
                              extensions: ["d"],
                              category: .systemsLanguages, highlightLanguage: "d", isSystemUTI: false),
            SupportedFileType(id: "fsharp", displayName: "F#",
                              extensions: ["fs", "fsx", "fsi"],
                              category: .systemsLanguages, highlightLanguage: "fsharp", isSystemUTI: false),
            SupportedFileType(id: "ocaml", displayName: "OCaml",
                              extensions: ["ml", "mli"],
                              category: .systemsLanguages, highlightLanguage: "ocaml", isSystemUTI: false),
            SupportedFileType(id: "tcl", displayName: "Tcl",
                              extensions: ["tcl", "tk"],
                              category: .scripting, highlightLanguage: "tcl", isSystemUTI: false),
            SupportedFileType(id: "assembly", displayName: "Assembly",
                              extensions: ["asm", "s"],
                              category: .systemsLanguages, highlightLanguage: "x86asm", isSystemUTI: false),

            // MARK: - Additional Scripting
            SupportedFileType(id: "rmd", displayName: "R Markdown",
                              extensions: ["rmd"],
                              category: .scripting, highlightLanguage: "r", isSystemUTI: false),
            SupportedFileType(id: "erlang-hrl", displayName: "Erlang Header",
                              extensions: ["hrl"],
                              category: .scripting, highlightLanguage: "erlang", isSystemUTI: false),
            SupportedFileType(id: "haskell-lhs", displayName: "Literate Haskell",
                              extensions: ["lhs"],
                              category: .scripting, highlightLanguage: "haskell", isSystemUTI: false),

            // MARK: - Template Languages
            SupportedFileType(id: "nunjucks", displayName: "Nunjucks/Jinja",
                              extensions: ["njk", "nunjucks", "jinja", "jinja2", "j2"],
                              category: .webDevelopment, highlightLanguage: "django", isSystemUTI: false),
            SupportedFileType(id: "twig", displayName: "Twig",
                              extensions: ["twig"],
                              category: .webDevelopment, highlightLanguage: "twig", isSystemUTI: false),
            SupportedFileType(id: "handlebars", displayName: "Handlebars/Mustache",
                              extensions: ["hbs", "handlebars", "mustache"],
                              category: .webDevelopment, highlightLanguage: "handlebars", isSystemUTI: false),
            SupportedFileType(id: "pug", displayName: "Pug/Jade",
                              extensions: ["pug", "jade"],
                              category: .webDevelopment, highlightLanguage: "pug", isSystemUTI: false),
            SupportedFileType(id: "haml", displayName: "HAML/Slim",
                              extensions: ["haml", "slim"],
                              category: .webDevelopment, highlightLanguage: "haml", isSystemUTI: false),
            SupportedFileType(id: "liquid", displayName: "Liquid",
                              extensions: ["liquid"],
                              category: .webDevelopment, highlightLanguage: "liquid", isSystemUTI: false),
            SupportedFileType(id: "ejs", displayName: "EJS",
                              extensions: ["ejs"],
                              category: .webDevelopment, highlightLanguage: "ejs", isSystemUTI: false),

            // MARK: - Documentation Markup
            SupportedFileType(id: "asciidoc", displayName: "AsciiDoc",
                              extensions: ["adoc", "asciidoc"],
                              category: .documentation, highlightLanguage: "asciidoc", isSystemUTI: false),
            SupportedFileType(id: "org", displayName: "Org Mode",
                              extensions: ["org"],
                              category: .documentation, highlightLanguage: "plaintext", isSystemUTI: false),
            SupportedFileType(id: "textile", displayName: "Textile",
                              extensions: ["textile"],
                              category: .documentation, highlightLanguage: "plaintext", isSystemUTI: false),

            // MARK: - DevOps & Infrastructure
            SupportedFileType(id: "terraform", displayName: "Terraform/HCL",
                              extensions: ["tf", "tfvars", "hcl"],
                              category: .dataFormats, highlightLanguage: "hcl", isSystemUTI: false),
            SupportedFileType(id: "hashicorp", displayName: "HashiCorp",
                              extensions: ["nomad", "consul", "vault"],
                              category: .dataFormats, highlightLanguage: "hcl", isSystemUTI: false),
            SupportedFileType(id: "kubernetes", displayName: "Kubernetes/Helm",
                              extensions: ["helm", "k8s", "kubernetes"],
                              category: .dataFormats, highlightLanguage: "yaml", isSystemUTI: false),
            SupportedFileType(id: "devops", displayName: "DevOps Config",
                              extensions: ["vagrantfile", "procfile"],
                              category: .dataFormats, highlightLanguage: "ruby", isSystemUTI: false),

            // MARK: - Build Tools
            SupportedFileType(id: "cmake", displayName: "CMake",
                              extensions: ["cmake"],
                              category: .shellAndTerminal, highlightLanguage: "cmake", isSystemUTI: false),
            SupportedFileType(id: "gradle", displayName: "Gradle",
                              extensions: ["gradle"],
                              category: .dataFormats, highlightLanguage: "groovy", isSystemUTI: false),
            SupportedFileType(id: "maven", displayName: "Maven",
                              extensions: ["pom"],
                              category: .dataFormats, highlightLanguage: "xml", isSystemUTI: false),
            SupportedFileType(id: "ruby-build", displayName: "Ruby Build",
                              extensions: ["gemfile", "rakefile", "guardfile"],
                              category: .scripting, highlightLanguage: "ruby", isSystemUTI: false),
            SupportedFileType(id: "taskrunner", displayName: "Task Runner",
                              extensions: ["justfile", "taskfile"],
                              category: .shellAndTerminal, highlightLanguage: "bash", isSystemUTI: false),

            // MARK: - Shell Variants
            SupportedFileType(id: "csh", displayName: "C Shell",
                              extensions: ["csh", "tcsh"],
                              category: .shellAndTerminal, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "ksh", displayName: "Korn Shell",
                              extensions: ["ksh"],
                              category: .shellAndTerminal, highlightLanguage: "bash", isSystemUTI: false),
            SupportedFileType(id: "ash", displayName: "Ash/Dash Shell",
                              extensions: ["ash", "dash"],
                              category: .shellAndTerminal, highlightLanguage: "bash", isSystemUTI: false),

            // MARK: - Windows Scripts
            SupportedFileType(id: "batch", displayName: "Windows Batch",
                              extensions: ["bat", "cmd"],
                              category: .shellAndTerminal, highlightLanguage: "dos", isSystemUTI: false),
            SupportedFileType(id: "vbscript", displayName: "VBScript",
                              extensions: ["vbs", "vba"],
                              category: .scripting, highlightLanguage: "vbscript", isSystemUTI: false),
        ]
    }

    // MARK: - Query Methods

    public func typesByCategory() -> [FileTypeCategory: [SupportedFileType]] {
        var grouped: [FileTypeCategory: [SupportedFileType]] = [:]
        for type in builtInTypes {
            grouped[type.category, default: []].append(type)
        }
        for key in grouped.keys {
            grouped[key]?.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        }
        return grouped
    }

    public func isExtensionEnabled(_ ext: String) -> Bool {
        let lowered = ext.lowercased()
        let disabled = SharedSettings.shared.disabledFileTypes

        if let type = extensionToType[lowered] {
            return !disabled.contains(type.id)
        }

        let customs = SharedSettings.shared.customExtensions
        if customs.contains(where: { $0.extensionName == lowered || $0.filenameMatch?.lowercased() == lowered }) {
            return true
        }

        return true
    }

    public func highlightLanguage(for ext: String) -> String? {
        let lowered = ext.lowercased()

        // Check custom extensions first — enables overrides and filename mappings
        if let custom = SharedSettings.shared.customExtensions.first(where: { $0.extensionName == lowered }) {
            return custom.highlightLanguage
        }

        return extensionToType[lowered]?.highlightLanguage
    }

    /// Look up highlight language by exact filename (e.g., "Jenkinsfile").
    public func highlightLanguageByFilename(_ filename: String) -> String? {
        let lowered = filename.lowercased()
        if let custom = SharedSettings.shared.customExtensions.first(where: { $0.filenameMatch?.lowercased() == lowered }) {
            return custom.highlightLanguage
        }
        return nil
    }

    /// Look up display name by exact filename (e.g., "Jenkinsfile").
    public func displayNameByFilename(_ filename: String) -> String? {
        let lowered = filename.lowercased()
        if let custom = SharedSettings.shared.customExtensions.first(where: { $0.filenameMatch?.lowercased() == lowered }) {
            return custom.displayName
        }
        return nil
    }

    public func fileType(for ext: String) -> SupportedFileType? {
        extensionToType[ext.lowercased()]
    }

    public func displayName(for ext: String) -> String? {
        let lowered = ext.lowercased()
        if let custom = SharedSettings.shared.customExtensions.first(where: { $0.extensionName == lowered }) {
            return custom.displayName
        }
        return extensionToType[lowered]?.displayName
    }

    public func fileType(byId id: String) -> SupportedFileType? {
        idToType[id]
    }

    public func search(_ query: String) -> [SupportedFileType] {
        guard !query.isEmpty else { return builtInTypes }

        let lowered = query.lowercased()
        return builtInTypes.filter { type in
            type.displayName.localizedCaseInsensitiveContains(lowered) ||
            type.extensions.contains { $0.localizedCaseInsensitiveContains(lowered) }
        }
    }
}
