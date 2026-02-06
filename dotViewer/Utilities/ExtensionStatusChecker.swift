import Foundation
import SwiftUI

/// Checks if the Quick Look extension is enabled in System Settings.
actor ExtensionStatusChecker {
    static let shared = ExtensionStatusChecker()

    private let extensionBundleId = "com.stianlars1.dotViewer.QuickLookPreview"

    private init() {}

    func checkStatus() async -> ExtensionStatus {
        // 1. Check if the appex exists on disk — most reliable in a sandboxed app.
        if checkViaFilesystem() {
            // Extension is bundled; try pluginkit to confirm it's not explicitly disabled.
            if let status = try? await checkViaListing() {
                return status
            }
            // pluginkit unavailable in sandbox — assume enabled since appex is present.
            return .enabled
        }

        // 2. Try pluginkit directly (works outside sandbox / development builds).
        if let status = try? await checkViaListing() {
            return status
        }
        if let status = try? await checkViaExtensionInfo() {
            return status
        }

        return .disabled
    }

    /// Check if the appex file exists in the app bundle's PlugIns directory.
    private func checkViaFilesystem() -> Bool {
        // Try the standard builtInPlugInsURL first
        if let pluginsURL = Bundle.main.builtInPlugInsURL {
            let appexURL = pluginsURL.appendingPathComponent("QuickLookExtension.appex")
            if FileManager.default.fileExists(atPath: appexURL.path) {
                return true
            }
        }

        // Fallback: construct the path manually from the bundle URL
        let manualURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/PlugIns/QuickLookExtension.appex")
        return FileManager.default.fileExists(atPath: manualURL.path)
    }

    /// Check via `pluginkit -m` listing all preview extensions.
    private func checkViaListing() async throws -> ExtensionStatus? {
        let output = try await runPluginkit(arguments: ["-m", "-p", "com.apple.quicklook.preview"])
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains(extensionBundleId) else { continue }

            if trimmed.hasPrefix("-") {
                return .disabled
            }
            // "+" means explicitly enabled; no prefix means system-managed (also enabled)
            return .enabled
        }

        return nil
    }

    /// Check via `pluginkit -e info -i <bundleID>` for a targeted query.
    private func checkViaExtensionInfo() async throws -> ExtensionStatus? {
        let output = try await runPluginkit(arguments: ["-e", "info", "-i", extensionBundleId])
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // If the output contains the bundle ID, the extension is registered
        if trimmed.contains(extensionBundleId) {
            return .enabled
        }

        return nil
    }

    private func runPluginkit(arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Discard stderr separately

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw PluginkitError.invalidOutput
        }

        return output
    }

    enum PluginkitError: LocalizedError {
        case invalidOutput

        var errorDescription: String? {
            switch self {
            case .invalidOutput:
                return "Could not read pluginkit output"
            }
        }
    }
}

enum ExtensionStatus: Equatable {
    case checking
    case enabled
    case disabled
    case error(String)

    var title: String {
        switch self {
        case .checking:
            "Checking Extension Status..."
        case .enabled:
            "Extension Enabled"
        case .disabled:
            "Extension Not Enabled"
        case .error(let message):
            "Error: \(message)"
        }
    }

    var description: String {
        switch self {
        case .checking:
            "Verifying Quick Look extension status"
        case .enabled:
            "dotViewer is ready"
        case .disabled:
            "Enable dotViewer in System Settings to preview code files."
        case .error:
            "Could not determine extension status."
        }
    }

    var icon: String {
        switch self {
        case .checking:
            "hourglass"
        case .enabled:
            "checkmark.circle.fill"
        case .disabled:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.circle.fill"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .checking:
            Color.blue.opacity(0.15)
        case .enabled:
            Color.green.opacity(0.15)
        case .disabled:
            Color.orange.opacity(0.15)
        case .error:
            Color.red.opacity(0.15)
        }
    }

    var iconColor: Color {
        switch self {
        case .checking:
            .blue
        case .enabled:
            .green
        case .disabled:
            .orange
        case .error:
            .red
        }
    }
}
