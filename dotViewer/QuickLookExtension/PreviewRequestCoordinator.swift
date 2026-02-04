import Foundation

actor PreviewRequestCoordinator {
    static let shared = PreviewRequestCoordinator()

    private var currentRequestId: String?

    private init() {}

    func startNewRequest() -> (id: String, previousId: String?) {
        let previous = currentRequestId
        let id = UUID().uuidString
        currentRequestId = id
        return (id, previous)
    }

    func isCurrent(_ requestId: String) -> Bool {
        return requestId == currentRequestId
    }
}
