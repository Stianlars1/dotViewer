import Foundation
import OSLog

public final class HighlightXPCClient: @unchecked Sendable {
    public static let shared = HighlightXPCClient()

    private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "HighlightXPCClient")

    private let lock = NSLock()
    private var connection: NSXPCConnection?

    private init() {}

    public func highlight(
        code: String,
        language: String,
        theme: String,
        showLineNumbers: Bool,
        requestId: String,
        timeout: TimeInterval
    ) async -> Result<String, HighlightFallbackReason> {
        await withCheckedContinuation { continuation in
            let state = CallbackState()
            let proxy = makeConnection().synchronousRemoteObjectProxyWithErrorHandler { _ in
                state.finish {
                    continuation.resume(returning: .failure(.serviceUnavailable))
                }
            } as? HighlightServiceProtocol

            guard let proxy else {
                state.finish {
                    continuation.resume(returning: .failure(.serviceUnavailable))
                }
                return
            }

            proxy.highlight(code: code, language: language, theme: theme, showLineNumbers: showLineNumbers, requestId: requestId) { data, error in
                state.finish {
                    if let error = error as NSError?, error.domain == "com.stianlars1.dotViewer.HighlightCancelled" {
                        self.logger.info("Highlight cancelled for request \(requestId, privacy: .public)")
                        continuation.resume(returning: .failure(.cancelled))
                        return
                    }
                    guard error == nil else {
                        let message = error?.localizedDescription ?? "unknown"
                        self.logger.error("Highlight failed for request \(requestId, privacy: .public): \(message)")
                        continuation.resume(returning: .failure(.highlightingFailed))
                        return
                    }
                    guard let data = data as Data?,
                          let html = String(data: data, encoding: .utf8)
                    else {
                        self.logger.error("Highlight returned invalid data for request \(requestId, privacy: .public)")
                        continuation.resume(returning: .failure(.highlightingFailed))
                        return
                    }
                    self.logger.info("Highlight succeeded for request \(requestId, privacy: .public) size=\(html.count, privacy: .public)")
                    continuation.resume(returning: .success(html))
                }
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                state.finish {
                    self.logger.error("Highlight timed out for request \(requestId, privacy: .public)")
                    continuation.resume(returning: .failure(.timeout))
                }
            }
        }
    }

    public func cancel(requestId: String) {
        let proxy = makeConnection().synchronousRemoteObjectProxyWithErrorHandler { _ in } as? HighlightServiceProtocol
        proxy?.cancel(requestId: requestId)
    }

    private func makeConnection() -> NSXPCConnection {
        lock.lock()
        defer { lock.unlock() }

        if let connection {
            return connection
        }

        let newConnection = NSXPCConnection(serviceName: "com.stianlars1.dotViewer.HighlightXPC")
        newConnection.remoteObjectInterface = NSXPCInterface(with: HighlightServiceProtocol.self)
        newConnection.resume()
        connection = newConnection
        return newConnection
    }
}

private final class CallbackState: @unchecked Sendable {
    private let lock = NSLock()
    private var completed = false

    func finish(_ block: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !completed else { return }
        completed = true
        block()
    }
}
