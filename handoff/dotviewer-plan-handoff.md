# dotViewer v2.5 - Implementation Handoff Plan

Last updated: 2026-02-05
Workspace: `/Users/stian/.codex/worktrees/773b/v2.5`

## Purpose
This document is a standalone execution brief for a fresh thread. It captures the context, priorities, constraints, and step-by-step implementation plan so no chat history is required.

## Scope for the next execution cycle
In scope:
- Fix syntax highlighting quality and coverage first.
- Fix line number layout spacing.
- Fix header/button sizing and copy behavior (including Markdown RAW/RENDERED copy semantics).
- Fix theme update latency.
- Defer file type storage format migration details to the last step.

Out of scope:
- New product features unrelated to Quick Look preview/thumbnail quality.
- Broad refactors outside the preview, highlight, and shared rendering pipeline.

## Priority order (locked)
1. Syntax highlighting.
2. Line number spacing.
3. Header size + button styling + copy UX + Markdown RAW/RENDERED control sizing.
4. Theme updates applying immediately.
5. File type storage format follow-up (`plist` discussion), after 1-4 are stable.

## Current repo state relevant to this plan
The working tree is already dirty before this handoff. Do not reset/revert unrelated edits.

Current modified/untracked files:
- `AGENTS.md`
- `dotViewer/Shared/FileTypeModels.swift`
- `dotViewer/Shared/FileTypeRegistry.swift`
- `dotViewer/project.yml`
- `scripts/dotviewer-gen-ql-content-types.sh`
- `dotViewer/Shared/DefaultFileTypes.json` (untracked)
- `scripts/dotviewer-gen-default-filetypes.py` (untracked)

## Problem summary from user review
Observed behavior to fix:
- Finder right-column miniature preview often shows spinner, then generic icon, not real file content.
- Syntax highlighting is effectively missing for many files (only flat foreground/background colors).
- Line-number gutter is too wide with excessive left spacing.
- Header is too tall; chips/buttons are oversized and visually noisy.
- Markdown RAW/RENDERED toggle is oversized and copy behavior is inconsistent with visible mode.
- Copy action works but lacks clear feedback.
- Theme changes require reselecting files multiple times before reflecting in preview.

## Architecture context (what is already in place)
- Preview entrypoint: `dotViewer/QuickLookExtension/PreviewProvider.swift`.
- Thumbnail entrypoint: `dotViewer/QuickLookThumbnailExtension/ThumbnailProvider.swift` and `dotViewer/QuickLookThumbnailExtension/TextThumbnailRenderer.swift`.
- Highlight XPC service: `dotViewer/HighlightXPC/HighlightService.swift` and `dotViewer/Shared/HighlightXPCClient.swift`.
- Current highlighter: tree-sitter with a heuristic fallback in `dotViewer/HighlightXPC/TreeSitterHighlighter.swift`.
- HTML/CSS/JS rendering shell: `dotViewer/Shared/PreviewHTMLBuilder.swift`.
- File-type registry/config: `dotViewer/Shared/FileTypeRegistry.swift` and related shared models.
- XcodeGen source of truth for extension metadata/entitlements/resources: `dotViewer/project.yml`.

## Research baseline to reuse
Use SourceCodeSyntaxHighlight as architecture guide, not as copy source.

Local reference repos:
- `/Users/stian/Developer/macOS Apps/v2.5/SourceCodeSyntaxHighlight`
- `/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/SourceCodeSyntaxHighlight`
- `/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/highlight`
- `/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/cmark-gfm`
- `/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/QLMarkdownGFM`
- `/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/qlmarkdown`
- `/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/qlstephen`
- `/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/QLColorCode`
- `/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/QLColorCode-extra`

## Licensing constraint
- SourceCodeSyntaxHighlight and highlight are GPL-licensed.
- Do not copy GPL source files or scripts directly into proprietary/non-GPL code without explicit licensing decision.
- Safe approach: implement the same architecture patterns and your own code paths, with attribution where appropriate.
- Language/filetype support parity is allowed as facts/config mapping, but avoid verbatim copying of GPL code text.

## Implementation plan (decision-complete)

### Phase 0 - Setup and branch hygiene
- Create a new branch with prefix `codex/`.
- Keep pre-existing modified files intact unless they are intentionally part of this work.
- Record every changed file in AGENTS log when done.

### Phase 1 - Syntax highlighting (highest priority)
Goal:
- Deliver clear multi-token syntax highlighting across the broad file set, with graceful fallback and no blank previews.

Actions:
- Keep current tree-sitter path as baseline runtime engine.
- Improve token class mapping and theme palette usage in `PreviewHTMLBuilder` so token classes are visually distinct.
- Expand language routing/mapping in `FileTypeRegistry` to maximize correct grammar selection.
- Ensure unsupported grammars still receive readable fallback highlighting, not flat plain text.
- Add explicit logging of fallback reason paths in `HighlightService` and `PreviewProvider`.
- Validate with smoke files covering scripts, code, data, and dotfiles.

Acceptance criteria:
- `.py`, `.js`, `.ts`, `.tsx`, `.swift`, `.go`, `.rs`, `.zsh`, `.json`, `.yaml`, `.xml`, `.md`, `.gitignore`, `.env` show meaningful token differentiation.
- No regression where previews drop to generic icon for textual files.

### Phase 2 - Line number spacing
Goal:
- Reduce wasted horizontal space and align line numbers close to the left edge without clipping.

Actions:
- Tune `.ln` width and paddings in `PreviewHTMLBuilder` CSS.
- Tune `.content` and `.code-view` container padding for finder column constraints.
- Verify with line numbers ON and OFF.

Acceptance criteria:
- Visually compact gutter with readable numbers.
- No overlap, clipping, or shift during long-file scroll.

### Phase 3 - Header and controls polish + copy behavior
Goal:
- Compact professional header UI and correct copy semantics.

Actions:
- Reduce header height and chip/button sizes in `PreviewHTMLBuilder`.
- Replace copy button glyph with consistent professional icon treatment.
- Implement copy feedback state (brief toast or button state change).
- Copy behavior rule:
- If RAW mode visible, copy raw source text.
- If RENDERED mode visible, copy rendered textual content (no HTML tags).
- Keep RAW/RENDERED control compact and synchronized with current mode.

Acceptance criteria:
- Header occupies less vertical space.
- Copy action provides visible confirmation.
- Copy output matches currently visible mode.

### Phase 4 - Theme refresh reliability
Goal:
- Theme changes from settings must reflect promptly without repeated deselect/reselect loops.

Actions:
- Trace theme propagation path: `SharedSettings` -> preview build -> HTML/CSS render.
- Invalidate stale cache entries when theme changes.
- Force re-render for active request on theme change where feasible.

Acceptance criteria:
- Theme switch reflects on next preview open consistently.
- No repeated manual reselecting needed beyond normal finder refresh behavior.

### Phase 5 - Filetype storage format follow-up (deferred)
Goal:
- Evaluate moving default filetype map format for startup/read performance and maintainability.

Actions:
- Benchmark current JSON load and parse path.
- Compare alternatives (`binary plist` and static Swift table) against JSON for load cost and build/runtime complexity.
- Keep JSON unless measured gain is meaningful and operationally safe.

Acceptance criteria:
- Documented decision with measurements and operational tradeoffs.
- If migration is chosen, add deterministic generator script and tests.

## Validation protocol
Use these commands during execution:
- `./scripts/dotviewer-refresh.sh --no-open`
- `./scripts/dotviewer-ql-smoke.sh TestFiles/test.json`
- `./scripts/dotviewer-ql-smoke.sh TestFiles/TEST_MARKDOWN.md`
- `./scripts/dotviewer-ql-smoke.sh TestFiles/test.yaml`
- Manual Finder checks on representative files: `.gitignore`, `.env`, `.zsh`, `.py`, `.ts`, `.swift`, `.xml`, `.md`.

Expected logs:
- Quick Look routing log line for selected file.
- `HTML built ...` for textual routed files.
- No repeated fallback-to-icon behavior for supported textual files.

## Risks and mitigations
- Risk: overbroad routing can hijack binary formats.
- Mitigation: keep textual gating strict (`FileAttributes` checks) and preserve binary guards.

- Risk: UI polish changes regress readability in narrow Finder column.
- Mitigation: verify in both narrow and wide column widths.

- Risk: theme cache staleness.
- Mitigation: include theme key in cache key and invalidate on settings change.

## Suggested starter prompt for a new thread
Use this exactly in a fresh context if needed:

"Implement `/Users/stian/.codex/worktrees/773b/v2.5/handoff/dotviewer-plan-handoff.md` step by step, one priority at a time. Start with Priority 1 (syntax highlighting), run validation after each phase, do not revert unrelated dirty files, and update `/Users/stian/.codex/worktrees/773b/v2.5/AGENTS.md` when done."
