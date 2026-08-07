import Foundation
import os.log

private let bridgeLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "SearchBridge")

/// Rendezvous between the host app's loopback search server and the Quick Look preview page.
///
/// Why this exists: a Quick Look preview cannot receive keyboard input. Character keys are claimed
/// by Finder's type-select before they reach the preview, synthetic events posted at the Quick Look
/// host are not forwarded to the remote web view, and a view-based extension is never granted first
/// responder. All three are measured — see docs/research/quicklook-search-keyboard-2026-08.md.
///
/// What *does* work is the network: the preview page can open `fetch`, `XMLHttpRequest` and a
/// held-open `EventSource` to `http://127.0.0.1`. So the host app runs a loopback server, the
/// extension embeds the coordinates in the generated HTML, and search queries are pushed to the page.
///
/// The coordinates are republished on every server start because the port is chosen fresh each time.
public enum SearchBridge {
    private static let portKey = "searchBridgePort"
    private static let nonceKey = "searchBridgeNonce"
    private static let updatedKey = "searchBridgeUpdatedAt"

    /// How long published coordinates are trusted. A stale port could belong to some other process
    /// by now, so the extension stops advertising the bridge rather than pointing the page at it.
    private static let freshness: TimeInterval = 60 * 60 * 12

    public struct Coordinates: Sendable, Equatable {
        public let port: UInt16
        /// Per-session secret. Required on every request so that other local processes cannot
        /// subscribe to the stream — loopback alone is not an access control boundary.
        public let nonce: String

        public init(port: UInt16, nonce: String) {
            self.port = port
            self.nonce = nonce
        }
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedSettings.appGroupId) ?? .standard
    }

    public static func publish(_ coordinates: Coordinates) {
        let d = defaults
        d.set(Int(coordinates.port), forKey: portKey)
        d.set(coordinates.nonce, forKey: nonceKey)
        d.set(Date().timeIntervalSince1970, forKey: updatedKey)
        bridgeLogger.info("Published search bridge on port \(coordinates.port, privacy: .public)")
    }

    public static func withdraw() {
        let d = defaults
        d.removeObject(forKey: portKey)
        d.removeObject(forKey: nonceKey)
        d.removeObject(forKey: updatedKey)
        bridgeLogger.info("Withdrew search bridge coordinates")
    }

    /// Coordinates to embed in a preview, or nil when no server is advertising.
    public static func current() -> Coordinates? {
        let d = defaults
        let port = d.integer(forKey: portKey)
        guard port > 0, port <= 65535, let nonce = d.string(forKey: nonceKey), !nonce.isEmpty else {
            return nil
        }
        let updated = d.double(forKey: updatedKey)
        guard updated > 0, Date().timeIntervalSince1970 - updated < freshness else {
            bridgeLogger.debug("Search bridge coordinates are stale — ignoring")
            return nil
        }
        return Coordinates(port: UInt16(port), nonce: nonce)
    }

    public static func makeNonce() -> String {
        UUID().uuidString + UUID().uuidString.prefix(8)
    }
}
