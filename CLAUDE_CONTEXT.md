# dotViewer - Claude Code Context File

> **Last Updated:** January 10, 2026 (Session 3)
> **Status:** All features implemented, ready for testing
> **Next Action:** Build, test, and deploy

---

## Project Overview

**dotViewer** is a macOS Quick Look extension that previews source code files, dotfiles, and config files with syntax highlighting. Users press Space in Finder to see a syntax-highlighted preview of code files.

### Key Features
- Quick Look extension for 50+ file types (TypeScript, Python, Swift, Go, Rust, etc.)
- Syntax highlighting using HighlightSwift library
- Configurable themes (Atom One, GitHub, Xcode, Solarized, Tokyo Night)
- Toggleable file types (enable/disable specific extensions)
- Custom extension support (add your own file type mappings)
- Line numbers (optional)
- Large file truncation with warnings

### Tech Stack
- **Language:** Swift 5
- **UI:** SwiftUI (main app) + NSViewController hosting SwiftUI (Quick Look extension)
- **Syntax Highlighting:** HighlightSwift (Swift Package)
- **Target:** macOS 14+ (Sonoma/Sequoia)
- **Distribution:** Direct download (not App Store)

---

## Project Structure

```
dotViewer/
├── dotViewer/                    # Main app target
│   ├── dotViewerApp.swift        # App entry point
│   ├── ContentView.swift         # Main UI (Status, Settings views)
│   ├── FileTypesView.swift       # File type management UI
│   ├── AddCustomExtensionSheet.swift  # Custom extension dialog
│   ├── Info.plist                # UTI exports
│   └── dotViewer.entitlements    # App Group entitlement
│
├── QuickLookPreview/             # Quick Look extension target
│   ├── PreviewViewController.swift    # QLPreviewingController
│   ├── PreviewContentView.swift       # SwiftUI preview UI
│   ├── Info.plist                     # QLSupportedContentTypes
│   └── QuickLookPreview.entitlements  # Sandbox + App Group
│
├── Shared/                       # Shared code (both targets)
│   ├── SharedSettings.swift      # App Groups UserDefaults
│   ├── FileTypeModel.swift       # Data models
│   ├── FileTypeRegistry.swift    # Built-in types catalog
│   ├── LanguageDetector.swift    # Language detection
│   ├── SyntaxHighlighter.swift   # Highlighting wrapper
│   ├── ThemeManager.swift        # Theme colors & settings
│   └── PreviewView.swift         # Preview components (main app only!)
│
└── dotViewer.xcodeproj/
```

---

## Current State

### What's Working
- ✅ Quick Look extension registered and activates
- ✅ Syntax highlighting for most file types
- ✅ Main app with sidebar navigation (Status, File Types, Settings)
- ✅ Theme selection and font size settings
- ✅ File type enable/disable toggles
- ✅ Custom extension support
- ✅ App Groups for settings sync between app and extension
- ✅ Loading spinner while highlighting (no plain text flash)
- ✅ Content aligned top-left (fixed centering bug)
- ✅ Optional header bar with toggle in settings
- ✅ `.zsh-theme` file support
- ✅ Catch-all preview for unknown file types (`public.data`)
- ✅ Markdown preview toggle (raw/rendered) with header button
- ✅ Settings UI for all new features
- ✅ Typora-inspired markdown rendering (serif fonts, styled headings, code blocks)
- ✅ "Open in App" button with configurable preferred editor

### Session 2 Features Added
- **Header toggle**: Show/hide file info header in settings
- **Markdown preview**: Toggle between raw code and rendered preview
- **zsh-theme support**: Full UTI and highlighting support
- **Catch-all preview**: Preview any text file (already had `public.data`)

### Session 3 Features Added
- **Typora-inspired markdown preview**: Beautiful serif typography, styled headings with underlines, proper code blocks with language labels, styled blockquotes, ordered/unordered lists, horizontal rules
- **Open in App button**: Header button to open files in preferred editor
- **Editor picker in settings**: Quick buttons for VS Code, Xcode, Sublime, TextEdit + custom app picker
- **Settings persistence**: Preferred editor stored via App Groups

---

## Bugs Fixed (Session 1 & 2)

### ✅ Bug 1: Duplicate SettingsView - FIXED
Deleted duplicate from dotViewerApp.swift

### ✅ Bug 2: PreviewView.swift in Wrong Target - FIXED
User removed from QuickLookPreview target in Xcode

### ✅ Bug 3: Hardcoded Colors - FIXED
Now uses ThemeManager.shared.backgroundColor and .textColor

### ✅ Bug 4: Content Centering - FIXED
Added GeometryReader with proper frame alignment

### ✅ Bug 5: Bundle Identifier Mismatch - FIXED
Changed main app from com.stianlars1.dotViewer.dotViewer to com.stianlars1.dotViewer

---

## Target Membership Reference

| File | dotViewer | QuickLookPreview |
|------|:---------:|:----------------:|
| SharedSettings.swift | ✅ | ✅ |
| FileTypeModel.swift | ✅ | ✅ |
| FileTypeRegistry.swift | ✅ | ✅ |
| LanguageDetector.swift | ✅ | ✅ |
| SyntaxHighlighter.swift | ✅ | ✅ |
| ThemeManager.swift | ✅ | ✅ |
| **PreviewView.swift** | ✅ | ❌ **MUST BE UNCHECKED** |
| ContentView.swift | ✅ | ❌ |
| FileTypesView.swift | ✅ | ❌ |
| AddCustomExtensionSheet.swift | ✅ | ❌ |
| dotViewerApp.swift | ✅ | ❌ |
| PreviewViewController.swift | ❌ | ✅ |
| PreviewContentView.swift | ❌ | ✅ |

---

## Key Technical Decisions

### Quick Look Extension Requirements
1. **Sandboxing Required:** Must have `com.apple.security.app-sandbox = true`
2. **App Groups Required:** For settings to sync between app and extension
3. **No XIB/Storyboard:** Using programmatic NSViewController with SwiftUI hosting

### Why HighlightSwift?
- Pure Swift, no web views
- Supports 180+ languages via highlight.js
- Async API doesn't block UI
- Theme support built-in

### Loading UX Flow
1. User presses Space on file
2. Quick Look calls `preparePreviewOfFile`
3. Show header + spinner on themed background
4. Highlight code async
5. Fade in content (0.15s animation)
6. No flash from plain text → highlighted

---

## Build & Test Commands

```bash
# Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData/dotViewer*

# After building in Xcode (Cmd+B):
rm -rf /Applications/dotViewer.app
cp -R ~/Library/Developer/Xcode/DerivedData/dotViewer*/Build/Products/Debug/dotViewer.app /Applications/
open /Applications/dotViewer.app

# Check extension is registered:
pluginkit -m -v -p com.apple.quicklook.preview | grep dotViewer

# Test Quick Look:
qlmanage -p /path/to/file.swift
```

---

## What Was Tried & Learned

### Issue: Extension Not Registering
**Tried:** Various Info.plist configurations
**Solution:** Must enable sandboxing (`com.apple.security.app-sandbox = true`)

### Issue: Settings Not Syncing
**Tried:** Standard UserDefaults, @AppStorage
**Solution:** App Groups with shared suite name (`group.com.stianlars1.dotviewer`)

### Issue: Plain Text Flash Before Highlighting
**Tried:** Show plain text immediately, then update
**Solution:** Show spinner, wait for highlighting, then fade in

### Issue: Duplicate Symbol Errors
**Cause:** Same files added to both targets with conflicting type names
**Solution:** Careful target membership (PreviewView.swift only in main app)

---

## Next Steps

1. **Fix dotViewerApp.swift** - Delete duplicate SettingsView (lines 18-53)
2. **Fix Xcode targets** - Remove PreviewView.swift from QuickLookPreview
3. **Clean colors** - Use ThemeManager in PreviewContentView
4. **Build & Test** - Verify all features work
5. **Optional:** Add app icon, polish UI

---

## Useful File Locations

- **App Group Container:** `~/Library/Group Containers/group.com.stianlars1.dotviewer/`
- **Quick Look Extension:** `dotViewer.app/Contents/PlugIns/QuickLookPreview.appex`
- **Build Output:** `~/Library/Developer/Xcode/DerivedData/dotViewer*/Build/Products/Debug/`
