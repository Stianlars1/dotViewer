import Foundation
import AppKit
@preconcurrency import QuickLookUI
import CoreGraphics
import OSLog
import Shared

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private static let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "QuickLookPreview")
    private static let routeLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "QuickLookRouting")

    // If Quick Look calls the legacy, view-based API, log it so we can see it immediately.
    func preparePreviewOfFile(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        Self.logger.log("preparePreviewOfFile called for \(url.lastPathComponent, privacy: .public)")
        completionHandler(nil)
    }

    @available(macOSApplicationExtension 12.0, *)
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let systemIsDark = await MainActor.run { Self.systemIsDark() }
        return await Self.buildPreviewReply(for: request.fileURL, systemIsDark: systemIsDark)
    }

    private static func buildPreviewReply(for url: URL, systemIsDark: Bool) async -> QLPreviewReply {
        let actualPathExtension = url.pathExtension.lowercased()
        let registry = FileTypeRegistry.shared
        let key = FileTypeResolution.bestKey(for: url, registry: registry)
        logger.log("Preview request: \(url.lastPathComponent, privacy: .public) ext=\(actualPathExtension, privacy: .public) key=\(key, privacy: .public)")
        logger.log("SharedSettings appGroup=\(SharedSettings.shared.isUsingAppGroup, privacy: .public)")

#if DEBUG
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
            let lineCount = text.components(separatedBy: "\n").count
            return makeRTFReply(text: text, palette: palette, lineCount: lineCount, fontSize: SharedSettings.shared.fontSize)
        }
#endif

        let (requestId, previousId) = await PreviewRequestCoordinator.shared.startNewRequest()
        if let previousId {
            HighlightXPCClient.shared.cancel(requestId: previousId)
        }

        let cacheEnabled = SharedSettings.shared.previewCacheEnabled
        let cacheTTL = SharedSettings.shared.previewCacheTTLSeconds
        let cacheMaxBytes = SharedSettings.shared.previewCacheMaxMB * 1_024 * 1_024
        let forceTextForUnknown = SharedSettings.shared.previewForceTextForUnknown

        await PreviewCache.shared.handleClearIfRequested()

        let fileAttributes = FileAttributes.attributes(for: url)
        let typeIsTextual = fileAttributes?.isTextual ?? false
        let looksTextualSample = fileAttributes?.looksTextual ?? false
        let mimeType = fileAttributes?.mimeType ?? "application/octet-stream"

        let isPlistFile = PlistConverter.isPropertyList(url: url)
        let isBinaryPlist = isPlistFile && PlistConverter.isBinaryPlist(url: url)
        let looksTextual = looksTextualSample || isBinaryPlist

        let isTransportCandidate = TransportStreamDetector.isTransportStreamCandidate(url: url, mimeType: mimeType)
        let transportMatches = isTransportCandidate && TransportStreamDetector.matchesTransportStreamSyncPattern(url: url)
        if isTransportCandidate && (!looksTextualSample || transportMatches) {
            routeLogger.log("Fallback: transport stream candidate for \(url.lastPathComponent, privacy: .public)")
            return QLPreviewReply(fileURL: url)
        }

        let isTextual = typeIsTextual || isBinaryPlist || (forceTextForUnknown && looksTextualSample)
        let isExtensionEnabled = registry.isExtensionEnabled(key)
        let isKnownType = registry.fileType(for: key) != nil || registry.highlightLanguage(for: key) != nil
        let allowUnknown = SharedSettings.shared.previewAllFileTypes

        routeLogger.log(
            "Routing check ext=\(actualPathExtension, privacy: .public) key=\(key, privacy: .public) textual=\(isTextual, privacy: .public) allowUnknown=\(allowUnknown, privacy: .public) known=\(isKnownType, privacy: .public) enabled=\(isExtensionEnabled, privacy: .public) forceText=\(forceTextForUnknown, privacy: .public)"
        )

        if !isTextual {
            routeLogger.log("Fallback: non-textual file without forceText for \(url.lastPathComponent, privacy: .public)")
            return QLPreviewReply(fileURL: url)
        }

        if !isExtensionEnabled || (!isKnownType && !allowUnknown) {
            routeLogger.log("Fallback: extension disabled or unsupported type for \(url.lastPathComponent, privacy: .public)")
            return makePlainTextFallback(url: url, systemIsDark: systemIsDark)
        }

        let fileMeta = FileInspector.fileMetadata(for: url)
        let fileSize = fileMeta.sizeBytes
        let fileMtime = fileMeta.mtime
        let isEmptyFile = fileSize == 0

        let languageId = registry.highlightLanguage(for: key) ?? "plaintext"
        let languageName = registry.displayName(for: key) ?? (key.isEmpty ? "Text" : key.uppercased())

        let isMarkdown = languageId == "markdown"
        let showLineNumbers = SharedSettings.shared.showLineNumbers
        let useMarkdownHighlight = SharedSettings.shared.markdownUseSyntaxHighlightInRaw
        let showBinaryWarning = (!typeIsTextual && !looksTextual && !isEmptyFile)
        let showUnknownTextWarning = (!typeIsTextual && looksTextualSample && !isKnownType && !isEmptyFile)
        let encoding = fileAttributes?.stringEncoding ?? .utf8

        routeLogger.debug("Preview routing: key=\(key, privacy: .public) lang=\(languageId, privacy: .public) markdown=\(isMarkdown, privacy: .public) known=\(isKnownType, privacy: .public) allowUnknown=\(allowUnknown, privacy: .public)")
        let shouldHighlight = !(isMarkdown && !useMarkdownHighlight)

        let routedExtensions: Set<String> = ["md", "markdown", "mdx", "json", "xml", "yaml", "yml", "ts", "tsx", "sh", "bash"]
        if routedExtensions.contains(key) {
            routeLogger.log(
                "Preview route file=\(url.lastPathComponent, privacy: .public) key=\(key, privacy: .public) lang=\(languageId, privacy: .public) highlight=\(shouldHighlight, privacy: .public)"
            )
        }

        let cacheKey = PreviewCacheKey(
            url: url,
            fileSize: fileSize,
            mtime: fileMtime,
            showLineNumbers: showLineNumbers,
            codeFontSize: SharedSettings.shared.fontSize,
            markdownUseSyntaxHighlightInRaw: useMarkdownHighlight,
            allowUnknown: allowUnknown,
            forceTextForUnknown: forceTextForUnknown,
            languageId: languageId,
            theme: SharedSettings.shared.selectedTheme,
            showHeader: SharedSettings.shared.showFileInfoHeader,
            markdownDefaultMode: SharedSettings.shared.markdownDefaultMode,
            markdownRenderFontSize: SharedSettings.shared.markdownRenderFontSize,
            markdownShowInlineImages: SharedSettings.shared.markdownShowInlineImages,
            markdownCustomCSS: SharedSettings.shared.markdownCustomCSS,
            markdownCustomCSSOverride: SharedSettings.shared.markdownCustomCSSOverride,
            wordWrap: SharedSettings.shared.wordWrap
        )

        if cacheEnabled, let cached = await PreviewCache.shared.load(key: cacheKey, ttlSeconds: cacheTTL) {
            let info = PreviewInfo(
                title: url.lastPathComponent,
                language: languageName.isEmpty ? "Text" : languageName,
                lineCount: cached.lineCount,
                fileSizeBytes: cached.fileSizeBytes,
                isTruncated: cached.isTruncated,
                showTruncationWarning: SharedSettings.shared.showTruncationWarning,
                showHeader: SharedSettings.shared.showFileInfoHeader,
                isSensitive: SensitiveFileDetector.isSensitive(url: url),
                rawText: cached.rawText,
                rawHTML: cached.rawHTML,
                renderedHTML: cached.renderedHTML,
                codeFontSize: SharedSettings.shared.fontSize,
                defaultMarkdownMode: SharedSettings.shared.markdownDefaultMode,
                markdownRenderFontSize: SharedSettings.shared.markdownRenderFontSize,
                markdownShowInlineImages: SharedSettings.shared.markdownShowInlineImages,
                markdownCustomCSS: SharedSettings.shared.markdownCustomCSS,
                markdownCustomCSSOverride: SharedSettings.shared.markdownCustomCSSOverride,
                themeName: SharedSettings.shared.selectedTheme,
                showUnknownTextWarning: showUnknownTextWarning,
                showBinaryWarning: showBinaryWarning,
                systemIsDark: systemIsDark,
                wordWrap: SharedSettings.shared.wordWrap,
                markdownShowTOC: SharedSettings.shared.markdownShowTOC,
                copyBehavior: SharedSettings.shared.copyBehavior
            )

            let palette = ThemePalette.palette(for: SharedSettings.shared.selectedTheme, systemIsDark: systemIsDark)
            let html = PreviewHTMLBuilder.buildHTML(info: info, palette: palette)
            routeLogger.log("HTML built (cache) for \(url.lastPathComponent, privacy: .public)")
            return makeHTMLReply(
                html: html,
                lineCount: cached.lineCount,
                fontSize: SharedSettings.shared.fontSize,
                showHeader: SharedSettings.shared.showFileInfoHeader
            )
        }

        let cancelledBeforeRead = !(await PreviewRequestCoordinator.shared.isCurrent(requestId))
        if cancelledBeforeRead {
            routeLogger.log("Request cancelled before read for \(url.lastPathComponent, privacy: .public)")
        }

        let maxBytes = SharedSettings.shared.maxFileSizeBytes
        let fileInfo: FileInfo
        if isBinaryPlist {
            guard let conversion = PlistConverter.convertBinaryPlistToXML(at: url, maxBytes: maxBytes) else {
                routeLogger.log("Fallback: plist conversion failed for \(url.lastPathComponent, privacy: .public)")
                return makePlainTextFallback(url: url, systemIsDark: systemIsDark)
            }
            let convertedTruncated = conversion.isTruncated || fileSize > maxBytes
            fileInfo = FileInspector.fileInfo(
                from: conversion.text,
                fileSizeBytes: fileSize,
                isTruncated: convertedTruncated
            )
        } else {
            do {
                fileInfo = try FileInspector.loadFile(url: url, maxBytes: maxBytes, encoding: encoding)
            } catch {
                routeLogger.error("Read failed for \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return makePlainTextFallback(url: url, systemIsDark: systemIsDark)
            }
        }

        let cancelledAfterRead = !(await PreviewRequestCoordinator.shared.isCurrent(requestId))
        if cancelledAfterRead {
            routeLogger.log("Request cancelled after read for \(url.lastPathComponent, privacy: .public)")
        }

        let shouldAttemptHighlight = shouldHighlight && !cancelledAfterRead
        let rawHTML: String
        if isMarkdown && !useMarkdownHighlight {
            rawHTML = PlainTextRenderer.render(code: fileInfo.text, showLineNumbers: showLineNumbers)
        } else if shouldAttemptHighlight {
            let highlightResult = await HighlightXPCClient.shared.highlight(
                code: fileInfo.text,
                language: languageId,
                theme: SharedSettings.shared.selectedTheme,
                showLineNumbers: showLineNumbers,
                requestId: requestId,
                timeout: 3.0
            )

            switch highlightResult {
            case .success(let html):
                rawHTML = html
            case .failure(.cancelled):
                routeLogger.log("Highlight cancelled for \(url.lastPathComponent, privacy: .public); using plain text HTML")
                rawHTML = PlainTextRenderer.render(code: fileInfo.text, showLineNumbers: showLineNumbers)
            case .failure:
                rawHTML = PlainTextRenderer.render(code: fileInfo.text, showLineNumbers: showLineNumbers)
            }
        } else {
            rawHTML = PlainTextRenderer.render(code: fileInfo.text, showLineNumbers: showLineNumbers)
        }

#if DEBUG
        if shouldHighlight && !rawHTML.contains("tok-") {
            routeLogger.log("Highlight output missing tok- spans for \(url.lastPathComponent, privacy: .public)")
        }
#endif

        let cancelledAfterHighlight = !(await PreviewRequestCoordinator.shared.isCurrent(requestId))
        if cancelledAfterHighlight {
            routeLogger.log("Request cancelled after highlight for \(url.lastPathComponent, privacy: .public)")
        }

        let renderedHTML: String?
        if isMarkdown && !cancelledAfterHighlight {
            renderedHTML = MarkdownRenderer.renderHTML(from: fileInfo.text)
        } else {
            renderedHTML = nil
        }

        let info = PreviewInfo(
            title: url.lastPathComponent,
            language: languageName.isEmpty ? "Text" : languageName,
            lineCount: fileInfo.lineCount,
            fileSizeBytes: fileInfo.fileSizeBytes,
            isTruncated: fileInfo.isTruncated,
            showTruncationWarning: SharedSettings.shared.showTruncationWarning,
            showHeader: SharedSettings.shared.showFileInfoHeader,
            isSensitive: SensitiveFileDetector.isSensitive(url: url),
            rawText: fileInfo.text,
            rawHTML: rawHTML,
            renderedHTML: renderedHTML,
            codeFontSize: SharedSettings.shared.fontSize,
            defaultMarkdownMode: SharedSettings.shared.markdownDefaultMode,
            markdownRenderFontSize: SharedSettings.shared.markdownRenderFontSize,
            markdownShowInlineImages: SharedSettings.shared.markdownShowInlineImages,
            markdownCustomCSS: SharedSettings.shared.markdownCustomCSS,
            markdownCustomCSSOverride: SharedSettings.shared.markdownCustomCSSOverride,
            themeName: SharedSettings.shared.selectedTheme,
            showUnknownTextWarning: showUnknownTextWarning,
            showBinaryWarning: showBinaryWarning,
            systemIsDark: systemIsDark,
            wordWrap: SharedSettings.shared.wordWrap,
            markdownShowTOC: SharedSettings.shared.markdownShowTOC,
            copyBehavior: SharedSettings.shared.copyBehavior
        )

        let palette = ThemePalette.palette(for: SharedSettings.shared.selectedTheme, systemIsDark: systemIsDark)
        let html = PreviewHTMLBuilder.buildHTML(info: info, palette: palette)
        routeLogger.log("HTML built for \(url.lastPathComponent, privacy: .public)")

        let isCurrentRequest = await PreviewRequestCoordinator.shared.isCurrent(requestId)
        let shouldCache = cacheEnabled && !info.isSensitive && isCurrentRequest
        if shouldCache {
            let entry = PreviewCacheEntry(
                createdAt: Date(),
                rawHTML: rawHTML,
                renderedHTML: renderedHTML,
                rawText: fileInfo.text,
                lineCount: fileInfo.lineCount,
                fileSizeBytes: fileInfo.fileSizeBytes,
                isTruncated: fileInfo.isTruncated
            )
            await PreviewCache.shared.store(
                key: cacheKey,
                entry: entry,
                ttlSeconds: cacheTTL,
                maxBytes: cacheMaxBytes
            )
        }

        return makeHTMLReply(
            html: html,
            lineCount: fileInfo.lineCount,
            fontSize: SharedSettings.shared.fontSize,
            showHeader: SharedSettings.shared.showFileInfoHeader
        )
    }

    @MainActor
    private static func systemIsDark() -> Bool {
        let appearance = NSApplication.shared.effectiveAppearance
        if let match = appearance.bestMatch(from: [.darkAqua, .aqua]) {
            return match == .darkAqua
        }
        return false
    }

    private static func makeHTMLReply(
        html: String,
        lineCount: Int = 40,
        fontSize: Double = 14,
        showHeader: Bool = true
    ) -> QLPreviewReply {
        let lineHeight = fontSize * 1.45
        let headerHeight: CGFloat = showHeader ? 48 : 0
        let padding: CGFloat = 32
        let contentHeight = CGFloat(lineCount) * lineHeight
        let estimatedHeight = contentHeight + headerHeight + padding

        let height = min(max(estimatedHeight, 160), 1000)
        let width: CGFloat = lineCount <= 5 ? 420 : 700

        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: width, height: height)) { _ in
            html.data(using: .utf8) ?? Data()
        }
        reply.stringEncoding = .utf8
        return reply
    }

    // MARK: - Experiment 1: RTF Data-Based Reply
    // Hypothesis: If QL renders RTF using a native NSTextView, Cmd+C may work natively.
    private static func makeRTFReply(
        text: String,
        palette: ThemePalette,
        lineCount: Int,
        fontSize: Double
    ) -> QLPreviewReply {
        let font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
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

        let lineHeight = fontSize * 1.45
        let height = min(max(CGFloat(lineCount) * lineHeight + 32, 160), 1000)
        let width: CGFloat = lineCount <= 5 ? 420 : 700

        let reply = QLPreviewReply(dataOfContentType: .rtf, contentSize: CGSize(width: width, height: height)) { _ in
            rtfData
        }
        return reply
    }

    private static func makePlainTextFallback(url: URL, systemIsDark: Bool) -> QLPreviewReply {
        let text: String
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            text = utf8
        } else if let latin1 = try? String(contentsOf: url, encoding: .isoLatin1) {
            text = latin1
        } else {
            text = ""
        }

        let lineCount = text.components(separatedBy: "\n").count

        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")

        let palette = ThemePalette.palette(for: SharedSettings.shared.selectedTheme, systemIsDark: systemIsDark)
        let html = """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8" />
          <style>
            body {
              margin: 0; padding: 12px;
              background: \(palette.background);
              color: \(palette.text);
              font-family: "SF Mono", Menlo, Monaco, monospace;
              font-size: \(Int(SharedSettings.shared.fontSize))px;
              line-height: 1.45;
            }
            pre { margin: 0; white-space: pre-wrap; word-wrap: break-word; }
          </style>
        </head>
        <body><pre>\(escaped)</pre></body>
        </html>
        """
        routeLogger.log("Plain text fallback built for \(url.lastPathComponent, privacy: .public)")
        return makeHTMLReply(
            html: html,
            lineCount: lineCount,
            fontSize: SharedSettings.shared.fontSize,
            showHeader: false
        )
    }
}

// MARK: - NSColor(hex:)

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
