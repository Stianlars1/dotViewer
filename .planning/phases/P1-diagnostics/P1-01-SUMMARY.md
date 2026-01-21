---
phase: P1-diagnostics
plan: 01
subsystem: performance
tags: [diagnostics, profiling, timing, nslog, instrumentation]

# Dependency graph
requires: []
provides:
  - Comprehensive timing instrumentation in highlighting pipeline
  - Performance diagnostics document with bottleneck analysis
  - Test files for performance benchmarking
affects: [P2-quick-wins, P3-persistent-cache, P4-highlighter-evaluation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - NSLog timing instrumentation with consistent format
    - Checkpoint-based performance logging

key-files:
  created:
    - .planning/phases/P1-diagnostics/DIAGNOSTICS.md
  modified:
    - QuickLookPreview/PreviewContentView.swift
    - Shared/SyntaxHighlighter.swift
    - Shared/FastSyntaxHighlighter.swift

key-decisions:
  - "Use NSLog for QuickLook extension logging (os_log may not surface)"
  - "Consistent log prefix [dotViewer PERF] for easy filtering"
  - "Section-based timing in FastSyntaxHighlighter to isolate bottlenecks"

patterns-established:
  - "Timing instrumentation: start time, section checkpoints, total at end"

issues-created: []

# Metrics
duration: 8min
completed: 2026-01-21
---

# Phase P1 Plan 01: Performance Diagnostics Summary

**Added comprehensive timing instrumentation to highlight pipeline, identifying HTML tag regex and cache loss as primary bottlenecks**

## Performance

- **Duration:** 8 min
- **Started:** 2026-01-21T08:01:41Z
- **Completed:** 2026-01-21T08:09:51Z
- **Tasks:** 4
- **Files modified:** 4

## Accomplishments

- Added detailed timing logs to PreviewContentView.highlightCode()
- Added timing logs to SyntaxHighlighter.highlight() with path tracking
- Added per-section timing to FastSyntaxHighlighter.highlight()
- Created DIAGNOSTICS.md documenting 5 key bottlenecks
- Identified primary issues: HTML tag regex for XML, cache loss on XPC termination
- Created test files for benchmarking (small/medium/large in Swift/JSON/XML)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add timing instrumentation to PreviewContentView** - `987807a` (perf)
2. **Task 2: Add timing instrumentation to SyntaxHighlighter** - `52b1a67` (perf)
3. **Task 3: Add timing instrumentation to FastSyntaxHighlighter** - `26a20c3` (perf)
4. **Task 4: Create DIAGNOSTICS.md** - `d97de77` (docs)

## Files Created/Modified

- `QuickLookPreview/PreviewContentView.swift` - Added timing logs throughout highlightCode()
- `Shared/SyntaxHighlighter.swift` - Added path tracking and timing
- `Shared/FastSyntaxHighlighter.swift` - Added per-section timing
- `.planning/phases/P1-diagnostics/DIAGNOSTICS.md` - Bottleneck analysis document

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Use NSLog over os_log | QuickLook extension's unified logs may not surface; NSLog is more reliable for debugging |
| Consistent log prefix | `[dotViewer PERF]` enables easy filtering in Console.app |
| Section-based timing | Isolates individual operations to identify specific bottlenecks |

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **QuickLook extension logging challenge:** Logs from the QuickLook extension don't appear in unified logging by default. Added NSLog calls but verification requires manual Console.app observation. Documented the log format for manual testing.

## Key Bottlenecks Identified

1. **HTML Tag Regex (MAJOR)** - For XML/plist files, regex matches thousands of tags
2. **Cache Loss on XPC Termination (MAJOR)** - Every preview re-highlights
3. **AttributedString Mutations (MODERATE)** - O(k) operations for k matches
4. **Per-Word Keyword Regex (MODERATE)** - Could batch into single pattern
5. **Missing .plist Mapping (MINOR)** - Falls back to content detection

## Next Phase Readiness

- Timing instrumentation in place for measuring improvements
- Bottlenecks identified and prioritized
- Recommendations documented for P2 (Quick Wins)
- Ready for P2-quick-wins phase

---
*Phase: P1-diagnostics*
*Completed: 2026-01-21*
