# dotViewer - Development Session Log

> **Session Date:** January 9-10, 2026
> **Developer:** User + Claude (Opus 4.5)

---

## Session Summary

Built a macOS Quick Look extension for syntax-highlighted code previews. The app is 95% complete but has build errors due to duplicate type declarations that need fixing.

---

## Chronological Progress

### Phase 1: Initial Setup
- Created Xcode project with two targets:
  - `dotViewer` (main app)
  - `QuickLookPreview` (Quick Look extension)
- Added HighlightSwift as Swift Package dependency
- Configured Info.plist files:
  - Main app: UTI exports for TypeScript, Go, Rust, etc.
  - Extension: QLSupportedContentTypes list

### Phase 2: Core Implementation
- Created shared files:
  - `LanguageDetector.swift` - Maps 70+ extensions to highlight.js languages
  - `SyntaxHighlighter.swift` - Async highlighting wrapper
  - `ThemeManager.swift` - Theme colors and settings
  - `PreviewView.swift` - SwiftUI preview components

### Phase 3: Quick Look Extension Issues

**Problem 1: Extension Not Registering**
- Symptom: `pluginkit` showed nothing for dotViewer
- Cause: Sandbox was disabled
- Fix: Set `com.apple.security.app-sandbox = true` in entitlements

**Problem 2: Extension Shows Spinner Forever**
- Symptom: Quick Look panel showed loading spinner indefinitely
- Cause: Async Task never called completion handler
- Fix: Call handler(nil) immediately, then update view async

**Problem 3: Plain Text Flash**
- Symptom: Plain text appeared, then jumped to highlighted version
- Cause: Showing plain text first, then replacing with highlighted
- Fix: Show spinner while highlighting, then fade in final content

### Phase 4: v2 Features
Added per user request:
- **Configurable file types**: Toggle on/off for each type
- **Custom extensions**: Add your own file type mappings
- **App Groups**: Settings sync between app and extension
- **Redesigned UI**: Sidebar navigation with Status, File Types, Settings

Files created:
- `SharedSettings.swift` - App Groups UserDefaults wrapper
- `FileTypeModel.swift` - FileTypeCategory, SupportedFileType models
- `FileTypeRegistry.swift` - 50+ built-in types catalog
- `FileTypesView.swift` - Toggle UI for file types
- `AddCustomExtensionSheet.swift` - Custom extension dialog
- `PreviewContentView.swift` - New SwiftUI preview with header, copy button

### Phase 5: Build Errors (Current State)

**Error 1: Duplicate SettingsView**
```
Invalid redeclaration of 'SettingsView'
```
- Exists in both dotViewerApp.swift AND ContentView.swift
- Need to delete from dotViewerApp.swift

**Error 2: Duplicate CodeContentView**
```
Invalid redeclaration of 'CodeContentView'
```
- PreviewView.swift defines CodeContentView
- PreviewContentView.swift also defines CodeContentView
- Both files in QuickLookPreview target
- Fix: Remove PreviewView.swift from QuickLookPreview target

**Error 3: Duplicate Color.init(hex:)**
```
Invalid redeclaration of 'init(hex:)'
```
- Defined in ThemeManager.swift AND PreviewContentView.swift
- Already removed from PreviewContentView.swift

---

## Files Created This Session

### Shared/ folder
| File | Purpose | Lines |
|------|---------|-------|
| SharedSettings.swift | App Groups settings | ~110 |
| FileTypeModel.swift | Data models | ~85 |
| FileTypeRegistry.swift | Built-in types | ~300 |

### dotViewer/ folder
| File | Purpose | Lines |
|------|---------|-------|
| FileTypesView.swift | File type toggles | ~145 |
| AddCustomExtensionSheet.swift | Custom extension UI | ~115 |
| ContentView.swift | Complete rewrite with navigation | ~395 |

### QuickLookPreview/ folder
| File | Purpose | Lines |
|------|---------|-------|
| PreviewContentView.swift | SwiftUI preview | ~318 |
| PreviewViewController.swift | Updated for SwiftUI | ~200 |

---

## Files Modified This Session

| File | Changes |
|------|---------|
| dotViewer.entitlements | Added App Group |
| QuickLookPreview.entitlements | Added App Group + Sandbox |
| ThemeManager.swift | Now uses SharedSettings |
| SyntaxHighlighter.swift | Uses SharedSettings for theme |

---

## Key Code Patterns

### Settings Access Pattern
```swift
// In any file that needs settings:
private var settings: SharedSettings { SharedSettings.shared }

// Usage:
let theme = settings.selectedTheme
let fontSize = settings.fontSize
```

### Quick Look Flow
```swift
func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
    // 1. Read file
    let data = try Data(contentsOf: url)
    let content = String(data: data, encoding: .utf8)

    // 2. Create SwiftUI view
    let state = PreviewState(content: content, ...)
    let view = PreviewContentView(state: state)
    let hosting = NSHostingView(rootView: view)

    // 3. Add to view hierarchy
    view.addSubview(hosting)

    // 4. Call handler immediately (view loads async)
    handler(nil)
}
```

### File Type Check Pattern
```swift
// Check if extension is enabled:
if !FileTypeRegistry.shared.isExtensionEnabled(ext) {
    handler(PreviewError.fileTypeDisabled)
    return
}
```

---

## Bugs Encountered & Solutions

| Bug | Cause | Solution |
|-----|-------|----------|
| Extension not in pluginkit | Sandbox disabled | Enable app-sandbox |
| Settings not syncing | Using standard UserDefaults | Use App Groups |
| Spinner forever | handler() never called | Call immediately |
| Plain text flash | Show plain, then highlight | Show spinner, fade in |
| Duplicate symbols | Files in both targets | Fix target membership |

---

## Pending Tasks

1. [ ] Delete duplicate SettingsView from dotViewerApp.swift (lines 18-53)
2. [ ] Remove PreviewView.swift from QuickLookPreview target in Xcode
3. [ ] Replace hardcoded colors in PreviewContentView with ThemeManager
4. [ ] Build and verify no errors
5. [ ] Test Quick Look functionality
6. [ ] Test settings sync between app and extension

---

## Test Files for Verification

After fixing, test with these file types:
- `.swift` - Should show Swift highlighting
- `.ts` / `.tsx` - TypeScript/React
- `.py` - Python
- `.gitignore` - Dotfile
- `.json` - JSON
- Large file (>500KB) - Should show truncation warning

---

## User's Bundle ID
`com.stianlars1.dotViewer`

## App Group ID
`group.com.stianlars1.dotviewer`

## GitHub
https://github.com/stianlars1/dotViewer
