# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-19)

**Core value:** Fast, beautiful code previews in Finder
**Current focus:** v1.1 Performance Overhaul — fixing critical performance issues

## Current Position

Milestone: v1.1 Performance Overhaul (BLOCKING)
Phase: P3 (Persistent Cache) - COMPLETE
Plan: 2 of 2 in current phase
Status: P3 complete, ready for P4
Last activity: 2026-01-21 — Completed P3-02-PLAN.md

Progress (v1.1 Performance): █████░░░░░ 50% (4/8 plans)
Progress (Overall to App Store): ██░░░░░░░░ 25%

## Performance Metrics

**v1.0 Milestone:**
- Total plans completed: 9
- Average duration: 3.4 min
- Total execution time: 31 min
- Timeline: 9 days (2026-01-10 → 2026-01-19)

**v1.1 Performance Milestone:**
- Total plans: 8-10 (P5 is conditional)
- Plans completed: 4
- Started: 2026-01-21
- P1-01 completed: 2026-01-21 (8 min)
- P2-01 completed: 2026-01-21 (2 min)
- P3-01 completed: 2026-01-21 (3 min)
- P3-02 completed: 2026-01-21 (4 min)

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

### Performance Issue Context

See: .planning/CONTEXT-ISSUES.md

**Root causes identified:**
1. ~~In-memory cache lost when QuickLook XPC service terminates~~ (FIXED in P3 - two-tier cache with disk persistence)
2. FastSyntaxHighlighter runs multiple regex passes
3. AttributedString mutation is expensive for large files
4. ~~Missing direct extension mappings force content detection~~ (FIXED in P2-01)
5. ~~Potential auto-detection overhead~~ (FIXED in P2-01)

**Target:** <500ms highlighting for 2000-line files

### Deferred Issues

None.

### Pending Todos

None.

### Blockers/Concerns

- App Store submission blocked until performance targets met
- Need data-driven highlighter decision (benchmarks required)

### Roadmap Evolution

- v1.1 milestone scope changed from "App Store Submission" to "Performance Overhaul"
- Original phases 6-12 moved to v1.2 milestone (queued)
- New phases P1-P6 created for performance work

## Session Continuity

Last session: 2026-01-21
Stopped at: P3 phase complete, ready for P4
Resume file: None
Next: `/gsd:plan-phase P4`

## Phase Overview

| Phase | Name | Plans | Status |
|-------|------|-------|--------|
| P1 | Diagnostics & Profiling | 1 | COMPLETE |
| P2 | Quick Wins | 1 | COMPLETE |
| P3 | Persistent Cache | 2 | **COMPLETE** |
| P4 | Highlighter Evaluation | 2 | Pending |
| P5 | Advanced Optimizations | 1-3 | Conditional |
| P6 | Integration & Verification | 1 | Pending |

## Quick Reference

```bash
# Plan next phase
/gsd:plan-phase P4

# View P3 summaries
cat .planning/phases/P3-persistent-cache/P3-01-SUMMARY.md
cat .planning/phases/P3-persistent-cache/P3-02-SUMMARY.md

# View cache performance results
cat .planning/phases/P3-persistent-cache/CACHE_RESULTS.md

# View milestone details
cat .planning/milestones/v1.1-performance-ROADMAP.md

# View performance issue context
cat .planning/CONTEXT-ISSUES.md
```
