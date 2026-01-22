import Foundation

/// Central registry of all supported file types with O(1) lookup
///
/// Thread Safety (@unchecked Sendable justification):
/// This class is inherently thread-safe because:
/// - All properties (`builtInTypes`, `extensionToType`, `idToType`) are immutable after init
/// - `SharedSettings.shared` access in query methods is itself thread-safe
/// - No mutable state exists; the registry is read-only after construction
final class FileTypeRegistry: @unchecked Sendable {
    static let shared = FileTypeRegistry()

    /// All built-in file types organized by category
    let builtInTypes: [SupportedFileType]

    // Pre-computed lookup dictionaries for O(1) access
    private let extensionToType: [String: SupportedFileType]
    private let idToType: [String: SupportedFileType]

    private init() {
        // Initialize built-in types
        let types = Self.createBuiltInTypes()
        self.builtInTypes = types

        // Build lookup dictionaries
        var extMap: [String: SupportedFileType] = [:]
        var idMap: [String: SupportedFileType] = [:]

        extMap.reserveCapacity(types.count * 3) // Average ~3 extensions per type
        idMap.reserveCapacity(types.count)

        for type in types {
            idMap[type.id] = type
            for ext in type.extensions {
                extMap[ext.lowercased()] = type
            }
        }

        self.extensionToType = extMap
        self.idToType = idMap
    }

    /// Creates all built-in file types
    private static func createBuiltInTypes() -> [SupportedFileType] {
        return [
            // MARK: - Web Development
            SupportedFileType(id: "typescript", displayName: "TypeScript",
                              extensions: ["ts", "mts", "cts"],
                              category: .webDevelopment, highlightLanguage: "typescript", isSystemUTI: false),
            SupportedFileType(id: "tsx", displayName: "TypeScript JSX",
                              extensions: ["tsx"],
                              category: .webDevelopment, highlightLanguage: "typescript", isSystemUTI: false),
            SupportedFileType(id: "javascript", displayName: "JavaScript",
                              extensions: ["js", "mjs", "cjs"],
                              category: .webDevelopment, highlightLanguage: "javascript", isSystemUTI: true),
            SupportedFileType(id: "jsx", displayName: "JavaScript JSX",
                              extensions: ["jsx"],
                              category: .webDevelopment, highlightLanguage: "javascript", isSystemUTI: false),
            SupportedFileType(id: "vue", displayName: "Vue",
                              extensions: ["vue"],
                              category: .webDevelopment, highlightLanguage: "xml", isSystemUTI: false),
            SupportedFileType(id: "svelte", displayName: "Svelte",
                              extensions: ["svelte"],
                              category: .webDevelopment, highlightLanguage: "xml", isSystemUTI: false),
            SupportedFileType(id: "astro", displayName: "Astro",
                              extensions: ["astro"],
                              category: .webDevelopment, highlightLanguage: "xml", isSystemUTI: false),
            SupportedFileType(id: "html", displayName: "HTML",
                              extensions: ["html", "htm", "xhtml"],
                              category: .webDevelopment, highlightLanguage: "xml", isSystemUTI: true),
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
                              category: .dataFormats, highlightLanguage: "ini", isSystemUTI: false),
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

    // MARK: - Query Methods (O(1) lookups)

    /// Get all types grouped by category
    func typesByCategory() -> [FileTypeCategory: [SupportedFileType]] {
        var grouped: [FileTypeCategory: [SupportedFileType]] = [:]
        for type in builtInTypes {
            grouped[type.category, default: []].append(type)
        }
        return grouped
    }

    /// Check if a file extension is enabled - O(1) lookup
    func isExtensionEnabled(_ ext: String) -> Bool {
        let lowered = ext.lowercased()
        let disabled = SharedSettings.shared.disabledFileTypes

        // Check built-in types - O(1) dictionary lookup
        if let type = extensionToType[lowered] {
            return !disabled.contains(type.id)
        }

        // Check custom extensions - they're always enabled if they exist
        let customs = SharedSettings.shared.customExtensions
        if customs.contains(where: { $0.extensionName == lowered }) {
            return true
        }

        // Unknown extension - allow by default (will be detected by filename or content)
        return true
    }

    /// Get highlight language for extension - O(1) lookup
    func highlightLanguage(for ext: String) -> String? {
        let lowered = ext.lowercased()

        // Check custom first (user overrides)
        if let custom = SharedSettings.shared.customExtensions.first(where: { $0.extensionName == lowered }) {
            return custom.highlightLanguage
        }

        // Check built-in - O(1) dictionary lookup
        return extensionToType[lowered]?.highlightLanguage
    }

    /// Get file type by extension - O(1) lookup
    func fileType(for ext: String) -> SupportedFileType? {
        extensionToType[ext.lowercased()]
    }

    /// Get file type by ID - O(1) lookup
    func fileType(byId id: String) -> SupportedFileType? {
        idToType[id]
    }

    /// Search file types by name or extension
    func search(_ query: String) -> [SupportedFileType] {
        guard !query.isEmpty else { return builtInTypes }

        let lowered = query.lowercased()
        return builtInTypes.filter { type in
            type.displayName.localizedCaseInsensitiveContains(lowered) ||
            type.extensions.contains { $0.localizedCaseInsensitiveContains(lowered) }
        }
    }
}
