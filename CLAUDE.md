# dotViewer - Claude Code Context

**Last Updated:** 2026-02-02
**Project:** macOS Quick Look Extension for developer files

---

## Quick Context

dotViewer is a Quick Look extension that previews dotfiles, config files, and source code with syntax highlighting. **It's currently slow** because it uses a JavaScript-based syntax highlighter.

## The Core Performance Problem

```
ROOT CAUSE: HighlightSwift uses highlight.js executed via JavaScriptCore
IMPACT: 10-100x slower than native C/C++ libraries used by competitors
SYMPTOMS: Files > 4KB appear slow, files > 15-20KB take SECONDS
```

## Key Research Documents

1. `QUICKLOOK_PERFORMANCE_RESEARCH.md` - Analysis of competitor extensions (QLStephen, QLMarkdown, SourceCodeSyntaxHighlight)
2. `DOTVIEWER_VS_COMPETITORS_ANALYSIS.md` - Detailed comparison and recommendations
3. `.planning/codebase/CONCERNS.md` - Known tech debt and issues

---

## Architecture Overview

```
dotViewer/                    # Main app (settings UI)
├── ContentView.swift         # Settings management

QuickLookPreview/             # Quick Look extension (the bottleneck)
├── PreviewViewController.swift   # Entry point, file reading
├── PreviewContentView.swift      # Rendering, highlighting calls
├── MarkdownWebView.swift         # Markdown rendering
└── MarkdownStyles.swift          # Markdown styling

Shared/                       # Shared code
├── SyntaxHighlighter.swift   # ❌ PROBLEM: Uses HighlightSwift (JavaScript)
├── SharedSettings.swift      # App Group settings
├── FileTypeRegistry.swift    # O(1) file type lookups
├── LanguageDetector.swift    # Language detection
├── HighlightCache.swift      # LRU cache (20 entries)
└── ThemeManager.swift        # Theme colors
```

## Critical Files for Performance Work

| File | Purpose | Performance Impact |
|------|---------|-------------------|
| `Shared/SyntaxHighlighter.swift` | **Calls HighlightSwift** | PRIMARY BOTTLENECK |
| `QuickLookPreview/PreviewContentView.swift` | Rendering, timeout logic | Has 2s timeout, 2000 line limit |
| `Shared/SharedSettings.swift` | File size limit (500KB default) | TOO HIGH for JS engine |

---

## Current Performance Mitigations

Already implemented (but insufficient):
1. **File size limit:** 500KB (too high)
2. **Line limit:** 2000 lines skips highlighting
3. **Timeout:** 2 seconds via TaskGroup
4. **Caching:** LRU cache with 20 entries
5. **Skip plaintext:** Files without language skip highlighting

---

## What Competitors Do Differently

### QLStephen (Plain Text)
- **100KB default limit** (5x lower than dotViewer)
- No syntax highlighting (just plain text)
- Uses system `QLPreviewRequestSetURLRepresentation()`

### SourceCodeSyntaxHighlight
- **Native C++ highlight library** (not JavaScript)
- **XPC service** for process isolation
- Configurable data limit via `--max-data`

### QLMarkdown
- **cmark-gfm (C library)** - renders War and Peace in 127ms
- **XPC service** for rendering
- No visible file size limit (C is fast enough)

---

## Recommended Fix Strategy

### Phase 1: Quick Fixes (Do First)
```swift
// In SharedSettings.swift, change:
return value > 0 ? value : 100_000 // 100KB default (was 500KB)

// In PreviewContentView.swift, change:
let maxLinesForHighlighting = 500 // (was 2000)

// Add early exit before line counting:
if fileSize > 50_000 { // 50KB
    // Skip highlighting entirely
}
```

### Phase 2: Replace Highlighting Engine
Options:
1. **Tree-sitter** - Modern, native, Swift bindings available
2. **highlight C++ library** - Used by SourceCodeSyntaxHighlight
3. **Custom regex-based** - Already partially implemented for markdown

### Phase 3: XPC Architecture (Optional)
- Add XPC service like SourceCodeSyntaxHighlight
- Isolate heavy processing
- Enable crash recovery

---

## Code Examples from Competitors

### QLStephen File Size Handling
```objc
// DEFAULT_MAX_FILE_SIZE = 102400 (100KB)
[myFile readDataOfLength:maxFileSize]
```

### SourceCodeSyntaxHighlight XPC Setup
```swift
let connection = NSXPCConnection(serviceName: "XPCLightRenderService")
connection.remoteObjectInterface = NSXPCInterface(with: XPCLightRenderServiceProtocol.self)
```

### Your Current Highlighting (THE PROBLEM)
```swift
// SyntaxHighlighter.swift - Uses JavaScript
import HighlightSwift

struct SyntaxHighlighter: Sendable {
    private let highlight = Highlight()  // JavaScript via JavaScriptCore

    func highlight(code: String, language: String?) async throws -> AttributedString {
        let result = try await highlight.request(code, mode: mode, colors: colors)
        return result.attributedText
    }
}
```

---

## Testing Performance Changes

### Manual Test Files
Create test files of various sizes:
- `test_1kb.js` - Should be instant
- `test_10kb.js` - Should be <500ms
- `test_50kb.js` - Should be <1s (currently slow)
- `test_100kb.js` - Should show truncation warning

### What to Measure
1. Time from spacebar to content visible
2. Memory usage during preview
3. CPU usage during highlighting

---

## Dependencies

| Package | Purpose | Notes |
|---------|---------|-------|
| **HighlightSwift** | Syntax highlighting | PROBLEM - uses JavaScript |
| SwiftUI | UI rendering | Fine |
| Quartz | Quick Look framework | Fine |

---

## Common Commands

```bash
# Build and run
open dotViewer.xcodeproj
# Cmd+R to build

# Reset Quick Look cache (for testing)
qlmanage -r

# Test Quick Look preview
qlmanage -p /path/to/file.js

# View logs
log stream --predicate 'subsystem == "com.stianlars1.dotViewer"'
```

---

## Next Steps Prompt

Use this prompt to continue performance improvements:

```
Continue fixing dotViewer's performance issues. Based on the research in
DOTVIEWER_VS_COMPETITORS_ANALYSIS.md:

1. First, apply the Phase 1 quick fixes:
   - Reduce maxFileSize to 100KB in SharedSettings.swift
   - Reduce maxLinesForHighlighting to 500 in PreviewContentView.swift
   - Add file size-based early exit before line counting

2. Then, research Tree-sitter as a replacement for HighlightSwift:
   - Find Swift bindings for Tree-sitter
   - Evaluate implementation complexity
   - Create a simple benchmark

Show me the specific changes needed.
```

---

## Reference Links

### Competitor Source Code
- QLStephen: https://github.com/whomwah/qlstephen
- QLMarkdown: https://github.com/sbarex/QLMarkdown
- SourceCodeSyntaxHighlight: https://github.com/sbarex/SourceCodeSyntaxHighlight

### Native Highlighting Libraries
- Tree-sitter: https://tree-sitter.github.io/tree-sitter/
- highlight: http://www.andre-simon.de/doku/highlight/en/highlight.php
- cmark-gfm: https://github.com/github/cmark-gfm

### Key Files to Study
- `sbarex/SourceCodeSyntaxHighlight/highlight-wrapper/wrapper_highlight.cpp`
- `sbarex/SourceCodeSyntaxHighlight/SyntaxHighlightRenderXPC/`
- `whomwah/qlstephen/QuickLookStephenProject/GeneratePreviewForURL.m`

---

*This file provides context for Claude Code sessions working on dotViewer.*
