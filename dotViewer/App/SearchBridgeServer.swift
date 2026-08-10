import AppKit
import Foundation
import Network
import Shared
import os.log

private let serverLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "SearchBridgeServer")

/// Loopback server that pushes search queries into open Quick Look previews.
///
/// See `SearchBridge` for why this is the only channel available. The preview page subscribes with
/// `EventSource`; this class holds those connections open and writes server-sent events to them.
///
/// Security posture — this carries keystrokes, so it is deliberately narrow:
///  * binds `127.0.0.1` only, via `requiredLocalEndpoint`
///  * rejects any connection whose remote endpoint is not loopback
///  * every request must carry the per-session nonce; loopback is not an access control boundary,
///    since any local process could otherwise subscribe to the stream
///  * the port is chosen fresh by the system on each start, so it is not guessable across launches
public final class SearchBridgeServer: @unchecked Sendable {
    public static let shared = SearchBridgeServer()

    private let queue = DispatchQueue(label: "com.stianlars1.dotViewer.searchBridge")
    private let lock = NSLock()

    private var listener: NWListener?
    private var subscribers: [ObjectIdentifier: NWConnection] = [:]
    private var nonce: String = ""
    private var keepAlive: DispatchSourceTimer?

    public private(set) var port: UInt16?

    private init() {}

    // MARK: - Lifecycle

    public func start() throws {
        lock.lock()
        defer { lock.unlock() }
        guard listener == nil else { return }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        // Bind loopback explicitly — the default would accept connections on every interface.
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)

        let listener = try NWListener(using: parameters)
        self.listener = listener
        nonce = SearchBridge.makeNonce()

        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }

        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                guard let resolved = listener.port?.rawValue else { return }
                self.port = resolved
                SearchBridge.publish(.init(port: resolved, nonce: self.nonce))
                serverLogger.info("Search bridge listening on 127.0.0.1:\(resolved, privacy: .public)")
            case .failed(let error):
                serverLogger.error("Search bridge failed: \(error.localizedDescription, privacy: .public)")
                self.stop()
            default:
                break
            }
        }

        listener.start(queue: queue)
        startKeepAlive()
    }

    public func stop() {
        lock.lock()
        let connections = Array(subscribers.values)
        subscribers.removeAll()
        listener?.cancel()
        listener = nil
        port = nil
        keepAlive?.cancel()
        keepAlive = nil
        lock.unlock()

        connections.forEach { $0.cancel() }
        SearchBridge.withdraw()
        serverLogger.info("Search bridge stopped")
    }

    /// Number of previews currently subscribed. Useful for deciding whether to bother intercepting
    /// keys at all — no subscribers means no open dotViewer preview.
    public var subscriberCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return subscribers.count
    }

    // MARK: - Publishing

    /// Push an event to every open preview. `kind` is the client-side action: `query`, `next`,
    /// `prev`, `close`, `open`.
    public func broadcast(kind: String, value: String = "") {
        let payload: [String: String] = ["type": kind, "value": value]
        guard let json = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: json, encoding: .utf8) else { return }
        send(raw: "data: \(text)\n\n")
    }

    private func send(raw: String) {
        lock.lock()
        let connections = Array(subscribers)
        lock.unlock()

        let data = Data(raw.utf8)
        for (id, connection) in connections {
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard error != nil else { return }
                self?.drop(id)
                connection.cancel()
            })
        }
    }

    private func drop(_ id: ObjectIdentifier) {
        lock.lock()
        subscribers.removeValue(forKey: id)
        lock.unlock()
    }

    /// SSE connections idle out through intermediaries and sleep; a comment line keeps them warm.
    private func startKeepAlive() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 20, repeating: 20)
        timer.setEventHandler { [weak self] in
            guard let self, self.subscriberCount > 0 else { return }
            self.send(raw: ": keepalive\n\n")
        }
        timer.resume()
        keepAlive = timer
    }

    // MARK: - Connection handling

    private func accept(_ connection: NWConnection) {
        guard isLoopback(connection) else {
            serverLogger.error("Rejected non-loopback connection")
            connection.cancel()
            return
        }
        connection.start(queue: queue)
        receiveRequest(on: connection, accumulated: Data())
    }

    private func isLoopback(_ connection: NWConnection) -> Bool {
        guard case .hostPort(let host, _) = connection.endpoint else { return false }
        switch host {
        case .ipv4(let address): return address.isLoopback
        case .ipv6(let address): return address.isLoopback
        default: return false
        }
    }

    private static let headerTerminator = Data("\r\n\r\n".utf8)

    /// A clipboard write carries the selected text, which for a select-all is the whole file, so
    /// this is sized for a document rather than for a search query. Still bounded: an unbounded
    /// read on a socket is a memory exhaustion waiting to happen, loopback or not.
    private static let maxRequestBytes = 16 * 1024 * 1024

    private func receiveRequest(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] chunk, _, isComplete, error in
            guard let self else { return }
            var buffer = accumulated
            if let chunk { buffer.append(chunk) }

            if error != nil || (isComplete && buffer.isEmpty) {
                connection.cancel()
                return
            }

            if buffer.count > Self.maxRequestBytes {
                serverLogger.error("Rejected oversized request")
                connection.cancel()
                return
            }

            // Deliberately searched as bytes rather than decoded first: a POST body is UTF-8 text
            // that routinely splits across reads, and decoding a partial buffer fails mid-character.
            guard let terminator = buffer.range(of: Self.headerTerminator) else {
                self.receiveRequest(on: connection, accumulated: buffer)
                return
            }

            guard let headerText = String(data: buffer[..<terminator.lowerBound], encoding: .utf8) else {
                connection.cancel()
                return
            }

            let body = buffer[terminator.upperBound...]
            let expected = Self.contentLength(in: headerText)
            guard body.count >= expected else {
                self.receiveRequest(on: connection, accumulated: buffer)
                return
            }

            self.route(request: headerText, body: Data(body.prefix(expected)), on: connection)
        }
    }

    private static func contentLength(in header: String) -> Int {
        for line in header.split(separator: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2,
                  parts[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length"
            else { continue }
            return max(0, Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0)
        }
        return 0
    }

    private func route(request: String, body: Data, on connection: NWConnection) {
        guard let requestLine = request.split(separator: "\r\n").first else {
            connection.cancel()
            return
        }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { connection.cancel(); return }
        let method = String(parts[0]).uppercased()

        let target = String(parts[1])
        let path = target.split(separator: "?").first.map(String.init) ?? target
        let params = queryParameters(of: target)

        guard params["nonce"] == nonce, !nonce.isEmpty else {
            serverLogger.error("Rejected request with bad nonce: \(path, privacy: .public)")
            respond(connection, status: "403 Forbidden", body: "bad nonce", close: true)
            return
        }

        switch path {
        case "/events":
            openStream(connection)
        case "/push":
            broadcast(kind: params["type"] ?? "query", value: params["value"] ?? "")
            respond(connection, status: "200 OK", body: "ok", close: true)
        case "/clipboard":
            guard method == "POST" else {
                respond(connection, status: "405 Method Not Allowed", body: "post only", close: true)
                return
            }
            writeClipboard(body: body, on: connection)
        case "/health":
            respond(connection, status: "200 OK", body: "subscribers=\(subscriberCount)", close: true)
        default:
            respond(connection, status: "404 Not Found", body: "no", close: true)
        }
    }

    /// Writes text the preview page selected into the system pasteboard.
    ///
    /// The page cannot do this itself. A Quick Look preview never receives a user gesture — that is
    /// the whole reason the event tap exists — and WebKit refuses both `document.execCommand('copy')`
    /// and the async Clipboard API without one. Every in-page route is measured in KI-009. The host
    /// app is an ordinary process with no such restriction, so the page hands the text back over the
    /// same loopback channel and the write happens here.
    private func writeClipboard(body: Data, on connection: NWConnection) {
        guard let text = String(data: body, encoding: .utf8), !text.isEmpty else {
            respond(connection, status: "400 Bad Request", body: "empty", close: true)
            return
        }

        // NSPasteboard is main-thread only; this runs on the listener queue.
        DispatchQueue.main.async {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }

        serverLogger.info("Clipboard write of \(text.count, privacy: .public) characters")
        respond(connection, status: "200 OK", body: "ok", close: true)
    }

    private func openStream(_ connection: NWConnection) {
        let headers = [
            "HTTP/1.1 200 OK",
            "Content-Type: text/event-stream; charset=utf-8",
            "Cache-Control: no-cache",
            "Connection: keep-alive",
            "Access-Control-Allow-Origin: *",
            "", "",
        ].joined(separator: "\r\n")

        connection.send(content: Data(headers.utf8), completion: .contentProcessed { [weak self] error in
            guard let self else { return }
            if error != nil { connection.cancel(); return }

            let id = ObjectIdentifier(connection)
            self.lock.lock()
            self.subscribers[id] = connection
            let count = self.subscribers.count
            self.lock.unlock()
            serverLogger.info("Preview subscribed (\(count, privacy: .public) open)")

            connection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .cancelled, .failed:
                    self?.drop(id)
                default:
                    break
                }
            }
            // Let the page confirm the channel is live before any query arrives.
            connection.send(content: Data("data: {\"type\":\"hello\",\"value\":\"\"}\n\n".utf8),
                            completion: .idempotent)
        })
    }

    private func respond(_ connection: NWConnection, status: String, body: String, close: Bool) {
        let payload = Data(body.utf8)
        let headers = [
            "HTTP/1.1 \(status)",
            "Content-Type: text/plain; charset=utf-8",
            "Content-Length: \(payload.count)",
            "Access-Control-Allow-Origin: *",
            "Connection: close",
            "", "",
        ].joined(separator: "\r\n")

        connection.send(content: Data(headers.utf8) + payload, completion: .contentProcessed { _ in
            if close { connection.cancel() }
        })
    }

    private func queryParameters(of target: String) -> [String: String] {
        guard let queryStart = target.firstIndex(of: "?") else { return [:] }
        let query = target[target.index(after: queryStart)...]
        var result: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            guard let name = kv.first?.removingPercentEncoding else { continue }
            let value = kv.count > 1 ? (kv[1].removingPercentEncoding ?? "") : ""
            result[name] = value
        }
        return result
    }
}

private extension IPv4Address {
    var isLoopback: Bool { rawValue.first == 127 }
}

private extension IPv6Address {
    var isLoopback: Bool { self == IPv6Address("::1") || asIPv4?.isLoopback == true }
}
