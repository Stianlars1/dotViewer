import AppKit
import OSLog
import QuickLookThumbnailing
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
        logger.info("Thumbnail request: \(url.lastPathComponent, privacy: .public)")

        Task.detached(priority: .userInitiated) { [handlerBox, settings, url, maximumSize, logger] in
            if Task.isCancelled {
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

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
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

            let isTextual = typeIsTextual || isBinaryPlist || (settings.forceTextForUnknown && looksTextualSample)
            if !isTextual {
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

            let registry = FileTypeRegistry.shared
            let key = FileTypeResolution.bestKey(for: url, registry: registry)
            let isExtensionEnabled = registry.isExtensionEnabled(key)
            let isKnownType = registry.fileType(for: key) != nil || registry.highlightLanguage(for: key) != nil

            if !isExtensionEnabled || (!isKnownType && !settings.allowUnknown) {
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

            let fileMeta = FileInspector.fileMetadata(for: url)
            let fileSize = fileMeta.sizeBytes
            let isEmptyFile = fileSize == 0
            let showBinaryWarning = (!typeIsTextual && !looksTextual && !isEmptyFile)
            if showBinaryWarning {
                logger.debug("Binary warning for \(url.lastPathComponent, privacy: .public)")
            }

            let encoding = fileAttributes?.stringEncoding ?? .utf8
            let languageName = registry.displayName(for: key) ?? (key.isEmpty ? "Text" : key.uppercased())

            if Task.isCancelled {
                await MainActor.run {
                    handlerBox.handler(nil, nil)
                }
                return
            }

            let snippet: TextThumbnailSnippet
            if isBinaryPlist {
                guard let conversion = PlistConverter.convertBinaryPlistToXML(at: url, maxBytes: settings.thumbnailMaxBytes) else {
                    await MainActor.run {
                        handlerBox.handler(nil, nil)
                    }
                    return
                }
                snippet = TextThumbnailRenderer.makeSnippet(
                    text: conversion.text,
                    maxLines: settings.thumbnailMaxLines,
                    truncatedByBytes: conversion.isTruncated
                )
            } else {
                do {
                    snippet = try TextThumbnailRenderer.loadSnippet(
                        url: url,
                        maxBytes: settings.thumbnailMaxBytes,
                        maxLines: settings.thumbnailMaxLines,
                        encoding: encoding
                    )
                } catch {
                    await MainActor.run {
                        handlerBox.handler(nil, error)
                    }
                    return
                }
            }

            // Request tree-sitter tokens from XPC (1.5s timeout for thumbnails)
            let languageId = registry.highlightLanguage(for: key) ?? ""
            var treeSitterTokens: [HighlightToken]? = nil
            if !languageId.isEmpty {
                let snippetCode = snippet.lines.joined(separator: "\n")
                let requestId = UUID().uuidString
                let result = await HighlightXPCClient.shared.highlightTokens(
                    code: snippetCode,
                    language: languageId,
                    requestId: requestId,
                    timeout: 1.5
                )
                if case .success(let tokens) = result, !tokens.isEmpty {
                    treeSitterTokens = tokens
                }
            }

            let systemIsDark = await MainActor.run { ThumbnailProvider.systemIsDark() }
            let palette = ThemePalette.palette(for: settings.selectedTheme, systemIsDark: systemIsDark)
            let badgeText = ThumbnailProvider.badgeText(for: url, key: key, languageName: languageName)
            let reply = TextThumbnailRenderer.makeReply(
                size: maximumSize,
                snippet: snippet,
                palette: palette,
                languageLabel: languageName,
                badgeText: badgeText,
                fileSizeBytes: fileSize,
                showHeader: settings.showHeader,
                showLineNumbers: settings.showLineNumbers,
                fontSize: CGFloat(settings.codeFontSize),
                treeSitterTokens: treeSitterTokens
            )

            await MainActor.run {
                handlerBox.handler(reply, nil)
            }
        }
    }

    @MainActor
    private static func systemIsDark() -> Bool {
        // NSApplication.shared.effectiveAppearance is unreliable in headless
        // extension contexts (thumbnail provider has no window/visual context).
        // Read the system preference directly instead.
        if let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") {
            return style.lowercased() == "dark"
        }
        return false
    }

    private static func badgeText(for url: URL, key: String, languageName: String) -> String {
        let ext = url.pathExtension.uppercased()
        let raw = !ext.isEmpty ? ext : (!key.isEmpty ? key.uppercased() : languageName.uppercased())
        if raw.count > 6 {
            return String(raw.prefix(6))
        }
        return raw
    }
}

private struct ThumbnailSettings: Sendable {
    let showLineNumbers: Bool
    let codeFontSize: Double
    let forceTextForUnknown: Bool
    let allowUnknown: Bool
    let selectedTheme: String
    let showHeader: Bool
    let thumbnailMaxBytes: Int
    let thumbnailMaxLines: Int

    static func capture() -> ThumbnailSettings {
        ThumbnailSettings(
            showLineNumbers: SharedSettings.shared.showLineNumbers,
            codeFontSize: SharedSettings.shared.fontSize,
            forceTextForUnknown: SharedSettings.shared.previewForceTextForUnknown,
            allowUnknown: SharedSettings.shared.previewAllFileTypes,
            selectedTheme: SharedSettings.shared.selectedTheme,
            showHeader: SharedSettings.shared.showFileInfoHeader,
            thumbnailMaxBytes: SharedSettings.shared.thumbnailMaxBytes,
            thumbnailMaxLines: SharedSettings.shared.thumbnailMaxLines
        )
    }
}

private final class HandlerBox: @unchecked Sendable {
    let handler: (QLThumbnailReply?, Error?) -> Void

    init(_ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        self.handler = handler
    }
}
