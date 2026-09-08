import Foundation

public struct ResolvedFileLanguage: Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let isCustomMapping: Bool

    public init(id: String, displayName: String, isCustomMapping: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.isCustomMapping = isCustomMapping
    }
}

/// Resolves language and label together so previews and thumbnails agree.
public enum FileLanguageResolver {
    public static func resolve(
        url: URL,
        key: String,
        sample: String? = nil,
        customMappings: [CustomExtension]? = nil
    ) -> ResolvedFileLanguage {
        let registry = FileTypeRegistry.shared
        let mappings = customMappings ?? SharedSettings.shared.customExtensions
        let filename = url.lastPathComponent.lowercased()
        if let custom = mappings.first(where: { $0.filenameMatch?.lowercased() == filename })
            ?? mappings.first(where: { !$0.isFilenameMapping && $0.extensionName == key.lowercased() }) {
            return ResolvedFileLanguage(id: custom.highlightLanguage, displayName: custom.displayName, isCustomMapping: true)
        }
        let type = registry.fileType(for: key)
        if type?.id == "gdscript", GAPSourceDetector.matches(sample ?? readSample(url)) {
            return ResolvedFileLanguage(id: "gap", displayName: "GAP")
        }
        return ResolvedFileLanguage(id: type?.highlightLanguage ?? "plaintext", displayName: type?.displayName ?? (key.isEmpty ? "Text" : key.uppercased()))
    }
    private static func readSample(_ url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return "" }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 32_768) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

}
