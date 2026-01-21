# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-19)

**Core value:** Fast, beautiful code previews in Finder
**Current focus:** v1.1 Performance Overhaul — fixing critical performance issues

## Current Position

Milestone: v1.1 Performance Overhaul (BLOCKING)
Phase: P5 (Advanced Optimizations) - COMPLETE
Plan: 1 of 1 in current phase
Status: P5 complete, ready for P6
Last activity: 2026-01-21 — Completed P5-01-PLAN.md

Progress (v1.1 Performance): █████████░ 88% (7/8 plans)
Progress (Overall to App Store): ████░░░░░░ 40%

## Performance Metrics

**v1.0 Milestone:**
- Total plans completed: 9
- Average duration: 3.4 min
- Total execution time: 31 min
- Timeline: 9 days (2026-01-10 → 2026-01-19)

**v1.1 Performance Milestone:**
- Total plans: 8 (P5 was conditional, completed with optimize-regex)
- Plans completed: 7
- Started: 2026-01-21
- P1-01 completed: 2026-01-21 (8 min)
- P2-01 completed: 2026-01-21 (2 min)
- P3-01 completed: 2026-01-21 (3 min)
- P3-02 completed: 2026-01-21 (4 min)
- P4-01 completed: 2026-01-21 (12 min)
- P4-02 completed: 2026-01-21 (3 min)
- P5-01 completed: 2026-01-21 (6 min)

## Accumulated Context

### v1.0 Decisions

All decisions logged in PROJECT.md Key Decisions table.

### v1.1 Decisions

| Decision | Rationale | Status |
|----------|-----------|--------|
| Prioritize performance over App Store timeline | User experience is paramount; 15-second highlighting is unacceptable | Active |
| Full overhaul approach | Quick fixes (line limits) defeat the app's purpose; need proper solution | Active |
| Use NSLog for QuickLook extension logging | os_log may not surface from sandboxed extension; NSLog more reliable | P1-01 |
| Consistent [dotViewer PERF] log prefix | Enables easy filtering in Console.app for performance analysis | P1-01 |
| Section-based timing in FastSyntaxHighlighter | Isolates individual operations to identify specific bottlenecks | P1-01 |
| Use plaintext fallback over auto-detection | Auto-detection runs multiple parsers (40-60% slower) | P2-01 |
| Use system UTIs for Xcode files | Apple provides official UTIs (com.apple.xcode.*) | P2-01 |
| Sync reads, async writes for cache | Fast cache hits (<50ms) while not blocking highlighting | P3-01 |
| SHA256 cache key = path + modDate + theme | Complete invalidation when any factor changes | P3-01 |
| Keep FastSyntaxHighlighter as primary | Comparable performance to JS-based, no JSCore overhead | P4-01 |
| Keep HighlightSwift as fallback | Already integrated, good accuracy | P4-01 |
| Keep Highlightr for benchmarking only | Same as HighlightSwift (highlight.js), no production advantage | P4-01 |
| Skip HTML tags for XML data files | 230ms savings - plist/config don't need tag colorization | P4-02 |
| Single-pass regex for keywords/types | O(n) instead of O(n x keywords) - 66% faster for code files | P5-01 |

### Performance Issue Context

See: .planning/CONTEXT-ISSUES.md

**Root causes identified:**
1. ~~In-memory cache lost when QuickLook XPC service terminates~~ (FIXED in P3 - two-tier cache with disk persistence)
2. ~~FastSyntaxHighlighter runs multiple regex passes~~ (ANALYZED in P4-01 - regex parsing is fast <10ms)
3. ~~AttributedString mutation expensive for XML~~ (FIXED in P4-02 - skip HTML tags for XML data, saves 230ms)
4. ~~Missing direct extension mappings force content detection~~ (FIXED in P2-01)
5. ~~Potential auto-detection overhead~~ (FIXED in P2-01)

**Target:** <500ms highlighting for 2000-line files
**Expected actual:** ~120ms for XML/plist with P4-02 optimization

### Benchmark Key Findings (P4-01)

- Regex parsing: <10ms for 2000 lines (not the bottleneck)
- HTML tag regex for XML: 230ms of 350ms total (TRUE bottleneck) - NOW FIXED
- All 3 highlighters have similar performance
- FastSyntaxHighlighter is best choice (no JSCore overhead)

### Deferred Issues

None.

### Pending Todos

None.

### Blockers/Concerns

- Need P6 integration testing to confirm all targets met

### Roadmap Evolution

- v1.1 milestone scope changed from "App Store Submission" to "Performance Overhaul"
- Original phases 6-12 moved to v1.2 milestone (queued)
- New phases P1-P6 created for performance work

## Session Continuity

Last session: 2026-01-21
Stopped at: P5-01 complete, P5 phase complete
Resume file: None
Next: `/gsd:plan-phase P6` (Integration & Verification)

## Phase Overview

| Phase | Name | Plans | Status |
|-------|------|-------|--------|
| P1 | Diagnostics & Profiling | 1 | COMPLETE |
| P2 | Quick Wins | 1 | COMPLETE |
| P3 | Persistent Cache | 2 | COMPLETE |
| P4 | Highlighter Evaluation | 2 | **COMPLETE** |
| P5 | Advanced Optimizations | 1 | **COMPLETE** |
| P6 | Integration & Verification | 1 | Pending |

## Quick Reference

```bash
# Plan next phase
/gsd:plan-phase P6

# View P5-01 summary
cat .planning/phases/P5-advanced-optimizations/P5-01-SUMMARY.md

# View benchmark results
cat .planning/phases/P4-highlighter-evaluation/BENCHMARK_RESULTS.md

# View milestone details
cat .planning/milestones/v1.1-performance-ROADMAP.md

# View performance issue context
cat .planning/CONTEXT-ISSUES.md
```
