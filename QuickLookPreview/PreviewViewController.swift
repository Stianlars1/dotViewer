import Cocoa
import Quartz
import SwiftUI

class PreviewViewController: NSViewController, QLPreviewingController {

    // MARK: - Configuration

    private var settings: SharedSettings { SharedSettings.shared }
    private let maxPreviewLines = 5000

    // MARK: - UI State

    /// The hosting view for SwiftUI content.
    /// NOTE: This property is accessed exclusively from the main thread via DispatchQueue.main.async.
    /// Quick Look serializes preview requests, and all UI updates go through main queue dispatch.
    private var hostingView: NSHostingView<PreviewContentView>?

    /// Track current request URL to detect and skip stale requests during rapid navigation
    private var currentRequestURL: URL?

    // MARK: - View Lifecycle

    override var nibName: NSNib.Name? { nil }

    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        // Don't set a fixed frame - let Quick Look determine the appropriate size
        // This allows proper rendering in both full preview (spacebar) and
        // Finder preview pane (compact mode)
    }

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        perfLog("[dotViewer] Preview start: \(url.lastPathComponent)")

        let filename = url.lastPathComponent
        let ext = url.pathExtension.lowercased()

        // Check if file type is enabled (only for known extensions)
        if !ext.isEmpty && !FileTypeRegistry.shared.isExtensionEnabled(ext) {
            handler(PreviewError.fileTypeDisabled)
            return
        }

        // For extensionless files, check if user wants to preview unknown files
        // If setting is OFF, let macOS system Quick Look handle it (shows white icon)
        if ext.isEmpty && !settings.previewUnknownFiles {
            handler(PreviewError.fileTypeDisabled)
            return
        }

        // Track current request to detect stale callbacks
        let requestURL = url
        currentRequestURL = url

        // Move all file I/O to background queue to avoid blocking Quick Look UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                handler(PreviewError.unreadableFile)
                return
            }

            do {
                // Get file attributes for size and modification date
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int ?? 0
                let modDate = attributes[.modificationDate] as? Date
                let maxSize = self.settings.maxFileSize

                let data: Data
                let isTruncated: Bool

                if fileSize > maxSize {
                    // Read only first portion
                    let handle = try FileHandle(forReadingFrom: url)
                    data = handle.readData(ofLength: maxSize)
                    handle.closeFile()
                    isTruncated = true
                } else {
                    data = try Data(contentsOf: url, options: [.uncached])
                    isTruncated = false
                }

                // Check if request is still current (user may have navigated away)
                guard self.currentRequestURL == requestURL else {
                    perfLog("[dotViewer PERF] Stale request detected after file read, skipping")
                    return
                }

                // MPEG-2 Transport Stream detection for .ts files
                // macOS may misidentify TypeScript files as video, so we sniff content
                if ext == "ts" && self.isMPEG2TransportStream(data) {
                    throw PreviewError.binaryFile
                }

                // Binary check (null byte detection)
                let checkSize = min(data.count, 8192)
                let sample = data.prefix(checkSize)
                if sample.contains(0x00) {
                    throw PreviewError.binaryFile
                }

                // Decode content
                let encoding = data.stringEncoding ?? .utf8
                guard var content = String(data: data, encoding: encoding) else {
                    throw PreviewError.unreadableFile
                }

                // Fast line counting using withUnsafeBytes on raw Data
                // PERFORMANCE: ~2x faster than String.utf8 iterator for large files
                let totalLineCount = data.countLines()

                let lineTruncated = totalLineCount > self.maxPreviewLines

                // Only use the slower truncation method for very large files (rare case)
                if lineTruncated {
                    let lines = content.components(separatedBy: .newlines)
                    content = lines.prefix(self.maxPreviewLines).joined(separator: "\n")
                }

                // Detect language
                var language = LanguageDetector.detect(for: url)
                if language == nil {
                    language = LanguageDetector.detectFromShebang(content)
                }
                // Content-based fallback for unknown files
                if language == nil {
                    language = LanguageDetector.detectFromContent(content)
                }

                // Build truncation message
                let truncationMessage = self.buildTruncationMessage(
                    sizeTruncated: isTruncated,
                    lineTruncated: lineTruncated,
                    originalSize: fileSize,
                    originalLines: totalLineCount
                )

                // Check cache for pre-highlighted content (includes theme and language for invalidation)
                var cachedHighlight: AttributedString? = nil
                let effectiveLineCount = lineTruncated ? self.maxPreviewLines : totalLineCount
                if let modDate = modDate {
                    let theme = SharedSettings.shared.selectedTheme
                    cachedHighlight = HighlightCache.shared.get(
                        path: url.path,
                        modDate: modDate,
                        theme: theme,
                        language: language
                    )
                    if cachedHighlight != nil {
                        perfLog("[dotViewer PERF] Cache HIT in preparePreviewOfFile - skipping highlight")
                    }
                }

                // Create preview state
                let previewState = PreviewState(
                    content: content,
                    filename: filename,
                    language: language,
                    lineCount: effectiveLineCount,
                    fileSize: self.formatFileSize(fileSize),
                    isTruncated: isTruncated || lineTruncated,
                    truncationMessage: truncationMessage,
                    fileURL: url,
                    modificationDate: modDate,
                    preHighlightedContent: cachedHighlight
                )

                // Present SwiftUI view on main thread
                DispatchQueue.main.async {
                    // Final stale check before UI update
                    guard self.currentRequestURL == requestURL else {
                        perfLog("[dotViewer PERF] Stale request detected before UI update, skipping")
                        return
                    }

                    let previewView = PreviewContentView(state: previewState)
                    let hosting = NSHostingView(rootView: previewView)
                    hosting.translatesAutoresizingMaskIntoConstraints = false

                    // Remove any existing hosting view
                    self.hostingView?.removeFromSuperview()

                    self.view.addSubview(hosting)
                    NSLayoutConstraint.activate([
                        hosting.topAnchor.constraint(equalTo: self.view.topAnchor),
                        hosting.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        hosting.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        hosting.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                    ])

                    self.hostingView = hosting
                    handler(nil)
                }

            } catch {
                DispatchQueue.main.async {
                    handler(error)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Detect if data is an MPEG-2 Transport Stream (video file)
    /// MPEG-2 TS has 0x47 sync bytes at 188-byte intervals
    /// Used to distinguish .ts video files from TypeScript source code
    private func isMPEG2TransportStream(_ data: Data) -> Bool {
        // MPEG-2 TS packet size is 188 bytes
        let packetSize = 188
        let syncByte: UInt8 = 0x47

        // Need at least 3 packets to be confident
        guard data.count >= packetSize * 3 else { return false }

        // Check if first byte is sync byte
        guard data[0] == syncByte else { return false }

        // Check sync bytes at 188-byte intervals (at least 3 packets)
        let checkCount = min(5, data.count / packetSize)
        var syncCount = 0

        for i in 0..<checkCount {
            let offset = i * packetSize
            if offset < data.count && data[offset] == syncByte {
                syncCount += 1
            }
        }

        // If most packets have sync byte at correct interval, it's MPEG-2
        return syncCount >= 3
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func buildTruncationMessage(sizeTruncated: Bool, lineTruncated: Bool, originalSize: Int, originalLines: Int) -> String? {
        guard sizeTruncated || lineTruncated else { return nil }

        var parts: [String] = []
        if sizeTruncated {
            parts.append("File truncated (original: \(formatFileSize(originalSize)))")
        }
        if lineTruncated {
            parts.append("Showing first \(maxPreviewLines) of \(originalLines) lines")
        }
        return parts.joined(separator: " • ")
    }
}

// MARK: - Error Types

enum PreviewError: Error, LocalizedError {
    case unreadableFile
    case binaryFile
    case fileTypeDisabled

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "Unable to read file content"
        case .binaryFile:
            return "Binary files cannot be previewed"
        case .fileTypeDisabled:
            return "This file type is disabled in dotViewer settings"
        }
    }
}

// MARK: - Fast Line Counting

extension Data {
    /// Count lines using fast byte scanning with withUnsafeBytes.
    /// PERFORMANCE: Using raw byte pointer is ~2x faster than String.utf8 iterator.
    /// Handles all line endings: \n (Unix), \r\n (Windows), \r (old Mac)
    func countLines() -> Int {
        return self.withUnsafeBytes { buffer -> Int in
            guard let bytes = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return 1
            }
            let count = buffer.count
            var lineCount = 1
            var previousWasCR = false
            let lfByte: UInt8 = 0x0A  // \n
            let crByte: UInt8 = 0x0D  // \r

            for i in 0..<count {
                let byte = bytes[i]
                if byte == lfByte {
                    lineCount += 1
                    previousWasCR = false
                } else if byte == crByte {
                    if previousWasCR {
                        lineCount += 1  // Previous \r was standalone
                    }
                    previousWasCR = true
                } else {
                    if previousWasCR {
                        lineCount += 1  // Previous \r was standalone
                    }
                    previousWasCR = false
                }
            }
            // Handle trailing \r
            if previousWasCR {
                lineCount += 1
            }
            return lineCount
        }
    }
}

// MARK: - Encoding Detection

extension Data {
    /// Detect string encoding with optimized fast path.
    /// PERFORMANCE: BOM check is O(1), UTF-8 check is the common case (99%+ of files).
    /// Returns immediately on UTF-8 success to avoid trying legacy encodings.
    ///
    /// NOTE: Returns nil only if NO encoding works (likely binary data).
    /// Callers should handle nil by showing an error or treating as binary.
    var stringEncoding: String.Encoding? {
        // Fast path: Check BOM first (no allocation, just byte comparison)
        if self.starts(with: [0xEF, 0xBB, 0xBF]) {
            return .utf8
        }
        if self.starts(with: [0xFF, 0xFE]) {
            return .utf16LittleEndian
        }
        if self.starts(with: [0xFE, 0xFF]) {
            return .utf16BigEndian
        }

        // 99%+ of modern files are UTF-8 - try it first and EARLY RETURN on success
        // This avoids trying other encodings when UTF-8 works (saves 2-5ms)
        if String(data: self, encoding: .utf8) != nil {
            return .utf8
        }

        // Fallback for legacy encodings (rare - only reached for non-UTF-8 files)
        // These encodings can represent any byte sequence, so they should always succeed
        // for text files, making this a reasonable fallback chain.
        for encoding in [String.Encoding.isoLatin1, .windowsCP1252, .macOSRoman] {
            if String(data: self, encoding: encoding) != nil {
                perfLog("[dotViewer] Using fallback encoding: \(encoding)")
                return encoding
            }
        }

        // If nothing works, this is likely binary data - return nil to signal error
        // rather than silently mangling the content with a wrong encoding
        return nil
    }
}
