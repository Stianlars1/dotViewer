import Foundation

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

    public static func palette(for theme: String, systemIsDark: Bool) -> ThemePalette {
        switch theme {
        case "auto":
            return systemIsDark ? .atomOneDark : .atomOneLight
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
        accent: "#007AFF"
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
        accent: "#007AFF"
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
        type: "#6F42C1",
        function: "#6F42C1",
        property: "#005CC5",
        punctuation: "#24292E",
        accent: "#0969DA"
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
        type: "#D2A8FF",
        function: "#D2A8FF",
        property: "#A5D6FF",
        punctuation: "#C9D1D9",
        accent: "#2F81F7"
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
        function: "#0B4F79",
        property: "#0B4F79",
        punctuation: "#000000",
        accent: "#007AFF"
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
        type: "#4EC9B0",
        function: "#DCDCAA",
        property: "#9CDCFE",
        punctuation: "#E6E6E6",
        accent: "#0A84FF"
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
        accent: "#268BD2"
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
        accent: "#268BD2"
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
        accent: "#7AA2F7"
    )

    public static let blackout = ThemePalette(
        name: "Blackout",
        isDark: true,
        background: "#0E0E10",
        text: "#E0E0E0",
        comment: "#5F5F5F",
        keyword: "#C678DD",
        string: "#98C379",
        number: "#D19A66",
        type: "#E5C07B",
        function: "#61AFEF",
        property: "#56B6C2",
        punctuation: "#E0E0E0",
        accent: "#007AFF"
    )
}
