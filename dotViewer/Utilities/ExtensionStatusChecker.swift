import Foundation
import SwiftUI
import OSLog

actor ExtensionStatusChecker {
    static let shared = ExtensionStatusChecker()
    private static let extensionBundleId = "com.stianlars1.dotViewer.QuickLookPreview"
    private let command: @Sendable ([String]) async throws -> String
    private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "ExtensionStatus")

    init(command: @escaping @Sendable ([String]) async throws -> String = { arguments in
        try await StatusProcessRunner.run(path: "/usr/bin/pluginkit", arguments: arguments)
    }) {
        self.command = command
    }

    func checkStatus() async -> ExtensionStatus {
        do {
            let output = try await command(["-m", "-i", Self.extensionBundleId])
            var sawDisabled = false
            var sawInconclusive = false
            for line in output.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let record = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "+-=!?").union(.whitespaces))
                guard record.hasPrefix(Self.extensionBundleId + "(") else { continue }
                if trimmed.hasPrefix("-") {
                    sawDisabled = true
                } else if ["=", "?", "!"].contains(where: trimmed.hasPrefix) {
                    sawInconclusive = true
                } else {
                    logger.info("Extension status resolved: enabled")
                    return .enabled
                }
            }
            if sawDisabled {
                logger.info("Extension status resolved: disabled")
                return .disabled
            }
            if sawInconclusive {
                logger.error("Extension registration is inconclusive")
                return .error("Extension status could not be confirmed. Try again.")
            }
            logger.info("Extension status resolved: not registered")
            return .disabled
        } catch StatusProcessRunner.Failure.timedOut {
            logger.error("Extension status check timed out")
            return .error("Status check timed out. Try again.")
        } catch {
            logger.error("Extension status check failed")
            return .error("Unable to check extension status. Try again.")
        }
    }
}

enum ExtensionStatus: Equatable, Sendable {
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
