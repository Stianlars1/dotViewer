import Foundation

/// Represents a registered Quick Look preview extension discovered via pluginkit.
public struct QLExtensionInfo: Identifiable, Sendable {
    public let id: String  // bundle identifier
    public let version: String
    public let path: String
    public let displayName: String
    public let parentName: String
    public let isEnabled: Bool
    public let uuid: String

    /// True when this extension belongs to dotViewer (any version/path).
    public var isDotViewer: Bool {
        id.hasPrefix("com.stianlars1.dotViewer")
    }

    /// True when this extension belongs to Apple.
    public var isApple: Bool {
        id.hasPrefix("com.apple.")
    }

    /// True when this is a third-party extension that could conflict with dotViewer.
    public var isThirdPartyConflict: Bool {
        !isDotViewer && !isApple && isEnabled
    }

    /// The parent app name for display.
    public var appName: String {
        parentName.isEmpty ? displayName : parentName
    }
}

/// Scans for registered Quick Look preview extensions and can enable/disable them.
actor ExtensionConflictScanner {
    static let shared = ExtensionConflictScanner()

    private let dotViewerPreviewId = "com.stianlars1.dotViewer.QuickLookPreview"
    private let dotViewerThumbnailId = "com.stianlars1.dotViewer.QuickLookThumbnail"

    private init() {}

    // MARK: - Discovery

    /// Scans all registered Quick Look preview extensions.
    func scanPreviewExtensions() async -> [QLExtensionInfo] {
        guard let output = try? await runPluginkit(arguments: ["-mDvvv", "-p", "com.apple.quicklook.preview"]) else {
            return []
        }
        return parsePluginkitOutput(output)
    }

    /// Returns only non-Apple, non-dotViewer extensions that are currently enabled.
    func scanConflicts() async -> [QLExtensionInfo] {
        let all = await scanPreviewExtensions()
        return all.filter { $0.isThirdPartyConflict }
    }

    /// Returns stale dotViewer registrations (old build paths that are not /Applications/dotViewer.app).
    func scanStaleDotViewerRegistrations() async -> [QLExtensionInfo] {
        let all = await scanPreviewExtensions()
        return all.filter { ext in
            ext.isDotViewer && !ext.path.hasPrefix("/Applications/dotViewer.app")
        }
    }

    // MARK: - Resolution

    /// Disables a competing extension so dotViewer takes priority.
    @discardableResult
    func disableExtension(_ bundleId: String) async -> Bool {
        guard let _ = try? await runPluginkit(arguments: ["-e", "ignore", "-i", bundleId]) else {
            return false
        }
        return true
    }

    /// Re-enables a previously disabled extension.
    @discardableResult
    func enableExtension(_ bundleId: String) async -> Bool {
        guard let _ = try? await runPluginkit(arguments: ["-e", "use", "-i", bundleId]) else {
            return false
        }
        return true
    }

    /// Ensures dotViewer's own extensions are enabled.
    @discardableResult
    func ensureDotViewerEnabled() async -> Bool {
        let a = await enableExtension(dotViewerPreviewId)
        let b = await enableExtension(dotViewerThumbnailId)
        return a && b
    }

    /// Disables all third-party conflicts and ensures dotViewer is enabled.
    func resolveAllConflicts() async -> Int {
        let conflicts = await scanConflicts()
        var resolved = 0
        for ext in conflicts {
            if await disableExtension(ext.id) {
                resolved += 1
            }
        }
        _ = await ensureDotViewerEnabled()
        // Reset Quick Look cache so changes take effect immediately
        _ = try? await runProcess(path: "/usr/bin/qlmanage", arguments: ["-r"])
        return resolved
    }

    // MARK: - Parsing

    private func parsePluginkitOutput(_ output: String) -> [QLExtensionInfo] {
        var extensions: [QLExtensionInfo] = []
        let lines = output.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Extension header line looks like: "+    com.example.ext(1.0)" or "-    com.example.ext(1.0)"
            guard let match = parseHeaderLine(trimmed, raw: line) else {
                i += 1
                continue
            }

            var path = ""
            var displayName = ""
            var parentName = ""
            var uuid = ""

            // Parse the indented detail lines that follow
            i += 1
            while i < lines.count {
                let detail = lines[i].trimmingCharacters(in: .whitespaces)
                if detail.isEmpty || (!detail.contains("=") && !detail.hasPrefix("SDK") && parseHeaderLine(detail, raw: lines[i]) != nil) {
                    break
                }
                if detail.hasPrefix("Path = ") {
                    path = String(detail.dropFirst("Path = ".count))
                } else if detail.hasPrefix("Display Name = ") {
                    displayName = String(detail.dropFirst("Display Name = ".count))
                } else if detail.hasPrefix("Parent Name = ") {
                    parentName = String(detail.dropFirst("Parent Name = ".count))
                } else if detail.hasPrefix("UUID = ") {
                    uuid = String(detail.dropFirst("UUID = ".count))
                }
                i += 1
            }

            extensions.append(QLExtensionInfo(
                id: match.id,
                version: match.version,
                path: path,
                displayName: displayName,
                parentName: parentName,
                isEnabled: match.isEnabled,
                uuid: uuid
            ))
        }

        return extensions
    }

    private struct HeaderMatch {
        let id: String
        let version: String
        let isEnabled: Bool
    }

    private func parseHeaderLine(_ trimmed: String, raw: String) -> HeaderMatch? {
        // Format: "+    com.example.id(1.0)" or "-    com.example.id(1.0)" or "     com.example.id(1.0)"
        let cleaned = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "+-").union(.whitespaces))
        guard cleaned.contains("(") && cleaned.contains(")") else { return nil }
        guard let parenStart = cleaned.firstIndex(of: "("),
              let parenEnd = cleaned.firstIndex(of: ")") else { return nil }

        let id = String(cleaned[cleaned.startIndex..<parenStart])
        let version = String(cleaned[cleaned.index(after: parenStart)..<parenEnd])

        // Check if it looks like a bundle ID (has at least 2 dots)
        guard id.filter({ $0 == "." }).count >= 2 else { return nil }

        let isEnabled = !raw.trimmingCharacters(in: .whitespaces).hasPrefix("-")

        return HeaderMatch(id: id, version: version, isEnabled: isEnabled)
    }

    // MARK: - Process execution

    private func runPluginkit(arguments: [String]) async throws -> String {
        try await runProcess(path: "/usr/bin/pluginkit", arguments: arguments)
    }

    private func runProcess(path: String, arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
