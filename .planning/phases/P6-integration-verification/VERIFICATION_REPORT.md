# Performance Verification Report

## Test Environment

- **macOS:** 15.6 (Build 24G84)
- **Hardware:** MacBook Pro, Apple M3 Max, 36 GB RAM
- **Build:** Release
- **Date:** 2026-01-21

---

## How to Verify dotViewer is Active

### Step 1: Open Console.app
```bash
open -a Console
```

### Step 2: Filter for dotViewer logs
In Console.app search bar, type:
```
dotViewer
```
Or use more specific filters:
```
[dotViewer E2E]
[dotViewer PERF]
```

### Step 3: Test a file
1. Open Finder
2. Navigate to a code file (e.g., any .swift, .json, .py file)
3. Select the file and press **Space** to preview

### Step 4: Check Console output
If dotViewer is handling the file, you'll see logs like:
```
═══════════════════════════════════════════════════════════════
[dotViewer E2E] ▶▶▶ PREVIEW START: filename.swift
═══════════════════════════════════════════════════════════════
[dotViewer PERF] highlightCode START - file: filename.swift, lines: 100, language: swift
[dotViewer PERF] SyntaxHighlighter.highlight START - language: swift, codeLen: 5000 chars
[dotViewer PERF] FastSyntaxHighlighter.highlight START - codeLen: 5000 chars, language: swift
[dotViewer PERF] FastSyntaxHighlighter.highlight DONE - total: 0.045s
[dotViewer PERF] highlightCode COMPLETE - total: 0.050s, highlighter: Fast
```

### If NO logs appear:
- Another QuickLook extension may be handling the file
- Try `qlmanage -r` to reset QuickLook
- Restart Finder: `killall Finder`
- Re-register app: `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R ~/Library/Developer/Xcode/DerivedData/dotViewer-*/Build/Products/Release/dotViewer.app`

---

## Test Files for Verification

Use files from THIS PROJECT for testing since they're guaranteed to have correct UTIs:

| File | Path | Expected Language | Lines |
|------|------|-------------------|-------|
| Swift (small) | `Shared/SyntaxHighlighter.swift` | swift | ~120 |
| Swift (medium) | `Shared/FastSyntaxHighlighter.swift` | swift | ~630 |
| Swift (large) | `QuickLookPreview/PreviewContentView.swift` | swift | ~1400 |
| JSON | `package.json` or any .json | json | varies |
| XML/Plist | `/Applications/Xcode.app/Contents/Info.plist` | xml/plist | ~2000 |

---

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| First view (cold, no cache) | <500ms | For 2000-line files |
| Memory cache hit | <50ms | Same session |
| Disk cache hit (after XPC restart) | <100ms | After `killall QuickLookUIService` |
| Small file (100 lines) | <100ms | Any language |
| Medium file (500 lines) | <200ms | Any language |

---

## Test Results

### Test 1: Swift File (FastSyntaxHighlighter.swift ~630 lines)

| Metric | Measured | Pass? |
|--------|----------|-------|
| First view (cold) | ___ms | [ ] |
| Second view (memory cache) | ___ms | [ ] |
| After killall QuickLookUIService | ___ms | [ ] |

Console output:
```
(paste relevant lines here)
```

### Test 2: XML/Plist File (Info.plist ~2000 lines)

| Metric | Measured | Pass? |
|--------|----------|-------|
| First view (cold) | ___ms | [ ] |
| Second view (memory cache) | ___ms | [ ] |
| After killall QuickLookUIService | ___ms | [ ] |

Console output:
```
(paste relevant lines here)
```

### Test 3: JSON File

| Metric | Measured | Pass? |
|--------|----------|-------|
| First view (cold) | ___ms | [ ] |
| Second view (memory cache) | ___ms | [ ] |

### Test 4: Python/JavaScript File (if available)

| Metric | Measured | Pass? |
|--------|----------|-------|
| First view (cold) | ___ms | [ ] |
| Second view (memory cache) | ___ms | [ ] |

---

## Cache Behavior Tests

### Theme Change Test
1. [ ] Preview a file with current theme
2. [ ] Change theme in dotViewer settings
3. [ ] Preview same file
4. [ ] Confirm re-highlighting occurred (should NOT be cache hit)

### File Modification Test
1. [ ] Preview a file
2. [ ] Edit the file (add a comment)
3. [ ] Preview same file again
4. [ ] Confirm re-highlighting occurred (cache invalidated)

---

## Summary Checklist

### Performance Targets
- [ ] Info.plist first view <500ms
- [ ] Cached view (memory) <50ms
- [ ] Cached view (disk) <100ms
- [ ] Small files <100ms
- [ ] Medium files <200ms

### Functional Requirements
- [ ] Cache persists across QuickLook restarts
- [ ] Theme change invalidates cache
- [ ] File modification invalidates cache
- [ ] dotViewer handles all tested file types

---

## Conclusion

[ ] **ALL TARGETS MET** - Ready for App Store submission
[ ] **TARGETS NOT MET** - See issues below

### Issues Found
1.
2.

### Recommendations


---

*Verification Date: 2026-01-21*
*Phase: P6-integration-verification*
