# dotViewer v2.0 - Complete Rewrite Prompt

**Use this prompt to start a fresh Claude Code session for rebuilding dotViewer from scratch.**

---

## CRITICAL: Read These Files First

Before starting ANY work, you MUST read these two research documents in the repository:

```
1. QUICKLOOK_PERFORMANCE_RESEARCH.md
2. DOTVIEWER_VS_COMPETITORS_ANALYSIS.md
3. ui_ux_screenshots.md
```

### Testing
test files located at:
```
# absolute path
/Users/stian/Developer/macOS Apps/v2.5/TestFiles
```

These documents contain:
- Analysis of 4 competitor Quick Look extensions (QLStephen, QLMarkdown, SourceCodeSyntaxHighlight)
- Why dotViewer v1 is slow (JavaScript-based highlighting via HighlightSwift)
- Architecture patterns that make competitors fast (native C/C++, XPC services)
- Code examples from competitor source code

**Do not proceed without reading and understanding these documents.**

---

## Project Overview

### What We're Building
**dotViewer** - A macOS Quick Look extension for developers that previews:
- Source code files with syntax highlighting
- Dotfiles and config files (`.gitignore`, `.env`, `.bashrc`, etc.)
- Markdown files with raw/rendered toggle
- Any text-based file
- Any unknown filetype file


### Why We're Rewriting
The current v1.0 uses **HighlightSwift** (JavaScript via JavaScriptCore) for syntax highlighting. This is **10-100x slower** than native C/C++ libraries used by competitors. Files >4KB appear slow, files >15KB take seconds.

### The Goal
Rebuild dotViewer with **blazing fast performance** using native highlighting, matching or exceeding competitor speed while keeping the exact same UI/UX and features.

---

## Architecture Decision: Fresh Project

**Create a brand new Xcode project.** Do not modify the existing codebase.

Reasons:
1. Clean architecture from the start
2. No legacy JavaScript highlighting code
3. Proper XPC service integration from day one
4. No risk of copying broken patterns
5. Fresh Swift 6 / macOS 15+ patterns

The existing codebase will serve as **UI/UX reference only**.

---

## Target Architecture (Based on Competitor Research)

### Project Structure
```
dotViewer/                          # Main app (settings UI)
├── App/
│   ├── dotViewerApp.swift          # App entry point
│   ├── ContentView.swift           # Main navigation
│   ├── StatusView.swift            # Extension status & onboarding
│   ├── FileTypesView.swift         # File type management
│   └── SettingsView.swift          # User preferences
├── Models/
│   ├── FileType.swift              # File type definitions
│   ├── Theme.swift                 # Theme enum (not strings!)
│   └── Settings.swift              # Settings model
└── Utilities/
    └── ExtensionStatusChecker.swift

QuickLookExtension/                 # Quick Look extension
├── PreviewProvider.swift           # QLPreviewProvider entry point (data-based preview)
├── PreviewView.swift               # SwiftUI preview rendering
└── Info.plist                      # UTI declarations

HighlightXPC/                       # XPC service for highlighting (NEW!)
├── main.swift                      # XPC service entry
├── HighlightService.swift          # XPC protocol implementation
├── NativeHighlighter.swift         # Native C/C++ wrapper OR Tree-sitter
└── HighlightXPC.entitlements

Shared/                             # Shared framework
├── HighlightProtocol.swift         # XPC communication protocol
├── FileTypeRegistry.swift          # O(1) file type lookups
├── LanguageDetector.swift          # Language detection
├── ThemeColors.swift               # Theme color definitions
└── SharedSettings.swift            # App Group settings
```

### Key Architectural Decisions

1. **XPC Service for Highlighting**
   - Like SourceCodeSyntaxHighlight
   - Isolates heavy processing from Quick Look UI
   - Can be killed without affecting Finder
   - Memory released after preview closes

2. **Native Highlighting Engine**
   - **Option A:** Tree-sitter (modern, used by GitHub/VS Code)
   - **Option B:** highlight C++ library (used by SourceCodeSyntaxHighlight)
   - **NOT JavaScript** - this is the whole point of the rewrite

3. **100KB Default File Limit**
   - Match QLStephen's proven default
   - User configurable via settings

4. **App Groups for IPC**
   - Settings shared between app and extension
   - Same pattern as v1 (this works fine)

5. **Extension Registration Is Not Optional**
   - The Quick Look preview/thumbnail targets must have a valid `NSExtension` dictionary in `Info.plist` (principal class + supported content types).
   - For **data-based previews** (`QLPreviewReply`), the preview extension principal class should subclass **`QLPreviewProvider`** and implement `providePreview(for:completionHandler:)`.
   - On macOS 15+, many code/script UTIs require an **exact** match in `QLSupportedContentTypes` (e.g. `public.python-script`, `com.netscape.javascript-source`, `public.swift-source`). Do not rely on conformance to `public.source-code` / `public.text`.
     - Debug with: `mdls -name kMDItemContentType <file>`
     - Keep the list in sync via: `./scripts/dotviewer-gen-ql-content-types.sh`
   - The preview/thumbnail extensions must be sandboxed and have the correct entitlements, otherwise they may not be discovered/instantiated on macOS 15+.
     - Preview/Thumbnail: `com.apple.security.app-sandbox`, `com.apple.security.files.user-selected.read-only`, `com.apple.security.application-groups`
     - Main app: `com.apple.security.application-groups` (if sharing settings)
   - If the project uses **XcodeGen**, don't hand-edit generated `Info.plist`/`*.entitlements` files — put the `NSExtension` dictionaries and entitlements in `project.yml`.

---

## Features to Implement (Exact Parity with v1)

### Quick Look Extension Features

1. **Syntax Highlighting**
   - 50+ languages support
   - Multiple color themes (10 themes)
   - Instant rendering (<100ms for typical files)

2. **Markdown Support**
   - Raw markdown view with syntax highlighting
   - Rendered markdown view (Typora-inspired)
   - Toggle between raw and rendered

3. **File Info Header**
   - Language badge
   - Line count
   - File size
   - Copy to clipboard button

4. **Security Warnings**
   - Banner for `.env` and sensitive files
   - Visual warning about API keys/secrets

5. **Truncation Handling**
   - Graceful truncation for large files
   - Warning banner when truncated

6. **Line Numbers**
   - Optional (user preference)
   - Efficient rendering (single Text view, not per-line)

### Main App Features

1. **Status View**
   - Extension enable/disable status
   - Quick stats (built-in types, custom types, disabled)
   - Onboarding steps
   - GitHub link

2. **File Types View**
   - Categorized list (7 categories)
   - Search functionality
   - Toggle individual types on/off
   - Add custom extensions
   - Show file count per category

3. **Settings View**
   - Theme selection dropdown
   - Font size slider (10-20pt range)
   - Show line numbers toggle
   - Max file size slider (10KB-500KB+)
   - Show truncation warning toggle
   - Show file info header toggle
   - Markdown preview mode (Raw/Rendered)
   - Preview all file types toggle
   - Theme preview code snippet
   - Danger zone: Uninstall button

### File Type Categories (100 total)
1. **Web Development** (18 types) - JS, TS, JSX, TSX, HTML, CSS, SCSS, Vue, Svelte, etc.
2. **Systems Languages** (17 types) - Swift, C, C++, Rust, Go, Java, Kotlin, etc.
3. **Scripting** (17 types) - Python, Ruby, PHP, Perl, Lua, etc.
4. **Data & Config** (19 types) - JSON, YAML, TOML, XML, INI, etc.
5. **Shell & Terminal** (13 types) - Bash, Zsh, Fish, etc.
6. **Documentation** (9 types) - Markdown, RST, AsciiDoc, etc.
7. **Dotfiles** (7 types) - .gitignore, .env, .editorconfig, etc.

### Themes (10 total)
1. Auto (system appearance)
2. Atom One Light
3. Atom One Dark
4. GitHub Light
5. GitHub Dark
6. Xcode Light
7. Xcode Dark
8. Solarized Light
9. Solarized Dark
10. Tokyo Night
11. Blackout (pure dark)

---

## UI/UX Specification

### Design Language
- **Style:** Native macOS, SwiftUI
- **Feel:** Clean, minimal, developer-focused
- **Colors:** Blue accent (#007AFF), dark sidebar, content area adapts to theme

### Main App Window
- **Size:** ~800x600 default, resizable
- **Layout:** Sidebar navigation + content area
- **Sidebar:** Dark background (#1E1E1E), blue selection highlight

### Navigation Items
```
☑️ Status      (checkmark icon)
📄 File Types  (document icon)
⚙️ Settings    (gear icon)
```

### Status View Layout
```
┌─────────────────────────────────────────┐
│              [Eye Logo]                  │
│              dotViewer                   │
│    Quick Look for Source Code & Dotfiles │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Enable Quick Look Extension        │ │
│  │ Follow these steps to enable...    │ │
│  │                                    │ │
│  │ 1. Click "Open Extension Settings" │ │
│  │ 2. Click "Quick Look" in sidebar   │ │
│  │ 3. Enable "dotViewer" checkbox     │ │
│  │ 4. Try previewing a file           │ │
│  │                                    │ │
│  │  [Open Extension Settings]         │ │
│  └────────────────────────────────────┘ │
│                                          │
│           Quick Stats                    │
│    100        0          0               │
│  Built-in  Custom    Disabled            │
│                                          │
│           How to Use                     │
│  1. Select any code file in Finder       │
│  2. Press Space to Quick Look            │
│  3. View syntax-highlighted preview      │
│                                          │
│  v1.0                      GitHub        │
└─────────────────────────────────────────┘
```

### File Types View Layout
```
┌─────────────────────────────────────────┐
│ [Search file types...]    [+ Add Custom]│
│                                          │
│ > 🌐 Web Development                  18 │
│ > 💻 Systems Languages                17 │
│ > </> Scripting                       17 │
│ > 📄 Data & Config                    19 │
│ > 🖥️ Shell & Terminal                 13 │
│ > 📝 Documentation                     9 │
│ v ⚙️ Dotfiles                          7 │
│   ┌────────────────────────────────────┐│
│   │ 🔵 Git Ignore                      ││
│   │    .gitignore                      ││
│   │ 🔵 Git Config                      ││
│   │    .gitconfig, .gitattributes      ││
│   │ 🔵 Environment                     ││
│   │    .env, .env.local, .env.dev      ││
│   └────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### Settings View Layout
```
┌─────────────────────────────────────────┐
│ Appearance                               │
│                                          │
│ Theme     [Blackout            ▼]        │
│ Font Size [────●────────────] 13pt      │
│ ☐ Show Line Numbers                      │
│                                          │
│ Preview Limits                           │
│                                          │
│ Max File Size [●────────────] 200 KB    │
│ Files larger than this will be truncated │
│ ☑️ Show Truncation Warning               │
│                                          │
│ Preview UI                               │
│                                          │
│ ☑️ Show File Info Header                 │
│ Markdown Preview [Raw Code|Rendered]     │
│ ☑️ Preview All File Types                │
│                                          │
│ Theme Preview                            │
│ ┌────────────────────────────────────┐  │
│ │ // Example code preview            │  │
│ │ func greet(name: String) -> String │  │
│ │     return "Hello, \(name)!"       │  │
│ │ }                                  │  │
│ └────────────────────────────────────┘  │
│                                          │
│ Danger Zone                              │
│ ┌────────────────────────────────────┐  │
│ │ Remove dotViewer from your system  │  │
│ │    [🗑️ Uninstall dotViewer]        │  │
│ └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Quick Look Preview Layout
```
┌─────────────────────────────────────────┐
│ ≡  [</> Raw] [Markdown] 32 lines • 553b 📋│
├─────────────────────────────────────────┤
│ # Task List Test File                    │
│                                          │
│ This file tests TaskItem UUID stability. │
│                                          │
│ ## Sprint Backlog                        │
│                                          │
│ - [x] Implement syntax highlighting      │
│ - [x] Add theme support                  │
│ - [ ] Fix progressive rendering          │
│                                          │
│ ## Code Reference                        │
│                                          │
│ ```swift                                 │
│ struct TaskItem: Identifiable {          │
│     let id: UUID                         │
│     let isChecked: Bool                  │
│     let text: String                     │
│ }                                        │
│ ```                                      │
└─────────────────────────────────────────┘
```

### Color Palette
```swift
// Sidebar
sidebarBackground: #1E1E1E
sidebarText: #FFFFFF (primary), #8E8E93 (secondary)
selectionBackground: #007AFF
selectionText: #FFFFFF

// Content Area
contentBackground: Theme-dependent
accentColor: #007AFF (system blue)
dangerColor: #FF3B30 (system red)

// Badges
languageBadge: Blue background, blue text
toggleOn: #34C759 (system green) or #007AFF
toggleOff: #8E8E93 (gray)
```

---

## Performance Requirements

### Target Benchmarks
| Metric | Target | Current v1 |
|--------|--------|------------|
| 1KB file | <50ms | ~100ms |
| 10KB file | <100ms | ~500ms |
| 50KB file | <200ms | 2-5 seconds |
| 100KB file | <500ms | 5-10 seconds |

### Non-Negotiable Performance Rules
1. **Never block the UI thread** for highlighting
2. **100KB default limit** (like QLStephen)
3. **XPC service timeout** - kill after 3 seconds
4. **Progressive rendering** - show content immediately, highlight async
5. **Instant plain text fallback** - if highlighting fails, show plain text

---

## Implementation Phases

### Phase 1: Project Setup & Core Architecture
1. Create new Xcode project with 3 targets:
   - Main app (SwiftUI)
   - Quick Look extension
   - XPC service
2. Set up App Groups for settings sharing
3. Create XPC protocol for highlighting
4. Implement basic file reading in extension

### Phase 2: Native Highlighting Engine
1. Research and choose: Tree-sitter vs highlight C++
2. Integrate chosen library via SPM or manual integration
3. Create Swift wrapper for native library
4. Implement basic highlighting for 5 test languages

### Phase 3: Quick Look Extension
1. Implement PreviewProvider (QLPreviewProvider)
2. Create PreviewView (SwiftUI)
3. Connect to XPC service
4. Implement file size limits and truncation
5. Add timeout protection

### Phase 4: Main App UI
1. Implement StatusView (exact copy of v1)
2. Implement FileTypesView with categories
3. Implement SettingsView with all options
4. Connect to SharedSettings

### Phase 5: Markdown Support
1. Implement raw markdown highlighting
2. Implement rendered markdown view
3. Add toggle functionality

### Phase 6: Polish & Testing
1. Add all 100 file types
2. Add all 10 themes
3. Performance testing
4. Edge case handling

---

## Reference Code from Competitors

### XPC Service Pattern (from SourceCodeSyntaxHighlight)
```swift
// Protocol definition
@objc protocol HighlightServiceProtocol {
    func highlight(
        code: String,
        language: String,
        theme: String,
        reply: @escaping (Data?, Error?) -> Void
    )
}

// Connection setup
let connection = NSXPCConnection(serviceName: "com.yourapp.HighlightXPC")
connection.remoteObjectInterface = NSXPCInterface(with: HighlightServiceProtocol.self)
connection.resume()

// Usage
let service = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
    // Handle error, fall back to plain text
}
service.highlight(code: code, language: "swift", theme: "atomOneDark") { data, error in
    // Use highlighted result
}
```

### File Size Limiting (from QLStephen)
```swift
// Always read truncated data
let maxSize = 102_400 // 100KB default
let handle = try FileHandle(forReadingFrom: url)
let data = handle.readData(ofLength: maxSize)
handle.closeFile()

let isTruncated = fileSize > maxSize
```

### Early Exit Pattern (from all competitors)
```swift
func preparePreviewOfFile(at url: URL, completionHandler: @escaping (Error?) -> Void) {
    // Check 1: Cancellation
    guard !QLPreviewRequestIsCancelled(request) else {
        completionHandler(nil)
        return
    }

    // Check 2: File exists
    guard FileManager.default.fileExists(atPath: url.path) else {
        completionHandler(PreviewError.fileNotFound)
        return
    }

    // Check 3: Not binary
    guard !isBinaryFile(at: url) else {
        completionHandler(PreviewError.binaryFile)
        return
    }

    // Proceed with preview...
}
```

---

## Files to Study

### In the Repository
```
QUICKLOOK_PERFORMANCE_RESEARCH.md  # Competitor analysis
DOTVIEWER_VS_COMPETITORS_ANALYSIS.md  # Detailed comparison
```

### Competitor Source Code (External)
```
https://github.com/whomwah/qlstephen
- QuickLookStephenProject/GeneratePreviewForURL.m (file size handling)

https://github.com/sbarex/SourceCodeSyntaxHighlight
- SyntaxHighlightRenderXPC/ (XPC service pattern)
- highlight-wrapper/wrapper_highlight.cpp (C++ integration)

https://github.com/sbarex/QLMarkdown
- QLExtension/ (Quick Look extension)
- Uses cmark-gfm (C library) for markdown
```

---

## Success Criteria

### Must Have
- [ ] Preview appears in <200ms for 50KB files
- [ ] All 100 file types supported
- [ ] All 10 themes working
- [ ] Markdown raw/rendered toggle
- [ ] Settings persist between app and extension
- [ ] File type enable/disable working
- [ ] XPC service isolates highlighting
- [ ] Graceful timeout fallback to plain text

### Nice to Have
- [ ] Caching for recently viewed files
- [ ] Custom file type additions
- [ ] Search in file types view

### Non-Goals (for v2.0)
- Thumbnail generation
- Printing support
- Export functionality

---

## Getting Started Commands

```bash
# Create new project
# Use Xcode: File > New > Project > macOS > App
# Add Quick Look Extension target
# Add XPC Service target

# Or clone and start fresh
cd ~/Projects
mkdir dotViewer-v2
cd dotViewer-v2
# Create Xcode project here

# Reference the old repo for UI/UX only
# Old repo: ~/path/to/old/dotViewer
```

---

## Final Notes

### What to Keep from v1
- UI/UX design (it's good!)
- File type categories and structure
- Theme names and color palettes
- Settings options and defaults
- App icon and branding

### What to Throw Away from v1
- HighlightSwift dependency (JavaScript - too slow)
- All syntax highlighting code
- Current PreviewContentView (1371 lines of spaghetti)
- Inline highlighting in SwiftUI views

### What's New in v2
- XPC service architecture
- Native C/C++ or Tree-sitter highlighting
- Clean separation of concerns
- Type-safe theme enum (not strings)
- Proper error handling

---

**Copy this entire document and paste it at the start of a new Claude Code session. The AI will have full context to rebuild dotViewer with blazing fast performance.**

---

*Document created: 2026-02-02*
*For use with: Claude Code (claude-3.5-sonnet or newer)*
*Repository: https://github.com/Stianlars1/dotViewer*
