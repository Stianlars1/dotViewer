import Foundation

/// Manages settings shared between main app and Quick Look extension via App Groups
final class SharedSettings: @unchecked Sendable {
    static let shared = SharedSettings()

    private let suiteName = "group.com.stianlars1.dotviewer"

    /// UserDefaults instance for App Group shared container
    lazy var userDefaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("Warning: Could not access App Group, falling back to standard")
            return .standard
        }
        return defaults
    }()

    private init() {}

    // MARK: - Theme Settings

    var selectedTheme: String {
        get { userDefaults.string(forKey: "selectedTheme") ?? "auto" }
        set {
            userDefaults.set(newValue, forKey: "selectedTheme")
            userDefaults.synchronize()
        }
    }

    var fontSize: Double {
        get {
            let value = userDefaults.double(forKey: "fontSize")
            return value > 0 ? value : 13.0
        }
        set {
            userDefaults.set(newValue, forKey: "fontSize")
            userDefaults.synchronize()
        }
    }

    var showLineNumbers: Bool {
        get { userDefaults.object(forKey: "showLineNumbers") as? Bool ?? true }
        set {
            userDefaults.set(newValue, forKey: "showLineNumbers")
            userDefaults.synchronize()
        }
    }

    // MARK: - File Type Settings

    var disabledFileTypes: Set<String> {
        get {
            let array = userDefaults.stringArray(forKey: "disabledFileTypes") ?? []
            return Set(array)
        }
        set {
            userDefaults.set(Array(newValue), forKey: "disabledFileTypes")
            userDefaults.synchronize()
        }
    }

    var customExtensions: [CustomExtension] {
        get {
            guard let data = userDefaults.data(forKey: "customExtensions"),
                  let extensions = try? JSONDecoder().decode([CustomExtension].self, from: data)
            else { return [] }
            return extensions
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: "customExtensions")
                userDefaults.synchronize()
            }
        }
    }

    // MARK: - Developer Settings

    var maxFileSize: Int {
        get {
            let value = userDefaults.integer(forKey: "maxFileSize")
            return value > 0 ? value : 500_000 // 500KB default
        }
        set {
            userDefaults.set(newValue, forKey: "maxFileSize")
            userDefaults.synchronize()
        }
    }

    var showTruncationWarning: Bool {
        get { userDefaults.object(forKey: "showTruncationWarning") as? Bool ?? true }
        set {
            userDefaults.set(newValue, forKey: "showTruncationWarning")
            userDefaults.synchronize()
        }
    }

    // MARK: - Preview UI Settings

    var showPreviewHeader: Bool {
        get { userDefaults.object(forKey: "showPreviewHeader") as? Bool ?? true }
        set {
            userDefaults.set(newValue, forKey: "showPreviewHeader")
            userDefaults.synchronize()
        }
    }

    /// Markdown render mode: "raw" or "rendered"
    var markdownRenderMode: String {
        get { userDefaults.string(forKey: "markdownRenderMode") ?? "rendered" }
        set {
            userDefaults.set(newValue, forKey: "markdownRenderMode")
            userDefaults.synchronize()
        }
    }

    var previewUnknownFiles: Bool {
        get { userDefaults.object(forKey: "previewUnknownFiles") as? Bool ?? true }
        set {
            userDefaults.set(newValue, forKey: "previewUnknownFiles")
            userDefaults.synchronize()
        }
    }

    // MARK: - Open in App Settings

    /// Bundle identifier of the preferred app for opening files (e.g., "com.microsoft.VSCode")
    var preferredEditorBundleId: String? {
        get { userDefaults.string(forKey: "preferredEditorBundleId") }
        set {
            userDefaults.set(newValue, forKey: "preferredEditorBundleId")
            userDefaults.synchronize()
        }
    }

    /// Display name of the preferred editor (for UI)
    var preferredEditorName: String? {
        get { userDefaults.string(forKey: "preferredEditorName") }
        set {
            userDefaults.set(newValue, forKey: "preferredEditorName")
            userDefaults.synchronize()
        }
    }

    /// Whether to show the "Open in App" button in preview header
    var showOpenInAppButton: Bool {
        get { userDefaults.object(forKey: "showOpenInAppButton") as? Bool ?? true }
        set {
            userDefaults.set(newValue, forKey: "showOpenInAppButton")
            userDefaults.synchronize()
        }
    }

    // MARK: - Helper to force sync

    func synchronize() {
        userDefaults.synchronize()
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
