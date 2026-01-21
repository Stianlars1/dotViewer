---
phase: P4-highlighter-evaluation
plan: 01
subsystem: performance
tags: [benchmark, highlightr, highlightswift, fastsyntaxhighlighter, regex, javascriptcore]

# Dependency graph
requires:
  - phase: P3
    provides: Two-tier cache, baseline performance data
provides:
  - Comprehensive highlighter benchmark data
  - Performance comparison across 3 highlighters
  - Data-driven architecture recommendation
  - HighlighterBenchmark.swift utility for future testing
affects: [P4-02, P5, P6]

# Tech tracking
tech-stack:
  added: [Highlightr]
  patterns: [benchmark-driven-decisions]

key-files:
  created:
    - Shared/HighlighterBenchmark.swift
    - .planning/phases/P4-highlighter-evaluation/BENCHMARK_RESULTS.md
  modified:
    - dotViewer.xcodeproj/project.pbxproj

key-decisions:
  - "Keep FastSyntaxHighlighter as primary (comparable performance, no JSCore overhead)"
  - "Keep HighlightSwift as fallback (already integrated, good accuracy)"
  - "Remove Highlightr from production (same as HighlightSwift, no advantage)"
  - "Bottleneck is HTML tag regex for XML files (230ms), not regex parsing (<10ms)"

patterns-established:
  - "Benchmark-driven optimization: measure before changing"
  - "HighlighterBenchmark pattern for future performance testing"

issues-created: []

# Metrics
duration: 12min
completed: 2026-01-21
---

# Phase P4 Plan 01: Highlighter Benchmarking Summary

**Benchmarked FastSyntaxHighlighter, HighlightSwift, and Highlightr across 5 languages and 4 file sizes to make data-driven architecture decision**

## Performance

- **Duration:** 12 min
- **Started:** 2026-01-21T09:00:00Z
- **Completed:** 2026-01-21T09:12:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added Highlightr package dependency for benchmarking comparison
- Created HighlighterBenchmark.swift utility with code generators for 5 languages
- Ran comprehensive regex parsing benchmarks (100-2000 lines, 5 languages)
- Documented full highlighting timing breakdown from DIAGNOSTICS.md
- Identified true bottleneck: HTML tag regex for XML files (230ms of 350ms total)
- Made data-driven recommendation: keep current architecture

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Highlightr package dependency** - `abf2949` (chore)
2. **Task 2: Create HighlighterBenchmark utility** - `4239c51` (feat)
3. **Task 3: Run comprehensive benchmarks and create results** - `d59f597` (docs)

## Files Created/Modified

- `Shared/HighlighterBenchmark.swift` - Benchmark utility comparing all 3 highlighters
- `dotViewer.xcodeproj/project.pbxproj` - Added Highlightr package dependency
- `.planning/phases/P4-highlighter-evaluation/BENCHMARK_RESULTS.md` - Full benchmark report

## Key Findings

### Regex Parsing is Fast (<10ms for 2000 lines)

| Size | Swift | JSON | XML | Python |
|------|-------|------|-----|--------|
| 100 lines | 0.32ms | 0.38ms | 0.37ms | 0.50ms |
| 500 lines | 1.28ms | 1.42ms | 1.43ms | 2.02ms |
| 1000 lines | 2.30ms | 2.57ms | 2.53ms | 3.82ms |
| 2000 lines | 4.51ms | 5.17ms | 4.95ms | 7.56ms |

### Bottleneck: HTML Tag Regex for XML (230ms)

For 1939-line Info.plist, timing breakdown:
- Index mapping: 15ms
- Language patterns: 5ms
- Comments: 25ms
- Strings: 55ms
- Numbers: 20ms
- **HTML tag regex: 230ms** (bottleneck)
- Keywords/Types: ~0ms
- **Total: ~350ms**

### All 3 Highlighters Have Similar Performance

| Highlighter | Basis | Performance |
|-------------|-------|-------------|
| FastSyntaxHighlighter | Native Swift regex | 300-400ms for 2000 lines |
| HighlightSwift | JavaScriptCore/highlight.js | 200-400ms for 2000 lines |
| Highlightr | JavaScriptCore/highlight.js | 200-400ms for 2000 lines |

## Decisions Made

1. **Keep FastSyntaxHighlighter as primary**
   - Comparable performance to JS-based alternatives
   - No JavaScriptCore overhead on startup
   - Predictable, debuggable Swift code

2. **Keep HighlightSwift as fallback**
   - Already integrated, good accuracy
   - Covers languages Fast doesn't support

3. **Remove Highlightr from production**
   - Same highlight.js as HighlightSwift
   - No meaningful performance advantage
   - Keep only in HighlighterBenchmark for testing

4. **Optimization target: XML data mode**
   - Skip HTML tag highlighting for plist/config files
   - Expected improvement: 230ms -> ~100ms

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- BENCHMARK_RESULTS.md provides data for P4-02 optimization decisions
- Identified specific optimization: disable HTML tags for XML data files
- HighlighterBenchmark.swift available for measuring P5 improvements

---
*Phase: P4-highlighter-evaluation*
*Completed: 2026-01-21*
