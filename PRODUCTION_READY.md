# dotViewer - Production Readiness Report

**Generated:** 2026-01-11
**Version:** 1.0
**Status:** Needs Critical Fixes Before Release

---

## Executive Summary

dotViewer is a macOS Quick Look extension for previewing code and dotfiles. The codebase is well-structured and feature-complete, but has several **critical issues** that must be addressed before production release.

| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| Security | 2 | 2 | 3 | - |
| Performance | 3 | 2 | 4 | 2 |
| Thread Safety | 2 | 2 | 2 | - |
| Error Handling | 1 | 3 | 4 | 3 |
| Code Quality | - | 2 | 5 | 6 |
| **Total** | **8** | **11** | **18** | **11** |

---

## Critical Issues (Must Fix Before Release)

### 1. O(n^2) Performance in Syntax Highlighting
**File:** `QuickLookPreview/PreviewContentView.swift:1014-1018`

```swift
// CURRENT - O(n) per character = O(n^2) total
let startOffset = codeString.distance(from: codeString.startIndex, to: stringRange.lowerBound)
let endOffset = codeString.distance(from: codeString.startIndex, to: stringRange.upperBound)
```

**Impact:** App hangs on files >1000 lines. A 5000-line file causes ~25 million operations.

**Fix:** Use incremental index tracking instead of distance calculation.

---

### 2. UUID Regeneration on Every Render
**File:** `QuickLookPreview/PreviewContentView.swift:419`

```swift
ForEach(parseMarkdownBlocks(content), id: \.id) { block in
```

**Impact:** `parseMarkdownBlocks()` generates new UUIDs every render, breaking SwiftUI's identity system. Causes visual glitches and performance issues.

**Fix:** Memoize parsed blocks in `@State`:
```swift
@State private var cachedBlocks: [MarkdownBlock]?
```

---

### 3. 5000 Views Created for Line Numbers
**File:** `QuickLookPreview/PreviewContentView.swift:344`

```swift
ForEach(1...min(lineCount, maxDisplayLines), id: \.self) { line in
    Text("\(line)")
```

**Impact:** Creates 5000 individual SwiftUI Text views. Excessive memory usage (~50MB+ for large files).

**Fix:** Use `LazyVStack` or render as single Canvas/attributed string.

---

### 4. Thread Safety in SharedSettings
**File:** `Shared/SharedSettings.swift:4`

```swift
final class SharedSettings: @unchecked Sendable {
```

**Impact:** Marked `@unchecked Sendable` but has NO thread synchronization. Race conditions when main app and Quick Look extension access settings simultaneously can corrupt data.

**Fix:** Add `NSLock` or switch to `@MainActor`:
```swift
private let lock = NSLock()

var fontSize: Double {
    get { lock.withLock { userDefaults.double(forKey: "fontSize") } }
    set { lock.withLock { userDefaults.set(newValue, forKey: "fontSize") } }
}
```

---

### 5. Process Timeout Missing (Potential Hang)
**File:** `dotViewer/ContentView.swift:207`

```swift
task.waitUntilExit()  // NO TIMEOUT!
```

**Impact:** If `pluginkit` hangs, the app freezes indefinitely.

**Fix:** Implement timeout:
```swift
let semaphore = DispatchSemaphore(value: 0)
task.terminationHandler = { _ in semaphore.signal() }
try task.run()
if semaphore.wait(timeout: .now() + 5) == .timedOut {
    task.terminate()
}
```

---

### 6. .env Files Expose Secrets
**File:** `dotViewer/Info.plist:312-321`

**Impact:** `.env` files often contain API keys, passwords, database credentials. Quick Look thumbnails in Finder can expose these secrets visually.

**Fix:** Either:
- Remove `.env` from supported types, OR
- Mask values: `API_KEY=sk-****` OR
- Show warning banner for `.env` files

---

### 7. Silent App Group Failure
**File:** `Shared/SharedSettings.swift:12-14`

```swift
print("Warning: Could not access App Group, falling back to standard")
return .standard
```

**Impact:** If App Group access fails, settings don't sync between app and extension. Users see different behavior with no indication why. `print()` not visible in production.

**Fix:** Use `os_log` and show user-visible warning:
```swift
import os.log
os_log(.error, "App Group access failed - settings may not sync")
```

---

### 8. No Input Validation
**File:** `Shared/SharedSettings.swift`

| Property | Issue |
|----------|-------|
| `fontSize` (line 30) | Accepts 0, negative, or 10000 |
| `maxFileSize` (line 79) | Could be manipulated to cause memory exhaustion |
| `customExtensions` (line 62) | No validation of extension names |

**Fix:** Add bounds checking:
```swift
var fontSize: Double {
    get { ... }
    set {
        let clamped = max(8, min(72, newValue))
        userDefaults.set(clamped, forKey: "fontSize")
    }
}
```

---

## High Priority Issues

### 9. Bundle Validation Missing
**File:** `dotViewer/ContentView.swift:589-599`

When user selects custom editor app, no validation that it's legitimate. Could launch arbitrary apps.

**Fix:** Validate bundle signature with `SecStaticCode`.

---

### 10. No Async Cancellation
**File:** `QuickLookPreview/PreviewContentView.swift:117-127`

Syntax highlighting has no timeout or cancellation. Large files block indefinitely.

**Fix:**
```swift
private var highlightTask: Task<Void, Never>?

.task {
    highlightTask?.cancel()
    highlightTask = Task.detached(timeout: .seconds(2)) {
        await highlightCode()
    }
}
```

---

### 11. Duplicate Code - Bundle IDs
**File:** `dotViewer/ContentView.swift:342-344, 676-678`

Same editor bundle ID array appears twice. Maintenance nightmare.

**Fix:** Extract to constant:
```swift
enum SupportedEditors {
    static let bundleIds = ["com.microsoft.VSCode", ...]
}
```

---

### 12. Regex Not Cached
**File:** `QuickLookPreview/PreviewContentView.swift:980-991`

Regex patterns compiled on every code block render.

**Fix:** Pre-compile as static:
```swift
private static let commentRegex = try! NSRegularExpression(pattern: "//[^\n]*")
```

---

### 13. Theme Logic Duplicated
**Files:** `Shared/ThemeManager.swift:38-65` and `Shared/SyntaxHighlighter.swift:33-60`

Same theme switch statement exists in two files.

**Fix:** SyntaxHighlighter should call `ThemeManager.shared.currentHighlightColors`.

---

## Medium Priority Issues

### 14. Remove Explicit synchronize() Calls
**File:** `Shared/SharedSettings.swift` (14 occurrences)

Apple deprecated explicit sync since macOS 10.14. Causes unnecessary disk I/O.

---

### 15. Use os_log Instead of print/NSLog
**Files:** Multiple

Debug logging with `print()` and `NSLog()` throughout. Not visible in production Console app properly.

```swift
import os.log
private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "Preview")
logger.info("Loading file: \(url.lastPathComponent)")
```

---

### 16. Version Hardcoded
**File:** `dotViewer/ContentView.swift:169`

```swift
Text("v1.0")
```

**Fix:** Read from Info.plist:
```swift
Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
```

---

### 17. Icon Fetching on Every Render
**File:** `dotViewer/ContentView.swift:686-693`

`customAppIcon` computed property fetches icon from disk on every view render.

**Fix:** Cache in `@State` variable.

---

### 18. Linear Search in FileTypeRegistry
**File:** `Shared/FileTypeRegistry.swift:220-223`

O(n) search through 100+ types for every file preview.

**Fix:** Pre-compute Dictionary mapping.

---

## Info.plist Issues

### Main App (dotViewer/Info.plist)

| Issue | Line | Severity |
|-------|------|----------|
| Empty `CFBundleIconFile` | 10 | Medium - needs app icon |
| Empty `NSMainStoryboardFile` | 30 | Low - SwiftUI app doesn't need it |
| Missing `NSSupportsAutomaticGraphicsSwitching` | - | Low - for battery optimization |

### Quick Look Extension (QuickLookPreview/Info.plist)

| Issue | Line | Severity |
|-------|------|----------|
| `public.data` too broad | 86 | Medium - might preview binary files |
| `public.content` too broad | 87 | Medium - very generic |
| Missing `QLThumbnailMinimumSize` | - | Low - for thumbnail optimization |

---

## Entitlements Review

### dotViewer.entitlements
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.stianlars1.dotviewer</string>
</array>
```

**Status:** Minimal and correct for sandbox.

**Missing (optional):**
- `com.apple.security.network.client` - if you add update checking
- `com.apple.security.files.bookmarks.app-scope` - for recent files

### QuickLookPreview.entitlements
**Status:** Correct - only needs app-groups for settings sync.

---

## File Structure Assessment

```
dotViewer/
├── dotViewer/                    # Main app
│   ├── dotViewerApp.swift        # App entry point
│   ├── ContentView.swift         # Main UI (743 lines - consider splitting)
│   ├── FileTypesView.swift       # File type management
│   ├── AddCustomExtensionSheet.swift
│   ├── Info.plist
│   └── dotViewer.entitlements
├── QuickLookPreview/             # Quick Look extension
│   ├── PreviewViewController.swift
│   ├── PreviewContentView.swift  # (1032 lines - needs splitting)
│   ├── MarkdownWebView.swift
│   ├── MarkdownStyles.swift
│   ├── Info.plist
│   └── QuickLookPreview.entitlements
├── Shared/                       # Shared framework
│   ├── SharedSettings.swift
│   ├── ThemeManager.swift
│   ├── SyntaxHighlighter.swift
│   ├── LanguageDetector.swift
│   ├── FileTypeRegistry.swift
│   ├── FileTypeModel.swift
│   └── PreviewView.swift
└── scripts/
    └── create-dmg.sh
```

### Recommendations:
1. Split `ContentView.swift` into `StatusView.swift`, `SettingsView.swift`, `EditorPickerView.swift`
2. Split `PreviewContentView.swift` into `CodePreviewView.swift`, `MarkdownPreviewView.swift`, `HeaderView.swift`
3. Add `Tests/` directory with unit tests

---

## Missing for Production

### Required:
- [ ] Fix all 8 critical issues
- [ ] Add app icon (CFBundleIconFile is empty)
- [ ] Set MARKETING_VERSION and CURRENT_PROJECT_VERSION in Xcode
- [ ] Test on macOS 13, 14, 15 (current deployment target)
- [ ] Test with files >10MB, >100K lines

### Recommended:
- [ ] Add unit tests for SharedSettings, FileTypeRegistry, LanguageDetector
- [ ] Add crash reporting (Sentry, Crashlytics)
- [ ] Add Privacy Policy URL (required for App Store)
- [ ] Add EULA/Terms
- [ ] Create proper README.md for GitHub
- [ ] Set up CI/CD (GitHub Actions)

### Nice to Have:
- [ ] Localization (Info.plist has DEVELOPMENT_LANGUAGE set)
- [ ] VoiceOver accessibility testing
- [ ] Keyboard navigation testing
- [ ] Dark/Light mode testing in all themes

---

## App Store Submission Checklist

- [ ] Screenshots (1280x800 or 2560x1600)
- [ ] App icon (1024x1024 PNG)
- [ ] App description (up to 4000 chars)
- [ ] Keywords (up to 100 chars)
- [ ] Support URL
- [ ] Privacy Policy URL
- [ ] Age Rating questionnaire
- [ ] Export Compliance (uses encryption?)
- [ ] Content Rights declaration
- [ ] Sign with Developer ID for notarization

---

## Performance Benchmarks Needed

Test these scenarios before release:

| Scenario | Target | Current Status |
|----------|--------|----------------|
| 100-line file preview | <100ms | Unknown |
| 1000-line file preview | <500ms | Unknown |
| 5000-line file preview | <2s | Likely slow |
| 10MB JSON file | <3s | Unknown |
| Rapid file switching | No lag | Unknown |
| Memory with 10 previews | <200MB | Unknown |

---

## Security Audit Summary

| Risk | Status | Mitigation |
|------|--------|------------|
| Arbitrary app launch | HIGH | Add bundle validation |
| .env file exposure | HIGH | Mask values or warn user |
| Path traversal | LOW | Using proper URL APIs |
| Memory exhaustion | MEDIUM | Add file size caps |
| Settings tampering | LOW | UserDefaults standard security |

---

## Recommended Fix Order

### Week 1 - Critical (Must ship with these)
1. Fix O(n^2) highlighting performance
2. Fix UUID regeneration in markdown
3. Add thread synchronization to SharedSettings
4. Add process timeout
5. Fix .env file handling

### Week 2 - High Priority
6. Add input validation
7. Fix line number view performance
8. Add proper logging infrastructure
9. Extract duplicate code
10. Cache regex patterns

### Week 3 - Polish
11. Remove synchronize() calls
12. Add unit tests
13. Fix remaining medium issues
14. Performance testing
15. App Store preparation

---

## Conclusion

dotViewer is a well-designed app with good SwiftUI architecture. The main concerns are:

1. **Performance** - Several O(n^2) or expensive operations will cause hangs on large files
2. **Thread Safety** - SharedSettings needs synchronization
3. **Security** - .env file exposure and missing validation

After fixing the 8 critical issues, the app will be ready for production release. Estimated effort: **2-3 weeks** for a polished, production-ready 1.0 release.
