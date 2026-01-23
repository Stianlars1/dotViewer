# Comprehensive Improvement Report: dotViewer QuickLook Extension

**Date:** 2025-01-23
**Scope:** Performance, UX, file-type support, and architecture improvements
**Codebase:** dotViewer macOS QuickLook Preview Extension

---

## 1. CRITICAL: TypeScript (.ts/.tsx) QuickLook Support

> **This is the #1 pain point and gets its own dedicated deep-dive section.**

### Problem Analysis

macOS assigns `.ts` files the system UTI `public.mpeg-2-transport-stream` (MPEG-2 Transport Stream video format). This creates a fundamental conflict:

- The system's **built-in video previewer** takes PRECEDENCE over third-party Quick Look extensions for any UTI it recognizes
- `.ts` is a legitimate video container format (used by broadcast TV, Blu-ray, etc.)
- TypeScript adopted the same extension years later, creating an irreconcilable system-level conflict
- This is an **industry-wide unsolved problem**: PreviewCode (smittytone) explicitly states it CANNOT handle `.ts` files for the same reason

### Current Implementation

**`dotViewer/Info.plist` (lines 53-84):** Declares exported UTI `com.stianlars1.dotviewer.typescript` for extensions `ts`, `mts`, `cts`:

```xml
<key>UTExportedTypeDeclarations</key>
<dict>
    <key>UTTypeIdentifier</key>
    <string>com.stianlars1.dotviewer.typescript</string>
    <!-- Extensions: ts, mts, cts -->
</dict>
```

**`QuickLookPreview/Info.plist` (lines 47-49):** Added MPEG-2 to supported content types as a fallback:

```xml
<!-- MPEG-2 kept for edge cases where .ts is actually video -->
<string>public.mpeg-2-transport-stream</string>
<string>public.avchd-mpeg-2-transport-stream</string>
```

**`dotViewer/Info.plist` (line 31-52):** Imported `com.microsoft.typescript` UTI for TypeScript recognition.

### Why Current Fix Is Insufficient

1. **`UTExportedTypeDeclarations` declares `com.stianlars1.dotviewer.typescript` for `.ts`** - but macOS only uses exported UTIs when no system UTI already claims the extension. Since `public.mpeg-2-transport-stream` is a SYSTEM UTI, it cannot be overridden by third-party apps.

2. **Adding `public.mpeg-2-transport-stream` to `QLSupportedContentTypes` (line 48)** tells the system "I can preview this type" - but the system's built-in video handler has higher priority and still wins the handler election.

3. **The `public.data` catch-all (line 38 in QLSupportedContentTypes)** should theoretically match everything, but macOS picks more specific handlers first. The video handler is more specific than `public.data`.

4. **MPEG-2 content detection** (added in commit `96fd769`) detects actual video content and bails out - but the problem is the extension never gets invoked in the first place for `.ts` files on stock macOS.

5. **The verification claimed success** - but this likely only works when **Xcode is installed**, because Xcode registers `com.apple.dt.typescript` as the UTI for `.ts` files, which overrides `public.mpeg-2-transport-stream`.

### Verification Commands

```bash
# Check what UTI macOS assigns to a .ts file
mdls -name kMDItemContentType /path/to/file.ts

# Expected on stock macOS: public.mpeg-2-transport-stream
# Expected with Xcode installed: com.apple.dt.typescript

# Try previewing directly
qlmanage -p /path/to/file.ts

# Check which app handles the UTI
/usr/bin/lsregister -dump | grep "mpeg-2-transport-stream"
```

### Solution Approaches to Investigate

| # | Approach | Feasibility | Notes |
|---|----------|-------------|-------|
| 1 | **`duti` / LSSetDefaultRoleHandlerForContentType** | Medium | Programmatically change UTI association on first app launch. Requires user consent. May not survive macOS updates. |
| 2 | **Legacy `.qlgenerator` plugin** | Medium | Ship alongside modern extension. Legacy plugins can override system handlers (deprecated since macOS 12 but still functional through macOS 15). Apple may remove support. |
| 3 | **Thumbnail Extension trick** | Low | Providing thumbnails for `.ts` may influence QuickLook routing, but unlikely to override the preview handler. |
| 4 | **File Provider Extension** | Low | May allow re-declaring file types, but heavy-weight and designed for cloud storage. |
| 5 | **User-space workaround** | High | Guide users to run `duti -s com.stianlars1.dotViewer public.mpeg-2-transport-stream viewer` post-install. Document in README. |
| 6 | **Accept partial limitation** | High | Document that `.ts` requires manual UTI override; `.tsx` works fine natively (no system UTI conflict). |

**Recommended approach:** Combination of #5 and #6 - provide a first-launch dialog explaining the limitation with a "Fix Now" button that runs the `duti` command, plus clear documentation. Fall back to graceful messaging if the fix isn't applied.

### Other Potentially Affected Extensions

| Extension | System UTI Conflict | Status |
|-----------|-------------------|--------|
| `.ts` | `public.mpeg-2-transport-stream` | **BROKEN on stock macOS** |
| `.mts` | Potentially MPEG-related | Needs investigation (`mdls` check) |
| `.cts` | None known | Likely works (custom UTI) |
| `.tsx` | None | **WORKS** (custom UTI `com.stianlars1.dotviewer.tsx`) |
| `.d` | Potential conflict with D language vs dtrace | Needs investigation |
| `.astro` | None | **WORKS** (custom UTI) |
| `.vue` | None | **WORKS** (custom UTI) |
| `.svelte` | None | **WORKS** (custom UTI) |

---

## 2. Ralph Loop Fixes Review

### Summary of All 8 Fixes Across 5 Commits

| # | Commit | Fix | File(s) | Effectiveness |
|---|--------|-----|---------|---------------|
| 1 | `76d886e` | Memory cache byte limits (10MB + LRU) | HighlightCache.swift | High - prevents OOM in XPC |
| 2 | `76d886e` | NSLock → OSAllocatedUnfairLock (3 caches) | FastSyntaxHighlighter, HighlightCache, DiskCache | High - eliminates priority inversion |
| 3 | `76d886e` | Static pattern caching | FastSyntaxHighlighter, LanguageDetector | High - zero allocation per call |
| 4 | `76d886e` | Substring optimization | LanguageDetector.swift | Medium - reduces String copies |
| 5 | `ddfc949` | MarkdownBlock UUID → Int IDs | PreviewContentView.swift | Medium - stable SwiftUI identity |
| 6 | `3fc94d9` | 25+ NSLog removed from production | DiskCache, PreviewViewController, MarkdownWebView | Medium - removes I/O overhead |
| 7 | `0ecf06d` | God class split (PreviewContentView) | PreviewContentView.swift, MarkdownRenderedViewLegacy.swift | Medium - maintainability |
| 8 | `f36eea0` | DiskCache key validation NSLog cleanup | DiskCache.swift | Low - minor cleanup |

### Remaining Issues Found

#### Issue A: TaskItem UUID Re-render Churn
**File:** `MarkdownRenderedViewLegacy.swift:7`
```swift
struct TaskItem: Identifiable {
    let id = UUID()  // <-- New UUID every time struct is created
    let checked: Bool
    let text: String
}
```
**Problem:** While `MarkdownBlock` was fixed to use deterministic Int IDs (commit `ddfc949`), `TaskItem` was NOT fixed. Every time the markdown is re-parsed, new UUIDs are generated for each task item, causing SwiftUI to treat them as new views and trigger unnecessary re-renders.

**Fix:** Use a deterministic ID based on the task item's index within its parent block:
```swift
struct TaskItem: Identifiable {
    let id: Int  // Index-based, assigned during parsing
    let checked: Bool
    let text: String
}
```

#### Issue B: SyntaxHighlighter NSLock Not Migrated
**File:** `SyntaxHighlighter.swift:19`
```swift
private static let colorCacheLock = NSLock()
```
**Problem:** While `FastSyntaxHighlighter`, `HighlightCache`, and `DiskCache` were all migrated to `OSAllocatedUnfairLock`, the original `SyntaxHighlighter` class was missed. It still uses the double-checked locking pattern with `NSLock` (lines 61, 68, 76).

**Fix:** Replace with `OSAllocatedUnfairLock<[String: ThemeColors]>` matching the pattern used in the other caches.

#### Issue C: PreviewViewController Recreates NSHostingView
**File:** `PreviewViewController.swift:181`
```swift
let hosting = NSHostingView(rootView: previewView)
```
**Problem:** Every preview request tears down the existing `NSHostingView` (line 185: `self.hostingView?.removeFromSuperview()`) and creates a new one. This is expensive - SwiftUI view hierarchy setup, constraint creation (lines 182-193), and layout passes all happen from scratch.

**Fix:** Reuse the existing `NSHostingView` by updating its `rootView` property:
```swift
if let existing = self.hostingView {
    existing.rootView = previewView
} else {
    let hosting = NSHostingView(rootView: previewView)
    // ... setup constraints only once ...
    self.hostingView = hosting
}
```

---

## 3. Swift 6 Best Practices Assessment

### @unchecked Sendable Audit

| Class | File:Line | Current Safety | Recommendation |
|-------|-----------|----------------|----------------|
| `SharedSettings` | SharedSettings.swift:14 | NSLock (line 18) | **Remove lock entirely.** UserDefaults is already thread-safe. The lock adds unnecessary overhead. Can be true `Sendable` with no synchronization. |
| `FileTypeRegistry` | FileTypeRegistry.swift:10 | Immutable after init | **Can be true `Sendable`.** All properties are `let` (lines 14-18). Remove `@unchecked` - the compiler can verify safety. |
| `DiskCache` | DiskCache.swift:20 | DispatchQueue + OSAllocatedUnfairLock | **Migrate to Actor.** Replace `writeQueue` (line 27) with actor isolation. The serial queue pattern maps directly to actor semantics. |
| `HighlightCache` | HighlightCache.swift:19 | OSAllocatedUnfairLock | **Migrate to Actor.** The `CacheState` struct (line 28) wrapping maps directly to actor-isolated state. |

### @Observable Migration

**File:** `ThemeManager.swift:5-6`
```swift
@MainActor
class ThemeManager: ObservableObject {
    @Published var selectedTheme: String
    @Published var fontSize: Double
    @Published var showLineNumbers: Bool
}
```

**Recommendation:** Migrate to `@Observable` (available since macOS 14.0, which is already the deployment target):
```swift
@MainActor
@Observable
class ThemeManager {
    var selectedTheme: String
    var fontSize: Double
    var showLineNumbers: Bool
}
```

**Benefits:**
- Finer-grained observation (only re-renders views that read changed properties)
- No `@Published` wrapper overhead
- No `objectWillChange` publisher allocations
- Simpler API (no `@ObservedObject`/`@StateObject` distinction in views)

### Structured Concurrency

**File:** `PreviewViewController.swift:60, 173, 200`

Current pattern uses nested `DispatchQueue` callbacks:
```swift
DispatchQueue.global(qos: .userInitiated).async { [weak self] in
    // File I/O
    DispatchQueue.main.async {
        // UI update
    }
}
```

**Recommendation:** Convert to async/await:
```swift
func preparePreviewOfFile(at url: URL) async throws {
    let content = try await Task.detached(priority: .userInitiated) {
        try String(contentsOf: url, encoding: .utf8)
    }.value

    // Already on MainActor (QLPreviewingController)
    let previewView = PreviewContentView(state: ...)
    updateHostingView(with: previewView)
}
```

**Note:** `QLPreviewingController` supports the async `preparePreviewOfFile(at:)` overload since macOS 12.0.

### Typed Throws (Swift 6)

**Recommendation:** Define typed error enums for precise error handling:
```swift
enum HighlightError: Error {
    case fileReadFailed(URL, underlying: Error)
    case encodingDetectionFailed
    case timeout
    case cancelled
}

enum PreviewError: Error {
    case unsupportedFileType(String)
    case fileTooLarge(bytes: Int)
    case highlightFailed(HighlightError)
}

// Usage with typed throws (Swift 6):
func highlight(content: String) throws(HighlightError) -> AttributedString { ... }
```

### NSLock Vulnerability

**File:** `SyntaxHighlighter.swift:19`

The double-checked locking pattern (lines 46-78) has a subtle issue:
```swift
// First check without lock (line 48-50) - reads shared state without synchronization
if let cached = Self.themeColorCache[cacheKey] { return cached }

// Acquire lock (line 61)
Self.colorCacheLock.lock()
// Second check under lock (lines 63-65)
if let cached = Self.themeColorCache[cacheKey] {
    Self.colorCacheLock.unlock()
    return cached
}
```

**Problem:** The first unsynchronized read of `themeColorCache` is a data race in Swift's strict concurrency model. Dictionary reads are not atomic - a concurrent write during the read could cause undefined behavior.

**Fix:** Use `OSAllocatedUnfairLock` wrapping the entire cache dictionary, eliminating the double-checked pattern.

---

## 4. Performance Improvements

### 4.1 ASCII Fast-Path for Character Classification

**Opportunity:** `PreviewContentView.swift:382` uses `char.isLetter` and `char.isNumber` which perform full Unicode analysis.

**Optimization:** For syntax highlighting and language detection, ASCII-only classification is sufficient and 5-10x faster:
```swift
extension Character {
    @inline(__always)
    var isASCIIAlphanumeric: Bool {
        let v = asciiValue ?? 0
        return (v >= 0x30 && v <= 0x39) ||  // 0-9
               (v >= 0x41 && v <= 0x5A) ||  // A-Z
               (v >= 0x61 && v <= 0x7A)     // a-z
    }
}
```

### 4.2 NSHostingView Reuse

**File:** `PreviewViewController.swift:181-195`

**Current:** Tears down and rebuilds the entire SwiftUI view hierarchy per request.
**Improvement:** Update `rootView` on existing `NSHostingView` - preserves the SwiftUI render tree and avoids constraint recalculation.
**Expected impact:** 50-100ms saved per preview request.

### 4.3 Regex enumerateMatches for Cancellation

**Current:** `FastSyntaxHighlighter` runs regex matches to completion, even if the user navigates away.

**Improvement:** Use `NSRegularExpression.enumerateMatches(in:options:range:using:)` with a cancellation check:
```swift
regex.enumerateMatches(in: text, range: fullRange) { match, _, stop in
    if Task.isCancelled {
        stop.pointee = true
        return
    }
    // Process match
}
```

**Expected impact:** Immediate cancellation when user navigates to a different file, freeing XPC resources.

### 4.4 Disk Cache Format: RTF → Binary Color Ranges

**Current (DiskCache.swift:219-230):** Stores highlighted text as RTF data. RTF parsing is expensive:
- NSAttributedString → RTF conversion allocates intermediate representations
- RTF decoding (line 169-175) re-parses document structure
- Typical 30KB source file produces ~150KB RTF cache entry

**Proposed:** Store as binary color range data:
```swift
struct CachedHighlight: Codable {
    let plainText: String  // Original text (for verification)
    let ranges: [(start: Int, length: Int, colorIndex: UInt8)]
    let palette: [UInt32]  // RGBA colors used
}
```

**Expected impact:** 3-5x faster cache reads, 60-80% smaller cache files.

### 4.5 Line Numbers String Caching

**Current:** Line number strings are regenerated on every render.

**Improvement:** Pre-compute and cache the line number column as a single `AttributedString`:
```swift
static var lineNumberCache: [Int: AttributedString] = [:]  // lineCount → rendered numbers
```

**Expected impact:** Eliminates O(n) string concatenation on re-renders.

### 4.6 LRU Eviction: O(n) → O(1) via OrderedDictionary

**Current (HighlightCache.swift:115-149):** Uses separate `accessOrder: [String]` array:
```swift
state.accessOrder.removeFirst()  // O(n) - shifts all elements
```

**Improvement:** Use `OrderedDictionary` from swift-collections:
```swift
import OrderedCollections

struct CacheState {
    var memoryCache: OrderedDictionary<String, CacheEntry>
    // Access order is implicit in dictionary ordering
    // Move-to-back on access: O(1) amortized
    // Remove oldest: O(1)
}
```

**Expected impact:** O(1) eviction instead of O(n) array shifts. Matters when cache is full (20 entries).

---

## 4.5 Performance Manual Test Results (Current State)

### Test Environment
- macOS with dotViewer QuickLook extension installed
- Files previewed via Finder Quick Look (spacebar)

### Results

| # | File | Size | Time | Verdict |
|---|------|------|------|---------|
| 1 | `~/.claude.json` | 30 KB | 8s blank + 8s formatting = **16s total** | **CRITICAL** - Unacceptable |
| 2 | `~/.claude.json.backup` | ~30 KB | Same as #1 (~16s) | **CRITICAL** - Confirms systematic issue |
| 3 | `~/.zsh_history` | 108 KB | ~6s | Needs improvement |
| 4 | `~/.zshrc-kopi 2` | ~4-9 KB | 2-3s | Unacceptably slow for tiny file |
| 5 | `~/.zshrc` | ~4-9 KB | 2-3s | Unacceptably slow for tiny file |
| 6 | `~/.zshrc-kopi` | ~4-9 KB | 2-3s | Unacceptably slow for tiny file |
| 7 | `.oh-my-zsh/*.md` | Various | Fast (rendered mode) | Acceptable |
| 7b | `.oh-my-zsh/tools/*.zsh` | Various | Slow | Same issue as shell scripts |

### Analysis

The **8-second blank window** before dotViewer even starts is the QuickLook system loading the extension. This is a macOS XPC startup cost that cannot be fully eliminated but can be mitigated:

**Root Causes:**
1. **XPC cold start** (~2-3s): First invocation loads the extension process
2. **File I/O on background queue** (PreviewViewController.swift:60): Adds a dispatch hop
3. **SwiftUI view hierarchy creation** (line 181): NSHostingView setup is expensive
4. **Syntax highlighting** (PreviewContentView.swift:182-367): Full regex-based highlighting runs synchronously before display
5. **No progressive rendering**: User sees NOTHING until highlighting completes

**Why .json/.zsh files are particularly slow:**
- JSON files trigger extensive brace-matching and nested structure detection
- Shell scripts have complex regex patterns for variable expansion, heredocs, etc.
- The `TaskGroup` timeout (PreviewContentView.swift:299-335) is set generously

**Critical Fix: Progressive Rendering (see Section 5.1)**
- Display plain text IMMEDIATELY (< 100ms)
- Apply syntax highlighting as an overlay AFTER initial render
- User sees content within 1 second instead of 8-16 seconds

---

## 5. UX Improvements

### 5.1 Progressive Text Display (Plain → Highlighted)

**Priority: P0 - This is the most impactful UX improvement possible.**

**Current flow:**
```
[8s blank] → [formatting] → [highlighted text]
```

**Target flow:**
```
[<1s] plain text visible → [background] highlighting applied as overlay
```

**Implementation approach:**
```swift
// In PreviewContentView
@State private var plainContent: String?
@State private var highlightedContent: AttributedString?

var body: some View {
    if let highlighted = highlightedContent {
        // Phase 2: Fully highlighted
        HighlightedTextView(content: highlighted)
    } else if let plain = plainContent {
        // Phase 1: Plain text (immediate)
        Text(plain)
            .font(.system(.body, design: .monospaced))
    } else {
        // Phase 0: Loading skeleton
        ProgressView()
    }
}

.task {
    // Show plain text immediately
    plainContent = try? String(contentsOf: state.fileURL)
    // Then highlight in background
    highlightedContent = await highlightCode()
}
```

### 5.2 Accessibility Labels

Add VoiceOver support to all interactive elements:
- Theme picker: `.accessibilityLabel("Code theme: \(themeName)")`
- Line numbers toggle: `.accessibilityLabel("Show line numbers")`
- Markdown render toggle: `.accessibilityLabel("Switch to rendered markdown view")`
- Error retry button: `.accessibilityLabel("Retry loading file")`

### 5.3 Custom Error Views with Retry

Replace generic error states with informative views:
```swift
struct PreviewErrorView: View {
    let error: PreviewError
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: errorIcon)
            Text(errorTitle)
                .font(.headline)
            Text(errorDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Try Again", action: retryAction)
        }
    }
}
```

### 5.4 Word Wrap Toggle

Add a toggle in the header bar to switch between horizontal scrolling and word-wrapped text. Store preference in `SharedSettings`.

### 5.5 Loading Skeleton for Cache Misses

Show a shimmer/skeleton animation while highlighting runs, instead of a blank view or spinner. This provides spatial context (approximate line count) before content loads.

---

## 6. Architecture Improvements

### 6.1 Extract PreviewViewModel from PreviewContentView

**File:** `PreviewContentView.swift` (779 lines after split)

**Current state:** View contains business logic for:
- Cache lookups (lines 199-208)
- File type detection (lines 216-282)
- Highlighting orchestration (lines 299-335)
- Cache writing (lines 350-359)

**Recommendation:** Extract to `@Observable` view model:
```swift
@Observable
@MainActor
class PreviewViewModel {
    var plainContent: String?
    var highlightedContent: AttributedString?
    var isLoading = false
    var error: PreviewError?

    func loadPreview(for state: PreviewState) async { ... }
    private func checkCache(key: String) -> AttributedString? { ... }
    private func highlight(content: String, type: FileType) async -> AttributedString { ... }
}
```

**Benefits:** Testable without SwiftUI, clear separation of concerns, PreviewContentView becomes purely declarative.

### 6.2 Protocol Abstractions for Testability

```swift
protocol SyntaxHighlighting: Sendable {
    func highlight(content: String, fileType: FileType, theme: Theme) async throws -> AttributedString
}

protocol HighlightCaching: Sendable {
    func get(key: String) async -> AttributedString?
    func set(key: String, value: AttributedString) async
}
```

**Benefits:** Unit tests can inject mock highlighters/caches. Integration tests can use real implementations.

### 6.3 Remove Deprecated Legacy API Methods

Audit for any remaining deprecated API usage:
- `NSAttributedString(data:options:documentAttributes:)` - has modern replacement
- Any remaining `NSKeyedArchiver`/`NSKeyedUnarchiver` patterns
- `FileManager.default.urls(for:in:)` vs modern URL APIs

### 6.4 Environment-Based Dependency Injection

```swift
private struct HighlighterKey: EnvironmentKey {
    static let defaultValue: any SyntaxHighlighting = FastSyntaxHighlighter()
}

extension EnvironmentValues {
    var highlighter: any SyntaxHighlighting {
        get { self[HighlighterKey.self] }
        set { self[HighlighterKey.self] = newValue }
    }
}
```

**Benefits:** SwiftUI previews can use lightweight mock highlighters. Test targets can inject controlled implementations.

---

## 7. Prioritized Action Items

### P0 - Critical (Ship Blockers)

| # | Item | Files | Impact |
|---|------|-------|--------|
| P0-1 | **Progressive rendering** (plain text first) | PreviewContentView.swift | Eliminates 8-16s blank window |
| P0-2 | **TypeScript UTI investigation** + user-facing fix | Info.plist, new FirstLaunchView | Unblocks .ts file support |
| P0-3 | **NSHostingView reuse** (update rootView) | PreviewViewController.swift:181 | 50-100ms per preview |
| P0-4 | **TaskItem UUID fix** | MarkdownRenderedViewLegacy.swift:7 | Prevents re-render churn |

### P1 - High (Next Sprint)

| # | Item | Files | Impact |
|---|------|-------|--------|
| P1-1 | **SyntaxHighlighter NSLock → OSAllocatedUnfairLock** | SyntaxHighlighter.swift:19 | Eliminates data race + priority inversion |
| P1-2 | **@Observable migration** (ThemeManager) | ThemeManager.swift:5 | Finer-grained SwiftUI updates |
| P1-3 | **PreviewViewModel extraction** | PreviewContentView.swift | Testability, separation of concerns |
| P1-4 | **ASCII fast-path** for character classification | PreviewContentView.swift, LanguageDetector | 5-10x faster detection |
| P1-5 | **Accessibility labels** on all controls | PreviewContentView.swift, header views | Accessibility compliance |
| P1-6 | **Regex cancellation** (enumerateMatches) | FastSyntaxHighlighter.swift | Immediate cancel on navigation |

### P2 - Medium (v1.2)

| # | Item | Files | Impact |
|---|------|-------|--------|
| P2-1 | **Actor migration** (DiskCache, HighlightCache) | DiskCache.swift:20, HighlightCache.swift:19 | True Sendable, no @unchecked |
| P2-2 | **Typed throws** (HighlightError, PreviewError) | Shared/, QuickLookPreview/ | Precise error handling |
| P2-3 | **Disk cache format** (RTF → binary ranges) | DiskCache.swift:219-230 | 3-5x faster reads |
| P2-4 | **Progressive display** (skeleton → plain → highlighted) | PreviewContentView.swift | Perceived performance |
| P2-5 | **Structured concurrency** (async preparePreview) | PreviewViewController.swift:60 | Eliminates DispatchQueue nesting |
| P2-6 | **FileTypeRegistry true Sendable** | FileTypeRegistry.swift:10 | Remove @unchecked (already safe) |
| P2-7 | **SharedSettings lock removal** | SharedSettings.swift:14-18 | UserDefaults is already thread-safe |

### P3 - Low (Backlog)

| # | Item | Files | Impact |
|---|------|-------|--------|
| P3-1 | **Full DI** (protocol abstractions + Environment) | New protocols, EnvironmentValues | Testability |
| P3-2 | **OrderedDictionary** for LRU | HighlightCache.swift:115 | O(1) eviction |
| P3-3 | **Line number caching** | PreviewContentView.swift | Avoids O(n) string concat |
| P3-4 | **Word wrap toggle** | PreviewContentView.swift, SharedSettings | User preference |
| P3-5 | **Custom error views** with retry | New PreviewErrorView.swift | Better error UX |
| P3-6 | **Loading skeleton** animation | PreviewContentView.swift | Perceived performance |
| P3-7 | **Remove deprecated APIs** | Various | Future-proofing |

---

## Appendix: File Reference

| File | Lines | Key Concerns |
|------|-------|-------------|
| `QuickLookPreview/PreviewViewController.swift` | ~200 | XPC entry point, DispatchQueue usage, NSHostingView lifecycle |
| `QuickLookPreview/PreviewContentView.swift` | ~779 | Main view, highlighting logic, cache integration |
| `QuickLookPreview/MarkdownRenderedViewLegacy.swift` | ~702 | Markdown rendering, TaskItem UUID issue |
| `Shared/SyntaxHighlighter.swift` | ~78 | NSLock data race, color cache |
| `Shared/FastSyntaxHighlighter.swift` | ~684 | Primary highlighter, regex patterns |
| `Shared/HighlightCache.swift` | ~205 | Memory LRU, OSAllocatedUnfairLock, O(n) eviction |
| `Shared/DiskCache.swift` | ~357 | RTF format, 500-entry limit, serial queue |
| `Shared/SharedSettings.swift` | ~144 | Unnecessary NSLock over UserDefaults |
| `Shared/FileTypeRegistry.swift` | ~448 | Immutable, can be true Sendable |
| `Shared/ThemeManager.swift` | ~50 | ObservableObject → @Observable candidate |
| `dotViewer/Info.plist` | ~110 | UTI declarations, TypeScript types |
| `QuickLookPreview/Info.plist` | ~50 | QLSupportedContentTypes, MPEG-2 entries |
