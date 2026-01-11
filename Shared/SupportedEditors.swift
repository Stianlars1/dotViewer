import Foundation
import AppKit

/// Centralized registry of supported code editors for "Open In" functionality
enum SupportedEditors {
    /// Tuple type for editor definitions
    typealias EditorInfo = (name: String, bundleId: String, icon: String)

    /// All supported editors with their bundle identifiers and SF Symbol icons
    static let all: [EditorInfo] = [
        ("VS Code", "com.microsoft.VSCode", "curlybraces.square"),
        ("Xcode", "com.apple.dt.Xcode", "hammer"),
        ("Sublime", "com.sublimetext.4", "text.alignleft"),
        ("TextEdit", "com.apple.TextEdit", "doc.text"),
        ("Nova", "com.panic.Nova", "sparkle"),
        ("BBEdit", "com.barebones.bbedit", "text.badge.star"),
        ("Cursor", "com.todesktop.230313mzl4w4u92", "cursorarrow.click.badge.clock"),
        ("Zed", "dev.zed.Zed", "text.cursor"),
    ]

    /// Just the bundle identifiers for quick lookups
    static let bundleIdentifiers: Set<String> = Set(all.map(\.bundleId))

    /// Check if a bundle ID is one of the preset editors
    static func isPresetEditor(_ bundleId: String) -> Bool {
        bundleIdentifiers.contains(bundleId)
    }

    /// Returns only editors that are installed on the current system
    static var installed: [EditorInfo] {
        all.filter { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.bundleId) != nil }
    }
}
