---
phase: P3-persistent-cache
plan: 02
type: execute
wave: 2
depends_on: ["P3-01"]
files_modified:
  - QuickLookPreview/PreviewContentView.swift
  - QuickLookPreview/PreviewViewController.swift
autonomous: true
---

<objective>
Integrate the two-tier cache with the highlighting flow and verify persistence across QuickLook restarts.

Purpose: Connect the new cache system to the actual code paths and verify that highlighted content persists across QuickLook XPC terminations.

Output: Working persistent cache, files only need highlighting ONCE.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/milestones/v1.1-performance-ROADMAP.md
@.planning/phases/P3-persistent-cache/P3-01-SUMMARY.md
@QuickLookPreview/PreviewContentView.swift
@QuickLookPreview/PreviewViewController.swift
@Shared/HighlightCache.swift
@Shared/SharedSettings.swift
</context>

<tasks>

<task type="auto">
  <name>Task 1: Update PreviewViewController to use new cache API</name>
  <files>QuickLookPreview/PreviewViewController.swift</files>
  <action>
Update the cache lookup in `preparePreviewOfFile` to use the new cache API that includes theme.

Find the cache check section (around line 121-126) and update:

**Current code:**
```swift
// Check cache for pre-highlighted content
var cachedHighlight: AttributedString? = nil
let effectiveLineCount = lineTruncated ? maxPreviewLines : totalLineCount
if let modDate = modDate {
    cachedHighlight = HighlightCache.shared.get(path: url.path, modDate: modDate)
}
```

**New code:**
```swift
// Check cache for pre-highlighted content (includes theme for invalidation)
var cachedHighlight: AttributedString? = nil
let effectiveLineCount = lineTruncated ? maxPreviewLines : totalLineCount
if let modDate = modDate {
    let theme = SharedSettings.shared.selectedTheme
    cachedHighlight = HighlightCache.shared.get(
        path: url.path,
        modDate: modDate,
        theme: theme
    )
    if cachedHighlight != nil {
        NSLog("[dotViewer PERF] Cache HIT in preparePreviewOfFile - skipping highlight")
    }
}
```

This ensures the cache key includes the theme, so changing themes invalidates the cache.
  </action>
  <verify>Build succeeds</verify>
  <done>PreviewViewController uses new theme-aware cache API</done>
</task>

<task type="auto">
  <name>Task 2: Update PreviewContentView to use new cache API</name>
  <files>QuickLookPreview/PreviewContentView.swift</files>
  <action>
Update the highlighting flow to use the new cache API.

**In highlightCode() function:**

1. Update cache read (around line 160-167):
```swift
// Check cache first (memory + disk)
if let modDate = state.modificationDate {
    let theme = SharedSettings.shared.selectedTheme
    if let cached = HighlightCache.shared.get(
        path: state.fileURL?.path ?? "",
        modDate: modDate,
        theme: theme
    ) {
        NSLog("[dotViewer PERF] highlightCode - using cached content")
        await MainActor.run {
            highlightedContent = cached
            withAnimation(.easeIn(duration: 0.15)) {
                isReady = true
            }
        }
        return
    }
}
```

2. Update cache write after successful highlighting (around line 267-272):
```swift
// Cache the result (memory + disk)
if let modDate = state.modificationDate, let filePath = state.fileURL?.path {
    let theme = SharedSettings.shared.selectedTheme
    HighlightCache.shared.set(
        path: filePath,
        modDate: modDate,
        theme: theme,
        highlighted: highlighted
    )
    NSLog("[dotViewer PERF] highlightCode - cached result for future use")
}
```

Also update any other cache interactions (markdown highlighting, etc.) to use the new API.
  </action>
  <verify>Build succeeds</verify>
  <done>PreviewContentView uses new theme-aware cache API for read and write</done>
</task>

<task type="auto">
  <name>Task 3: Verify cache persistence across QuickLook restarts</name>
  <files>N/A</files>
  <action>
Test that the cache survives QuickLook XPC termination:

1. Build and install:
   ```bash
   xcodebuild -scheme dotViewer -configuration Debug build
   APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "dotViewer.app" -type d 2>/dev/null | head -1)
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "$APP_PATH"
   killall QuickLookUIService 2>/dev/null || true
   ```

2. Start log monitoring:
   ```bash
   log stream --predicate 'message CONTAINS "[dotViewer"' --style compact
   ```

3. First preview of Info.plist:
   - Press Space on Info.plist
   - Should see: "Cache MISS", then highlighting, then "cached result for future use"
   - Note the highlighting time

4. Second preview (same file):
   - Press Escape, then Space again
   - Should see: "Cache HIT" (memory cache)
   - Should be nearly instant

5. Kill QuickLook XPC and test again:
   ```bash
   killall QuickLookUIService
   # Wait 2 seconds
   ```
   - Press Space on Info.plist again
   - Should see: "Disk HIT, promoting to memory"
   - Should be fast (only disk read, no highlighting)

6. Verify disk cache location:
   ```bash
   ls -la ~/Library/Group\ Containers/group.no.skreland.dotViewer/Library/Caches/HighlightCache/
   ```
   Should show cached files with SHA256 names.

7. Document results in terminal output.
  </action>
  <verify>
- First view: Cache MISS, highlighting runs
- Second view (same process): Memory HIT
- After XPC kill: Disk HIT (no re-highlighting)
- Cache files visible in App Groups container
  </verify>
  <done>
- Cache persistence verified
- Memory tier working
- Disk tier surviving XPC restarts
- Performance improvement documented
  </done>
</task>

<task type="auto">
  <name>Task 4: Measure and document performance improvement</name>
  <files>.planning/phases/P3-persistent-cache/CACHE_RESULTS.md</files>
  <action>
Create a results document comparing performance before and after cache:

```markdown
# Cache Performance Results

## Test Environment
- macOS: [version]
- Date: 2026-01-21

## Test File: Info.plist
- Size: ~50KB
- Lines: 1940

## Results

### Before Persistent Cache (from P1 Diagnostics)
- First view: [X]ms
- Second view (same process): [X]ms (memory cache)
- After XPC restart: [X]ms (had to re-highlight)

### After Persistent Cache
- First view: [X]ms (cache miss, full highlight)
- Second view (same process): [X]ms (memory hit)
- After XPC restart: [X]ms (disk hit)

## Improvement
- XPC restart scenario: [X]ms → [X]ms ([X]% faster)
- Effective "highlight once" achieved: YES/NO

## Cache Statistics
- Cache location: ~/Library/Group Containers/group.no.skreland.dotViewer/Library/Caches/HighlightCache/
- Files cached: [X]
- Total size: [X]KB

## Conclusion
[Summary of whether cache goals were met]
```
  </action>
  <verify>CACHE_RESULTS.md exists with measurements</verify>
  <done>
- Performance before/after documented
- Cache persistence verified and measured
- Results show "highlight once" achieved
  </done>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] `xcodebuild -scheme dotViewer -configuration Debug build` succeeds
- [ ] Cache HIT on second view of same file
- [ ] Disk HIT after QuickLook XPC restart (no re-highlighting)
- [ ] Cache files visible in App Groups container
- [ ] CACHE_RESULTS.md documents improvement
</verification>

<success_criteria>

- All tasks completed
- All verification checks pass
- Files only need highlighting ONCE (ever)
- Cache survives QuickLook XPC termination
- Measurable performance improvement documented
  </success_criteria>

<output>
After completion, create `.planning/phases/P3-persistent-cache/P3-02-SUMMARY.md`
</output>
