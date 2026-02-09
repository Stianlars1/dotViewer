# Backlog

## Planned Improvements

Derived from known issues — see [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for full details.

| ID | Title | Priority | Related |
|----|-------|----------|---------|
| B-001 | Markdown rendered mode — Typora-quality polish | High | KI-004 — Parser rewritten, CSS overhauled; spacing/typography refinements remain |
| B-002 | Markdown raw mode — structural readability | Medium | KI-003 — Color-differentiated via tree-sitter mappings; size/weight differentiation remains |
| B-003 | Thumbnail/preview visual parity | Critical | KI-002, KI-006 |
| B-004 | Catch-all UTI for unknown text extensions | High | KI-005 |
| B-005 | Resolve 14 duplicate extension warnings | Low | KI-008 |

## Feature Ideas

From v1 requirements and future direction.

| ID | Title | Priority | Notes |
|----|-------|----------|-------|
| B-010 | ~~Markdown rendered/raw toggle in preview header~~ | ~~Done~~ | Completed 2026-02-09 — toggle works for all markdown files including named files (README, CHANGELOG) |
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
