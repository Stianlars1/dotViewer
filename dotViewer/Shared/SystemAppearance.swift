import Foundation

public enum SystemAppearance {
    public static func isDark(defaults: UserDefaults = .standard) -> Bool {
        guard let style = defaults.string(forKey: "AppleInterfaceStyle") else {
            return false
        }
        return style.caseInsensitiveCompare("dark") == .orderedSame
    }
}
