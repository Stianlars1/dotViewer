# Backlog

## Planned Improvements

Derived from known issues — see [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for full details.

| ID | Title | Priority | Related |
|----|-------|----------|---------|
| B-001 | Markdown rendered mode — Typora-quality polish | Low | KI-004 — Parser rewritten, CSS polished, TOC sidebar added; minor typography refinements remain |
| B-002 | Markdown raw mode — structural readability | Medium | KI-003 — Color-differentiated via tree-sitter mappings; size/weight differentiation remains |
| B-003 | ~~Thumbnail/preview visual parity~~ | ~~Done~~ | Completed 2026-02-09 — ThumbnailSyntaxColorizer adds per-token coloring (KI-002, KI-006 partially fixed) |
| B-004 | ~~Catch-all UTI for unknown text extensions~~ | ~~Done~~ | Already fixed — public.data in QLSupportedContentTypes (KI-005) |
| B-005 | ~~Resolve 14 duplicate extension warnings~~ | ~~Done~~ | Completed 2026-02-09 — canonical owners chosen for all duplicates (KI-008) |
| B-006 | Cmd+C text copy in Quick Look preview | High | CGEventTap helper approach failed due to TCC sandbox attribution. See KI-009 for detailed research and untried approaches. Next step: research team to evaluate alternatives (remove sandbox, independent helper, NSPasteboard from QL extension). |

## Feature Ideas

From v1 requirements and future direction.

| ID | Title | Priority | Notes |
|----|-------|----------|-------|
| B-010 | ~~Markdown rendered/raw toggle in preview header~~ | ~~Done~~ | Completed 2026-02-09 — toggle works for all markdown files including named files (README, CHANGELOG) |
| B-019 | ~~Table of Contents for rendered markdown~~ | ~~Done~~ | Completed 2026-02-09 — sidebar TOC with heading navigation, toggle in header + settings, code-block-aware scanner |
| B-011 | Automated test suite | High | Unit tests for FileTypeRegistry, integration tests for XPC, snapshot tests for thumbnails |
| B-012 | App Store distribution | Medium | Requires sandboxing review, notarization, screenshots, listing |
| B-013 | Print / export to PDF | Medium | From v1 PROJECT.md requirements |
| B-014 | Line number highlighting / deep linking | Medium | Click line number to highlight, URL fragment for linking |
| B-015 | Search within preview | Medium | Cmd+F to search highlighted content |
| B-016 | Additional tree-sitter grammars | Low | Cover more of the 177 entries currently using heuristic fallback |
| B-017 | Performance benchmarking suite | Low | Automated timing for large files across all grammars |
| B-018 | Custom theme editor in host app | Low | Let users create/modify color palettes |

## Technical Debt

| ID | Title | Priority | Notes |
|----|-------|----------|-------|
| B-030 | 177 file types without tree-sitter grammar | Low | Fall back to heuristic highlighting; expected but could add more grammars over time |
| B-031 | DefaultFileTypes.json full audit | Low | ~250 entries unaudited for extension correctness (common languages verified) |
| B-032 | ThemePalette ↔ CSS token sync | Medium | Changes to ThemePalette.swift must be manually mirrored in PreviewHTMLBuilder CSS and TextThumbnailRenderer |
| B-033 | Thumbnail temp file cleanup | Low | PNG files written to NSTemporaryDirectory() with UUID filenames; OS cleans these but explicit cleanup would be cleaner |
