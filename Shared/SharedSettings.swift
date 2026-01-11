import Foundation

/// Manages settings shared between main app and Quick Look extension via App Groups
/// Thread-safe for concurrent access from main app and Quick Look extension
final class SharedSettings: @unchecked Sendable {
    static let shared = SharedSettings()

    private let suiteName = "group.com.stianlars1.dotviewer"
    private let lock = NSLock()

    /// UserDefaults instance for App Group shared container (initialized eagerly for thread safety)
    let userDefaults: UserDefaults

    private init() {
        if let defaults = UserDefaults(suiteName: suiteName) {
            self.userDefaults = defaults
        } else {
            // Note: print() not visible in production Console, but App Group failure is rare
            // and usually indicates provisioning profile misconfiguration
            print("Warning: Could not access App Group, falling back to standard")
            self.userDefaults = .standard
        }
    }

    // MARK: - Theme Settings

    var selectedTheme: String {
        get { lock.withLock { userDefaults.string(forKey: "selectedTheme") ?? "auto" } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "selectedTheme") } }
    }

    var fontSize: Double {
        get {
            lock.withLock {
                let value = userDefaults.double(forKey: "fontSize")
                return value > 0 ? value : 13.0
            }
        }
        set {
            lock.withLock {
                // Clamp to valid range: 8-72 points
                let clamped = max(8, min(72, newValue))
                userDefaults.set(clamped, forKey: "fontSize")
            }
        }
    }

    var showLineNumbers: Bool {
        get { lock.withLock { userDefaults.object(forKey: "showLineNumbers") as? Bool ?? true } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "showLineNumbers") } }
    }

    // MARK: - File Type Settings

    var disabledFileTypes: Set<String> {
        get {
            lock.withLock {
                let array = userDefaults.stringArray(forKey: "disabledFileTypes") ?? []
                return Set(array)
            }
        }
        set {
            lock.withLock {
                userDefaults.set(Array(newValue), forKey: "disabledFileTypes")
            }
        }
    }

    var customExtensions: [CustomExtension] {
        get {
            lock.withLock {
                guard let data = userDefaults.data(forKey: "customExtensions"),
                      let extensions = try? JSONDecoder().decode([CustomExtension].self, from: data)
                else { return [] }
                return extensions
            }
        }
        set {
            lock.withLock {
                if let data = try? JSONEncoder().encode(newValue) {
                    userDefaults.set(data, forKey: "customExtensions")
                }
            }
        }
    }

    // MARK: - Developer Settings

    var maxFileSize: Int {
        get {
            lock.withLock {
                let value = userDefaults.integer(forKey: "maxFileSize")
                return value > 0 ? value : 500_000 // 500KB default
            }
        }
        set {
            lock.withLock {
                // Clamp to valid range: 10KB - 50MB
                let clamped = max(10_000, min(50_000_000, newValue))
                userDefaults.set(clamped, forKey: "maxFileSize")
            }
        }
    }

    var showTruncationWarning: Bool {
        get { lock.withLock { userDefaults.object(forKey: "showTruncationWarning") as? Bool ?? true } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "showTruncationWarning") } }
    }

    // MARK: - Preview UI Settings

    var showPreviewHeader: Bool {
        get { lock.withLock { userDefaults.object(forKey: "showPreviewHeader") as? Bool ?? true } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "showPreviewHeader") } }
    }

    /// Markdown render mode: "raw" or "rendered"
    var markdownRenderMode: String {
        get { lock.withLock { userDefaults.string(forKey: "markdownRenderMode") ?? "raw" } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "markdownRenderMode") } }
    }

    var previewUnknownFiles: Bool {
        get { lock.withLock { userDefaults.object(forKey: "previewUnknownFiles") as? Bool ?? true } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "previewUnknownFiles") } }
    }

    // MARK: - Open in App Settings

    /// Bundle identifier of the preferred app for opening files (e.g., "com.microsoft.VSCode")
    var preferredEditorBundleId: String? {
        get { lock.withLock { userDefaults.string(forKey: "preferredEditorBundleId") } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "preferredEditorBundleId") } }
    }

    /// Display name of the preferred editor (for UI)
    var preferredEditorName: String? {
        get { lock.withLock { userDefaults.string(forKey: "preferredEditorName") } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "preferredEditorName") } }
    }

    /// Whether to show the "Open in App" button in preview header
    var showOpenInAppButton: Bool {
        get { lock.withLock { userDefaults.object(forKey: "showOpenInAppButton") as? Bool ?? true } }
        set { lock.withLock { userDefaults.set(newValue, forKey: "showOpenInAppButton") } }
    }
}

// MARK: - Custom Extension Model

/// User-defined custom extension mapping
struct CustomExtension: Identifiable, Codable, Hashable {
    let id: UUID
    var extensionName: String // without dot
    var displayName: String
    var highlightLanguage: String

    init(extensionName: String, displayName: String, highlightLanguage: String) {
        self.id = UUID()
        self.extensionName = extensionName.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        self.displayName = displayName
        self.highlightLanguage = highlightLanguage
    }

    init(id: UUID = UUID(), extensionName: String, displayName: String, highlightLanguage: String) {
        self.id = id
        self.extensionName = extensionName.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        self.displayName = displayName
        self.highlightLanguage = highlightLanguage
    }
}

// MARK: - Supported Editors Registry

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
