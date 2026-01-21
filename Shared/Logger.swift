import Foundation
import os.log

// MARK: - Performance Logging (DEBUG only)

/// Performance logging that compiles to no-op in Release builds.
/// This removes the 2-5ms overhead from NSLog calls in hot paths.
#if DEBUG
/// Log performance metrics (DEBUG builds only)
/// - Parameter message: The message to log (supports string interpolation or format strings)
/// - Parameter args: Optional arguments for NSLog-style format strings
@inline(__always)
func perfLog(_ message: String, _ args: CVarArg...) {
    if args.isEmpty {
        NSLog("%@", message)
    } else {
        withVaList(args) { va_list in
            NSLogv(message, va_list)
        }
    }
}
#else
/// Performance logging disabled in Release builds
@inline(__always)
func perfLog(_ message: String, _ args: CVarArg...) {
    // No-op in Release builds - compiler optimizes this away
}
#endif

/// Centralized logging for dotViewer using Apple's unified logging system
/// Logs can be viewed in Console.app by filtering for subsystem "com.stianlars1.dotViewer"
enum DotViewerLogger {
    private static let subsystem = "com.stianlars1.dotViewer"

    /// Logger for Quick Look preview operations
    static let preview = Logger(subsystem: subsystem, category: "Preview")

    /// Logger for settings and configuration
    static let settings = Logger(subsystem: subsystem, category: "Settings")

    /// Logger for main app operations
    static let app = Logger(subsystem: subsystem, category: "App")

    /// Logger for caching operations
    static let cache = Logger(subsystem: subsystem, category: "Cache")

    // MARK: - Performance Timing Helpers

    /// Logs the elapsed time for an operation
    /// - Parameters:
    ///   - logger: The logger to use
    ///   - operation: Description of the operation
    ///   - start: The start time from CFAbsoluteTimeGetCurrent()
    static func logTiming(_ logger: Logger, operation: String, start: CFAbsoluteTime) {
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        logger.info("\(operation) completed in \(elapsed, format: .fixed(precision: 3))s")
    }

    /// Creates a timing scope that automatically logs when it goes out of scope
    /// Usage: let timer = DotViewerLogger.startTiming(.preview, "highlightCode")
    ///        // ... do work ...
    ///        // timer automatically logs on dealloc
    static func startTiming(_ logger: Logger, _ operation: String) -> TimingScope {
        TimingScope(logger: logger, operation: operation)
    }
}

/// Auto-logging timing scope - logs elapsed time when deallocated
final class TimingScope {
    private let logger: Logger
    private let operation: String
    private let start: CFAbsoluteTime

    init(logger: Logger, operation: String) {
        self.logger = logger
        self.operation = operation
        self.start = CFAbsoluteTimeGetCurrent()
    }

    deinit {
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        logger.info("\(self.operation) completed in \(elapsed, format: .fixed(precision: 3))s")
    }

    /// Manually log intermediate timing without ending the scope
    func checkpoint(_ label: String) {
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        logger.debug("\(self.operation) - \(label): \(elapsed, format: .fixed(precision: 3))s")
    }
}
