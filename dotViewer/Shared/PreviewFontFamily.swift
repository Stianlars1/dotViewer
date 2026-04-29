import AppKit
import Foundation

public enum PreviewFontFamily {
    public static let systemSansValue = "System"
    public static let defaultCodeFamily = "SF Mono"
    public static let defaultMarkdownRenderedFamily = systemSansValue

    public static let systemSansCSSStack = "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Helvetica, Arial, sans-serif"
    public static let codeFallbackCSSStack = "\"SF Mono\", Menlo, Monaco, Consolas, \"Liberation Mono\", monospace"

    public static func sanitized(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }

        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_./"))
        let scalars = trimmed.unicodeScalars.filter { allowed.contains($0) }
        let sanitized = String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else { return fallback }
        return String(sanitized.prefix(80))
    }

    public static func codeCSSStack(for familyName: String) -> String {
        preferredCSSStack(
            familyName: familyName,
            fallbackFamily: defaultCodeFamily,
            fallbackStack: codeFallbackCSSStack
        )
    }

    public static func markdownCSSStack(for familyName: String) -> String {
        let sanitized = sanitized(familyName, fallback: defaultMarkdownRenderedFamily)
        if sanitized == systemSansValue {
            return systemSansCSSStack
        }
        return preferredCSSStack(
            familyName: sanitized,
            fallbackFamily: defaultMarkdownRenderedFamily,
            fallbackStack: systemSansCSSStack
        )
    }

    private static func preferredCSSStack(
        familyName: String,
        fallbackFamily: String,
        fallbackStack: String
    ) -> String {
        let sanitized = sanitized(familyName, fallback: fallbackFamily)
        if sanitized == systemSansValue {
            return systemSansCSSStack
        }
        return "\"\(escapeCSSString(sanitized))\", \(fallbackStack)"
    }

    private static func escapeCSSString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

public enum PreviewFontResolver {
    public static func codeFont(
        familyName: String,
        size: CGFloat,
        weight: NSFont.Weight = .regular,
        traits: NSFontDescriptor.SymbolicTraits = []
    ) -> NSFont {
        let family = PreviewFontFamily.sanitized(
            familyName,
            fallback: PreviewFontFamily.defaultCodeFamily
        )

        if family == PreviewFontFamily.defaultCodeFamily {
            let base = NSFont.monospacedSystemFont(ofSize: size, weight: weight)
            return applying(traits: traits, to: base, size: size)
        }

        if let selected = font(familyName: family, size: size, weight: weight, traits: traits) {
            return selected
        }

        let fallback = NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        return applying(traits: traits, to: fallback, size: size)
    }

    public static func appFont(
        familyName: String,
        size: CGFloat,
        weight: NSFont.Weight = .regular
    ) -> NSFont {
        let family = PreviewFontFamily.sanitized(
            familyName,
            fallback: PreviewFontFamily.defaultMarkdownRenderedFamily
        )

        if family == PreviewFontFamily.systemSansValue {
            return NSFont.systemFont(ofSize: size, weight: weight)
        }

        return font(familyName: family, size: size, weight: weight, traits: []) ??
            NSFont.systemFont(ofSize: size, weight: weight)
    }

    private static func font(
        familyName: String,
        size: CGFloat,
        weight: NSFont.Weight,
        traits: NSFontDescriptor.SymbolicTraits
    ) -> NSFont? {
        let manager = NSFontManager.shared
        return manager.font(
            withFamily: familyName,
            traits: fontManagerTraits(from: traits),
            weight: fontManagerWeight(from: weight),
            size: size
        ) ?? NSFont(name: familyName, size: size).map {
            applying(traits: traits, to: $0, size: size)
        }
    }

    private static func applying(
        traits: NSFontDescriptor.SymbolicTraits,
        to font: NSFont,
        size: CGFloat
    ) -> NSFont {
        guard !traits.isEmpty else {
            return font
        }
        let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: size) ?? font
    }

    private static func fontManagerTraits(
        from traits: NSFontDescriptor.SymbolicTraits
    ) -> NSFontTraitMask {
        var mask: NSFontTraitMask = []
        if traits.contains(.italic) {
            mask.insert(.italicFontMask)
        }
        return mask
    }

    private static func fontManagerWeight(from weight: NSFont.Weight) -> Int {
        if weight < .light {
            return 2
        }
        if weight < .regular {
            return 4
        }
        if weight < .semibold {
            return 5
        }
        if weight < .bold {
            return 8
        }
        return 9
    }
}
