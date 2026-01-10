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
    }

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        let filename = url.lastPathComponent
        let ext = url.pathExtension.lowercased()

        // Check if file type is enabled (only for known extensions)
        if !ext.isEmpty && !FileTypeRegistry.shared.isExtensionEnabled(ext) {
            handler(PreviewError.fileTypeDisabled)
            return
        }

        do {
            // Get file attributes for size
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int ?? 0
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

            // Binary check
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

            // Count lines and truncate if needed
            let lines = content.components(separatedBy: .newlines)
            let totalLineCount = lines.count
            let lineTruncated = totalLineCount > maxPreviewLines

            if lineTruncated {
                content = lines.prefix(maxPreviewLines).joined(separator: "\n")
            }

            // Detect language
            var language = LanguageDetector.detect(for: url)
            if language == nil {
                language = LanguageDetector.detectFromShebang(content)
            }

            // Build truncation message
            let truncationMessage = buildTruncationMessage(
                sizeTruncated: isTruncated,
                lineTruncated: lineTruncated,
                originalSize: fileSize,
                originalLines: totalLineCount
            )

            // Create preview state
            let previewState = PreviewState(
                content: content,
                filename: filename,
                language: language,
                lineCount: lineTruncated ? maxPreviewLines : totalLineCount,
                fileSize: formatFileSize(fileSize),
                isTruncated: isTruncated || lineTruncated,
                truncationMessage: truncationMessage
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
