---
phase: P6-integration-verification
plan: 01
type: execute
wave: 1
depends_on: ["P4-02"]
files_modified:
  - .planning/phases/P6-integration-verification/VERIFICATION_REPORT.md
autonomous: false
---

<objective>
Comprehensive verification that all performance improvements work together and meet targets.

Purpose: Final integration testing to ensure the complete solution works correctly across all scenarios before resuming App Store submission.

Output: VERIFICATION_REPORT.md confirming all targets met.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
@~/.claude/get-shit-done/references/checkpoints.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/milestones/v1.1-performance-ROADMAP.md
@.planning/phases/P1-diagnostics/DIAGNOSTICS.md
@.planning/phases/P3-persistent-cache/CACHE_RESULTS.md
@.planning/phases/P4-highlighter-evaluation/BENCHMARK_RESULTS.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Clean build and full reinstall</name>
  <files>N/A</files>
  <action>
Perform a completely clean build and install:

```bash
# 1. Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/dotViewer-*

# 2. Clean highlight cache
rm -rf ~/Library/Group\ Containers/group.no.skreland.dotViewer/Library/Caches/HighlightCache/*

# 3. Build release configuration
xcodebuild -scheme dotViewer -configuration Release build

# 4. Find and register app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "dotViewer.app" -type d 2>/dev/null | head -1)
echo "Built app: $APP_PATH"

# 5. Re-register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "$APP_PATH"

# 6. Restart QuickLook
killall QuickLookUIService 2>/dev/null || true
killall Finder

# 7. Wait for restart
sleep 3
```
  </action>
  <verify>Release build succeeds, app registered</verify>
  <done>Clean release build installed and registered</done>
</task>

<task type="auto">
  <name>Task 2: Performance verification against targets</name>
  <files>.planning/phases/P6-integration-verification/VERIFICATION_REPORT.md</files>
  <action>
Run comprehensive performance tests and document in VERIFICATION_REPORT.md:

```markdown
# Performance Verification Report

## Test Environment
- macOS: [version]
- Hardware: [Mac model]
- Build: Release
- Date: 2026-01-21

## Success Criteria Checklist

### Performance Targets

| Target | Requirement | Measured | Pass? |
|--------|-------------|----------|-------|
| Info.plist first view | <500ms | Xms | [ ] |
| Cached view (memory) | <50ms | Xms | [ ] |
| Cached view (disk, after XPC restart) | <100ms | Xms | [ ] |
| Small file (100 lines) | <100ms | Xms | [ ] |
| Medium file (500 lines) | <200ms | Xms | [ ] |

### Functional Requirements

| Requirement | Status | Notes |
|-------------|--------|-------|
| Cache persists across QuickLook restarts | [ ] | |
| Theme change invalidates cache | [ ] | |
| File modification invalidates cache | [ ] | |
| All Xcode UTIs handled | [ ] | |
| No regression in existing functionality | [ ] | |

## Detailed Test Results

### Test 1: Info.plist (1940 lines)
- First view: Xms
- Second view (memory cache): Xms
- After `killall QuickLookUIService`: Xms
- Expected: <500ms first, <100ms cached

### Test 2: Small Swift File (100 lines)
- First view: Xms
- Cached: Xms

### Test 3: Medium JSON File (500 lines)
- First view: Xms
- Cached: Xms

### Test 4: Theme Change Test
1. Preview file with theme A
2. Change theme to B in settings
3. Preview same file
4. Should re-highlight (cache invalidated): [ ] Pass / [ ] Fail

### Test 5: File Modification Test
1. Preview file
2. Modify file content
3. Preview again
4. Should re-highlight: [ ] Pass / [ ] Fail

### Test 6: Xcode UTI Verification

| File Type | UTI | Handled by dotViewer? |
|-----------|-----|----------------------|
| .entitlements | com.apple.xcode.entitlements-property-list | [ ] |
| .xcconfig | com.apple.xcode.xcconfig | [ ] |
| .xcscheme | com.apple.xcode.xcscheme | [ ] |
| .plist | com.apple.property-list | [ ] |
| .strings | com.apple.xcode.strings-text | [ ] |

## Memory Usage

| Scenario | Memory (MB) | Acceptable? |
|----------|-------------|-------------|
| Idle | X | [ ] |
| During highlighting | X | [ ] |
| After highlighting | X | [ ] |

## Conclusion

[ ] ALL TARGETS MET - Ready for App Store submission
[ ] TARGETS NOT MET - See issues below

### Issues Found (if any)
1. [Issue description]
2. [Issue description]

### Recommendations
[Any final recommendations]
```
  </action>
  <verify>VERIFICATION_REPORT.md completed</verify>
  <done>Performance verification complete</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>Complete performance optimization including:
- Persistent disk cache
- Optimized highlighting
- All Xcode UTI support
  </what-built>
  <how-to-verify>
Manual verification steps:

1. **Open Finder, navigate to a folder with code files**

2. **Test Info.plist or large XML file (~2000 lines):**
   - Press Space to preview
   - Should appear within 1 second (target: <500ms)
   - Syntax highlighting should be visible

3. **Close and reopen same file:**
   - Should be instant (cached)

4. **Kill QuickLook and test again:**
   ```bash
   killall QuickLookUIService
   ```
   - Press Space on same file
   - Should still be fast (disk cache)

5. **Test Xcode files:**
   - Preview a .entitlements file
   - Preview a .xcconfig file
   - Both should show in dotViewer with highlighting

6. **Change theme in dotViewer settings:**
   - Preview same file
   - Should show new theme colors

7. **Overall feel:**
   - Is the experience "instant"?
   - Any noticeable delays?
   - Any visual glitches?
  </how-to-verify>
  <resume-signal>Type "approved" if all tests pass, or describe any issues</resume-signal>
</task>

<task type="auto">
  <name>Task 4: Remove diagnostic logging for production</name>
  <files>QuickLookPreview/PreviewContentView.swift, Shared/SyntaxHighlighter.swift, Shared/FastSyntaxHighlighter.swift</files>
  <action>
Clean up logging for production:

1. Remove or comment out detailed timing logs:
   - Keep: Cache hit/miss logs (helpful for debugging)
   - Remove: Per-iteration benchmark logs
   - Remove: Per-section timing in FastSyntaxHighlighter

2. Keep essential logs with `[dotViewer]` prefix:
   ```swift
   // Keep these:
   NSLog("[dotViewer] Cache HIT for: \(filename)")
   NSLog("[dotViewer] Cache MISS, highlighting: \(filename)")

   // Remove these:
   // NSLog("[dotViewer PERF] index mapping: %.3fs", ...)
   // NSLog("[Benchmark] iteration X: Xms")
   ```

3. Ensure no debug prints in release build

4. Remove HighlighterBenchmark.swift from release target (keep in debug only)
  </action>
  <verify>Build succeeds, no excessive logging in release</verify>
  <done>
- Diagnostic logging cleaned up
- Production-ready build
  </done>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] Release build succeeds
- [ ] All performance targets met per VERIFICATION_REPORT.md
- [ ] Human verification passed
- [ ] No excessive logging in release
- [ ] Ready to resume App Store submission
</verification>

<success_criteria>

- All tasks completed
- All verification checks pass
- Info.plist <500ms on first view
- Cache working (memory + disk)
- All Xcode UTIs handled
- Human verification approved
- Production-ready code
  </success_criteria>

<output>
After completion, create `.planning/phases/P6-integration-verification/P6-01-SUMMARY.md`
</output>
