# Changelog

All notable changes to dotViewer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Constants.swift** - Centralized configuration constants replacing magic numbers
- **Path validation** - Defense-in-depth cache key validation
- **Rate limiting** - Cache cleanup now rate-limited to prevent excessive disk I/O
- **Expanded sensitive file detection** - Now detects AWS credentials, SSH keys, certificates, and more file types

### Changed
- **Cache cleanup** - No longer holds lock during I/O operations (improved UI responsiveness)
- **Thread safety** - ThemeManager access now properly captured on main thread
- **JSON detection** - Stricter heuristics to avoid false positives
- **String encoding** - Improved fallback chain with proper logging
- **Lock patterns** - Regex cache lock now uses `withLock { }` for safer resource management

### Fixed
- **Silent error suppression** - Cache operations now log errors instead of silently failing
- **Input validation** - Custom extensions now validated for path traversal, reserved names, and invalid characters
- **Error handling** - Standardized error handling patterns across cache operations

### Documentation
- **@unchecked Sendable** - Added thread safety justifications to DiskCache, SharedSettings, HighlightCache, FileTypeRegistry
- **Force-unwrap regex** - Documented safety rationale for static regex pattern compilation
- **Deprecated APIs** - Added migration documentation for legacy cache methods
- **hostingView** - Documented main-thread access pattern

### Security
- Added validation for custom file extensions (rejects path traversal, reserved extensions)
- Added cache key validation (defense in depth)
- Expanded sensitive file detection patterns

## [1.0.0] - 2025-01-XX

### Added
- Initial release
- Syntax highlighting for 100+ file types
- 10 built-in themes with auto light/dark mode
- Markdown rendering with raw/rendered toggle
- Two-tier caching (memory + disk)
- Custom extension support
- Configurable preview settings
