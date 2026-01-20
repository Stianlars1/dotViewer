import SwiftUI
import Combine

/// ViewModel for the main application state
@MainActor
final class AppViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var items: [Item] = []

    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await apiClient.fetchItems()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
    }

    func deleteItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
    }
}
