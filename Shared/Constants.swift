import Foundation

/// Centralized constants for dotViewer configuration values.
/// These values were previously hardcoded as "magic numbers" throughout the codebase.
enum Constants {

    // MARK: - Cache Configuration

    /// Maximum disk cache size in bytes (100MB)
    static let cacheMaxSizeBytes: Int = 100 * 1024 * 1024

    /// Maximum number of entries in the disk cache
    static let cacheMaxEntries: Int = 500

    /// Number of writes before triggering cache cleanup
    static let cacheCleanupInterval: Int = 10

    /// Minimum seconds between cache cleanup operations (rate limiting)
    static let cacheCleanupMinInterval: TimeInterval = 30.0

    /// Maximum entries in memory cache (LRU)
    static let memoryCacheMaxEntries: Int = 20

    // MARK: - Preview Configuration

    /// Maximum lines to display in preview (files beyond this show without syntax highlighting)
    static let previewMaxLines: Int = 5000

    /// Maximum lines to apply syntax highlighting (for performance)
    static let highlightingMaxLines: Int = 2000

    /// Default maximum file size for preview in bytes (500KB)
    static let defaultMaxFileSize: Int = 500 * 1024

    // MARK: - Language Detection

    /// Number of characters to sample for content-based language detection
    static let contentSampleSize: Int = 500

    /// Number of characters to analyze for code-like content detection
    static let contentAnalysisSampleSize: Int = 2000

    // MARK: - Performance

    /// Timeout for syntax highlighting in nanoseconds (2 seconds)
    static let highlightingTimeoutNanoseconds: UInt64 = 2_000_000_000

    // MARK: - Input Validation

    /// Maximum allowed custom extension length
    static let maxCustomExtensionLength: Int = 20
}
