# Coding Conventions

**Analysis Date:** 2026-01-14

## Naming Patterns

**Files:**
- PascalCase for all Swift files matching primary type: `FileTypeRegistry.swift`
- Descriptive suffixes: `*View.swift` (UI), `*Manager.swift` (state), `*Detector.swift` (analysis)
- Examples: `ContentView.swift`, `ThemeManager.swift`, `LanguageDetector.swift`

**Functions:**
- camelCase for all functions: `getHighlightLanguage()`, `detectFromContent()`
- Action-based naming: `toggleType()`, `uninstallApp()`, `openExtensionSettings()`
- Async functions: `highlight(code:language:) async throws`

**Variables:**
- camelCase for variables: `maxEntries`, `suiteName`
- Private state: `@State private var selectedItem`
- Published properties: `@Published var selectedTheme`
- Constants: lowercase camelCase (not UPPER_SNAKE_CASE)

**Types:**
- PascalCase for all types: `FileTypeRegistry`, `SharedSettings`
- No I prefix for protocols: `Codable`, `Identifiable`
- Enums: PascalCase name, camelCase values: `FileTypeCategory.webDevelopment`

## Code Style

**Formatting:**
- 4-space indentation (Xcode default)
- No external formatter configured (relies on Xcode)
- Clean spacing with proper blank lines between sections

**Linting:**
- No SwiftLint or other linter configured
- Relies on Swift compiler warnings and Xcode diagnostics

**Quotes:**
- Double quotes for strings (Swift standard)
- String interpolation: `"\(variable)"` pattern

**Semicolons:**
- Not used (Swift standard)

## Import Organization

**Order:**
1. Foundation/system frameworks
2. Apple UI frameworks (SwiftUI, AppKit)
3. Third-party packages (HighlightSwift)
4. No blank lines between imports

**Examples from codebase:**
```swift
import Foundation
import os.log
import SwiftUI
import HighlightSwift
```

**Path Aliases:**
- No path aliases (standard Swift imports)

## Error Handling

**Patterns:**
- `async throws` for operations that can fail
- Try/catch at service boundaries
- Graceful degradation with logging

**Error Types:**
- Standard Swift Error protocol
- No custom error types defined
- Timeout handling via TaskGroup

**Logging:**
- os.log for error logging: `logger.error("message")`
- Include context in error messages

## Logging

**Framework:**
- Apple os.log via `Shared/Logger.swift`
- Subsystem: `com.stianlars1.dotViewer`

**Categories:**
- `DotViewerLogger.preview` - Quick Look operations
- `DotViewerLogger.settings` - Configuration
- `DotViewerLogger.app` - Main app
- `DotViewerLogger.cache` - Caching operations

**Patterns:**
- Structured logging with context
- Performance timing via `TimingScope`
- Log at service boundaries

## Comments

**When to Comment:**
- Explain why, not what
- Document complex algorithms and heuristics
- Mark performance-critical sections

**Documentation Comments (///):**
- Required for public types and methods
- Clear, concise descriptions
- Examples: `/// Central registry of all supported file types with O(1) lookup`

**MARK Sections:**
- Consistent use of `// MARK: - Section Name`
- Used for code organization in large files
- Examples: `// MARK: - Configuration`, `// MARK: - Query Methods (O(1) lookups)`

**TODO Comments:**
- Format: `// TODO: description`
- No username prefix (git blame provides history)

## Function Design

**Size:**
- Prefer smaller functions
- Large files exist (`PreviewContentView.swift` at 1,371 lines) - candidate for refactoring

**Parameters:**
- Named parameters for clarity
- Use trailing closure syntax for callbacks
- Destructure where appropriate

**Return Values:**
- Explicit return types
- Optional returns for lookups that may fail
- Async/await for asynchronous operations

## Module Design

**Exports:**
- Public API via type visibility (internal by default)
- Shared module exposes types to both targets

**Singletons:**
- Static shared instances: `FileTypeRegistry.shared`
- Thread-safe with locks or actors

**Separation:**
- Clear target boundaries (app, extension, shared)
- No circular dependencies between modules

## SwiftUI Patterns

**State Management:**
- `@State` for local view state
- `@ObservedObject` for shared observable objects
- `@Published` for observable properties

**View Composition:**
- Extract reusable components
- Use `some View` return type
- Prefer computed properties for derived state

**Concurrency:**
- `@MainActor` for UI-bound code
- `@unchecked Sendable` with explicit synchronization
- Task cancellation for debounced operations

---

*Convention analysis: 2026-01-14*
*Update when patterns change*
