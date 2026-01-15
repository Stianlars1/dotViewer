import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "StatusChecker")

/// Singleton that manages Quick Look extension status checking.
/// Uses @MainActor to ensure thread-safe UI updates and survives SwiftUI view recreation.
@MainActor
final class ExtensionStatusChecker: ObservableObject {
    static let shared = ExtensionStatusChecker()

    @Published private(set) var isEnabled = false
    @Published private(set) var isChecking = true

    private var checkTask: Task<Void, Never>?
    private var lastCheckTime: Date?

    private init() {
        logger.debug("ExtensionStatusChecker initialized")
    }

    /// Triggers a status check, cancelling any in-flight check to prevent races.
    func check() {
        // Debounce: skip if checked within last 0.5 seconds to prevent rapid successive calls
        if let lastCheck = lastCheckTime, Date().timeIntervalSince(lastCheck) < 0.5 {
            return
        }
        lastCheckTime = Date()

        // Cancel previous check if still running
        checkTask?.cancel()
        isChecking = true

        checkTask = Task {
            logger.info("Starting extension status check")
            let enabled = await checkPluginkit()

            // Only update if this task wasn't cancelled
            guard !Task.isCancelled else {
                logger.debug("Status check cancelled, skipping update")
                return
            }

            self.isEnabled = enabled
            self.isChecking = false
            logger.info("Extension status: \(enabled ? "enabled" : "disabled")")
        }
    }

    /// Runs pluginkit command and parses output to determine extension status.
    /// Marked nonisolated to avoid blocking the MainActor.
    private nonisolated func checkPluginkit() async -> Bool {
        await withCheckedContinuation { continuation in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
            task.arguments = ["-mA", "-p", "com.apple.quicklook.preview"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice

            // Thread-safe flag to ensure we only resume once
            let didResume = LockedValue(false)

            let resumeOnce: (Bool) -> Void = { enabled in
                let alreadyResumed = didResume.withLock { value in
                    if value { return true }
                    value = true
                    return false
                }
                guard !alreadyResumed else { return }
                continuation.resume(returning: enabled)
            }

            // Set up timeout using DispatchWorkItem (not semaphore - avoids blocking)
            let timeoutWork = DispatchWorkItem {
                logger.warning("pluginkit timed out after 5 seconds")
                task.terminate()
                resumeOnce(false)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: timeoutWork)

            task.terminationHandler = { [pipe] _ in
                timeoutWork.cancel()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                logger.debug("pluginkit output length: \(data.count) bytes")

                // Parse: "+    bundleID(version)" = enabled, "-" = disabled, space = neutral
                for line in output.components(separatedBy: .newlines) {
                    if line.contains("com.stianlars1.dotViewer.QuickLookPreview") {
                        // First char determines status: + = enabled, - = disabled
                        let enabled = line.first == "+"
                        logger.info("Found extension: enabled=\(enabled)")
                        resumeOnce(enabled)
                        return
                    }
                }

                logger.warning("Extension not found in pluginkit output")
                resumeOnce(false)
            }

            do {
                try task.run()
                logger.debug("pluginkit process started")
            } catch {
                logger.error("Failed to run pluginkit: \(error.localizedDescription)")
                timeoutWork.cancel()
                resumeOnce(false)
            }
        }
    }
}

/// Thread-safe wrapper for a value, used to ensure continuation is resumed only once.
private final class LockedValue<T>: @unchecked Sendable {
    private var value: T
    private let lock = NSLock()

    init(_ value: T) {
        self.value = value
    }

    func withLock<R>(_ body: (inout T) -> R) -> R {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}
