import Foundation
import AppKit
@preconcurrency import QuickLookUI
import CoreGraphics
import OSLog
import Shared

/// Quick Look front-end. The rendering pipeline itself lives in `PreviewContentBuilder` so that the
/// host app's ⌥Space panel draws from exactly the same code; everything here is about turning that
/// result into a `QLPreviewReply` and sizing the Quick Look window.
final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private static let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "QuickLookPreview")

    // If Quick Look calls the legacy, view-based API, log it so we can see it immediately.
    func preparePreviewOfFile(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        Self.logger.log("preparePreviewOfFile called for \(url.lastPathComponent, privacy: .public)")
        completionHandler(nil)
    }

    @available(macOSApplicationExtension 12.0, *)
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let url = request.fileURL
        let systemIsDark = SystemAppearance.isDark()

#if DEBUG
        if let experiment = Self.debugExperimentReply(for: url, systemIsDark: systemIsDark) {
            return experiment
        }
#endif

        switch await PreviewContentBuilder.build(for: url, systemIsDark: systemIsDark) {
        case .systemFallback:
            return QLPreviewReply(fileURL: url)
        case .rendered(let render):
            return Self.makeHTMLReply(
                html: render.html,
                lineCount: render.lineCount,
                fontSize: render.fontSize,
                showHeader: render.showHeader
            )
        }
    }

    private static func makeHTMLReply(
        html: String,
        lineCount: Int = 40,
        fontSize: Double = 14,
        showHeader: Bool = true
    ) -> QLPreviewReply {
        let contentSize = computeContentSize(lineCount: lineCount, fontSize: fontSize, showHeader: showHeader)

        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: contentSize) { _ in
            html.data(using: .utf8) ?? Data()
        }
        reply.stringEncoding = .utf8
        return reply
    }
}

// MARK: - Debug experiments

#if DEBUG
private extension PreviewProvider {
    /// Fixtures used to probe Quick Look behaviour by hand. Never reached in a release build.
    static func debugExperimentReply(for url: URL, systemIsDark: Bool) -> QLPreviewReply? {
        if url.deletingPathExtension().lastPathComponent == "dotviewer_heartbeat" {
            let palette = ThemePalette.palette(for: SharedSettings.shared.selectedTheme, systemIsDark: systemIsDark)
            let heartbeatHTML = """
            <!doctype html>
            <html><body style="font-family:-apple-system;padding:20px;background:\(palette.background);color:\(palette.text);">
            <h2>dotViewer preview active</h2>
            <p>Heartbeat OK for \(url.lastPathComponent)</p>
            </body></html>
            """
            logger.log("Heartbeat preview returned for \(url.lastPathComponent, privacy: .public)")
            return makeHTMLReply(html: heartbeatHTML, lineCount: 3, fontSize: 14, showHeader: false)
        }

        // Experiment 1: RTF data-based reply — test if QL renders RTF with native text selection
        if url.lastPathComponent.hasPrefix("test_rtf_") {
            logger.log("Experiment 1: RTF path for \(url.lastPathComponent, privacy: .public)")
            let text: String
            do {
                text = try String(contentsOf: url, encoding: .utf8)
            } catch {
                logger.error("Experiment 1: Read failed: \(error.localizedDescription, privacy: .public)")
                text = "Failed to read file"
            }
            let palette = ThemePalette.palette(for: SharedSettings.shared.selectedTheme, systemIsDark: systemIsDark)
            let lineCount = TextLineUtilities.visualLineCount(in: text)
            return makeRTFReply(text: text, palette: palette, lineCount: lineCount, fontSize: SharedSettings.shared.fontSize)
        }

        return nil
    }

    /// Hypothesis: if QL renders RTF using a native NSTextView, Cmd+C may work natively.
    static func makeRTFReply(
        text: String,
        palette: ThemePalette,
        lineCount: Int,
        fontSize: Double
    ) -> QLPreviewReply {
        let font = PreviewFontResolver.codeFont(
            familyName: SharedSettings.shared.codeFontFamilyName,
            size: CGFloat(fontSize),
            weight: .regular
        )
        let textColor = NSColor(hex: palette.text) ?? .labelColor
        let bgColor = NSColor(hex: palette.background) ?? .textBackgroundColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.45

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .backgroundColor: bgColor,
            .paragraphStyle: paragraphStyle
        ]

        let attributed = NSAttributedString(string: text, attributes: attributes)

        guard let rtfData = try? attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            logger.error("Experiment 1: RTF conversion failed, falling back to HTML")
            let escaped = text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            return makeHTMLReply(html: "<pre>\(escaped)</pre>", lineCount: lineCount, fontSize: fontSize, showHeader: false)
        }

        logger.log("Experiment 1: RTF data generated, \(rtfData.count) bytes")

        let contentSize = computeContentSize(lineCount: lineCount, fontSize: fontSize, showHeader: false)

        return QLPreviewReply(dataOfContentType: .rtf, contentSize: contentSize) { _ in
            rtfData
        }
    }
}
#endif

// MARK: - Window sizing

private extension PreviewProvider {
    static func computeContentSize(lineCount: Int, fontSize: Double, showHeader: Bool) -> CGSize {
        let settings = SharedSettings.shared
        let mode = settings.previewWindowSizeMode
        let size = PreviewSizing.initialContentSize(
            lineCount: lineCount,
            fontSize: fontSize,
            showHeader: showHeader,
            windowSizeMode: mode,
            fixedWidth: settings.previewWindowFixedWidth,
            fixedHeight: settings.previewWindowFixedHeight,
            lastWidth: settings.previewWindowLastWidth,
            lastHeight: settings.previewWindowLastHeight,
            aspectRatioKey: settings.previewWindowAspectRatio,
            aspectBaseWidth: settings.previewWindowAspectBaseWidth
        )

        if mode == "remember" {
            settings.previewWindowLastWidth = Int(size.width)
            settings.previewWindowLastHeight = Int(size.height)
        }

        return size
    }
}

// MARK: - NSColor(hex:)

#if DEBUG
private extension NSColor {
    convenience init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }
        guard sanitized.count == 6 || sanitized.count == 8 else { return nil }
        let scanner = Scanner(string: sanitized)
        var hexNumber: UInt64 = 0
        guard scanner.scanHexInt64(&hexNumber) else { return nil }
        let r, g, b, a: CGFloat
        if sanitized.count == 6 {
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
            b = CGFloat(hexNumber & 0x0000FF) / 255
            a = 1.0
        } else {
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000FF) / 255
        }
        self.init(calibratedRed: r, green: g, blue: b, alpha: a)
    }
}
#endif
