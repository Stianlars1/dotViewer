import Foundation

/// Represents a file type category for organization in the UI.
public enum FileTypeCategory: String, CaseIterable, Codable, Identifiable {
    case webDevelopment = "Web Development"
    case systemsLanguages = "Systems Languages"
    case scripting = "Scripting"
    case dataFormats = "Data & Config"
    case documentation = "Documentation"
    case shellAndTerminal = "Shell & Terminal"
    case dotfiles = "Dotfiles"
    case custom = "Custom"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .webDevelopment: return "globe"
        case .systemsLanguages: return "cpu"
        case .scripting: return "chevron.left.forwardslash.chevron.right"
        case .dataFormats: return "doc.text"
        case .documentation: return "text.justify"
        case .shellAndTerminal: return "terminal"
        case .dotfiles: return "gearshape"
        case .custom: return "plus.circle"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .webDevelopment: return 0
        case .systemsLanguages: return 1
        case .scripting: return 2
        case .dataFormats: return 3
        case .shellAndTerminal: return 4
        case .documentation: return 5
        case .dotfiles: return 6
        case .custom: return 7
        }
    }
}

/// Represents a supported file type.
public struct SupportedFileType: Identifiable, Codable, Hashable {
    public let id: String
    public let displayName: String
    public let extensions: [String]
    public let filenames: [String]
    public let category: FileTypeCategory
    public let highlightLanguage: String
    public let isSystemUTI: Bool

    public init(
        id: String,
        displayName: String,
        extensions: [String],
        filenames: [String] = [],
        category: FileTypeCategory,
        highlightLanguage: String,
        isSystemUTI: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.extensions = extensions
        self.filenames = filenames
        self.category = category
        self.highlightLanguage = highlightLanguage
        self.isSystemUTI = isSystemUTI
    }

    public var extensionDisplay: String {
        let extensionItems = extensions.map { ".\($0)" }
        if !extensionItems.isEmpty {
            return extensionItems.joined(separator: ", ")
        }
        if filenames.isEmpty {
            return "—"
        }
        return filenames.joined(separator: ", ")
    }
}

/// User-defined custom extension mapping.
public struct CustomExtension: Identifiable, Codable, Hashable {
    public let id: UUID
    public var extensionName: String
    public var displayName: String
    public var highlightLanguage: String
    public var filenameMatch: String?

    public init(extensionName: String, displayName: String, highlightLanguage: String, filenameMatch: String? = nil) {
        self.id = UUID()
        self.extensionName = extensionName.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        self.displayName = displayName
        self.highlightLanguage = highlightLanguage
        self.filenameMatch = filenameMatch
    }

    public init(id: UUID, extensionName: String, displayName: String, highlightLanguage: String, filenameMatch: String? = nil) {
        self.id = id
        self.extensionName = extensionName.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        self.displayName = displayName
        self.highlightLanguage = highlightLanguage
        self.filenameMatch = filenameMatch
    }

    /// Whether this is a filename-based mapping (e.g., "Jenkinsfile") rather than extension-based.
    public var isFilenameMapping: Bool {
        filenameMatch != nil
    }
}

/// Available highlight language identifiers for custom extensions.
public struct HighlightLanguage: Identifiable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let hasTreeSitterGrammar: Bool

    public init(id: String, displayName: String, hasTreeSitterGrammar: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.hasTreeSitterGrammar = hasTreeSitterGrammar
    }

    /// Display name with quality tier suffix for picker UI.
    public var pickerDisplayName: String {
        hasTreeSitterGrammar ? displayName : "\(displayName) (basic)"
    }

    public static let all: [HighlightLanguage] = [
        // Plain text (no highlighting)
        HighlightLanguage(id: "plaintext", displayName: "Plain Text"),

        // Tree-sitter grammars (full highlighting)
        HighlightLanguage(id: "awk", displayName: "AWK", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "bash", displayName: "Bash/Shell", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "c", displayName: "C", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "cpp", displayName: "C++", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "csharp", displayName: "C#", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "clojure", displayName: "Clojure", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "cmake", displayName: "CMake", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "css", displayName: "CSS", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "d", displayName: "D", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "dart", displayName: "Dart", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "dockerfile", displayName: "Dockerfile", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "elixir", displayName: "Elixir", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "erlang", displayName: "Erlang", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "fish", displayName: "Fish", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "fortran", displayName: "Fortran", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "gleam", displayName: "Gleam", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "go", displayName: "Go", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "graphql", displayName: "GraphQL", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "haskell", displayName: "Haskell", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "hcl", displayName: "HCL/Terraform", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "html", displayName: "HTML", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "ini", displayName: "INI/Config", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "java", displayName: "Java", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "javascript", displayName: "JavaScript", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "json", displayName: "JSON", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "julia", displayName: "Julia", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "kotlin", displayName: "Kotlin", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "lua", displayName: "Lua", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "makefile", displayName: "Makefile", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "markdown", displayName: "Markdown", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "nix", displayName: "Nix", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "objectivec", displayName: "Objective-C", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "ocaml", displayName: "OCaml", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "pascal", displayName: "Pascal", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "perl", displayName: "Perl", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "php", displayName: "PHP", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "python", displayName: "Python", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "r", displayName: "R", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "ruby", displayName: "Ruby", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "rust", displayName: "Rust", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "scala", displayName: "Scala", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "scss", displayName: "SCSS", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "sql", displayName: "SQL", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "swift", displayName: "Swift", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "toml", displayName: "TOML", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "tsx", displayName: "TSX", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "typescript", displayName: "TypeScript", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "vim", displayName: "Vim Script", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "wat", displayName: "WebAssembly", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "xml", displayName: "XML", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "yaml", displayName: "YAML", hasTreeSitterGrammar: true),
        HighlightLanguage(id: "zig", displayName: "Zig", hasTreeSitterGrammar: true),

        // Heuristic-only (basic keyword highlighting)
        HighlightLanguage(id: "diff", displayName: "Diff"),
        HighlightLanguage(id: "nginx", displayName: "Nginx"),
    ]
}

/// Shared validation for custom extension/filename entries.
public enum CustomExtensionValidation {
    public static let reservedExtensions: Set<String> = [
        "app", "framework", "bundle", "plugin", "kext", "xpc",
        "dylib", "a", "o", "so", "dll", "exe", "bin",
        "dmg", "pkg", "mpkg", "iso", "img",
        "zip", "tar", "gz", "bz2", "xz", "rar", "7z",
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
        "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "heif",
        "mp3", "mp4", "wav", "aac", "flac", "mov", "avi", "mkv", "webm"
    ]

    public static let maxExtensionLength = 30
    public static let maxFilenameLength = 60

    /// Validate an extension name (without leading dot).
    public static func validateExtension(_ ext: String) -> String? {
        if ext.isEmpty {
            return "Extension cannot be empty."
        }
        if ext.count > maxExtensionLength {
            return "Extension is too long (max \(maxExtensionLength) characters)."
        }
        if ext.hasPrefix(".") || ext.hasSuffix(".") {
            return "Extension cannot start or end with a dot."
        }
        if ext.contains("..") {
            return "Extension cannot contain consecutive dots."
        }
        if ext.contains("/") || ext.contains("\\") {
            return "Extension contains invalid characters."
        }
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>| \t\n\r")
        if ext.unicodeScalars.contains(where: { invalidChars.contains($0) }) {
            return "Extension contains invalid characters (spaces, special characters, etc.)."
        }
        let allowedChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        if !ext.unicodeScalars.allSatisfy({ allowedChars.contains($0) }) {
            return "Extension must contain only letters, numbers, hyphens, underscores, or dots."
        }
        if reservedExtensions.contains(ext) {
            return "'\(ext)' is a reserved system extension and cannot be added."
        }
        return nil
    }

    /// Validate a filename (e.g., "Jenkinsfile").
    public static func validateFilename(_ name: String) -> String? {
        if name.isEmpty {
            return "Filename cannot be empty."
        }
        if name.count > maxFilenameLength {
            return "Filename is too long (max \(maxFilenameLength) characters)."
        }
        if name.contains("/") || name.contains("\\") || name.contains(":") {
            return "Filename cannot contain path separators."
        }
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|\t\n\r")
        if name.unicodeScalars.contains(where: { invalidChars.contains($0) }) {
            return "Filename contains invalid characters."
        }
        return nil
    }

    /// Auto-generate a display name from an extension.
    public static func autoDisplayName(from ext: String) -> String {
        let base = ext.components(separatedBy: ".").last ?? ext
        return base.prefix(1).uppercased() + base.dropFirst()
    }

    /// Auto-generate a display name from a filename.
    public static func autoDisplayNameFromFilename(_ name: String) -> String {
        name
    }
}
