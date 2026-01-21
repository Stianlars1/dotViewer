# Performance Diagnostics

## Test Environment

- **macOS version:** 15.6 (Build 24G84)
- **Hardware:** MacBook Pro, Apple M3 Max, 36 GB RAM
- **Date:** 2026-01-21

## Instrumentation Added

Comprehensive timing logs have been added to:

1. **PreviewContentView.highlightCode()** - Main entry point
   - Function entry with file info (filename, lines, language)
   - Cache check timing (hit/miss)
   - Skip reason logging (file too large, no language, plaintext, content heuristic)
   - Highlighter path selection (FastSyntaxHighlighter vs HighlightSwift)
   - SyntaxHighlighter duration
   - Cache write timing
   - Animation trigger timing

2. **SyntaxHighlighter.highlight()** - Highlighter router
   - Language support check
   - ThemeManager color resolution timing
   - FastSyntaxHighlighter execution timing
   - HighlightSwift fallback timing
   - Mode logging (.languageAlias vs .automatic)

3. **FastSyntaxHighlighter.highlight()** - Native Swift highlighter
   - Code length and language at entry
   - Index mapping build time
   - Language patterns lookup time (with keyword/type/builtin counts)
   - Per-category timing:
     - Comments (line, block, hash, HTML)
     - Strings (single, double, backtick, multiline)
     - Numbers (decimal, hex)
     - Language-specific patterns (HTML tags, JSON keys)
     - Keywords (with count)
     - Types (with count)
     - Builtins (with count)
   - Total time

## Log Format

All logs use `NSLog()` with prefix `[dotViewer PERF]`:

```
[dotViewer PERF] highlightCode START - file: Info.plist, lines: 1940, language: xml
[dotViewer PERF] [+0.000s] cache check START
[dotViewer PERF] [+0.001s] cache check: MISS
[dotViewer PERF] [+0.001s] PATH: SyntaxHighlighter (FastSyntaxHighlighter supported: YES)
[dotViewer PERF] SyntaxHighlighter.highlight START - language: xml, codeLen: 49610 chars, fastSupported: YES
[dotViewer PERF] [SH +0.001s] ThemeManager.syntaxColors took: 0.001s
[dotViewer PERF] FastSyntaxHighlighter.highlight START - codeLen: 49610 chars, language: xml
[dotViewer PERF] [Fast +0.015s] index mapping: 0.015s
[dotViewer PERF] [Fast +0.020s] languagePatterns: 0.005s (keywords: 0, types: 0, builtins: 0)
[dotViewer PERF] [Fast +0.045s] comments: 0.025s
[dotViewer PERF] [Fast +0.100s] strings: 0.055s (multiline was: 0.000s)
[dotViewer PERF] [Fast +0.120s] numbers: 0.020s
[dotViewer PERF] [Fast +0.350s] language-specific (html/json): 0.230s  <- BOTTLENECK
[dotViewer PERF] [Fast +0.350s] keywords (0): 0.000s
[dotViewer PERF] [Fast +0.350s] types (0): 0.000s
[dotViewer PERF] [Fast +0.350s] builtins (0): 0.000s
[dotViewer PERF] FastSyntaxHighlighter.highlight DONE - total: 0.350s
```

## Key Findings

### Issue 1: Missing .plist Extension Mapping

**Location:** `Shared/LanguageDetector.swift`

`.plist` extension is NOT in `extensionMap`. This means:
1. `LanguageDetector.detect()` returns `nil` for direct extension lookup
2. Falls through to content-based detection via `detectFromContent()`
3. Content detection sees `<?xml` and returns "xml"
4. This works but adds unnecessary overhead

**Impact:** Minor - adds ~1ms for content scanning, but detection works correctly.

### Issue 2: XML/Plist Uses FastSyntaxHighlighter HTML Path

**Location:** `Shared/FastSyntaxHighlighter.swift`

For language "xml", `htmlPatterns()` is used which enables:
- `supportsHtmlTags = true` - runs `htmlTagRegex` over entire file
- `supportsHtmlComments = true` - runs `htmlCommentRegex`

The `htmlTagRegex` pattern `</?\\w+[^>]*>` is expensive for large XML files because:
1. It matches EVERY tag (thousands of matches in a 2000-line plist)
2. Each match requires AttributedString range mutation

**Impact:** MAJOR - This is likely the primary bottleneck.

### Issue 3: Per-Word Regex for Keywords/Types

**Location:** `Shared/FastSyntaxHighlighter.swift`

For each keyword/type, a new regex is compiled and run:
```swift
for keyword in patterns.keywords {
    highlightWord(in: &result, code: codeNS, word: keyword, mapping: mapping, color: colors.keyword)
}
```

For languages with many keywords (Swift has 80+), this creates 80+ regex compilations and full scans.

**Impact:** Moderate for code files, but XML/JSON have no keywords so N/A for plist.

### Issue 4: AttributedString Mutation Overhead

Each `applyHighlight()` call mutates the AttributedString:
```swift
attributed[mapping.attrIndices[startChar]..<mapping.attrIndices[endChar]].foregroundColor = color
```

For a large file with thousands of matches, this creates significant overhead.

**Impact:** MODERATE - Accumulates across all highlight phases.

### Issue 5: In-Memory Cache Lost on XPC Termination

**Location:** `QuickLookPreview/HighlightCache.swift` (if exists) or inline caching

QuickLook extensions run as XPC services that may be terminated between previews. Any in-memory cache is lost.

**Impact:** MAJOR - Every preview re-highlights even recently viewed files.

## Test Files Summary

| File | Lines | Size | Language | Highlighter Expected |
|------|-------|------|----------|---------------------|
| small-100.swift | 105 | 2.3K | swift | Fast |
| small-100.json | 93 | 1.9K | json | Fast |
| small-100.xml | 95 | 2.8K | xml | Fast |
| medium-500.swift | 386 | 8.0K | swift | Fast |
| medium-500.json | 454 | 15K | json | Fast |
| medium-500.xml | 609 | 18K | xml | Fast |
| large-2000.swift | 2106 | 57K | swift | SKIP (>2000 lines) |
| large-2000.json | 2204 | 75K | json | SKIP (>2000 lines) |
| large-2000.xml | 2859 | 96K | xml | SKIP (>2000 lines) |
| main-Info.plist | 1939 | 48K | xml (via content) | Fast |

Note: Files >2000 lines are skipped entirely and shown as plain text.

## Bottleneck Analysis

Based on code analysis, the expected bottlenecks are:

1. **HTML Tag Regex (for XML/plist)** - O(n*m) where n = file length, m = tag count
2. **AttributedString Mutations** - O(k) per mutation, k = match count
3. **Index Mapping Build** - O(n) but must iterate all characters
4. **Keyword Highlighting** - O(w*n) where w = keyword count

For a 1940-line plist file with ~2000 tags:
- Each tag requires one regex match application
- Each match requires one AttributedString mutation
- Total: ~2000 mutations minimum

## Recommendations

### Quick Wins (Phase P2)

1. **Add .plist extension mapping**
   ```swift
   "plist": "xml"
   ```
   Saves content detection overhead.

2. **Skip HTML tag highlighting for XML data files**
   Plist files are data, not markup - syntax highlighting adds visual noise without value.
   Consider a simplified "xml-data" mode that only highlights strings/numbers.

### Cache (Phase P3)

3. **Implement persistent disk cache**
   - Cache key: file path + modification date + theme hash
   - Store serialized AttributedString
   - Survives XPC termination

### Highlighter (Phase P4)

4. **Batch keyword highlighting**
   Instead of one regex per keyword, create a single alternation pattern:
   ```swift
   let pattern = "\\b(keyword1|keyword2|keyword3)\\b"
   ```
   Reduces from O(w*n) to O(n) scans.

5. **Consider WKWebView approach for large files**
   Offload highlighting to WebKit, which has highly optimized HTML/CSS rendering.

6. **Evaluate Highlightr library**
   Claims 50ms for 500 lines - would be ~200ms for 2000 lines, within target.

## Next Steps

1. Run actual QuickLook previews with Console.app open
2. Filter by subsystem "com.stianlars1.dotViewer"
3. Capture timing data for each test file
4. Update this document with measured values

---
*Generated: 2026-01-21*
*Phase: P1-diagnostics*
