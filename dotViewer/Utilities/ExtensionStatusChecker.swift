import Foundation
import SwiftUI

/// Checks if the Quick Look extension is enabled in System Settings.
actor ExtensionStatusChecker {
    static let shared = ExtensionStatusChecker()

    private let extensionBundleId = "com.stianlars1.dotViewer.QuickLookPreview"

    private init() {}

    func checkStatus() async -> ExtensionStatus {
        do {
            let output = try await runPluginkit()
            return parsePluginkitOutput(output)
        } catch {
            return .error(error.localizedDescription)
        }
    }

    private func runPluginkit() async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-m", "-p", "com.apple.quicklook.preview"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw PluginkitError.invalidOutput
        }

        return output
    }

    private func parsePluginkitOutput(_ output: String) -> ExtensionStatus {
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains(extensionBundleId) else { continue }

            if trimmed.hasPrefix("+") {
                return .enabled
            } else if trimmed.hasPrefix("-") {
                return .disabled
            }
        }

        return .disabled
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
