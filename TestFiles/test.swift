import Foundation

// Sample Swift file for E2E testing
struct User: Codable {
    let id: Int
    let name: String
    let email: String

    func greet() -> String {
        return "Hello, \(name)!"
    }
}

@MainActor
class UserManager {
    private var users: [User] = []

    func addUser(_ user: User) {
        users.append(user)
    }

    func findUser(byId id: Int) -> User? {
        return users.first { $0.id == id }
    }
}
