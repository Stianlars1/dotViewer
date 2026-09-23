import Foundation

/// Builds before 1.5.8 saved the main window's frame under a key that held a per-build type address
/// ("NSWindow Frame SwiftUI.ModifiedContent<dotViewer.ContentView, dotViewer.(unknown context at
/// $10a3c…)…"), so every update forgot the window's size and left one more key behind. The scene now
/// has a fixed id; this removes the keys the old builds left.
enum StaleWindowFrames {
    static let keyPrefix = "NSWindow Frame SwiftUI.ModifiedContent<dotViewer.ContentView,"

    static func remove(from defaults: UserDefaults = .standard) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
