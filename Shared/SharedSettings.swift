import Foundation
import os.log

private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "SharedSettings")

/// Manages settings shared between main app and Quick Look extension via App Groups
/// Thread-safe for concurrent access from main app and Quick Look extension
///
/// Thread Safety (@unchecked Sendable justification):
/// This class is manually verified thread-safe through:
/// - `lock`: NSLock protecting all property access (getters and setters)
/// - `userDefaults` and `isUsingAppGroup`: Immutable after initialization
/// - All public properties use `lock.withLock { }` for atomic read/write
final class SharedSettings: @unchecked Sendable {
    static let shared = SharedSettings()

    private let suiteName = "group.stianlars1.dotViewer.shared"
    private let lock = NSLock()

    /// Indicates whether App Group access succeeded (for diagnostics)
    let isUsingAppGroup: Bool

    /// UserDefaults instance for App Group shared container (initialized eagerly for thread safety)
    let userDefaults: UserDefaults

    private init() {
        if let defaults = UserDefaults(suiteName: suiteName) {
            self.userDefaults = defaults
            self.isUsingAppGroup = true
            logger.info("App Group container accessed successfully")
        } else {
            // App Group failure is rare and usually indicates provisioning profile misconfiguration
            logger.error("Could not access App Group container - settings will not sync between app and extension")
            self.userDefaults = .standard
            self.isUsingAppGroup = false
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
                do {
                    let data = try JSONEncoder().encode(newValue)
                    userDefaults.set(data, forKey: "customExtensions")
                } catch {
                    logger.error("Failed to encode custom extensions: \(error.localizedDescription)")
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
