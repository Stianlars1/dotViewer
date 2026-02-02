# Quick Look Extension Performance Research

This document contains findings from analyzing popular macOS Quick Look extensions to understand what makes them performant and fast. The goal is to apply these insights to improve dotViewer's performance.

## Executive Summary

After analyzing **QLStephen**, **QLMarkdown**, **SourceCodeSyntaxHighlight**, and **Markdown Preview**, I've identified several key architectural patterns and performance techniques that make these extensions fast:

1. **File Size Limits with Truncation** - Critical for preventing slow loads
2. **XPC Services** - Offload heavy processing to separate processes
3. **Early Exit Patterns** - Cancel checks and validation before processing
4. **Native System Delegation** - Let the OS handle rendering when possible
5. **Lazy Initialization** - Defer expensive operations until needed
6. **Memory-Efficient Reading** - Read only what's needed, never the whole file

---

## 1. QLStephen (Plain Text Files)

**Repository:** https://github.com/whomwah/qlstephen
**Languages:** Objective-C (53.8%), C (41.5%)
**Purpose:** Preview plain text files without extensions

### Key Performance Techniques

#### 1.1 File Size Limiting (CRITICAL)
```objc
// DEFAULT_MAX_FILE_SIZE = 102,400 bytes (100KB)
// User configurable via: defaults write com.whomwah.quicklookstephen maxFileSize 102400

[myFile readDataOfLength:maxFileSize]  // Only reads first N bytes!
```

**This is the single most important technique.** QLStephen limits preview to first 100KB by default. Users can adjust, but there's ALWAYS a cap.

#### 1.2 Two Rendering Strategies
```objc
// Small files: Use full file
QLPreviewRequestSetURLRepresentation()  // Let OS handle it

// Large files: Use truncated data
QLPreviewRequestSetDataRepresentation()  // Use partial data
```

#### 1.3 Early Cancellation Check
```objc
if (QLPreviewRequestIsCancelled(request)) return noErr;  // Exit immediately
```

#### 1.4 Memory Management
```objc
@autoreleasepool {
    // All processing wrapped - automatic cleanup
}
```

#### 1.5 File Type Detection via System Calls
Uses `/usr/bin/file --mime --brief` instead of parsing file content manually - much faster for MIME detection.

---

## 2. QLMarkdown (Markdown Rendering)

**Repository:** https://github.com/sbarex/QLMarkdown
**Languages:** Swift with C libraries
**Purpose:** Render Markdown files as HTML

### Key Performance Techniques

#### 2.1 cmark-gfm Library (EXTREMELY FAST)
```
cmark can render War and Peace (500KB+) in 127 milliseconds
10,000x faster than original Markdown.pl
```

**Key insight:** They use a native C library (cmark-gfm) for markdown parsing, NOT a JavaScript or interpreted language implementation.

#### 2.2 XPC Architecture for Isolation
```
QLExtension → QLMarkdownXPCHelper → Rendering
```
XPC service runs in separate process:
- Crash isolation (preview crash doesn't kill Finder)
- Memory isolation
- Can be terminated after preview closes

#### 2.3 Dual Rendering Paths
```swift
// Legacy (pre-macOS 12): Direct WebView
preparePreviewOfFile() → WebView

// Modern (macOS 12+): Data-based (more efficient)
providePreview() → QLPreviewReply
```

#### 2.4 Anti-Flicker Pattern
```swift
// WebView hidden until content ready
webView.isHidden = true
// ... load content ...
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    self.webView.isHidden = false  // Smooth reveal
}
```

#### 2.5 Local Resource Bundling
```
Mermaid.min.js bundled locally
MathJax bundled locally
NO network requests at preview time
```

#### 2.6 Image Embedding
Instead of file system access (restricted in Quick Look sandbox), images are base64-encoded directly into HTML output.

---

## 3. SourceCodeSyntaxHighlight (Syntax Highlighting)

**Repository:** https://github.com/sbarex/SourceCodeSyntaxHighlight
**Languages:** Swift, C++, Lua
**Purpose:** Syntax highlighting for 150+ languages

### Key Performance Techniques

#### 3.1 Data Limit Setting (CRITICAL)
```
--max-data bytes    # Trims source file that exceeds size
```
Users can configure this in settings. **Zero = unlimited (not recommended).**

#### 3.2 XPC Service Architecture
```
QLExtension
    ↓
NSXPCConnection (synchronous proxy)
    ↓
SyntaxHighlightRenderXPC (separate process)
    ↓
highlight library (C++)
```

**Why this matters:** The XPC service:
- Runs in isolated process
- Automatically terminated after "some seconds" to release resources
- CPU-intensive highlighting doesn't block UI

#### 3.3 Native C++ Highlight Library
They wrap the `highlight` library (http://www.andre-simon.de/doku/highlight/en/highlight.php):
- Written in C++ with Lua configuration
- Single static generator instance (avoid repeated init)
- Fragment mode enabled (skip document wrapper)
- Preformatting disabled

#### 3.4 Lazy Initialization
```swift
lazy var themes: [HTheme] = { /* load only when accessed */ }()
lazy var languages: [String: Any] = { /* parse JSON on demand */ }()
```

#### 3.5 UTI-Based File Detection
Uses Uniform Type Identifiers instead of extension-only matching:
- More reliable than extension checking
- Leverages system's file type database

#### 3.6 RTF vs HTML Output Options
```swift
// RTF: Recommended for pre-Monterey (faster native text rendering)
// HTML: More features but requires WebView
```

#### 3.7 Early Exit for Binary Files
```swift
// Specialized paths for images, PDFs, audio, movies
// Prevents inappropriate syntax highlighting attempts
```

---

## 4. Markdown Preview (anybox.ltd)

**Source:** Closed source (Mac App Store)
**Purpose:** Quick Look for Markdown with toggle view

### Key Features (from product description)
- Toggle between raw Markdown and rendered HTML
- KaTeX for math (bundled locally)
- Mermaid for diagrams (bundled locally)
- **No network requests required**
- **Requires macOS 13+** (modern APIs only)

---

## Common Patterns Across All Extensions

### Pattern 1: FILE SIZE LIMITS
| Extension | Default Limit | Configurable |
|-----------|--------------|--------------|
| QLStephen | 100KB | Yes |
| SourceCodeSyntaxHighlight | Configurable | Yes (--max-data) |
| QLMarkdown | None visible | N/A |

### Pattern 2: XPC SERVICE ARCHITECTURE
```
Extension (sandboxed, limited)
    ↓
XPC Service (isolated, can be killed)
    ↓
Heavy Processing (syntax, rendering)
```

### Pattern 3: NATIVE LIBRARIES
| Extension | Heavy Lifting By |
|-----------|-----------------|
| QLStephen | System (QLPreviewRequest*) |
| QLMarkdown | cmark-gfm (C library) |
| SourceCodeSyntaxHighlight | highlight (C++ library) |

### Pattern 4: EARLY EXIT PATTERNS
```objc
// Check 1: Was request cancelled?
if (QLPreviewRequestIsCancelled(request)) return;

// Check 2: Is this a valid file type?
if (!isTextFile) return;

// Check 3: Is encoding valid?
if (fileEncoding == kCFStringEncodingInvalidId) return;
```

### Pattern 5: DELEGATE TO SYSTEM
```objc
// DON'T: Custom render everything
// DO: Use system APIs when possible
QLPreviewRequestSetURLRepresentation()  // Let OS render
QLThumbnailRequestSetThumbnailWithURLRepresentation()  // Let OS draw
```

---

## Critical Findings for dotViewer

Based on your description of dotViewer's performance issues:

> "files bigger than 4 kB is appearing slow. If we have files bigger than 15-20kB it takes SECONDS"

### Root Cause Analysis

1. **You likely have NO file size limit** - All fast extensions cap at 100KB+
2. **You may be reading entire files** - QLStephen only reads first N bytes
3. **Syntax highlighting may be in main thread** - Should be XPC
4. **You may be using JavaScript-based highlighter** - Native C/C++ is 10-1000x faster

### Recommended Fixes (Priority Order)

#### Fix #1: Add File Size Limit (IMMEDIATE)
```swift
let MAX_PREVIEW_SIZE = 100_000  // 100KB default

func previewFile(at url: URL) {
    let handle = try FileHandle(forReadingFrom: url)
    let data = handle.readData(ofLength: MAX_PREVIEW_SIZE)  // CRITICAL
    // ... process only this data
}
```

#### Fix #2: Truncated Preview for Large Files
```swift
if fileSize > MAX_PREVIEW_SIZE {
    // Show partial content with "... [truncated]" indicator
    // Or show file info instead of content
}
```

#### Fix #3: Consider XPC Service for Syntax Highlighting
Move syntax highlighting to XPC service:
- Isolated memory
- Can be killed without affecting Finder
- Async processing

#### Fix #4: Use Native Highlighting Library
If using JS-based highlighter (highlight.js, Prism):
- Consider using `highlight` C++ library (like SourceCodeSyntaxHighlight)
- Or use system text rendering for plain text

#### Fix #5: Implement Early Exit
```swift
// At start of preparePreviewOfFile:
guard !QLPreviewRequestIsCancelled(request) else { return }

// After reading file attributes:
guard attributes.isTextFile else {
    // Show file icon/info instead
    return
}
```

---

## Architecture Comparison

| Aspect | QLStephen | QLMarkdown | SourceCodeSyntaxHighlight | dotViewer (current) |
|--------|-----------|------------|--------------------------|---------------------|
| File size limit | 100KB | None | Configurable | None? |
| Rendering | System | WebView | WebView/RTF | ? |
| Processing | Main thread | XPC | XPC | Main thread? |
| Highlight engine | None | cmark-gfm (C) | highlight (C++) | JS-based? |

---

## Key Takeaways

1. **File size limits are non-negotiable** for good performance
2. **Native C/C++ libraries** vastly outperform JavaScript
3. **XPC services** isolate heavy work and enable resource cleanup
4. **Early exit patterns** prevent wasted processing
5. **System delegation** (QLPreviewRequest*) is optimized by Apple
6. **Memory-efficient reading** means never loading whole large files

---

## Next Steps

1. Review dotViewer's current file reading implementation
2. Identify if/where syntax highlighting bottleneck occurs
3. Implement file size limit as immediate fix
4. Consider XPC architecture for long-term stability
5. Benchmark current vs. improved performance

---

*Research conducted: 2026-02-02*
*Sources: GitHub repositories for QLStephen, QLMarkdown, SourceCodeSyntaxHighlight*
