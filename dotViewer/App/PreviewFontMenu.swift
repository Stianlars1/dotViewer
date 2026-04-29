import AppKit
import Shared

enum PreviewFontMenu {
    static var codeFontFamilies: [String] {
        uniqueFamilies(prepending: [PreviewFontFamily.defaultCodeFamily])
    }

    static var renderedFontFamilies: [String] {
        uniqueFamilies(prepending: [PreviewFontFamily.defaultMarkdownRenderedFamily])
    }

    static func title(for family: String) -> String {
        switch family {
        case PreviewFontFamily.defaultCodeFamily:
            return "Default (\(PreviewFontFamily.defaultCodeFamily))"
        case PreviewFontFamily.systemSansValue:
            return "System"
        default:
            return family
        }
    }

    private static func uniqueFamilies(prepending preferred: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for family in preferred + NSFontManager.shared.availableFontFamilies.sorted() {
            let sanitized = PreviewFontFamily.sanitized(family, fallback: "")
            guard !sanitized.isEmpty, !seen.contains(sanitized) else { continue }
            seen.insert(sanitized)
            result.append(sanitized)
        }

        return result
    }
}
