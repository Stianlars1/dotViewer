import Foundation
import Darwin

/// Runs short system-status commands off the cooperative executor. File-backed output avoids
/// waiting for a child that is itself waiting for a full stdout/stderr pipe to be drained.
enum StatusProcessRunner {
    enum Failure: Error, Equatable {
        case timedOut
        case unsuccessfulExit(Int32)
        case invalidOutput
    }

    static func run(path: String, arguments: [String], timeout: TimeInterval = 5) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do { continuation.resume(returning: try execute(path: path, arguments: arguments, timeout: timeout)) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    private static func execute(path: String, arguments: [String], timeout: TimeInterval) throws -> String {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let outputURL = directory.appendingPathComponent("stdout")
        let errorURL = directory.appendingPathComponent("stderr")
        try Data().write(to: outputURL)
        try Data().write(to: errorURL)
        let output = try FileHandle(forWritingTo: outputURL)
        defer { try? output.close() }
        let errors = try FileHandle(forWritingTo: errorURL)
        defer { try? errors.close() }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = output
        process.standardError = errors
        try process.run()

        let deadline = Deadline()
        let timer = DispatchWorkItem { deadline.expire(process) }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + max(0, timeout), execute: timer)
        process.waitUntilExit()
        let timedOut = deadline.finish()
        timer.cancel()
        if timedOut { throw Failure.timedOut }
        guard process.terminationStatus == 0 else { throw Failure.unsuccessfulExit(process.terminationStatus) }
        guard let text = String(data: try Data(contentsOf: outputURL), encoding: .utf8) else { throw Failure.invalidOutput }
        return text
    }

    private final class Deadline: @unchecked Sendable {
        private let lock = NSLock()
        private var completed = false
        private var timedOut = false

        func expire(_ process: Process) {
            lock.lock()
            defer { lock.unlock() }
            guard !completed, process.isRunning else { return }
            timedOut = true
            // Only the child started by this invocation; SIGKILL also bounds commands ignoring TERM.
            kill(process.processIdentifier, SIGKILL)
        }

        func finish() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            completed = true
            return timedOut
        }
    }
}
