import Foundation

/// All syntax token types used in highlighting.
/// Adding a case here forces updates to `ThemePalette.hex(for:)`,
/// `PreviewHTMLBuilder` CSS generation, and `TokenColorMapper`.
public enum TokenType: String, CaseIterable, Sendable {
    case comment
    case keyword
    case string
    case number
    case type
    case function
    case property
    case punctuation
    case tag
    case attribute
    case escape
    case builtin
    case namespace
    case parameter
    // Semantic aliases (not backed by palette properties — they map to other tokens)
    case constant    // uses number color
    case identifier  // uses text color
}

public struct ThemeChoice: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct ThemePalette: Equatable, Sendable {
    public let name: String
    public let isDark: Bool
    public let background: String
    public let text: String
    public let comment: String
    public let keyword: String
    public let string: String
    public let number: String
    public let type: String
    public let function: String
    public let property: String
    public let punctuation: String
    public let accent: String
    public let tag: String
    public let attribute: String
    public let escape: String
    public let builtin: String
    public let namespace: String
    public let parameter: String

    /// Returns the hex color for a given token type.
    /// The exhaustive switch ensures compile-time enforcement when new cases are added.
    public func hex(for token: TokenType) -> String {
        switch token {
        case .comment:     return comment
        case .keyword:     return keyword
        case .string:      return string
        case .number:      return number
        case .type:        return type
        case .function:    return function
        case .property:    return property
        case .punctuation: return punctuation
        case .tag:         return tag
        case .attribute:   return attribute
        case .escape:      return escape
        case .builtin:     return builtin
        case .namespace:   return namespace
        case .parameter:   return parameter
        case .constant:    return number
        case .identifier:  return text
        }
    }

    public static let selectableThemes: [ThemeChoice] = [
        ThemeChoice(id: "auto", title: "Atom One (System)"),
        ThemeChoice(id: "atomOneLight", title: "Atom One Light"),
        ThemeChoice(id: "atomOneDark", title: "Atom One Dark"),
        ThemeChoice(id: "githubAuto", title: "GitHub (System)"),
        ThemeChoice(id: "githubLight", title: "GitHub Light"),
        ThemeChoice(id: "githubDark", title: "GitHub Dark"),
        ThemeChoice(id: "xcodeAuto", title: "Xcode (System)"),
        ThemeChoice(id: "xcodeLight", title: "Xcode Light"),
        ThemeChoice(id: "xcodeDark", title: "Xcode Dark"),
        ThemeChoice(id: "solarizedAuto", title: "Solarized (System)"),
        ThemeChoice(id: "solarizedLight", title: "Solarized Light"),
        ThemeChoice(id: "solarizedDark", title: "Solarized Dark"),
        ThemeChoice(id: "tokyoNight", title: "Tokyo Night"),
        ThemeChoice(id: "blackout", title: "Blackout"),
    ]

    public static func followsSystemAppearance(theme: String) -> Bool {
        systemThemePair(for: theme) != nil
    }

    public static func lightPalette(for theme: String) -> ThemePalette {
        if let pair = systemThemePair(for: theme) {
            return pair.light
        }
        return palette(for: theme, systemIsDark: false)
    }

    public static func darkPalette(for theme: String) -> ThemePalette? {
        if let pair = systemThemePair(for: theme) {
            return pair.dark
        }
        let palette = palette(for: theme, systemIsDark: true)
        return palette.isDark ? palette : nil
    }

    public static func systemThemePair(for theme: String) -> (light: ThemePalette, dark: ThemePalette)? {
        switch theme {
        case "auto":
            return (.atomOneLight, .atomOneDark)
        case "githubAuto":
            return (.githubLight, .githubDark)
        case "xcodeAuto":
            return (.xcodeLight, .xcodeDark)
        case "solarizedAuto":
            return (.solarizedLight, .solarizedDark)
        default:
            return nil
        }
    }

    public static func palette(for theme: String, systemIsDark: Bool) -> ThemePalette {
        if let pair = systemThemePair(for: theme) {
            return systemIsDark ? pair.dark : pair.light
        }

        switch theme {
        case "atomOneLight":
            return .atomOneLight
        case "atomOneDark":
            return .atomOneDark
        case "githubLight":
            return .githubLight
        case "githubDark":
            return .githubDark
        case "xcodeLight":
            return .xcodeLight
        case "xcodeDark":
            return .xcodeDark
        case "solarizedLight":
            return .solarizedLight
        case "solarizedDark":
            return .solarizedDark
        case "tokyoNight":
            return .tokyoNight
        case "blackout":
            return .blackout
        default:
            return systemIsDark ? .atomOneDark : .atomOneLight
        }
    }

    public static let atomOneLight = ThemePalette(
        name: "Atom One Light",
        isDark: false,
        background: "#FAFAFA",
        text: "#383A42",
        comment: "#A0A1A7",
        keyword: "#A626A4",
        string: "#50A14F",
        number: "#986801",
        type: "#C18401",
        function: "#4078F2",
        property: "#0184BC",
        punctuation: "#383A42",
        accent: "#007AFF",
        tag: "#E45649",
        attribute: "#986801",
        escape: "#0184BC",
        builtin: "#0184BC",
        namespace: "#E45649",
        parameter: "#383A42"
    )

    public static let atomOneDark = ThemePalette(
        name: "Atom One Dark",
        isDark: true,
        background: "#282C34",
        text: "#ABB2BF",
        comment: "#5C6370",
        keyword: "#C678DD",
        string: "#98C379",
        number: "#D19A66",
        type: "#E5C07B",
        function: "#61AFEF",
        property: "#56B6C2",
        punctuation: "#ABB2BF",
        accent: "#007AFF",
        tag: "#E06C75",
        attribute: "#D19A66",
        escape: "#56B6C2",
        builtin: "#56B6C2",
        namespace: "#E06C75",
        parameter: "#ABB2BF"
    )

    public static let githubLight = ThemePalette(
        name: "GitHub Light",
        isDark: false,
        background: "#FFFFFF",
        text: "#24292E",
        comment: "#6A737D",
        keyword: "#D73A49",
        string: "#032F62",
        number: "#005CC5",
        type: "#E36209",
        function: "#6F42C1",
        property: "#005CC5",
        punctuation: "#24292E",
        accent: "#0969DA",
        tag: "#22863A",
        attribute: "#E36209",
        escape: "#E36209",
        builtin: "#005CC5",
        namespace: "#005CC5",
        parameter: "#E36209"
    )

    public static let githubDark = ThemePalette(
        name: "GitHub Dark",
        isDark: true,
        background: "#0D1117",
        text: "#C9D1D9",
        comment: "#8B949E",
        keyword: "#FF7B72",
        string: "#A5D6FF",
        number: "#79C0FF",
        type: "#FFA657",
        function: "#D2A8FF",
        property: "#79C0FF",
        punctuation: "#C9D1D9",
        accent: "#2F81F7",
        tag: "#7EE787",
        attribute: "#FFA657",
        escape: "#FFA657",
        builtin: "#FFA198",
        namespace: "#FFA198",
        parameter: "#FFA198"
    )

    public static let xcodeLight = ThemePalette(
        name: "Xcode Light",
        isDark: false,
        background: "#FFFFFF",
        text: "#000000",
        comment: "#3F6E2A",
        keyword: "#AD3DA4",
        string: "#C41A16",
        number: "#1C00CF",
        type: "#0B4F79",
        function: "#326D74",
        property: "#0B4F79",
        punctuation: "#000000",
        accent: "#007AFF",
        tag: "#326D74",
        attribute: "#AD3DA4",
        escape: "#C41A16",
        builtin: "#AD3DA4",
        namespace: "#0B4F79",
        parameter: "#000000"
    )

    public static let xcodeDark = ThemePalette(
        name: "Xcode Dark",
        isDark: true,
        background: "#1F1F24",
        text: "#E6E6E6",
        comment: "#6A9955",
        keyword: "#C586C0",
        string: "#CE9178",
        number: "#B5CEA8",
        type: "#DABAFF",
        function: "#67B7A4",
        property: "#9CDCFE",
        punctuation: "#E6E6E6",
        accent: "#0A84FF",
        tag: "#67B7A4",
        attribute: "#B281EB",
        escape: "#CE9178",
        builtin: "#B281EB",
        namespace: "#4EC9B0",
        parameter: "#E6E6E6"
    )

    public static let solarizedLight = ThemePalette(
        name: "Solarized Light",
        isDark: false,
        background: "#FDF6E3",
        text: "#657B83",
        comment: "#93A1A1",
        keyword: "#859900",
        string: "#2AA198",
        number: "#D33682",
        type: "#B58900",
        function: "#268BD2",
        property: "#268BD2",
        punctuation: "#657B83",
        accent: "#268BD2",
        tag: "#268BD2",
        attribute: "#B58900",
        escape: "#DC322F",
        builtin: "#D33682",
        namespace: "#D33682",
        parameter: "#657B83"
    )

    public static let solarizedDark = ThemePalette(
        name: "Solarized Dark",
        isDark: true,
        background: "#002B36",
        text: "#839496",
        comment: "#586E75",
        keyword: "#859900",
        string: "#2AA198",
        number: "#D33682",
        type: "#B58900",
        function: "#268BD2",
        property: "#268BD2",
        punctuation: "#839496",
        accent: "#268BD2",
        tag: "#268BD2",
        attribute: "#B58900",
        escape: "#DC322F",
        builtin: "#D33682",
        namespace: "#D33682",
        parameter: "#839496"
    )

    public static let tokyoNight = ThemePalette(
        name: "Tokyo Night",
        isDark: true,
        background: "#1A1B26",
        text: "#A9B1D6",
        comment: "#565F89",
        keyword: "#BB9AF7",
        string: "#9ECE6A",
        number: "#FF9E64",
        type: "#2AC3DE",
        function: "#7AA2F7",
        property: "#7DCFFF",
        punctuation: "#A9B1D6",
        accent: "#7AA2F7",
        tag: "#F7768E",
        attribute: "#FF9E64",
        escape: "#89DDFF",
        builtin: "#E0AF68",
        namespace: "#F7768E",
        parameter: "#E0AF68"
    )

    public static let blackout = ThemePalette(
        name: "Blackout",
        isDark: true,
        background: "#0E0E10",
        text: "#E0E0E0",
        comment: "#808080",
        keyword: "#C678DD",
        string: "#98C379",
        number: "#D19A66",
        type: "#E5C07B",
        function: "#61AFEF",
        property: "#56B6C2",
        punctuation: "#E0E0E0",
        accent: "#007AFF",
        tag: "#E06C75",
        attribute: "#D19A66",
        escape: "#56B6C2",
        builtin: "#56B6C2",
        namespace: "#E06C75",
        parameter: "#E0E0E0"
    )
}
