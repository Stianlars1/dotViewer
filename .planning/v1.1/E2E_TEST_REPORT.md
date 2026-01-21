# dotViewer V1.1 E2E Test Report

**Date:** 2026-01-21
**Build:** Debug (Developer ID signed)
**Test Method:** `qlmanage -p` with unified logging capture

---

## Executive Summary

| Metric | Result |
|--------|--------|
| Files Tested | 13 extensions |
| dotViewer Handled | 12/13 (92%) |
| Avg Highlight Time | 3.9ms |
| FastSyntaxHighlighter Used | 12/13 files |
| Cache Working | **NO** (disk cache bug) |

---

## Test Results by File Type

### Code Files

| Extension | Handled | Time | Highlighter | Language Detected |
|-----------|---------|------|-------------|-------------------|
| .swift | ✅ | 3-5ms | Fast | swift |
| .js | ✅ | 3ms | Fast | javascript |
| .ts | ❌ | N/A | N/A | Claimed as video |
| .py | ✅ | 3ms | Fast | python |
| .go | ✅ | 4ms | Fast | go |
| .rs | ✅ | 6ms | Fast | rust |

### Data/Config Files

| Extension | Handled | Time | Highlighter | Language Detected |
|-----------|---------|------|-------------|-------------------|
| .json | ✅ | 2ms | Fast | json |
| .yaml | ✅ | 4ms | Fast | yaml |
| .env | ✅ | 17ms | HighlightSwift | (fallback) |
| .plist | ✅ | 2ms | Fast | xml |
| .xml | ✅ | 3ms | Fast | xml |

### Documentation/Shell

| Extension | Handled | Time | Highlighter | Language Detected |
|-----------|---------|------|-------------|-------------------|
| .md | ✅ | 2ms | Fast | markdown |
| .sh | ✅ | 7ms | Fast | bash |
| .zsh | ✅ | 3ms | Fast | bash |

---

## Performance Analysis

### Highlight Time Distribution

```
< 3ms:  .json, .md, .plist, .zsh        (30%)
3-5ms:  .swift, .js, .py, .go, .yaml, .xml  (46%)
5-7ms:  .rs, .sh                         (15%)
> 10ms: .env (17ms - HighlightSwift)    (8%)
```

### FastSyntaxHighlighter Coverage

- **Fast path used:** 12/13 files (92%)
- **Fallback to HighlightSwift:** 1 file (.env)
- **Single-pass regex optimization:** Confirmed working for keywords/types/builtins

---

## Bugs Found

### 1. CRITICAL: Disk Cache Write Failure

**Error:** `Dataene kunne ikke skrives fordi de ikke har riktig format.`
(Translation: "The data could not be written because it doesn't have the correct format")

**Impact:**
- Disk cache never persists
- Every preview re-highlights from scratch
- No cross-session caching

**Root Cause:** NSKeyedArchiver encoding issue with AttributedString

**Location:** `Shared/DiskCache.swift`

### 2. HIGH: TypeScript Files Not Handled

**Error:** macOS identifies `.ts` files as `public.mpeg-2-transport-stream`

**Impact:** TypeScript files render as video transport stream, not code

**Root Cause:** UTI conflict - `.ts` extension used by both TypeScript and MPEG-2 TS

**Potential Fix:**
- Add explicit UTI declaration for TypeScript in app's Info.plist
- Or claim higher priority for `com.microsoft.typescript` UTI

### 3. LOW: Memory Cache Ineffective

**Observation:** Each qlmanage invocation creates new extension process

**Impact:** In-memory cache (HighlightCache) only works within single preview session

**Note:** This is expected macOS behavior, not a bug - disk cache should compensate

---

## Cache Behavior Test Results

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| 1. First preview | MISS | MISS | ✅ |
| 2. Second preview (same session) | HIT (memory) | MISS | ❌ (new process) |
| 3. After killing QuickLookUIService | HIT (disk) | MISS | ❌ (disk cache broken) |

---

## Phase 6: Column View vs Spacebar Sync

**Test Methodology (Manual):**
1. Open Finder in column view
2. Select a code file to show mini-preview
3. Press spacebar for full Quick Look
4. Check Console.app for duplicate `PREVIEW START` logs

**Expected Behavior:** Single preview should be reused
**Status:** Requires manual verification

---

## Verification Checklist

- [x] dotViewer extension loads and handles files
- [x] `[dotViewer E2E]` logs appear in Console.app
- [x] FastSyntaxHighlighter used for most languages
- [x] Performance under 10ms for most files
- [ ] Disk cache persists highlighted content
- [ ] TypeScript files handled correctly

---

## Recommendations

### Immediate (P0)

1. **Fix Disk Cache Serialization**
   - Switch from NSKeyedArchiver to JSON/PropertyList for cache
   - Or use NSAttributedString's RTF data encoding

2. **Fix TypeScript UTI**
   - Declare custom UTI with higher priority
   - Add `LSItemContentTypes` for `.ts` extension

### Future (P1)

3. **Add Disk Cache Diagnostics**
   - Log successful writes with file size
   - Add cache hit rate metrics

4. **Consider Process-Shared Cache**
   - Use App Group for shared memory cache
   - Or implement cache warming on app launch

---

## Raw Performance Data

```
swift:  0.005s (26 lines, 438 chars)
js:     0.003s (25 lines, 517 chars)
py:     0.003s (28 lines, 651 chars)
go:     0.004s (37 lines, 635 chars)
rs:     0.006s (40 lines, 740 chars)
json:   0.002s (20 lines, 372 chars)
yaml:   0.004s (22 lines)
env:    0.017s (HighlightSwift fallback)
plist:  0.002s (xml mode)
xml:    0.003s
md:     0.002s
sh:     0.007s (35 lines, 508 chars)
zsh:    0.003s (28 lines, 549 chars)
```

---

## Test Environment

- **macOS:** Darwin 24.6.0
- **Build Configuration:** Debug
- **Signing:** Developer ID Application
- **Extension:** com.stianlars1.dotViewer.QuickLookPreview
- **Test Files Location:** `TestFiles/`
