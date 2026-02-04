import Foundation

@objc public protocol HighlightServiceProtocol {
    func highlight(
        code: String,
        language: String,
        theme: String,
        showLineNumbers: Bool,
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
