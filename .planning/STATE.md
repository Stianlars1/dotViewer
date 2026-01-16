# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-15)

**Core value:** Fix all known bugs without breaking existing functionality — every fix must be verified to not regress current behavior.
**Current focus:** Phase 3 — Performance & Syntax Highlighting (CRITICAL)

## Current Position

Phase: 3 of 4 (Performance & Syntax Highlighting)
Plan: 3 of 4 in current phase
Status: CHECKPOINT - awaiting human verification
Last activity: 2026-01-16 — 03-03 Task 3 (performance verification)

Progress: █████████░ 90% (9/10 plans near complete, awaiting verification)

## Performance Metrics

**Velocity:**
- Total plans completed: 8
- Average duration: 3 min
- Total execution time: 21 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | 3 min | 1 min |
| 02 | 3 | 3 min | 1 min |
| 03 | 2 | 15 min | 7.5 min |

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
| reorg | Skip Phase 3 QA | Tested during development; not needed as separate phase |
| reorg | Swap Phase 4 ↔ 5 | Performance is critical for user retention; App Store can wait |
| 03-01 | Use once_cell::Lazy for SyntaxSet/ThemeSet | Pre-load at startup for fast subsequent calls |
| 03-01 | Map atomOneDark -> base16-ocean.dark | Closest visual match from Syntect defaults |
| 03-01 | Hex color strings (#RRGGBB) for FFI | Simple parsing in Swift, cross-platform compatible |
| 03-02 | Use SyntectSwiftFFI as module name | Matches UniFFI generated import name in Swift bindings |
| 03-02 | Include uniffi-bindgen binary in project | Ensures consistent version, no global install required |
| 03-02 | Universal binary via lipo | Supports both Intel and Apple Silicon Macs |
| 03-03 | Remove HighlightSwift dependency | No longer needed with native Syntect integration |
| 03-03 | Increase max lines to 5000 | Syntect is fast enough for larger files |

### Roadmap Reorganization (2026-01-16)

**Phase reordering:**
- Phase 3 (QA) → Skipped (tested during development)
- Phase 4 (App Store) → Now Phase 4 (moved back)
- Phase 5 (Performance) → Now Phase 3 (priority: critical)

**Items confirmed as pre-existing fixes:**
- 02-03 markdown toggle — was already working

**Result:** 4 phases, 10 total plans (6 complete, 4 remaining)

### Performance Research (2026-01-16)

**Problem:** 1-2 seconds to load 10-30KB files in QuickLook preview

**Current implementation:**
- HighlightSwift library (wraps highlight.js via JavaScript)
- JavaScript bridge overhead is likely the bottleneck

**Alternatives researched:**
| Solution | Type | Speed | Languages |
|----------|------|-------|-----------|
| HighlightSwift (current) | JS bridge | Slow (1-2s) | 185+ |
| Andre-simon Highlight | Native C++ | Fast | 200+ |
| CodeColors approach | Swift regex | "Instant" | ~60 |

**Recommended approach:**
1. Profile first to confirm bottleneck
2. Implement lazy loading for instant initial display
3. Switch to faster highlighting library if JS is confirmed as bottleneck

### Syntect Integration (2026-01-16)

**Implementation complete:**
- Rust native library with UniFFI bindings
- XCFramework built (universal binary: arm64 + x86_64)
- SyntaxHighlighter refactored to use Syntect
- HighlightSwift dependency removed
- Timing instrumentation added to PreviewContentView

**Awaiting verification:**
- Performance target: <100ms per file
- Rapid navigation at 140 BPM

### Deferred Issues

- **App Store sandbox**: Sandbox disabled to allow pluginkit. Phase 4 will implement sandbox-compatible detection.

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-01-16
Stopped at: 03-03 Task 3 checkpoint (human-verify)
Resume file: None
Next: User verifies performance, then 03-04-PLAN.md (optional cleanup/enhancements)
