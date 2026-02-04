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
    public let category: FileTypeCategory
    public let highlightLanguage: String
    public let isSystemUTI: Bool

    public init(
        id: String,
        displayName: String,
        extensions: [String],
        category: FileTypeCategory,
        highlightLanguage: String,
        isSystemUTI: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.extensions = extensions
        self.category = category
        self.highlightLanguage = highlightLanguage
        self.isSystemUTI = isSystemUTI
    }

    public var extensionDisplay: String {
        extensions.map { ".\($0)" }.joined(separator: ", ")
    }
}

/// User-defined custom extension mapping.
public struct CustomExtension: Identifiable, Codable, Hashable {
    public let id: UUID
    public var extensionName: String
    public var displayName: String
    public var highlightLanguage: String

    public init(extensionName: String, displayName: String, highlightLanguage: String) {
        self.id = UUID()
        self.extensionName = extensionName.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        self.displayName = displayName
        self.highlightLanguage = highlightLanguage
    }

    public init(id: UUID, extensionName: String, displayName: String, highlightLanguage: String) {
        self.id = id
        self.extensionName = extensionName.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        self.displayName = displayName
        self.highlightLanguage = highlightLanguage
    }
}

/// Available highlight language identifiers for custom extensions.
public struct HighlightLanguage: Identifiable, Hashable, Sendable {
    public let id: String
    public let displayName: String

    public static let all: [HighlightLanguage] = [
        HighlightLanguage(id: "plaintext", displayName: "Plain Text"),
        HighlightLanguage(id: "bash", displayName: "Bash/Shell"),
        HighlightLanguage(id: "c", displayName: "C"),
        HighlightLanguage(id: "cpp", displayName: "C++"),
        HighlightLanguage(id: "csharp", displayName: "C#"),
        HighlightLanguage(id: "css", displayName: "CSS"),
        HighlightLanguage(id: "diff", displayName: "Diff"),
        HighlightLanguage(id: "dockerfile", displayName: "Dockerfile"),
        HighlightLanguage(id: "go", displayName: "Go"),
        HighlightLanguage(id: "graphql", displayName: "GraphQL"),
        HighlightLanguage(id: "html", displayName: "HTML"),
        HighlightLanguage(id: "ini", displayName: "INI/Config"),
        HighlightLanguage(id: "java", displayName: "Java"),
        HighlightLanguage(id: "javascript", displayName: "JavaScript"),
        HighlightLanguage(id: "json", displayName: "JSON"),
        HighlightLanguage(id: "kotlin", displayName: "Kotlin"),
        HighlightLanguage(id: "lua", displayName: "Lua"),
        HighlightLanguage(id: "makefile", displayName: "Makefile"),
        HighlightLanguage(id: "markdown", displayName: "Markdown"),
        HighlightLanguage(id: "nginx", displayName: "Nginx"),
        HighlightLanguage(id: "objectivec", displayName: "Objective-C"),
        HighlightLanguage(id: "perl", displayName: "Perl"),
        HighlightLanguage(id: "php", displayName: "PHP"),
        HighlightLanguage(id: "python", displayName: "Python"),
        HighlightLanguage(id: "ruby", displayName: "Ruby"),
        HighlightLanguage(id: "rust", displayName: "Rust"),
        HighlightLanguage(id: "scala", displayName: "Scala"),
        HighlightLanguage(id: "scss", displayName: "SCSS"),
        HighlightLanguage(id: "sql", displayName: "SQL"),
        HighlightLanguage(id: "swift", displayName: "Swift"),
        HighlightLanguage(id: "typescript", displayName: "TypeScript"),
        HighlightLanguage(id: "xml", displayName: "XML"),
        HighlightLanguage(id: "yaml", displayName: "YAML"),
    ]
}
