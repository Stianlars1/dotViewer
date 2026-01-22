import Cocoa
import Quartz
import SwiftUI

class PreviewViewController: NSViewController, QLPreviewingController {

    // MARK: - Configuration

    private var settings: SharedSettings { SharedSettings.shared }
    private let maxPreviewLines = 5000

    // MARK: - UI State

    private var hostingView: NSHostingView<PreviewContentView>?

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
        // E2E PERFORMANCE TRACKING: Start time for entire preview pipeline
        let _ = CFAbsoluteTimeGetCurrent()  // e2eStartTime - kept for manual timing analysis
        NSLog("═══════════════════════════════════════════════════════════════")
        NSLog("[dotViewer E2E] ▶▶▶ PREVIEW START: %@", url.lastPathComponent)
        NSLog("═══════════════════════════════════════════════════════════════")

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

        do {
            // Get file attributes for size and modification date
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int ?? 0
            let modDate = attributes[.modificationDate] as? Date
            let maxSize = settings.maxFileSize

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

            // MPEG-2 Transport Stream detection for .ts files
            // macOS may misidentify TypeScript files as video, so we sniff content
            if ext == "ts" && isMPEG2TransportStream(data) {
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

            // Count lines efficiently using UTF-8 byte scanning
            // This is O(n) but much faster than .components(separatedBy:) which allocates memory
            // Handles all line ending formats: \n (Unix), \r\n (Windows), \r (old Mac)
            let lfByte = UInt8(ascii: "\n")
            let crByte = UInt8(ascii: "\r")
            var totalLineCount = 1
            var previousWasCR = false
            for byte in content.utf8 {
                if byte == lfByte {
                    totalLineCount += 1
                    previousWasCR = false
                } else if byte == crByte {
                    // Don't count yet - wait to see if followed by \n
                    if previousWasCR {
                        // Previous \r was standalone (old Mac format)
                        totalLineCount += 1
                    }
                    previousWasCR = true
                } else {
                    if previousWasCR {
                        // Previous \r was standalone (old Mac format)
                        totalLineCount += 1
                    }
                    previousWasCR = false
                }
            }
            // Handle trailing \r if file ends with it
            if previousWasCR {
                totalLineCount += 1
            }

            let lineTruncated = totalLineCount > maxPreviewLines

            // Only use the slower truncation method for very large files (rare case)
            if lineTruncated {
                let lines = content.components(separatedBy: .newlines)
                content = lines.prefix(maxPreviewLines).joined(separator: "\n")
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
            let truncationMessage = buildTruncationMessage(
                sizeTruncated: isTruncated,
                lineTruncated: lineTruncated,
                originalSize: fileSize,
                originalLines: totalLineCount
            )

            // Check cache for pre-highlighted content (includes theme and language for invalidation)
            var cachedHighlight: AttributedString? = nil
            let effectiveLineCount = lineTruncated ? maxPreviewLines : totalLineCount
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
                fileSize: formatFileSize(fileSize),
                isTruncated: isTruncated || lineTruncated,
                truncationMessage: truncationMessage,
                fileURL: url,
                modificationDate: modDate,
                preHighlightedContent: cachedHighlight
            )

            // Present SwiftUI view on main thread
            DispatchQueue.main.async {
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
            }

            // Call handler immediately - view will update asynchronously with highlighting
            handler(nil)

        } catch {
            handler(error)
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

// MARK: - Encoding Detection

extension Data {
    var stringEncoding: String.Encoding? {
        // Check BOM
        if self.starts(with: [0xEF, 0xBB, 0xBF]) {
            return .utf8
        }
        if self.starts(with: [0xFF, 0xFE]) {
            return .utf16LittleEndian
        }
        if self.starts(with: [0xFE, 0xFF]) {
            return .utf16BigEndian
        }

        // Try UTF-8
        if String(data: self, encoding: .utf8) != nil {
            return .utf8
        }

        // Try other common encodings
        let encodings: [String.Encoding] = [.isoLatin1, .windowsCP1252, .macOSRoman]
        for encoding in encodings {
            if String(data: self, encoding: encoding) != nil {
                return encoding
            }
        }

        return .utf8
    }
}
