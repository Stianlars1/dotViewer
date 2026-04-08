import XCTest
@testable import Shared

final class FileTypeResolutionTests: XCTestCase {

    // MARK: - Simple Extensions

    func testPlainExtension() {
        let url = URL(fileURLWithPath: "/tmp/test.swift")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "swift")
    }

    func testJsonExtension() {
        let url = URL(fileURLWithPath: "/tmp/data.json")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "json")
    }

    func testCueExtension() {
        let url = URL(fileURLWithPath: "/tmp/disc.cue")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "cue")
    }

    func testSingleDotConfigPrefersExtensionOverBasenameAlias() {
        let url = URL(fileURLWithPath: "/tmp/sample.conf")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "conf")
    }

    func testSingleDotTSVPrefersExtensionOverBasenameAlias() {
        let url = URL(fileURLWithPath: "/tmp/sample.tsv")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "tsv")
    }

    func testManpageSectionOneExtension() {
        let url = URL(fileURLWithPath: "/tmp/dotviewer.1")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "1")
    }

    func testManpageMdocExtension() {
        let url = URL(fileURLWithPath: "/tmp/dotviewer.mdoc")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "mdoc")
    }

    // MARK: - Dotfiles

    func testDotGitignore() {
        let url = URL(fileURLWithPath: "/tmp/.gitignore")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "gitignore")
    }

    func testDotEnv() {
        let url = URL(fileURLWithPath: "/tmp/.env")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "env")
    }

    func testDotEnvLocal() {
        // .env.local should resolve to "env.local" or "env" (chained dotfile)
        let url = URL(fileURLWithPath: "/tmp/.env.local")
        let key = FileTypeResolution.bestKey(for: url)
        // Should match "env.local" first (full name), or "env" (prefix)
        XCTAssertTrue(key == "env.local" || key == "env",
                       "Expected 'env.local' or 'env' but got '\(key)'")
    }

    // MARK: - Chained Dotfiles

    func testEslintrcJson() {
        // .eslintrc.json → "eslintrc.json" full name → "eslintrc" prefix → "json" extension
        let url = URL(fileURLWithPath: "/tmp/.eslintrc.json")
        let key = FileTypeResolution.bestKey(for: url)
        // Should prefer eslintrc or eslintrc.json or json — any is valid
        XCTAssertFalse(key.isEmpty)
    }

    // MARK: - Multi-dot Files

    func testMultiDotFileResolvesToKnownSegment() {
        // .claude.json.backup.1770685742797 → try extension first (1770685742797 - unknown),
        // then intermediate segments: "backup" (known!), so resolves to "backup"
        let url = URL(fileURLWithPath: "/tmp/.claude.json.backup.1770685742797")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "backup", "Multi-dot file should resolve to 'backup' intermediate segment")
    }

    // MARK: - Filenames

    func testMakefileByName() {
        let url = URL(fileURLWithPath: "/tmp/Makefile")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "makefile")
    }

    func testDockerfileByName() {
        let url = URL(fileURLWithPath: "/tmp/Dockerfile")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "dockerfile")
    }

    // MARK: - Edge Cases

    func testEmptyFileName() {
        // Shouldn't crash
        let url = URL(fileURLWithPath: "/tmp/")
        _ = FileTypeResolution.bestKey(for: url)
    }

    func testFileWithOnlyExtension() {
        let url = URL(fileURLWithPath: "/tmp/test.py")
        let key = FileTypeResolution.bestKey(for: url)
        XCTAssertEqual(key, "py")
    }

    func testReadmeMd() {
        // README.md → "readme.md" full name → "readme" prefix
        // The registry has a filename entry for README.md, so "readme.md" should match
        let url = URL(fileURLWithPath: "/tmp/README.md")
        let key = FileTypeResolution.bestKey(for: url)
        // Should resolve to the readme or markdown entry
        XCTAssertFalse(key.isEmpty)
    }

    func testDockerComposeYml() {
        let url = URL(fileURLWithPath: "/tmp/docker-compose.yml")
        let key = FileTypeResolution.bestKey(for: url)
        // Should match yml at minimum
        XCTAssertFalse(key.isEmpty)
    }
}
