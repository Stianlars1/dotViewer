import Foundation
import UniformTypeIdentifiers

public struct FileAttributes {
    public let mimeType: String
    public let stringEncoding: String.Encoding
    public let isTextual: Bool
    public let looksTextual: Bool

    public static func attributes(for url: URL) -> FileAttributes? {
        if url.lastPathComponent == ".DS_Store" {
            return nil
        }

        let sample = fileSample(for: url)
        let looksText = looksTextual(sample: sample)

        let magic = magicString(for: url, locale: "en_US.UTF-8")
            ?? magicString(for: url, locale: "C")
        guard let magic else {
            return attributesFromUTType(url: url, sample: sample, looksTextual: looksText)
        }

        let regex = try? NSRegularExpression(pattern: "(\\S+/\\S+); charset=(\\S+)", options: [])
        guard let match = regex?.firstMatch(in: magic, options: [], range: NSRange(magic.startIndex..., in: magic)),
              let mimeRange = Range(match.range(at: 1), in: magic),
              let charsetRange = Range(match.range(at: 2), in: magic)
        else {
            return attributesFromUTType(url: url, sample: sample, looksTextual: looksText)
        }

        let mimeType = String(magic[mimeRange])
        let charset = String(magic[charsetRange])
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        let stringEncoding = String.Encoding(rawValue: nsEncoding)
        let bomEncoding = encodingFromBOM(sample: sample)
        let resolvedEncoding: String.Encoding
        if cfEncoding == kCFStringEncodingInvalidId {
            resolvedEncoding = bomEncoding ?? .utf8
        } else {
            resolvedEncoding = stringEncoding
        }

        return FileAttributes(
            mimeType: mimeType,
            stringEncoding: resolvedEncoding,
            isTextual: isTextualMime(mimeType),
            looksTextual: looksText
        )
    }

    private static func attributesFromUTType(url: URL, sample: Data, looksTextual: Bool) -> FileAttributes? {
        let ext = url.pathExtension
        let type = UTType(filenameExtension: ext)
        let isText = type?.conforms(to: .text) == true || type?.conforms(to: .sourceCode) == true
        let mimeType = type?.preferredMIMEType ?? (looksTextual ? "text/plain" : "application/octet-stream")
        return FileAttributes(
            mimeType: mimeType,
            stringEncoding: encodingFromBOM(sample: sample) ?? .utf8,
            isTextual: isText,
            looksTextual: looksTextual
        )
    }

    private static func isTextualMime(_ mimeType: String) -> Bool {
        if mimeType.hasPrefix("text/") {
            return true
        }
        if let type = UTType(mimeType: mimeType) {
            return type.conforms(to: .text)
        }
        return false
    }

    private static func magicString(for url: URL, locale: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/file")
        process.arguments = ["--mime", "--brief", url.path]

        var environment = ProcessInfo.processInfo.environment
        environment["LC_ALL"] = locale
        process.environment = environment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0,
              let output = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func fileSample(for url: URL, maxBytes: Int = 8 * 1024) -> Data {
        guard maxBytes > 0,
              let handle = try? FileHandle(forReadingFrom: url)
        else {
            return Data()
        }
        let data = handle.readData(ofLength: maxBytes)
        try? handle.close()
        return data
    }

    private static func looksTextual(sample: Data) -> Bool {
        guard !sample.isEmpty else { return true }

        var controlCount = 0
        for byte in sample {
            if byte == 0 { return false }
            if byte == 0x7F { controlCount += 1; continue }

            if byte < 0x20 {
                switch byte {
                case 0x09, 0x0A, 0x0D, 0x0C: // tab, LF, CR, FF
                    continue
                default:
                    controlCount += 1
                }
            }
        }

        // If a large portion of the sample is control chars, assume binary.
        let ratio = Double(controlCount) / Double(sample.count)
        return ratio < 0.05
    }

    private static func encodingFromBOM(sample: Data) -> String.Encoding? {
        if sample.count >= 3,
           sample[0] == 0xEF,
           sample[1] == 0xBB,
           sample[2] == 0xBF {
            return .utf8
        }
        if sample.count >= 2,
           sample[0] == 0xFF,
           sample[1] == 0xFE {
            return .utf16LittleEndian
        }
        if sample.count >= 2,
           sample[0] == 0xFE,
           sample[1] == 0xFF {
            return .utf16BigEndian
        }
        return nil
    }
}
