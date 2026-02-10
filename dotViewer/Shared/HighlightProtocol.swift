import Foundation

public struct HighlightToken: Codable, Sendable {
    public let s: Int   // start byte offset
    public let e: Int   // end byte offset
    public let c: String // token class name (e.g. "keyword", "string")

    public init(s: Int, e: Int, c: String) {
        self.s = s
        self.e = e
        self.c = c
    }
}

@objc public protocol HighlightServiceProtocol {
    func highlight(
        code: String,
        language: String,
        theme: String,
        showLineNumbers: Bool,
        requestId: String,
        reply: @escaping (NSData?, NSError?) -> Void
    )

    func highlightTokens(
        code: String,
        language: String,
        requestId: String,
        reply: @escaping (NSData?, NSError?) -> Void
    )

    func cancel(requestId: String)
}

public enum HighlightFallbackReason: String, Error {
    case serviceUnavailable
    case timeout
    case highlightingFailed
    case cancelled
}
