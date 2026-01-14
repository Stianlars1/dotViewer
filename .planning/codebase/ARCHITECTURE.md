# Architecture

**Analysis Date:** 2026-01-14

## Pattern Overview

**Overall:** Native macOS Application with Shared Framework Model

**Key Characteristics:**
- Two-target architecture (Main app + Quick Look extension)
- Shared framework for cross-process code reuse
- App Groups for inter-process communication
- Singleton pattern for shared state managers

## Layers

**Presentation Layer (UI):**
- Purpose: User-facing views and interactions
- Contains: SwiftUI views, view controllers
- Location: `dotViewer/` (app views), `QuickLookPreview/` (extension views)
- Depends on: Service layer for business logic
- Used by: SwiftUI runtime, Quick Look framework

**Service/Business Logic Layer:**
- Purpose: Core functionality and state management
- Contains: FileTypeRegistry, LanguageDetector, SyntaxHighlighter, ThemeManager
- Location: `Shared/*.swift`
- Depends on: Data layer, HighlightSwift library
- Used by: Presentation layer

**Data/Settings Layer:**
- Purpose: Persistence and configuration
- Contains: SharedSettings, FileTypeModel, HighlightCache
- Location: `Shared/SharedSettings.swift`, `Shared/FileTypeModel.swift`
- Depends on: UserDefaults, App Groups
- Used by: Service layer, Presentation layer

**Infrastructure Layer:**
- Purpose: Cross-cutting concerns
- Contains: Logger, TimingScope
- Location: `Shared/Logger.swift`
- Depends on: Apple os.log framework
- Used by: All layers

## Data Flow

**Quick Look Preview Flow:**

1. User presses Space on file in Finder → macOS invokes Quick Look
2. `PreviewViewController.preparePreviewOfFile()` called with file URL
3. File validation: binary check, encoding detection, size/line limits
4. Language detection via `LanguageDetector.detect(for:)`:
   - Extension lookup via `FileTypeRegistry` (O(1))
   - Shebang detection for scripts
   - Content-based detection (JSON/YAML/XML patterns)
5. Cache check via `HighlightCache.shared`
6. Syntax highlighting via `SyntaxHighlighter.highlight()` (2s timeout)
7. Create `PreviewState` and render `PreviewContentView`
8. Return completed SwiftUI view to Quick Look framework

**Settings Sync Flow:**

1. User changes setting in main app UI
2. `SharedSettings.shared` persists to App Group container (thread-safe)
3. Quick Look extension reads from same container on next preview
4. Changes apply to subsequent previews

**State Management:**
- File-based: Settings in UserDefaults via App Groups
- In-memory: HighlightCache LRU cache, theme state
- No database or persistent in-memory state across launches

## Key Abstractions

**Singleton Managers:**
- `FileTypeRegistry.shared` - Central file type registry with O(1) lookups
- `SharedSettings.shared` - Thread-safe App Group settings
- `ThemeManager.shared` - Theme state and color resolution
- `HighlightCache.shared` - LRU cache for highlighted content
- `ExtensionStatusChecker.shared` - Extension availability detection

**Observable State (SwiftUI):**
- `ThemeManager: ObservableObject` - Theme changes notify UI
- `ExtensionStatusChecker: ObservableObject` - Status updates notify views

**Thread Safety Patterns:**
- `@unchecked Sendable` on singletons for concurrent access
- `NSLock` for SharedSettings property access
- `LockedValue<T>` wrapper for one-time continuation resumption

**Enum-based State:**
- `NavigationItem` - App navigation (Status, File Types, Settings)
- `MarkdownBlockType` - Markdown rendering blocks
- `FileTypeCategory` - File type organization

## Entry Points

**Main App:**
- Location: `dotViewer/dotViewerApp.swift`
- Triggers: User launches app
- Responsibilities: Create window, initialize ContentView

**Quick Look Extension:**
- Location: `QuickLookPreview/PreviewViewController.swift`
- Triggers: User presses Space on supported file in Finder
- Responsibilities: Validate file, detect language, highlight code, render preview

**Root Views:**
- `dotViewer/ContentView.swift` - Navigation hub (Status, File Types, Settings)
- `QuickLookPreview/PreviewContentView.swift` - File preview rendering

## Error Handling

**Strategy:** Graceful degradation with logging

**Patterns:**
- Try/catch at service boundaries with os.log error logging
- Timeout protection for syntax highlighting (2 second limit)
- Fallback to plain text if highlighting fails
- Silent recovery for App Group failures with warning logs

## Cross-Cutting Concerns

**Logging:**
- Apple os.log unified logging (`Shared/Logger.swift`)
- Subsystem: `com.stianlars1.dotViewer`
- Categories: Preview, Settings, App, Cache
- TimingScope for performance measurement

**Validation:**
- File type validation via FileTypeRegistry
- Extension name validation in CustomExtension
- Font size clamping (8-72pt range)
- File size limits (10KB-50MB configurable)

**Security:**
- Sensitive file detection (`.env`, credentials)
- Security warning banner for sensitive files
- App sandbox with read-only file access

**Theme Management:**
- ThemeManager as single source of truth
- Auto/Light/Dark theme detection
- 10 syntax highlighting themes via HighlightSwift

---

*Architecture analysis: 2026-01-14*
*Update when major patterns change*
