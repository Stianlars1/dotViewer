import Foundation

/// Represents a file type category for organization in the UI
enum FileTypeCategory: String, CaseIterable, Codable, Identifiable {
    case webDevelopment = "Web Development"
    case systemsLanguages = "Systems Languages"
    case scripting = "Scripting"
    case dataFormats = "Data & Config"
    case documentation = "Documentation"
    case shellAndTerminal = "Shell & Terminal"
    case dotfiles = "Dotfiles"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
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

    var sortOrder: Int {
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

/// Represents a supported file type
struct SupportedFileType: Identifiable, Codable, Hashable {
    let id: String // unique identifier
    let displayName: String
    let extensions: [String]
    let category: FileTypeCategory
    let highlightLanguage: String
    let isSystemUTI: Bool // true if macOS provides UTI

    var extensionDisplay: String {
        extensions.map { ".\($0)" }.joined(separator: ", ")
    }
}

/// Available highlight.js languages for custom extension picker
struct HighlightLanguage: Identifiable, Hashable {
    let id: String
    let displayName: String

    static let all: [HighlightLanguage] = [
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
