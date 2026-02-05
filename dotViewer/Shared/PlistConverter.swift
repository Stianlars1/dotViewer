import Foundation
import UniformTypeIdentifiers

public enum PlistConverter {
    private static let binaryMagic = Data([0x62, 0x70, 0x6c, 0x69, 0x73, 0x74, 0x30, 0x30]) // bplist00
    private static let plistIdentifier = "com.apple.property-list"

    public static func isPropertyList(url: URL) -> Bool {
        if url.pathExtension.lowercased() == "plist" {
            return true
        }
        guard let plistType = UTType(plistIdentifier) else {
            return false
        }
        if let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            if contentType == plistType || contentType.conforms(to: plistType) {
                return true
            }
        }
        if let extType = UTType(filenameExtension: url.pathExtension) {
            if extType == plistType || extType.conforms(to: plistType) {
                return true
            }
        }
        return false
    }

    public static func isBinaryPlist(url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        let data = handle.readData(ofLength: binaryMagic.count)
        try? handle.close()
        return data == binaryMagic
    }

    public static func convertBinaryPlistToXML(at url: URL, maxBytes: Int) -> (text: String, isTruncated: Bool)? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/plutil")
        process.arguments = ["-convert", "xml1", "-o", "-", "--", url.path]

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }

        var outputData = data
        var truncated = false
        if maxBytes > 0, data.count > maxBytes {
            outputData = data.subdata(in: 0..<maxBytes)
            truncated = true
        }

        let text = String(data: outputData, encoding: .utf8) ?? String(decoding: outputData, as: UTF8.self)
        return (text: text, isTruncated: truncated)
    }
}
