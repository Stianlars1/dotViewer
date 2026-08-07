import Foundation
import OSLog

/// A file dotViewer has decided to draw, and everything a host needs to size a window around it.
public struct PreviewRender: Sendable {
    public let html: String
    public let lineCount: Int
    public let fontSize: Double
    public let showHeader: Bool
    public let title: String
    public let language: String
}

public enum PreviewOutcome: Sendable {
    case rendered(PreviewRender)
    /// Not ours to draw — a video, an image, anything binary. Quick Look hands the file back to the
    /// system renderer; the ⌥Space panel declines to open and lets Finder's own preview take it.
    case systemFallback
}

/// The single rendering pipeline: file URL in, HTML out.
///
/// Both front-ends call this — `PreviewProvider` (Quick Look) and `PreviewPanelController`
/// (the host app's ⌥Space panel). Keeping one path is what stops the two from drifting as settings
/// keys and cache fields are added; the front-ends differ only in how they present the result.
public enum PreviewContentBuilder {
    private static let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "PreviewContent")
    private static let routeLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "QuickLookRouting")

    /// - Parameter enableSearchBridge: whether the generated page should subscribe to the loopback
    ///   search bridge. True for Quick Look, where keyboard input cannot reach the page. False for
    ///   the ⌥Space panel, which is a real window and receives ⌘F natively — subscribing there would
    ///   make the `CGEventTap` swallow keys the panel is already handling.
    /// - Parameter forceSearchUI: emit the search bar even when the "Show Find in Preview" setting
    ///   is off. That setting exists because in Quick Look the bar is only useful when the loopback
    ///   bridge can drive it; the panel handles ⌘F itself, so there the bar is always warranted.
    public static func build(
        for url: URL,
        systemIsDark: Bool,
        enableSearchBridge: Bool = true,
        forceSearchUI: Bool = false
    ) async -> PreviewOutcome {
        let actualPathExtension = url.pathExtension.lowercased()
        let registry = FileTypeRegistry.shared
        let key = FileTypeResolution.bestKey(for: url, registry: registry)
        logger.log("Preview request: \(url.lastPathComponent, privacy: .public) ext=\(actualPathExtension, privacy: .public) key=\(key, privacy: .public)")

        let (requestId, previousId) = await PreviewRequestCoordinator.shared.startNewRequest()
        if let previousId {
            HighlightXPCClient.shared.cancel(requestId: previousId)
        }

        let settings = SharedSettings.shared
        let cacheEnabled = settings.previewCacheEnabled
        let cacheTTL = settings.previewCacheTTLSeconds
        let cacheMaxBytes = settings.previewCacheMaxMB * 1_024 * 1_024
        let forceTextForUnknown = settings.previewForceTextForUnknown

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
            return .systemFallback
        }

        let isTextual = typeIsTextual || isBinaryPlist || (forceTextForUnknown && looksTextualSample)
        let isExtensionEnabled = registry.isExtensionEnabled(key)
        let isKnownType = registry.fileType(for: key) != nil || registry.highlightLanguage(for: key) != nil
        let allowUnknown = settings.previewAllFileTypes

        routeLogger.log(
            "Routing check ext=\(actualPathExtension, privacy: .public) key=\(key, privacy: .public) textual=\(isTextual, privacy: .public) allowUnknown=\(allowUnknown, privacy: .public) known=\(isKnownType, privacy: .public) enabled=\(isExtensionEnabled, privacy: .public) forceText=\(forceTextForUnknown, privacy: .public)"
        )

        if !isTextual {
            routeLogger.log("Fallback: non-textual file without forceText for \(url.lastPathComponent, privacy: .public)")
            return .systemFallback
        }

        if !isExtensionEnabled || (!isKnownType && !allowUnknown) {
            routeLogger.log("Fallback: extension disabled or unsupported type for \(url.lastPathComponent, privacy: .public)")
            return .rendered(plainTextFallback(url: url, systemIsDark: systemIsDark))
        }

        let fileMeta = FileInspector.fileMetadata(for: url)
        let fileSize = fileMeta.sizeBytes
        let fileMtime = fileMeta.mtime
        let isEmptyFile = fileSize == 0

        var languageId = registry.highlightLanguage(for: key) ?? "plaintext"
        var languageName = registry.displayName(for: key) ?? (key.isEmpty ? "Text" : key.uppercased())

        if actualPathExtension.isEmpty,
           let detected = ShebangLanguageDetector.detect(url: url) ?? detectedLanguage(forMimeType: mimeType) {
            languageId = detected.languageId
            languageName = detected.displayName
        }

        let isMarkdown = languageId == "markdown"
        let showLineNumbers = settings.showLineNumbers
        let useMarkdownHighlight = settings.markdownUseSyntaxHighlightInRaw
        let showBinaryWarning = (!typeIsTextual && !looksTextual && !isEmptyFile)
        let showUnknownTextWarning = (!typeIsTextual && looksTextualSample && !isKnownType && !isEmptyFile)
        let encoding = fileAttributes?.stringEncoding ?? .utf8

        routeLogger.debug("Preview routing: key=\(key, privacy: .public) lang=\(languageId, privacy: .public) markdown=\(isMarkdown, privacy: .public) known=\(isKnownType, privacy: .public) allowUnknown=\(allowUnknown, privacy: .public)")
        let shouldHighlight = !(isMarkdown && !useMarkdownHighlight)

        let cacheKey = PreviewCacheKey(
            url: url,
            fileSize: fileSize,
            mtime: fileMtime,
            showLineNumbers: showLineNumbers,
            codeFontSize: settings.fontSize,
            codeFontFamilyName: settings.codeFontFamilyName,
            markdownUseSyntaxHighlightInRaw: useMarkdownHighlight,
            allowUnknown: allowUnknown,
            forceTextForUnknown: forceTextForUnknown,
            languageId: languageId,
            theme: settings.selectedTheme,
            showHeader: settings.showFileInfoHeader,
            markdownDefaultMode: settings.markdownDefaultMode,
            markdownRenderFontSize: settings.markdownRenderFontSize,
            markdownRenderedFontFamilyName: settings.markdownRenderedFontFamilyName,
            markdownRenderedWidthMode: settings.markdownRenderedWidthMode,
            markdownRenderedCustomMaxWidth: settings.markdownRenderedCustomMaxWidth,
            markdownShowInlineImages: settings.markdownShowInlineImages,
            markdownCustomCSS: settings.markdownCustomCSS,
            markdownCustomCSSOverride: settings.markdownCustomCSSOverride,
            markdownTOCDefaultOpen: settings.markdownTOCDefaultOpen,
            includeLineNumbersInCopy: settings.includeLineNumbersInCopy,
            codeContentWidthMode: settings.codeContentWidthMode,
            codeContentCustomMaxWidth: settings.codeContentCustomMaxWidth,
            codeContentAlignment: settings.codeContentAlignment,
            markdownRawContentAlignment: settings.markdownRawContentAlignment,
            markdownRenderedContentAlignment: settings.markdownRenderedContentAlignment,
            wordWrap: settings.wordWrap
        )

        if cacheEnabled, let cached = await PreviewCache.shared.load(key: cacheKey, ttlSeconds: cacheTTL) {
            let info = makeInfo(
                url: url,
                languageName: languageName,
                lineCount: cached.lineCount,
                fileSizeBytes: cached.fileSizeBytes,
                isTruncated: cached.isTruncated,
                rawText: cached.rawText,
                rawHTML: cached.rawHTML,
                renderedHTML: cached.renderedHTML,
                showUnknownTextWarning: showUnknownTextWarning,
                showBinaryWarning: showBinaryWarning,
                systemIsDark: systemIsDark,
                enableSearchBridge: enableSearchBridge,
                forceSearchUI: forceSearchUI
            )

            let palette = ThemePalette.palette(for: settings.selectedTheme, systemIsDark: systemIsDark)
            let html = PreviewHTMLBuilder.buildHTML(info: info, palette: palette)
            routeLogger.log("HTML built (cache) for \(url.lastPathComponent, privacy: .public)")
            return .rendered(PreviewRender(
                html: html,
                lineCount: cached.lineCount,
                fontSize: settings.fontSize,
                showHeader: settings.showFileInfoHeader,
                title: info.title,
                language: info.language
            ))
        }

        let cancelledBeforeRead = !(await PreviewRequestCoordinator.shared.isCurrent(requestId))
        if cancelledBeforeRead {
            routeLogger.log("Request cancelled before read for \(url.lastPathComponent, privacy: .public)")
        }

        let maxBytes = settings.maxFileSizeBytes
        let fileInfo: FileInfo
        if isBinaryPlist {
            guard let conversion = PlistConverter.convertBinaryPlistToXML(at: url, maxBytes: maxBytes) else {
                routeLogger.log("Fallback: plist conversion failed for \(url.lastPathComponent, privacy: .public)")
                return .rendered(plainTextFallback(url: url, systemIsDark: systemIsDark))
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
                return .rendered(plainTextFallback(url: url, systemIsDark: systemIsDark))
            }
        }

        let cancelledAfterRead = !(await PreviewRequestCoordinator.shared.isCurrent(requestId))
        if cancelledAfterRead {
            routeLogger.log("Request cancelled after read for \(url.lastPathComponent, privacy: .public)")
        }

        var effectiveLanguageId = languageId
        var effectiveLanguageName = languageName

        if let shebang = ShebangLanguageDetector.detect(in: fileInfo.text),
           key.isEmpty || (!isKnownType && actualPathExtension.isEmpty) {
            effectiveLanguageId = shebang.languageId
            effectiveLanguageName = shebang.displayName
        }

        let specialHTML: String?
        if let kind = DelimitedTextKind(rawValue: key),
           let preview = DelimitedTextRenderer.preview(text: fileInfo.text, kind: kind) {
            specialHTML = preview.html
            effectiveLanguageId = "plaintext"
            effectiveLanguageName = kind.rawValue.uppercased()
        } else if ManPageRenderer.shouldRender(url: url, mimeType: mimeType, key: key, text: fileInfo.text),
                  let html = ManPageRenderer.renderHTML(url: url) {
            specialHTML = html
            effectiveLanguageId = "plaintext"
            effectiveLanguageName = "Man Page"
        } else {
            specialHTML = nil
        }

        let shouldAttemptHighlight = shouldHighlight && !cancelledAfterRead && specialHTML == nil
        let rawHTML: String
        if let specialHTML {
            rawHTML = specialHTML
        } else if isMarkdown && !useMarkdownHighlight {
            rawHTML = PlainTextRenderer.render(code: fileInfo.text, showLineNumbers: showLineNumbers)
        } else if shouldAttemptHighlight {
            let highlightResult = await HighlightXPCClient.shared.highlight(
                code: fileInfo.text,
                language: effectiveLanguageId,
                theme: settings.selectedTheme,
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

        let info = makeInfo(
            url: url,
            languageName: effectiveLanguageName,
            lineCount: fileInfo.lineCount,
            fileSizeBytes: fileInfo.fileSizeBytes,
            isTruncated: fileInfo.isTruncated,
            rawText: fileInfo.text,
            rawHTML: rawHTML,
            renderedHTML: renderedHTML,
            showUnknownTextWarning: showUnknownTextWarning,
            showBinaryWarning: showBinaryWarning,
            systemIsDark: systemIsDark,
            enableSearchBridge: enableSearchBridge,
            forceSearchUI: forceSearchUI
        )

        let palette = ThemePalette.palette(for: settings.selectedTheme, systemIsDark: systemIsDark)
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

        return .rendered(PreviewRender(
            html: html,
            lineCount: fileInfo.lineCount,
            fontSize: settings.fontSize,
            showHeader: settings.showFileInfoHeader,
            title: info.title,
            language: info.language
        ))
    }

    // MARK: - Helpers

    /// Every field here reads from `SharedSettings`, so it is the same for the cached and freshly
    /// rendered paths — keeping it in one place is what stops the two from drifting.
    private static func makeInfo(
        url: URL,
        languageName: String,
        lineCount: Int,
        fileSizeBytes: Int,
        isTruncated: Bool,
        rawText: String,
        rawHTML: String,
        renderedHTML: String?,
        showUnknownTextWarning: Bool,
        showBinaryWarning: Bool,
        systemIsDark: Bool,
        enableSearchBridge: Bool,
        forceSearchUI: Bool
    ) -> PreviewInfo {
        let settings = SharedSettings.shared
        return PreviewInfo(
            title: url.lastPathComponent,
            language: languageName.isEmpty ? "Text" : languageName,
            lineCount: lineCount,
            fileSizeBytes: fileSizeBytes,
            isTruncated: isTruncated,
            showTruncationWarning: settings.showTruncationWarning,
            showHeader: settings.showFileInfoHeader,
            isSensitive: SensitiveFileDetector.isSensitive(url: url),
            rawText: rawText,
            rawHTML: rawHTML,
            renderedHTML: renderedHTML,
            codeFontSize: settings.fontSize,
            codeFontFamilyName: settings.codeFontFamilyName,
            codeContentWidthMode: settings.codeContentWidthMode,
            codeContentCustomMaxWidth: settings.codeContentCustomMaxWidth,
            codeContentAlignment: settings.codeContentAlignment,
            defaultMarkdownMode: settings.markdownDefaultMode,
            markdownRenderFontSize: settings.markdownRenderFontSize,
            markdownRenderedFontFamilyName: settings.markdownRenderedFontFamilyName,
            markdownRenderedWidthMode: settings.markdownRenderedWidthMode,
            markdownRenderedCustomMaxWidth: settings.markdownRenderedCustomMaxWidth,
            markdownRawContentAlignment: settings.markdownRawContentAlignment,
            markdownRenderedContentAlignment: settings.markdownRenderedContentAlignment,
            markdownShowInlineImages: settings.markdownShowInlineImages,
            markdownCustomCSS: settings.markdownCustomCSS,
            markdownCustomCSSOverride: settings.markdownCustomCSSOverride,
            themeName: settings.selectedTheme,
            showUnknownTextWarning: showUnknownTextWarning,
            showBinaryWarning: showBinaryWarning,
            systemIsDark: systemIsDark,
            wordWrap: settings.wordWrap,
            markdownShowTOC: settings.markdownShowTOC,
            markdownTOCDefaultOpen: settings.markdownTOCDefaultOpen,
            copyBehavior: settings.copyBehavior,
            showSearchButton: forceSearchUI || settings.showSearchButton,
            includeLineNumbersInCopy: settings.includeLineNumbersInCopy,
            sourceDirectory: url.deletingLastPathComponent().path,
            enableSearchBridge: enableSearchBridge
        )
    }

    private static func detectedLanguage(forMimeType mimeType: String) -> ShebangMatch? {
        switch mimeType.lowercased() {
        case "text/x-shellscript":
            return ShebangMatch(languageId: "bash", displayName: "Shell Script")
        case "text/x-script.python":
            return ShebangMatch(languageId: "python", displayName: "Python")
        case "text/x-perl":
            return ShebangMatch(languageId: "perl", displayName: "Perl")
        case "text/x-ruby":
            return ShebangMatch(languageId: "ruby", displayName: "Ruby")
        case "text/x-php":
            return ShebangMatch(languageId: "php", displayName: "PHP")
        default:
            return nil
        }
    }

    /// Last resort for a file we know is text but cannot route: no header, no highlighting, but
    /// still the user's theme and font rather than a blank window.
    public static func plainTextFallback(url: URL, systemIsDark: Bool) -> PreviewRender {
        let text: String
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            text = utf8
        } else if let latin1 = try? String(contentsOf: url, encoding: .isoLatin1) {
            text = latin1
        } else {
            text = ""
        }

        let lineCount = TextLineUtilities.visualLineCount(in: text)

        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")

        let settings = SharedSettings.shared
        let palette = ThemePalette.palette(for: settings.selectedTheme, systemIsDark: systemIsDark)
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
              font-family: \(PreviewFontFamily.codeCSSStack(for: settings.codeFontFamilyName));
              font-size: \(Int(settings.fontSize))px;
              line-height: 1.45;
            }
            pre { margin: 0; white-space: pre-wrap; word-wrap: break-word; }
          </style>
        </head>
        <body><pre>\(escaped)</pre></body>
        </html>
        """
        routeLogger.log("Plain text fallback built for \(url.lastPathComponent, privacy: .public)")
        return PreviewRender(
            html: html,
            lineCount: lineCount,
            fontSize: settings.fontSize,
            showHeader: false,
            title: url.lastPathComponent,
            language: "Text"
        )
    }
}
