import Foundation

public struct LanguageDetector {
    private let registry: FileTypeRegistry

    public init(registry: FileTypeRegistry = .shared) {
        self.registry = registry
    }

    public func detectLanguage(for url: URL) -> String? {
        let key = FileTypeResolution.bestKey(for: url, registry: registry)
        return registry.highlightLanguage(for: key)
    }
}
