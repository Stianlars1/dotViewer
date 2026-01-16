# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-15)

**Core value:** Fix all known bugs without breaking existing functionality — every fix must be verified to not regress current behavior.
**Current focus:** Phase 2 — Extension Manager UI Improvements

## Current Position

Phase: 2 of 5 (UI Bug Fixes)
Plan: 2 of 3 in current phase
Status: In progress
Last activity: 2026-01-16 — Completed 02-01-PLAN.md (custom extension edit)

Progress: █████░░░░░ 50% (5/10 plans)

## Performance Metrics

**Velocity:**
- Total plans completed: 5
- Average duration: 1 min
- Total execution time: 5 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | 3 min | 1 min |
| 02 | 2 | 2 min | 1 min |

**Recent Trend:**
- Last 5 plans: 01-01 (1 min), 01-02 (1 min), 01-03 (1 min), 02-02 (1 min), 02-01 (2 min)
- Trend: Consistent ~1-2 min per plan

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 01-01 | UTI extensions without leading dot | macOS handles dot prefix for dotfiles |
| 01-01 | Shell dotfiles conform to public.shell-script | Proper shell syntax highlighting |
| 01-01 | Git dotfiles conform only to public.plain-text | Git configs are not executable scripts |
| 01-02 | Use logger.error() for encoding failures | Visibility in Console.app for debugging |
| 01-02 | Preserve void return on setter | API compatibility with existing callers |
| 02-01 | Extension name not editable in edit sheet | Serves as unique identifier; delete and re-add if different extension needed |
| 02-02 | Use .borderedProminent + .tint(.red) for destructive buttons | Prominent style shows filled background; explicit tint ensures red color |
| hotfix | Disable sandbox for now | Sandbox blocks pluginkit; Phase 4 will fix properly for App Store |
| reorg | Encoding fix moved to Phase 1 | Foundational — must fix before custom extension UI work |
| reorg | Removed 01-02, 01-04, 03-02 from roadmap | Already implemented or false issues |

### Roadmap Reorganization (2026-01-15)

**Items removed (already done):**
- .mjs, .cjs, .mts, .cts mappings (found in LanguageDetector.swift)
- .env syntax highlighting (found in LanguageDetector.swift)

**Items removed (false issue):**
- "Duplicate initializers" — two initializers serve different purposes

**Items moved:**
- Silent encoding fix moved from Phase 3 to Phase 1 (now 01-02)

**Result:** 10 plans total (down from 14)

### Deferred Issues

- **App Store sandbox**: Sandbox disabled to allow pluginkit. Phase 4 will implement sandbox-compatible detection.

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-01-16
Stopped at: Completed 02-01-PLAN.md (custom extension edit)
Resume file: None
Next: Remaining Phase 2 plan (02-03 markdown toggle fix)
