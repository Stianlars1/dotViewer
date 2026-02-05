import Foundation
import AppKit
import QuickLookThumbnailing
import Shared

struct TextThumbnailSnippet {
    let lines: [String]
    let isTruncated: Bool
    let lineCount: Int
}

enum TextThumbnailRenderer {
    static func loadSnippet(
        url: URL,
        maxBytes: Int,
        maxLines: Int,
        encoding: String.Encoding
    ) throws -> TextThumbnailSnippet {
        let handle = try FileHandle(forReadingFrom: url)
        let data = handle.readData(ofLength: maxBytes)
        try? handle.close()
        let text = decodeString(data: data, encoding: encoding)
        return makeSnippet(text: text, maxLines: maxLines, truncatedByBytes: data.count >= maxBytes)
    }

    static func makeSnippet(text: String, maxLines: Int, truncatedByBytes: Bool) -> TextThumbnailSnippet {
        let rawLines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let truncatedByLines = rawLines.count > maxLines
        let limitedLines = rawLines.prefix(maxLines).map(String.init)
        let isTruncated = truncatedByLines || truncatedByBytes

        var lines = limitedLines
        if isTruncated, let last = lines.indices.last {
            lines[last] = lines[last] + " ..."
        }

        return TextThumbnailSnippet(lines: lines, isTruncated: isTruncated, lineCount: max(limitedLines.count, 1))
    }

    static func makeReply(
        size: CGSize,
        snippet: TextThumbnailSnippet,
        palette: ThemePalette,
        languageLabel: String,
        badgeText: String,
        fileSizeBytes: Int,
        showHeader: Bool,
        showLineNumbers: Bool,
        fontSize: CGFloat
    ) -> QLThumbnailReply {
        let reply = QLThumbnailReply(contextSize: size) { context in
            let rect = CGRect(origin: .zero, size: size)
            let headerHeight: CGFloat = showHeader ? 20 : 0
            let padding: CGFloat = 8

            let backgroundColor = NSColor(hex: palette.background) ?? .windowBackgroundColor
            let textColor = NSColor(hex: palette.text) ?? .labelColor
            let gutterColor = NSColor(hex: palette.isDark ? "#3B3F51" : "#C0C4CC") ?? textColor.withAlphaComponent(0.6)
            let headerColor = NSColor(hex: palette.isDark ? "#1F232B" : "#F2F3F5") ?? backgroundColor
            let accentColor = NSColor(hex: palette.accent) ?? .systemBlue
            let metaColor = NSColor(hex: palette.comment) ?? textColor.withAlphaComponent(0.6)

            context.setFillColor(backgroundColor.cgColor)
            context.fill(rect)

            let graphicsContext = NSGraphicsContext(cgContext: context, flipped: true)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = graphicsContext

            if showHeader {
                let headerRect = CGRect(x: 0, y: 0, width: rect.width, height: headerHeight)
                headerColor.setFill()
                headerRect.fill()

                let chipFont = NSFont.systemFont(ofSize: 9, weight: .semibold)
                let chipText = languageLabel.isEmpty ? "TEXT" : languageLabel.uppercased()
                let chipAttributes: [NSAttributedString.Key: Any] = [
                    .font: chipFont,
                    .foregroundColor: accentColor
                ]
                let chipSize = chipText.size(withAttributes: chipAttributes)
                let chipPaddingX: CGFloat = 6
                let chipPaddingY: CGFloat = 2
                let chipHeight = chipSize.height + chipPaddingY * 2
                let chipWidth = chipSize.width + chipPaddingX * 2
                let chipRect = CGRect(
                    x: padding,
                    y: (headerHeight - chipHeight) / 2,
                    width: chipWidth,
                    height: chipHeight
                )

                accentColor.withAlphaComponent(palette.isDark ? 0.25 : 0.2).setFill()
                NSBezierPath(roundedRect: chipRect, xRadius: chipHeight / 2, yRadius: chipHeight / 2).fill()
                chipText.draw(
                    at: CGPoint(x: chipRect.minX + chipPaddingX, y: chipRect.minY + chipPaddingY - 0.5),
                    withAttributes: chipAttributes
                )

                let sizeText = ByteCountFormatter.string(fromByteCount: Int64(fileSizeBytes), countStyle: .file)
                let lineText = snippet.isTruncated ? "\(snippet.lineCount)+ lines" : "\(snippet.lineCount) lines"
                let metaText = "\(lineText) - \(sizeText)"
                let metaAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 9),
                    .foregroundColor: metaColor
                ]
                let metaX = chipRect.maxX + 8
                metaText.draw(at: CGPoint(x: metaX, y: (headerHeight - 10) / 2), withAttributes: metaAttributes)
            }

            let contentTop = showHeader ? headerHeight + padding : padding
            let contentRect = CGRect(
                x: padding,
                y: contentTop,
                width: rect.width - padding * 2,
                height: rect.height - contentTop - padding
            )
            if contentRect.width > 0, contentRect.height > 0 {
                context.saveGState()
                context.clip(to: contentRect)

                let lineFont = NSFont.monospacedSystemFont(ofSize: max(9, min(fontSize, 12)), weight: .regular)
                let numberFont = NSFont.monospacedSystemFont(ofSize: max(8, min(fontSize - 1, 11)), weight: .regular)
                let lineHeight = lineFont.ascender - lineFont.descender + lineFont.leading

                let digitWidth = "0".size(withAttributes: [.font: numberFont]).width
                let lineDigits = max(2, String(snippet.lineCount).count)
                let gutterWidth = showLineNumbers ? max(24, digitWidth * CGFloat(lineDigits) + 6) : 0
                let textOriginX = contentRect.minX + gutterWidth

                for (index, line) in snippet.lines.enumerated() {
                    let lineY = contentRect.minY + CGFloat(index) * lineHeight
                    if lineY + lineHeight > contentRect.maxY { break }

                    if showLineNumbers {
                        let number = "\(index + 1)"
                        let numberAttributes: [NSAttributedString.Key: Any] = [
                            .font: numberFont,
                            .foregroundColor: gutterColor
                        ]
                        let numberX = contentRect.minX + gutterWidth - 4 - number.size(withAttributes: numberAttributes).width
                        number.draw(at: CGPoint(x: numberX, y: lineY), withAttributes: numberAttributes)
                    }

                    let textAttributes: [NSAttributedString.Key: Any] = [
                        .font: lineFont,
                        .foregroundColor: textColor
                    ]
                    line.draw(at: CGPoint(x: textOriginX, y: lineY), withAttributes: textAttributes)
                }

                context.restoreGState()
            }

            NSGraphicsContext.restoreGraphicsState()
            return true
        }

        if !badgeText.isEmpty {
            reply.extensionBadge = badgeText
        }
        return reply
    }

    private static func decodeString(data: Data, encoding: String.Encoding) -> String {
        if let decoded = String(data: data, encoding: encoding) {
            return decoded
        }
        return String(decoding: data, as: UTF8.self)
    }
}

private extension NSColor {
    convenience init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
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
