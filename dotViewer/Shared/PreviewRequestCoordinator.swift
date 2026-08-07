import Foundation

/// Tracks which preview request is the live one so a superseded request can stop doing work.
///
/// One instance per process: the Quick Look extension and the host app's ⌥Space panel each render
/// independently and must not cancel each other's requests.
public actor PreviewRequestCoordinator {
    public static let shared = PreviewRequestCoordinator()

    private var currentRequestId: String?

    private init() {}

    public func startNewRequest() -> (id: String, previousId: String?) {
        let previous = currentRequestId
        let id = UUID().uuidString
        currentRequestId = id
        return (id, previous)
    }

    public func isCurrent(_ requestId: String) -> Bool {
        return requestId == currentRequestId
    }
}
