import Foundation

public struct FileInfo {
    public let text: String
    public let lineCount: Int
    public let fileSizeBytes: Int
    public let isTruncated: Bool
}

public enum FileInspector {
    public static func fileMetadata(for url: URL) -> (sizeBytes: Int, mtime: TimeInterval) {
        let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
        let mtime = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        return (fileSize, mtime)
    }

    public static func loadFile(url: URL, maxBytes: Int, encoding: String.Encoding) throws -> FileInfo {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? NSNumber
        let fileSizeBytes = fileSize?.intValue ?? 0

        let handle = try FileHandle(forReadingFrom: url)
        let data = handle.readData(ofLength: maxBytes)
        try? handle.close()

        let isTruncated = fileSizeBytes > maxBytes
        let text = decodeString(data: data, encoding: encoding)
        return fileInfo(from: text, fileSizeBytes: fileSizeBytes, isTruncated: isTruncated)
    }

    public static func fileInfo(from text: String, fileSizeBytes: Int, isTruncated: Bool) -> FileInfo {
        let lineCount = max(countLines(in: text), 1)
        return FileInfo(text: text, lineCount: lineCount, fileSizeBytes: fileSizeBytes, isTruncated: isTruncated)
    }

    private static func decodeString(data: Data, encoding: String.Encoding) -> String {
        if let decoded = String(data: data, encoding: encoding) {
            return decoded
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static func countLines(in text: String) -> Int {
        var count = 0
        for scalar in text.unicodeScalars where scalar == "\n" {
            count += 1
        }
        return text.isEmpty ? 0 : count + 1
    }
}
