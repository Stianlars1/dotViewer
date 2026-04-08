import Foundation
import AppKit
import QuickLookThumbnailing
import Shared

struct TextThumbnailSnippet {
    let lines: [String]
    let isTruncated: Bool
    let lineCount: Int
}

struct ColoredToken {
    let text: String
    let color: NSColor
    let isBold: Bool
    let isItalic: Bool

    init(text: String, color: NSColor, isBold: Bool = false, isItalic: Bool = false) {
        self.text = text
        self.color = color
        self.isBold = isBold
        self.isItalic = isItalic
    }
}

enum ThumbnailSyntaxColorizer {
    private static let keywords: Set<String> = [
        "func", "def", "class", "import", "return", "if", "else", "for",
        "while", "let", "var", "const", "function", "public", "private",
        "static", "struct", "enum", "switch", "case", "guard", "throw",
        "try", "catch", "async", "await", "override", "final", "protocol",
        "extension", "self", "super", "nil", "true", "false", "in", "do",
        "break", "continue", "where", "as", "is", "new", "void", "int",
        "float", "double", "bool", "string", "from", "export", "default",
        "interface", "type", "namespace", "module", "package", "abstract",
        "implements", "extends", "throws", "yield", "lambda", "elif",
        "except", "finally", "raise", "with", "pass", "del", "not",
        "and", "or", "fn", "mut", "pub", "use", "mod", "crate", "impl",
        "trait", "match", "ref", "move", "unsafe", "extern", "dyn",
        "go", "chan", "defer", "select", "range", "map", "make",
        "val", "fun", "object", "sealed", "data", "when",
        "then", "end", "begin", "elsif", "unless", "until", "puts",
        "print", "println", "echo", "require", "include"
    ]

    static func colorize(line: String, palette: ThemePalette) -> [ColoredToken] {
        let commentColor = NSColor(hex: palette.comment) ?? .gray
        let stringColor = NSColor(hex: palette.string) ?? .green
        let keywordColor = NSColor(hex: palette.keyword) ?? .purple
        let numberColor = NSColor(hex: palette.number) ?? .orange
        let typeColor = NSColor(hex: palette.type) ?? .yellow
        let textColor = NSColor(hex: palette.text) ?? .labelColor

        let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })

        // Whole-line comment detection
        if trimmed.hasPrefix("//") || trimmed.hasPrefix("#") ||
           trimmed.hasPrefix("--") || trimmed.hasPrefix("%") ||
           trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") ||
           trimmed.hasPrefix(";") || trimmed.hasPrefix("rem ") ||
           trimmed.hasPrefix("REM ") {
            return [ColoredToken(text: line, color: commentColor, isItalic: true)]
        }

        var tokens: [ColoredToken] = []
        let chars = Array(line.unicodeScalars)
        let count = chars.count
        var i = 0

        while i < count {
            let ch = chars[i]

            // Strings: "..." or '...' or `...`
            if ch == "\"" || ch == "'" || ch == "`" {
                let quote = ch
                var end = i + 1
                while end < count {
                    if chars[end] == "\\" {
                        end += 2
                        continue
                    }
                    if chars[end] == quote {
                        end += 1
                        break
                    }
                    end += 1
                }
                let start = line.index(line.startIndex, offsetBy: i)
                let finish = line.index(line.startIndex, offsetBy: min(end, count))
                tokens.append(ColoredToken(text: String(line[start..<finish]), color: stringColor))
                i = min(end, count)
                continue
            }

            // Inline comment: //
            if ch == "/" && i + 1 < count && chars[i + 1] == "/" {
                let start = line.index(line.startIndex, offsetBy: i)
                tokens.append(ColoredToken(text: String(line[start...]), color: commentColor, isItalic: true))
                i = count
                continue
            }

            // Words: identifiers, keywords, types, numbers
            if ch.properties.isAlphabetic || ch == "_" {
                var end = i + 1
                while end < count && (chars[end].properties.isAlphabetic || chars[end] == "_" || chars[end].properties.numericType != nil) {
                    end += 1
                }
                let start = line.index(line.startIndex, offsetBy: i)
                let finish = line.index(line.startIndex, offsetBy: end)
                let word = String(line[start..<finish])

                if keywords.contains(word) {
                    tokens.append(ColoredToken(text: word, color: keywordColor, isBold: true))
                } else if word.first?.isUppercase == true && word.count > 1 && word.dropFirst().contains(where: { $0.isLowercase }) {
                    tokens.append(ColoredToken(text: word, color: typeColor, isBold: true))
                } else {
                    tokens.append(ColoredToken(text: word, color: textColor))
                }
                i = end
                continue
            }

            // Numbers
            if ch.properties.numericType != nil || (ch == "." && i + 1 < count && chars[i + 1].properties.numericType != nil) {
                var end = i + 1
                while end < count && (chars[end].properties.numericType != nil || chars[end] == "." || chars[end] == "x" || chars[end] == "X" ||
                                      (chars[end] >= "a" && chars[end] <= "f") || (chars[end] >= "A" && chars[end] <= "F") || chars[end] == "_") {
                    end += 1
                }
                let start = line.index(line.startIndex, offsetBy: i)
                let finish = line.index(line.startIndex, offsetBy: end)
                tokens.append(ColoredToken(text: String(line[start..<finish]), color: numberColor))
                i = end
                continue
            }

            // Default: punctuation, whitespace, operators
            var end = i + 1
            while end < count {
                let next = chars[end]
                if next.properties.isAlphabetic || next == "_" || next == "\"" || next == "'" || next == "`" ||
                   next.properties.numericType != nil || (next == "/" && end + 1 < count && chars[end + 1] == "/") {
                    break
                }
                end += 1
            }
            let start = line.index(line.startIndex, offsetBy: i)
            let finish = line.index(line.startIndex, offsetBy: end)
            tokens.append(ColoredToken(text: String(line[start..<finish]), color: textColor))
            i = end
        }

        if tokens.isEmpty {
            return [ColoredToken(text: line, color: textColor)]
        }
        return tokens
    }
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
        let rawLines = TextLineUtilities.lines(forDisplayFrom: text)
        let truncatedByLines = rawLines.count > maxLines
        let limitedLines = Array(rawLines.prefix(maxLines))
        let isTruncated = truncatedByLines || truncatedByBytes

        var lines = limitedLines
        if isTruncated, let last = lines.indices.last {
            lines[last] = lines[last] + " ..."
        }

        return TextThumbnailSnippet(lines: lines, isTruncated: isTruncated, lineCount: rawLines.count)
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
        fontSize: CGFloat,
        treeSitterTokens: [HighlightToken]? = nil
    ) -> QLThumbnailReply {
        // Pre-convert tree-sitter tokens to per-line colored tokens
        let perLineTokens: [[ColoredToken]]?
        if let treeSitterTokens, !treeSitterTokens.isEmpty {
            perLineTokens = TreeSitterTokenConverter.convert(
                tokens: treeSitterTokens,
                lines: snippet.lines,
                palette: palette
            )
        } else {
            perLineTokens = nil
        }

        let image = NSImage(size: size, flipped: true) { rect in
            let headerHeight: CGFloat = showHeader ? 20 : 0
            let padding: CGFloat = 8
            let cornerRadius: CGFloat = 4

            let backgroundColor = NSColor(hex: palette.background) ?? .windowBackgroundColor
            let textColor = NSColor(hex: palette.text) ?? .labelColor
            let gutterColor = NSColor(hex: palette.isDark ? "#3B3F51" : "#C0C4CC") ?? textColor.withAlphaComponent(0.6)
            let headerColor = NSColor(hex: palette.isDark ? "#1F232B" : "#F2F3F5") ?? backgroundColor
            let accentColor = NSColor(hex: palette.accent) ?? .systemBlue
            let metaColor = NSColor(hex: palette.comment) ?? textColor.withAlphaComponent(0.6)
            let borderColor = (NSColor(hex: palette.comment) ?? textColor).withAlphaComponent(0.15)

            let clipPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
            clipPath.addClip()

            backgroundColor.setFill()
            rect.fill()

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
                NSGraphicsContext.current?.cgContext.saveGState()
                NSGraphicsContext.current?.cgContext.clip(to: contentRect)

                let codeFontSize = max(9, min(fontSize, 12))
                let lineFont = NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .regular)
                let lineFontBold = NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .bold)
                let lineFontItalic: NSFont = {
                    let desc = lineFont.fontDescriptor.withSymbolicTraits(.italic)
                    return NSFont(descriptor: desc, size: codeFontSize) ?? lineFont
                }()
                let lineFontBoldItalic: NSFont = {
                    let desc = lineFontBold.fontDescriptor.withSymbolicTraits(.italic)
                    return NSFont(descriptor: desc, size: codeFontSize) ?? lineFontBold
                }()
                let numberFont = NSFont.monospacedSystemFont(ofSize: max(8, min(fontSize - 1, 11)), weight: .regular)
                let singleLineHeight = lineFont.ascender - lineFont.descender + lineFont.leading

                let digitWidth = "0".size(withAttributes: [.font: numberFont]).width
                let lineDigits = max(2, String(snippet.lineCount).count)
                let gutterWidth = showLineNumbers ? max(24, digitWidth * CGFloat(lineDigits) + 6) : 0
                let textOriginX = contentRect.minX + gutterWidth
                let textAvailableWidth = contentRect.width - gutterWidth

                let fontForToken: (ColoredToken) -> NSFont = { token in
                    switch (token.isBold, token.isItalic) {
                    case (true, true):   return lineFontBoldItalic
                    case (true, false):  return lineFontBold
                    case (false, true):  return lineFontItalic
                    case (false, false): return lineFont
                    }
                }

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping

                var currentY = contentRect.minY

                for (index, line) in snippet.lines.enumerated() {
                    if currentY >= contentRect.maxY { break }

                    let displayLine = line.isEmpty ? " " : line

                    // Measure line height using full text for accurate word-wrap sizing
                    let measureAttributes: [NSAttributedString.Key: Any] = [
                        .font: lineFont,
                        .foregroundColor: textColor,
                        .paragraphStyle: paragraphStyle
                    ]
                    let measureString = NSAttributedString(string: displayLine, attributes: measureAttributes)
                    let textBoundingSize = CGSize(width: max(1, textAvailableWidth), height: contentRect.maxY - currentY)
                    let textBounds = measureString.boundingRect(
                        with: textBoundingSize,
                        options: [.usesLineFragmentOrigin, .usesFontLeading]
                    )
                    let lineWraps = ceil(textBounds.height) > singleLineHeight * 1.5
                    let drawnHeight = max(singleLineHeight, ceil(textBounds.height))

                    if showLineNumbers {
                        let number = "\(index + 1)"
                        let numberAttributes: [NSAttributedString.Key: Any] = [
                            .font: numberFont,
                            .foregroundColor: gutterColor
                        ]
                        let numberX = contentRect.minX + gutterWidth - 4 - number.size(withAttributes: numberAttributes).width
                        number.draw(at: CGPoint(x: numberX, y: currentY), withAttributes: numberAttributes)
                    }

                    // Use tree-sitter tokens when available, fall back to heuristic colorizer
                    let tokens = perLineTokens?[index] ?? ThumbnailSyntaxColorizer.colorize(line: displayLine, palette: palette)

                    if lineWraps {
                        let attributed = NSMutableAttributedString()
                        for token in tokens {
                            let attrs: [NSAttributedString.Key: Any] = [
                                .font: fontForToken(token),
                                .foregroundColor: token.color,
                                .paragraphStyle: paragraphStyle
                            ]
                            attributed.append(NSAttributedString(string: token.text, attributes: attrs))
                        }
                        let drawRect = CGRect(
                            x: textOriginX,
                            y: currentY,
                            width: textAvailableWidth,
                            height: contentRect.maxY - currentY
                        )
                        attributed.draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
                    } else {
                        var tokenX = textOriginX
                        for token in tokens {
                            let tokenAttrs: [NSAttributedString.Key: Any] = [
                                .font: fontForToken(token),
                                .foregroundColor: token.color
                            ]
                            let tokenStr = NSAttributedString(string: token.text, attributes: tokenAttrs)
                            let tokenWidth = tokenStr.size().width
                            if tokenX + tokenWidth > textOriginX + textAvailableWidth { break }
                            tokenStr.draw(at: CGPoint(x: tokenX, y: currentY))
                            tokenX += tokenWidth
                        }
                    }

                    currentY += drawnHeight
                }

                NSGraphicsContext.current?.cgContext.restoreGState()
            }

            borderColor.setStroke()
            let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: cornerRadius, yRadius: cornerRadius)
            borderPath.lineWidth = 1
            borderPath.stroke()

            return true
        }

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            // Fallback to contextSize if PNG conversion fails
            return QLThumbnailReply(contextSize: size) { _ in true }
        }

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        do {
            try pngData.write(to: tempURL)
        } catch {
            return QLThumbnailReply(contextSize: size) { _ in true }
        }

        let reply = QLThumbnailReply(imageFileURL: tempURL)
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

struct TokenStyle {
    let color: NSColor
    let isBold: Bool
    let isItalic: Bool
}

enum TokenColorMapper {
    static func color(for tokenClass: String, palette: ThemePalette) -> NSColor {
        return style(for: tokenClass, palette: palette).color
    }

    /// Bold/italic style per token type (thumbnail-specific — CSS handles this separately in previews).
    private static func styleFlags(for token: TokenType) -> (isBold: Bool, isItalic: Bool) {
        switch token {
        case .comment:     return (false, true)
        case .keyword:     return (true,  false)
        case .string:      return (false, false)
        case .number:      return (false, false)
        case .type:        return (true,  false)
        case .function:    return (false, false)
        case .property:    return (false, false)
        case .constant:    return (false, false)
        case .identifier:  return (false, false)
        case .punctuation: return (false, false)
        case .tag:         return (true,  false)
        case .attribute:   return (false, true)
        case .escape:      return (false, false)
        case .builtin:     return (false, true)
        case .namespace:   return (false, false)
        case .parameter:   return (false, false)
        }
    }

    static func style(for tokenClass: String, palette: ThemePalette) -> TokenStyle {
        if let token = TokenType(rawValue: tokenClass) {
            let flags = styleFlags(for: token)
            return TokenStyle(
                color: NSColor(hex: palette.hex(for: token)) ?? .labelColor,
                isBold: flags.isBold,
                isItalic: flags.isItalic
            )
        }
        return TokenStyle(
            color: NSColor(hex: palette.text) ?? .labelColor,
            isBold: false,
            isItalic: false
        )
    }
}

enum TreeSitterTokenConverter {
    /// Converts byte-offset tokens into per-line `[ColoredToken]` arrays.
    /// Each line in `lines` gets its own array of colored tokens, covering every character.
    static func convert(
        tokens: [HighlightToken],
        lines: [String],
        palette: ThemePalette
    ) -> [[ColoredToken]] {
        let textColor = NSColor(hex: palette.text) ?? .labelColor

        // Build a byte offset map: lineStartOffsets[i] = byte offset of the start of lines[i]
        var lineStartOffsets: [Int] = []
        var offset = 0
        for line in lines {
            lineStartOffsets.append(offset)
            offset += line.utf8.count + 1 // +1 for the "\n" that joined them
        }

        var result: [[ColoredToken]] = Array(repeating: [], count: lines.count)

        for lineIndex in lines.indices {
            let lineStart = lineStartOffsets[lineIndex]
            let lineBytes = lines[lineIndex].utf8.count
            let lineEnd = lineStart + lineBytes
            let lineData = Array(lines[lineIndex].utf8)

            // Collect tokens that overlap this line
            var lineTokens: [(start: Int, end: Int, style: TokenStyle)] = []
            for token in tokens {
                if token.e <= lineStart { continue }
                if token.s >= lineEnd { break }
                // Clamp to line bounds
                let s = max(token.s - lineStart, 0)
                let e = min(token.e - lineStart, lineBytes)
                if s < e {
                    lineTokens.append((s, e, TokenColorMapper.style(for: token.c, palette: palette)))
                }
            }

            if lineTokens.isEmpty {
                result[lineIndex] = [ColoredToken(text: lines[lineIndex], color: textColor)]
                continue
            }

            var colored: [ColoredToken] = []
            var pos = 0
            for lt in lineTokens {
                if lt.start > pos {
                    let text = String(decoding: lineData[pos..<lt.start], as: UTF8.self)
                    colored.append(ColoredToken(text: text, color: textColor))
                }
                if lt.start < lt.end {
                    let text = String(decoding: lineData[lt.start..<lt.end], as: UTF8.self)
                    colored.append(ColoredToken(text: text, color: lt.style.color, isBold: lt.style.isBold, isItalic: lt.style.isItalic))
                }
                pos = lt.end
            }
            if pos < lineBytes {
                let text = String(decoding: lineData[pos..<lineBytes], as: UTF8.self)
                colored.append(ColoredToken(text: text, color: textColor))
            }
            result[lineIndex] = colored.isEmpty ? [ColoredToken(text: lines[lineIndex], color: textColor)] : colored
        }

        return result
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
