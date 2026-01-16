# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-15)

**Core value:** Fix all known bugs without breaking existing functionality — every fix must be verified to not regress current behavior.
**Current focus:** Phase 3 — Performance & Syntax Highlighting (CRITICAL)

## Current Position

Phase: 3 of 4 (Performance & Syntax Highlighting)
Plan: 1 of 2 (revised phase - Tree-sitter approach)
Status: PLANNING - approach change
Last activity: 2026-01-16 — Reverted Syntect, switching to Tree-sitter + Neon

Progress: ██████░░░░ 60% (6/10 plans complete, Phase 3 restarted)

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
| 03 | Abandon Syntect/Rust approach | 3 failed integration attempts; complexity too high |
| 03 | Switch to Tree-sitter + Neon | All Swift packages, well-maintained, simpler integration |

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

### Syntect Approach — ABANDONED (2026-01-16)

**Reason:** After 3 attempts, the Rust/UniFFI/XCFramework approach proved too complex with persistent integration issues. Reverting to HighlightSwift baseline and trying a simpler approach.

**Original implementation (reverted):**
- Rust native library with UniFFI bindings
- XCFramework built (universal binary: arm64 + x86_64)
- SyntaxHighlighter refactored to use Syntect
- HighlightSwift dependency removed

**Issues encountered:**
- Module naming conflicts
- Build system complexity
- Persistent integration issues across 3 attempts

### Tree-sitter + Neon Approach — ACTIVE (2026-01-16)

**New approach:**
- Tree-sitter via Swift packages (ChimeHQ/SwiftTreeSitter + ChimeHQ/Neon)
- All Swift native — no Rust, no FFI, no XCFramework
- Used by Neovim, Zed, GitHub for syntax highlighting
- ~20ms expected performance

**Benefits:**
- Pure Swift Package Manager integration
- Well-maintained by ChimeHQ (macOS dev tools company)
- Proper AST-based parsing (more accurate than regex)

**Status:** Planning

### Deferred Issues

- **App Store sandbox**: Sandbox disabled to allow pluginkit. Phase 4 will implement sandbox-compatible detection.

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-01-16
Stopped at: Reverted Syntect approach, planning Tree-sitter integration
Resume file: None
Next: Create and execute 03-01-PLAN.md for Tree-sitter + Neon integration
