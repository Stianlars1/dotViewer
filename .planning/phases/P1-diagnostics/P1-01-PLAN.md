---
phase: P1-diagnostics
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - QuickLookPreview/PreviewContentView.swift
  - Shared/SyntaxHighlighter.swift
  - Shared/FastSyntaxHighlighter.swift
  - .planning/phases/P1-diagnostics/DIAGNOSTICS.md
autonomous: true
---

<objective>
Add comprehensive timing instrumentation to understand exactly where time is spent during syntax highlighting.

Purpose: Before optimizing, we must measure. This phase adds detailed logging and documents baseline performance to identify the actual bottleneck(s).

Output: DIAGNOSTICS.md with baseline measurements and bottleneck analysis.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/milestones/v1.1-performance-ROADMAP.md
@.planning/CONTEXT-ISSUES.md
@QuickLookPreview/PreviewContentView.swift
@Shared/SyntaxHighlighter.swift
@Shared/FastSyntaxHighlighter.swift
@Shared/LanguageDetector.swift
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add timing instrumentation to PreviewContentView</name>
  <files>QuickLookPreview/PreviewContentView.swift</files>
  <action>
Add detailed timing logs to the `highlightCode()` function. Use `CFAbsoluteTimeGetCurrent()` for precise timing.

Add timing points at:
1. Function entry (capture start time)
2. Before cache check
3. After cache check (log hit/miss)
4. Before calling SyntaxHighlighter
5. After SyntaxHighlighter returns
6. Before setting state/animation
7. Function exit (log total time)

Format logs as:
```swift
let startTime = CFAbsoluteTimeGetCurrent()
NSLog("[dotViewer PERF] highlightCode START - file: \(state.filename), lines: \(state.lineCount), language: \(state.language ?? "nil")")

// ... at each timing point:
NSLog("[dotViewer PERF] [+%.3fs] cache check: \(cached != nil ? "HIT" : "MISS")", CFAbsoluteTimeGetCurrent() - startTime)

// ... at end:
NSLog("[dotViewer PERF] highlightCode COMPLETE - total: %.3fs", CFAbsoluteTimeGetCurrent() - startTime)
```

Also log which highlighter path is taken (FastSyntaxHighlighter vs HighlightSwift fallback).
  </action>
  <verify>Build succeeds: `xcodebuild -scheme dotViewer -configuration Debug build 2>&1 | tail -5`</verify>
  <done>Timing instrumentation added to PreviewContentView.highlightCode()</done>
</task>

<task type="auto">
  <name>Task 2: Add timing instrumentation to SyntaxHighlighter</name>
  <files>Shared/SyntaxHighlighter.swift</files>
  <action>
Add timing logs to the `highlight()` function to track:
1. Which path is taken (FastSyntaxHighlighter vs HighlightSwift)
2. Time spent in FastSyntaxHighlighter.isSupported() check
3. Time spent in FastSyntaxHighlighter.highlight()
4. Time spent in HighlightSwift fallback (if used)
5. Time spent resolving colors

Format:
```swift
NSLog("[dotViewer PERF] SyntaxHighlighter.highlight - language: \(language ?? "nil"), fastSupported: \(FastSyntaxHighlighter.isSupported(language))")
let highlightStart = CFAbsoluteTimeGetCurrent()
// ... highlighting code ...
NSLog("[dotViewer PERF] SyntaxHighlighter.highlight DONE - took: %.3fs, path: \(usedFast ? "Fast" : "HighlightSwift")", CFAbsoluteTimeGetCurrent() - highlightStart)
```
  </action>
  <verify>Build succeeds</verify>
  <done>Timing instrumentation added to SyntaxHighlighter</done>
</task>

<task type="auto">
  <name>Task 3: Add timing instrumentation to FastSyntaxHighlighter</name>
  <files>Shared/FastSyntaxHighlighter.swift</files>
  <action>
Add timing logs to understand where time is spent within FastSyntaxHighlighter:
1. Time to build index mapping
2. Time to apply comment patterns
3. Time to apply string patterns
4. Time to apply number patterns
5. Time to apply keywords (total for all keywords)
6. Time to apply types
7. Total time

Format:
```swift
NSLog("[dotViewer PERF] FastSyntaxHighlighter - code length: \(code.count) chars")
var sectionStart = CFAbsoluteTimeGetCurrent()

// After index mapping:
NSLog("[dotViewer PERF] [Fast] index mapping: %.3fs", CFAbsoluteTimeGetCurrent() - sectionStart)
sectionStart = CFAbsoluteTimeGetCurrent()

// After comments:
NSLog("[dotViewer PERF] [Fast] comments: %.3fs", CFAbsoluteTimeGetCurrent() - sectionStart)
// ... etc
```
  </action>
  <verify>Build succeeds</verify>
  <done>Timing instrumentation added to FastSyntaxHighlighter</done>
</task>

<task type="auto">
  <name>Task 4: Run baseline measurements and create DIAGNOSTICS.md</name>
  <files>.planning/phases/P1-diagnostics/DIAGNOSTICS.md</files>
  <action>
1. Build and run the app
2. Register with Launch Services and restart QuickLook:
   ```bash
   # Find built app
   APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "dotViewer.app" -type d 2>/dev/null | head -1)

   # Register and restart
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "$APP_PATH"
   killall QuickLookUIService 2>/dev/null || true
   ```

3. Create test files if not already present:
   - Small: 100 lines (Swift, JSON, XML)
   - Medium: 500 lines (Swift, JSON, XML)
   - Large: 2000 lines (Swift, JSON, XML)
   - Use existing Info.plist as XML test case

4. Preview each test file and capture console logs:
   ```bash
   log stream --predicate 'process == "com.apple.quicklook.extension.previewUI" AND message CONTAINS "[dotViewer PERF]"' --style compact
   ```

5. Document findings in DIAGNOSTICS.md with:
   - Table of baseline measurements
   - Identification of slowest operations
   - Analysis of which highlighter is used for each file type
   - Recommendations based on data

Format for DIAGNOSTICS.md:
```markdown
# Performance Diagnostics

## Test Environment
- macOS version: [version]
- Hardware: [Mac model]
- Date: 2026-01-21

## Baseline Measurements

### Small Files (100 lines)
| File Type | Language Detected | Highlighter Used | Total Time | Bottleneck |
|-----------|-------------------|------------------|------------|------------|
| test.swift | swift | Fast | Xms | - |
| test.json | json | Fast | Xms | - |
| test.xml | xml | Fast | Xms | - |

### Medium Files (500 lines)
[same table format]

### Large Files (2000 lines)
[same table format]

### Info.plist Specific
- File size: X KB
- Line count: X
- Language detected: [value]
- Highlighter used: [Fast/HighlightSwift]
- Total time: Xms

#### Timing Breakdown
- Index mapping: Xms (X%)
- Comments: Xms (X%)
- Strings: Xms (X%)
- Numbers: Xms (X%)
- Keywords: Xms (X%)
- Types: Xms (X%)

## Bottleneck Analysis

[Analysis of where time is spent]

## Recommendations

[Data-driven recommendations for optimization]
```
  </action>
  <verify>DIAGNOSTICS.md exists with baseline measurements</verify>
  <done>
- Baseline measurements captured for small/medium/large files
- Bottleneck identified and documented
- Recommendations provided based on data
  </done>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] `xcodebuild -scheme dotViewer -configuration Debug build` succeeds
- [ ] Timing logs appear in Console when previewing files
- [ ] DIAGNOSTICS.md contains baseline measurements
- [ ] Bottleneck(s) clearly identified
</verification>

<success_criteria>

- All tasks completed
- All verification checks pass
- We have quantitative data showing where time is spent
- Clear understanding of which highlighter is used for .plist files
- Actionable recommendations for next phases
  </success_criteria>

<output>
After completion, create `.planning/phases/P1-diagnostics/P1-01-SUMMARY.md`
</output>
