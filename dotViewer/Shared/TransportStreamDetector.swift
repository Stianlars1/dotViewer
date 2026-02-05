import Foundation
import UniformTypeIdentifiers

public enum TransportStreamDetector {
    private static let transportStreamIdentifier = "public.mpeg-2-transport-stream"

    public static func isTransportStreamCandidate(url: URL, mimeType: String?) -> Bool {
        let loweredMime = mimeType?.lowercased() ?? ""
        if loweredMime.hasPrefix("video/") {
            return true
        }
        if loweredMime == "application/mp2t" || loweredMime == "video/mp2t" {
            return true
        }

        guard let transportType = UTType(transportStreamIdentifier) else {
            return false
        }

        if let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            if contentType == transportType || contentType.conforms(to: transportType) {
                return true
            }
        }

        if let extType = UTType(filenameExtension: url.pathExtension) {
            if extType == transportType || extType.conforms(to: transportType) {
                return true
            }
        }

        return false
    }

    public static func matchesTransportStreamSyncPattern(url: URL, maxBytes: Int = 188 * 4) -> Bool {
        guard maxBytes > 0,
              let handle = try? FileHandle(forReadingFrom: url)
        else {
            return false
        }

        let data = handle.readData(ofLength: maxBytes)
        try? handle.close()
        return matchesTransportStreamSyncPattern(data: data)
    }

    public static func matchesTransportStreamSyncPattern(data: Data) -> Bool {
        let packetSize = 188
        let minPackets = 3
        guard data.count >= packetSize * minPackets else {
            return false
        }

        for index in 0..<minPackets {
            let offset = index * packetSize
            if data[offset] != 0x47 {
                return false
            }
        }
        return true
    }
}
