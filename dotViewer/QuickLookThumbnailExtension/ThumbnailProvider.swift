import AppKit
import OSLog
import QuickLookThumbnailing
import WebKit
import Shared

final class ThumbnailProvider: QLThumbnailProvider {
    private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "QuickLookThumbnail")

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let handlerBox = HandlerBox(handler)
        let settings = ThumbnailSettings.capture()
        let url = request.fileURL
        let maximumSize = request.maximumSize
        let requestId = UUID().uuidString

        logger.info("Thumbnail request: \(url.lastPathComponent, privacy: .public)")

        Task.detached(priority: .userInitiated) { [handlerBox, settings, url, maximumSize, requestId] in
            if Task.isCancelled {
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

            let fileAttributes = FileAttributes.attributes(for: url)
            let typeIsTextual = fileAttributes?.isTextual ?? false
            let looksTextual = fileAttributes?.looksTextual ?? false
            let isTextual = typeIsTextual || (settings.forceTextForUnknown && looksTextual)
            if !isTextual {
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

            let registry = FileTypeRegistry.shared
            let key = FileTypeResolution.bestKey(for: url, registry: registry)
            let isExtensionEnabled = registry.isExtensionEnabled(key)
            let isKnownType = registry.fileType(for: key) != nil

            if !isExtensionEnabled || (!isKnownType && !settings.allowUnknown) {
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

            let fileMeta = FileInspector.fileMetadata(for: url)
            let fileSize = fileMeta.sizeBytes
            let fileMtime = fileMeta.mtime

            let isMarkdown = ["md", "markdown", "mdx"].contains(key)
            let showBinaryWarning = !typeIsTextual
            let encoding = fileAttributes?.stringEncoding ?? .utf8

            let languageId = registry.highlightLanguage(for: key) ?? "plaintext"
            let languageName = registry.fileType(for: key)?.displayName ?? (key.isEmpty ? "Text" : key.uppercased())

            let cacheKey = PreviewCacheKey(
                url: url,
                fileSize: fileSize,
                mtime: fileMtime,
                showLineNumbers: settings.showLineNumbers,
                codeFontSize: settings.codeFontSize,
                markdownUseSyntaxHighlightInRaw: settings.markdownUseSyntaxHighlightInRaw,
                allowUnknown: settings.allowUnknown,
                forceTextForUnknown: settings.forceTextForUnknown,
                languageId: languageId,
                theme: settings.selectedTheme,
                showHeader: settings.showHeader,
                markdownDefaultMode: settings.markdownDefaultMode,
                markdownRenderFontSize: settings.markdownRenderFontSize,
                markdownShowInlineImages: settings.markdownShowInlineImages,
                markdownCustomCSS: settings.markdownCustomCSS,
                markdownCustomCSSOverride: settings.markdownCustomCSSOverride
            )

            await PreviewCache.shared.handleClearIfRequested()

            let rawHTML: String
            let rawText: String
            let renderedHTML: String?
            let lineCount: Int
            let fileSizeBytes: Int
            let isTruncated: Bool

            if settings.cacheEnabled,
               let cached = await PreviewCache.shared.load(key: cacheKey, ttlSeconds: settings.cacheTTL) {
                rawHTML = cached.rawHTML
                rawText = cached.rawText
                renderedHTML = cached.renderedHTML
                lineCount = cached.lineCount
                fileSizeBytes = cached.fileSizeBytes
                isTruncated = cached.isTruncated
            } else {
                let fileInfo: FileInfo
                do {
                    fileInfo = try FileInspector.loadFile(url: url, maxBytes: settings.maxFileSizeBytes, encoding: encoding)
                } catch {
                    await MainActor.run {
                        handlerBox.handler(nil, error)
                    }
                    return
                }

                rawText = fileInfo.text
                lineCount = fileInfo.lineCount
                fileSizeBytes = fileInfo.fileSizeBytes
                isTruncated = fileInfo.isTruncated

                if isMarkdown && !settings.markdownUseSyntaxHighlightInRaw {
                    rawHTML = PlainTextRenderer.render(code: fileInfo.text, showLineNumbers: settings.showLineNumbers)
                } else {
                    let highlightResult = await HighlightXPCClient.shared.highlight(
                        code: fileInfo.text,
                        language: languageId,
                        theme: settings.selectedTheme,
                        showLineNumbers: settings.showLineNumbers,
                        requestId: requestId,
                        timeout: 3.0
                    )
                    if Task.isCancelled {
                        HighlightXPCClient.shared.cancel(requestId: requestId)
                        await MainActor.run {
                            handlerBox.handler(nil, nil)
                        }
                        return
                    }
                    switch highlightResult {
                    case .success(let html):
                        rawHTML = html
                    case .failure:
                        rawHTML = PlainTextRenderer.render(code: fileInfo.text, showLineNumbers: settings.showLineNumbers)
                    }
                }

                if isMarkdown {
                    renderedHTML = MarkdownRenderer.renderHTML(from: fileInfo.text)
                } else {
                    renderedHTML = nil
                }

                if settings.cacheEnabled && !SensitiveFileDetector.isSensitive(url: url) {
                    let entry = PreviewCacheEntry(
                        createdAt: Date(),
                        rawHTML: rawHTML,
                        renderedHTML: renderedHTML,
                        rawText: rawText,
                        lineCount: lineCount,
                        fileSizeBytes: fileSizeBytes,
                        isTruncated: isTruncated
                    )
                    await PreviewCache.shared.store(
                        key: cacheKey,
                        entry: entry,
                        ttlSeconds: settings.cacheTTL,
                        maxBytes: settings.cacheMaxBytes
                    )
                }
            }

            let info = PreviewInfo(
                title: url.lastPathComponent,
                language: languageName.isEmpty ? "Text" : languageName,
                lineCount: lineCount,
                fileSizeBytes: fileSizeBytes,
                isTruncated: isTruncated,
                showTruncationWarning: settings.showTruncationWarning,
                showHeader: settings.showHeader,
                isSensitive: SensitiveFileDetector.isSensitive(url: url),
                rawText: rawText,
                rawHTML: rawHTML,
                renderedHTML: renderedHTML,
                codeFontSize: settings.codeFontSize,
                defaultMarkdownMode: settings.markdownDefaultMode,
                markdownRenderFontSize: settings.markdownRenderFontSize,
                markdownShowInlineImages: settings.markdownShowInlineImages,
                markdownCustomCSS: settings.markdownCustomCSS,
                markdownCustomCSSOverride: settings.markdownCustomCSSOverride,
                showBinaryWarning: showBinaryWarning
            )

            let systemIsDark = await MainActor.run { ThumbnailProvider.systemIsDark() }
            let palette = ThemePalette.palette(for: settings.selectedTheme, systemIsDark: systemIsDark)
            let html = PreviewHTMLBuilder.buildHTML(info: info, palette: palette)

            guard let image = await ThumbnailHTMLRenderer.render(html: html, size: maximumSize, timeoutSeconds: 1.0) else {
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

            let reply = QLThumbnailReply(contextSize: maximumSize) { context in
                let rect = CGRect(origin: .zero, size: maximumSize)
                context.clear(rect)
                let targetRect = ThumbnailHTMLRenderer.aspectFitRect(for: image.size, in: rect)
                image.draw(in: targetRect)
                return true
            }

            await MainActor.run {
                handlerBox.handler(reply, nil)
            }
        }
    }

    @MainActor
    private static func systemIsDark() -> Bool {
        let appearance = NSApplication.shared.effectiveAppearance
        if let match = appearance.bestMatch(from: [.darkAqua, .aqua]) {
            return match == .darkAqua
        }
        return false
    }
}

private struct ThumbnailSettings: Sendable {
    let showLineNumbers: Bool
    let codeFontSize: Double
    let markdownUseSyntaxHighlightInRaw: Bool
    let forceTextForUnknown: Bool
    let allowUnknown: Bool
    let selectedTheme: String
    let showHeader: Bool
    let markdownDefaultMode: String
    let markdownRenderFontSize: Double
    let markdownShowInlineImages: Bool
    let markdownCustomCSS: String
    let markdownCustomCSSOverride: Bool
    let showTruncationWarning: Bool
    let cacheEnabled: Bool
    let cacheTTL: Int
    let cacheMaxBytes: Int
    let maxFileSizeBytes: Int

    static func capture() -> ThumbnailSettings {
        ThumbnailSettings(
            showLineNumbers: SharedSettings.shared.showLineNumbers,
            codeFontSize: SharedSettings.shared.fontSize,
            markdownUseSyntaxHighlightInRaw: SharedSettings.shared.markdownUseSyntaxHighlightInRaw,
            forceTextForUnknown: SharedSettings.shared.previewForceTextForUnknown,
            allowUnknown: SharedSettings.shared.previewAllFileTypes,
            selectedTheme: SharedSettings.shared.selectedTheme,
            showHeader: SharedSettings.shared.showFileInfoHeader,
            markdownDefaultMode: SharedSettings.shared.markdownDefaultMode,
            markdownRenderFontSize: SharedSettings.shared.markdownRenderFontSize,
            markdownShowInlineImages: SharedSettings.shared.markdownShowInlineImages,
            markdownCustomCSS: SharedSettings.shared.markdownCustomCSS,
            markdownCustomCSSOverride: SharedSettings.shared.markdownCustomCSSOverride,
            showTruncationWarning: SharedSettings.shared.showTruncationWarning,
            cacheEnabled: SharedSettings.shared.previewCacheEnabled,
            cacheTTL: SharedSettings.shared.previewCacheTTLSeconds,
            cacheMaxBytes: SharedSettings.shared.previewCacheMaxMB * 1_024 * 1_024,
            maxFileSizeBytes: SharedSettings.shared.maxFileSizeBytes
        )
    }
}

private final class HandlerBox: @unchecked Sendable {
    let handler: (QLThumbnailReply?, Error?) -> Void

    init(_ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        self.handler = handler
    }
}

@MainActor
private final class ThumbnailHTMLRenderer: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private var continuation: CheckedContinuation<NSImage?, Never>?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.suppressesIncrementalRendering = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
    }

    static func render(html: String, size: CGSize, timeoutSeconds: Double = 1.0) async -> NSImage? {
        let renderer = ThumbnailHTMLRenderer()
        return await renderer.renderInternal(html: html, size: size, timeoutSeconds: timeoutSeconds)
    }

    private func renderInternal(html: String, size: CGSize, timeoutSeconds: Double) async -> NSImage? {
        webView.frame = CGRect(origin: .zero, size: size)
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                self.webView.loadHTMLString(html, baseURL: nil)

                Task { @MainActor in
                    // Prevent a hung thumbnail request if WebKit never finishes.
                    try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                    guard self.continuation != nil else { return }
                    self.webView.stopLoading()
                    self.finish(nil)
                }
            }
        } onCancel: {
            Task { @MainActor in
                self.webView.stopLoading()
                self.finish(nil)
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let snapshotConfig = WKSnapshotConfiguration()
        snapshotConfig.rect = webView.bounds
        webView.takeSnapshot(with: snapshotConfig) { [weak self] image, _ in
            guard let self else { return }
            self.finish(image)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(nil)
    }

    private func finish(_ image: NSImage?) {
        continuation?.resume(returning: image)
        continuation = nil
    }

    static func aspectFitRect(for imageSize: CGSize, in container: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return container }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        let x = container.midX - width / 2
        let y = container.midY - height / 2
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
