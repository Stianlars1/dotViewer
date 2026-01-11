import Foundation
import os.log

/// Centralized logging infrastructure using os.log for proper Console.app visibility
enum AppLogger {
    /// Logger for Quick Look preview operations
    static let preview = Logger(subsystem: "com.stianlars1.dotViewer", category: "Preview")

    /// Logger for settings and configuration
    static let settings = Logger(subsystem: "com.stianlars1.dotViewer", category: "Settings")

    /// Logger for main app operations
    static let app = Logger(subsystem: "com.stianlars1.dotViewer", category: "App")

    /// Logger for file type detection and registry
    static let fileTypes = Logger(subsystem: "com.stianlars1.dotViewer", category: "FileTypes")
}
