import Foundation
import OSLog
import Shared

final class HighlightService: NSObject, NSXPCListenerDelegate, HighlightServiceProtocol {
    private let highlighter = TreeSitterHighlighter()
    private let cancellationRegistry = HighlightCancellationRegistry()

    private let log = OSLog(subsystem: "com.stianlars1.dotViewer", category: "HighlightXPC")
    private lazy var signposter = OSSignposter(logHandle: log)

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HighlightServiceProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    func highlight(
        code: String,
        language: String,
        theme: String,
        showLineNumbers: Bool,
        requestId: String,
        reply: @escaping (NSData?, NSError?) -> Void
    ) {
        if cancellationRegistry.isCancelled(requestId) {
            let error = NSError(domain: "com.stianlars1.dotViewer.HighlightCancelled", code: 1)
            reply(nil, error)
            return
        }

        let shouldLog = SharedSettings.shared.performanceLoggingEnabled
        let signpostID = signposter.makeSignpostID()
        let interval = shouldLog ? signposter.beginInterval("highlight.total", id: signpostID) : nil

        let html = highlighter.highlight(
            code: code,
            language: language,
            showLineNumbers: showLineNumbers,
            shouldCancel: { [weak cancellationRegistry] in
                cancellationRegistry?.isCancelled(requestId) ?? false
            }
        )

        if let interval {
            signposter.endInterval("highlight.total", interval)
        }

        if cancellationRegistry.isCancelled(requestId) || html == nil {
            let error = NSError(domain: "com.stianlars1.dotViewer.HighlightCancelled", code: 1)
            reply(nil, error)
        } else {
            reply(html?.data(using: .utf8) as NSData?, nil)
        }

        cancellationRegistry.clear(requestId)
    }

    func highlightTokens(
        code: String,
        language: String,
        requestId: String,
        reply: @escaping (NSData?, NSError?) -> Void
    ) {
        if cancellationRegistry.isCancelled(requestId) {
            let error = NSError(domain: "com.stianlars1.dotViewer.HighlightCancelled", code: 1)
            reply(nil, error)
            return
        }

        let tokens = highlighter.extractTokens(
            code: code,
            language: language,
            shouldCancel: { [weak cancellationRegistry] in
                cancellationRegistry?.isCancelled(requestId) ?? false
            }
        )

        if cancellationRegistry.isCancelled(requestId) || tokens == nil {
            let error = NSError(domain: "com.stianlars1.dotViewer.HighlightCancelled", code: 1)
            reply(nil, error)
        } else if let tokens, let data = try? JSONEncoder().encode(tokens) {
            reply(data as NSData, nil)
        } else {
            reply(NSData(), nil)
        }

        cancellationRegistry.clear(requestId)
    }

    func cancel(requestId: String) {
        cancellationRegistry.cancel(requestId)
    }
}

private final class HighlightCancellationRegistry {
    private let lock = NSLock()
    private var cancelled: Set<String> = []

    func cancel(_ requestId: String) {
        lock.lock()
        cancelled.insert(requestId)
        lock.unlock()
    }

    func isCancelled(_ requestId: String) -> Bool {
        lock.lock()
        let value = cancelled.contains(requestId)
        lock.unlock()
        return value
    }

    func clear(_ requestId: String) {
        lock.lock()
        cancelled.remove(requestId)
        lock.unlock()
    }
}
