import Foundation
import AppKit
import os.log

private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "CopyHelper")

enum HelperStatus: Equatable {
    case stopped
    case running
    case needsPermission
    case error(String)
}

@MainActor
final class CopyHelperManager: ObservableObject {
    static let shared = CopyHelperManager()

    @Published var status: HelperStatus = .stopped

    private var process: Process?
    private var stdoutPipe: Pipe?

    private init() {}

    func launch() {
        guard process == nil || process?.isRunning != true else { return }

        guard let helperURL = Self.helperURL() else {
            status = .error("CopyHelper binary not found")
            logger.error("CopyHelper binary not found in app bundle")
            return
        }

        let proc = Process()
        proc.executableURL = helperURL
        proc.arguments = ["--parent-pid", "\(ProcessInfo.processInfo.processIdentifier)"]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        self.stdoutPipe = pipe

        proc.terminationHandler = { [weak self] process in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.process === process {
                    self.process = nil
                    if self.status == .running {
                        self.status = .stopped
                    }
                    logger.info("CopyHelper terminated with status \(process.terminationStatus)")
                }
            }
        }

        do {
            try proc.run()
        } catch {
            status = .error("Failed to launch: \(error.localizedDescription)")
            logger.error("Failed to launch CopyHelper: \(error.localizedDescription)")
            return
        }

        self.process = proc

        // Read first line from stdout/stderr asynchronously for status
        let fileHandle = pipe.fileHandleForReading
        Task.detached { [weak self] in
            let data = fileHandle.availableData
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if output.contains("OK:running") {
                    self.status = .running
                    logger.info("CopyHelper started successfully")
                } else if output.contains("ERROR:accessibility_not_trusted") {
                    self.status = .needsPermission
                    logger.warning("CopyHelper needs Accessibility permission")
                } else if output.contains("ERROR:") {
                    self.status = .error(output)
                    logger.error("CopyHelper error: \(output)")
                }
            }
        }
    }

    func stop() {
        guard let proc = process, proc.isRunning else {
            process = nil
            status = .stopped
            return
        }
        proc.terminate()
        process = nil
        status = .stopped
        logger.info("CopyHelper stopped by user")
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Private

    private static func helperURL() -> URL? {
        // CopyHelper lives alongside the main executable in Contents/MacOS/
        guard let mainExec = Bundle.main.executableURL else { return nil }
        let helperURL = mainExec.deletingLastPathComponent().appendingPathComponent("CopyHelper")
        return FileManager.default.fileExists(atPath: helperURL.path) ? helperURL : nil
    }
}
