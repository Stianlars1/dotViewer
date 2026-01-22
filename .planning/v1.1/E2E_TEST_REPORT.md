# dotViewer V1.1 E2E Test Report

**Date:** 2026-01-21 (Updated)
**Build:** Debug (Developer ID signed)
**Test Method:** `qlmanage -p` with unified logging capture
**Test Run:** Bug Verification Round 2

---

## Executive Summary

| Metric | Previous | Current | Status |
|--------|----------|---------|--------|
| Files Tested | 13 | 14 extensions | |
| dotViewer Handled | 12/13 (92%) | 13/14 (93%) | |
| Avg Highlight Time | 3.9ms | ~4ms | ✅ |
| FastSyntaxHighlighter Used | 12/13 | 12/13 files | ✅ |
| Disk Cache Working | **NO** | **YES** | ✅ FIXED |
| TypeScript Handled | **NO** | **NO** | ❌ NOT FIXED |

---

## Bug Verification Status

### Bug 1: Disk Cache (CRITICAL) - FIXED ✅

**Previous Error:** `"Dataene kunne ikke skrives fordi de ikke har riktig format"`

**Fix Applied:** Changed cache location from App Group container to extension's own sandbox:
```
~/Library/Containers/com.stianlars1.dotViewer.QuickLookPreview/Data/Library/Application Support/HighlightCache/
```

**Verification Results:**
| Test | Expected | Actual | Status |
|------|----------|--------|--------|
| First preview (cleared cache) | MISS + Write | Cache file created | ✅ |
| Second preview (same file) | Disk HIT | No new file, same timestamp | ✅ |
| Cache directory exists | Yes | Yes (13 data files + version) | ✅ |

**Evidence:**
- 13 cache files created for 13 handled files
- Cache file timestamp unchanged on second preview (HIT behavior)
- Cache directory: `~/Library/Containers/com.stianlars1.dotViewer.QuickLookPreview/Data/Library/Application Support/HighlightCache/`

### Bug 2: TypeScript Files (.ts) - NOT FIXED ❌

**Previous Error:** macOS identifies `.ts` as `public.mpeg-2-transport-stream` (video)

**Fix Applied:** Moved `public.data` to position 0 in Info.plist QLSupportedContentTypes

**Verification Results:**
| Test | Expected | Actual | Status |
|------|----------|--------|--------|
| test.ts UTI | Any | `public.mpeg-2-transport-stream` | (macOS behavior) |
| dotViewer handles test.ts | Yes | **NO** | ❌ |
| Movie player intercepts | No | **YES** | ❌ |

**Evidence:**
- Log shows `Content type UTI: public.mpeg-2-transport-stream. Generator used: <private>`
- `got displayBundleID com.apple.qldisplay.Movie` - Movie player selected
- AVFoundation errors trying to play text as video
- Only 13 Highlight log entries for 14 files tested
- test.ts (27 lines) not appearing in logs (test.py and test.zsh both have 27 lines, only 2x 28-line entries found)

**Root Cause Analysis:**
The `public.data` approach does not override the system Movie player's claim on `public.mpeg-2-transport-stream`. Quick Look's priority system still prefers the specialized Movie player over our extension's generic `public.data` claim.

---

## Test Results by File Type

### Code Files

| Extension | Handled | Cache | Lines | Status |
|-----------|---------|-------|-------|--------|
| .swift | ✅ | ✅ | 25 | Working |
| .js | ✅ | ✅ | 24 | Working |
| .ts | ❌ | N/A | 27 | **Movie player intercepts** |
| .py | ✅ | ✅ | 27 | Working |
| .go | ✅ | ✅ | 36 | Working |
| .rs | ✅ | ✅ | 39 | Working |

### Data/Config Files

| Extension | Handled | Cache | Lines | Status |
|-----------|---------|-------|-------|--------|
| .json | ✅ | ✅ | 19 | Working |
| .yaml | ✅ | ✅ | 21 | Working |
| .env | ✅ | ✅ | 8 | Working (HighlightSwift) |
| .plist | ✅ | ✅ | 16 | Working |
| .xml | ✅ | ✅ | 16 | Working |

### Documentation/Shell

| Extension | Handled | Cache | Lines | Status |
|-----------|---------|-------|-------|--------|
| .md | ✅ | ✅ | 25 | Working |
| .sh | ✅ | ✅ | 34 | Working |
| .zsh | ✅ | ✅ | 27 | Working |

---

## Disk Cache Verification

### Cache Directory Structure
```
~/Library/Containers/com.stianlars1.dotViewer.QuickLookPreview/
  Data/Library/Application Support/HighlightCache/
    cache_version (1 byte - version marker)
    222755bd... (787 bytes - test.swift cache)
    ... (12 more cache files)
```

### Cache Behavior Confirmation
1. **Clear cache** → Directory removed
2. **First preview** → Cache file written (new timestamp)
3. **Second preview** → No change (same timestamp = HIT)

---

## Recommendations for TypeScript Fix

The `public.data` first position approach doesn't work because:
1. System Quick Look still routes `public.mpeg-2-transport-stream` to Movie player
2. Our extension never receives the file to perform content sniffing

### Alternative Approaches to Consider:

1. **App-level UTI Declaration** (Info.plist in main app)
   - Declare custom UTI for `.ts` that conforms to `public.source-code`
   - Use `UTExportedTypeDeclarations`

2. **Content-Type Override**
   - Use `QLPreviewRequestSetURLRepresentation` with forced content type
   - Requires earlier interception point

3. **Launch Services Priority**
   - Register app as handler for `.ts` with higher priority
   - May require LSHandlerRank key

4. **Finder Extension Alternative**
   - Use Finder Sync extension for file type context
   - Combined with Quick Look for preview

---

## Verification Checklist

- [x] dotViewer extension loads and handles files
- [x] `[dotViewer E2E]` logs appear in Console.app
- [x] FastSyntaxHighlighter used for most languages
- [x] Performance under 10ms for most files
- [x] **Disk cache persists highlighted content** ✅ FIXED
- [ ] TypeScript files handled correctly ❌ NOT FIXED

---

## Test Environment

- **macOS:** Darwin 24.6.0
- **Build Configuration:** Debug
- **Signing:** Developer ID Application
- **Extension:** com.stianlars1.dotViewer.QuickLookPreview
- **Test Files Location:** `TestFiles/`
- **Test Run Timestamp:** 2026-01-21 16:04:30

---

## Summary

| Bug | Previous Status | Current Status | Action |
|-----|-----------------|----------------|--------|
| Disk Cache Failure | CRITICAL | ✅ **FIXED** | Resolved |
| TypeScript .ts Files | HIGH | ❌ **NOT FIXED** | Needs different approach |

**Overall Progress:** 1/2 bugs fixed. Disk cache is now working correctly. TypeScript handling requires a different solution than the `public.data` first position approach.
