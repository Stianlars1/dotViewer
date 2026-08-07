import AppKit
import Shared

enum PreviewFontMenu {
    /// Only fixed-pitch families. The menu previously offered every font installed on the system,
    /// which let a proportional face like Al Nile or Zapfino be picked as the *code* font — columns
    /// stop aligning and such faces often carry old-style figures, so digits in UUIDs and timestamps
    /// drop below the baseline and the preview looks broken rather than merely unusual.
    static var codeFontFamilies: [String] {
        uniqueFamilies(prepending: [PreviewFontFamily.defaultCodeFamily], monospacedOnly: true)
    }

    /// Rendered markdown is prose, so proportional faces are the right default here — no filter.
    static var renderedFontFamilies: [String] {
        uniqueFamilies(prepending: [PreviewFontFamily.defaultMarkdownRenderedFamily])
    }

    /// Resets a stored code font that is not fixed-pitch.
    ///
    /// The picker used to offer every installed family, so existing users can be sitting on a
    /// proportional face (Al Nile, say) with no way to tell that is why their previews look wrong —
    /// filtering the menu alone would leave them stuck, since their font simply vanishes from the
    /// list while still being applied.
    static func migrateInvalidCodeFontIfNeeded() {
        let stored = SharedSettings.shared.codeFontFamilyName
        guard !stored.isEmpty,
              stored != PreviewFontFamily.defaultCodeFamily,
              !isMonospaced(stored)
        else { return }

        SharedSettings.shared.codeFontFamilyName = PreviewFontFamily.defaultCodeFamily
    }

    private static func isMonospaced(_ family: String) -> Bool {
        let descriptor = NSFontDescriptor(fontAttributes: [.family: family])
        // Ask for traits rather than instantiating and reading isFixedPitch: some families only
        // report fixed pitch on particular faces, and this covers the whole family.
        if let font = NSFont(descriptor: descriptor, size: 12), font.isFixedPitch { return true }
        let traits = descriptor.symbolicTraits
        return traits.contains(.monoSpace)
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

    private static func uniqueFamilies(
        prepending preferred: [String],
        monospacedOnly: Bool = false
    ) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        let installed = NSFontManager.shared.availableFontFamilies.sorted()
        let candidates = monospacedOnly ? installed.filter(isMonospaced) : installed

        // `preferred` is never filtered — the default must always be selectable even if the trait
        // check misjudges it.
        for family in preferred + candidates {
            let sanitized = PreviewFontFamily.sanitized(family, fallback: "")
            guard !sanitized.isEmpty, !seen.contains(sanitized) else { continue }
            seen.insert(sanitized)
            result.append(sanitized)
        }

        return result
    }
}
