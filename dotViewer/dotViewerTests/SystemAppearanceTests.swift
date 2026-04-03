import XCTest
@testable import Shared

final class SystemAppearanceTests: XCTestCase {
    func testDarkModeDefaultsValue() {
        let suiteName = "SystemAppearanceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set("Dark", forKey: "AppleInterfaceStyle")
        XCTAssertTrue(SystemAppearance.isDark(defaults: defaults))
    }

    func testNonDarkDefaultsValue() {
        let suiteName = "SystemAppearanceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set("Light", forKey: "AppleInterfaceStyle")
        XCTAssertFalse(SystemAppearance.isDark(defaults: defaults))
    }
}
