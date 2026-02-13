# Backlog

## Planned Improvements

Derived from known issues — see [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for full details.

| ID | Title | Priority | Related |
|----|-------|----------|---------|
| B-001 | Markdown rendered mode — Typora-quality polish | Low | KI-004 — Parser rewritten, CSS polished, TOC sidebar added; minor typography refinements remain. KI-013 (TOC close button), KI-017 (scroll spy), KI-018 (TOC setting + JS TDZ) now fixed. TOC sidebar font syncs with render font size. |
| B-002 | ~~Markdown raw mode — structural readability~~ | ~~Mostly Done~~ | KI-003 — Color + size/weight differentiation added 2026-02-11 via data-language scoped CSS. Minor polish remains. |
| B-003 | ~~Thumbnail/preview visual parity~~ | ~~Done~~ | Completed 2026-02-11 — Per-token coloring + bold/italic styling + dark mode fix (KI-002, KI-006, KI-011) |
| B-004 | ~~Catch-all UTI for unknown text extensions~~ | ~~Won't Fix~~ | Quick Look uses exact UTI matching (not conformance). `public.data` does NOT catch dynamic UTIs (`dyn.*`). No `.appex` mechanism exists to catch truly unknown extensions. Mitigated by exhaustive UTI coverage (501 entries). See KI-005, KI-010. |
| B-005 | ~~Resolve 14 duplicate extension warnings~~ | ~~Done~~ | Completed 2026-02-09 — canonical owners chosen for all duplicates (KI-008) |
| B-006 | ~~Cmd+C text copy in Quick Look preview~~ | ~~Done~~ | Completed 2026-02-10 — Configurable copy behavior presets (8 modes including auto-copy default). True Cmd+C remains a macOS limitation (KI-009), but workaround covers all practical use cases. |

## Feature Ideas

From v1 requirements and future direction.

| ID | Title | Priority | Notes |
|----|-------|----------|-------|
| B-010 | ~~Markdown rendered/raw toggle in preview header~~ | ~~Done~~ | Completed 2026-02-09 — toggle works for all markdown files including named files (README, CHANGELOG) |
| B-019 | ~~Table of Contents for rendered markdown~~ | ~~Done~~ | Completed 2026-02-09 — sidebar TOC with heading navigation, toggle in header + settings, code-block-aware scanner. Fixed 2026-02-12: setting now fully gates feature (KI-018), font size syncs with render setting, Apple sidebar.left toggle icon. |
| B-011 | ~~Automated test suite~~ | ~~Partial~~ | Completed 2026-02-11 — 7 unit test classes (FileTypeRegistry, FileTypeResolution, ThemePalette, MarkdownRenderer, PlistConverter, FileAttributes, TransportStreamDetector). XPC integration tests and snapshot tests remain. |
| B-012 | App Store distribution | Medium | Requires sandboxing review, notarization, screenshots, listing |
| B-013 | Print / export to PDF | Medium | From v1 PROJECT.md requirements |
| B-014 | ~~Line number highlighting / deep linking~~ | ~~Done~~ | Completed 2026-02-11 — Click line numbers to highlight, Shift+click for range selection. Deep linking via URL fragments not implemented. |
| B-015 | ~~Search within preview~~ | ~~Done~~ | Completed 2026-02-11 — Optional search bar (off by default), uses text selection + paste workflow since Quick Look intercepts keyboard input. Highlights matches with prev/next navigation. |
| B-016 | Additional tree-sitter grammars | Low | Cover more of the 177 entries currently using heuristic fallback |
| B-017 | Performance benchmarking suite | Low | Automated timing for large files across all grammars |
| B-018 | Custom theme editor in host app | Low | Let users create/modify color palettes |
| B-020 | ~~Broader UTI declarations for developer extensions~~ | ~~Done~~ | Completed 2026-02-10 — 396 custom UTI exports, ~64 system + ~63 vendor UTIs. Expanded from ~78 → 501 QLSupportedContentTypes. All 561 extensions in DefaultFileTypes.json now routable. Added 58 file types from sbarex user requests. See KI-010. |
| B-021 | ~~Custom file types UX improvements~~ | ~~Done~~ | Completed 2026-02-10 — Added explanatory note in FileTypesView, clarified toggle descriptions in SettingsView. |
| B-022 | Layout width customization / presets | Low | Allow users to choose preview content width (narrow, medium, wide, full) or set a custom max-width |
| B-023 | Content alignment options | Low | Left-align vs centered content in preview, especially for narrow code files |
| B-024 | ~~Custom file types improvements (from design doc)~~ | ~~Done~~ | Completed 2026-02-12 — Override built-in types with confirmation dialog, filename-based mappings (Jenkinsfile, Dockerfile), dots in extensions (.env.local), HighlightLanguage picker expanded 33→54 with quality tiers, shared `CustomExtensionValidation` enum, auto-suggest display name, override badges in file types list. See `docs/custom-file-types-design.md`. |
| B-025 | ~~Markdown clickable links~~ | ~~Done~~ | Completed 2026-02-12 — Clicking links copies URL to clipboard with toast confirmation. Tooltip on hover. Relative links resolved to absolute file:// paths. KI-012. |
| B-026 | ~~Synced font sizes~~ | ~~Done~~ | Completed 2026-02-12 — New `syncFontSizes` setting (default ON). Code and rendered markdown share one font size. Toggle in Settings > Appearance, disabled slider with note in Markdown settings when synced. |

## Technical Debt

| ID | Title | Priority | Notes |
|----|-------|----------|-------|
| B-030 | 177 file types without tree-sitter grammar | Low | Fall back to heuristic highlighting; expected but could add more grammars over time |
| B-031 | ~~DefaultFileTypes.json full audit~~ | ~~Done~~ | Completed 2026-02-12 — 393 entries, all checks passed. Added 4 filename entries (Jenkinsfile, Caddyfile, Gruntfile, Gulpfile). Fixed 3 grammar aliases (csharp→c_sharp, makefile→make, objectivec→objc). |
| B-032 | ~~ThemePalette ↔ CSS token sync~~ | ~~Mostly Done~~ | `TokenType` enum (2026-02-11) is now single source of truth — `tokenCSSRules()` generates CSS. TextThumbnailRenderer still uses separate mapping. |
| B-033 | Thumbnail temp file cleanup | Low | PNG files written to NSTemporaryDirectory() with UUID filenames; OS cleans these but explicit cleanup would be cleaner |
| B-034 | ~~Fix missing UTI declarations for .bat, .jsx, .vb~~ | ~~Done~~ | Completed 2026-02-12 — Fixed `dotviewer-gen-utis.py` to export "already custom" UTIs. Added 6 missing UTExportedTypeDeclarations (KI-015). |
| B-035 | ~~Blackout theme contrast audit~~ | ~~Done~~ | Completed 2026-02-12 — Comment color `#5F5F5F` → `#808080` (5.0:1 ratio, WCAG AA compliant). KI-016. |
| B-036 | ~~Fix TOC scroll spy active tracking~~ | ~~Done~~ | Completed 2026-02-12 — Fixed by adding `id` attrs to setext headings (B-037). KI-017. |
| B-037 | ~~Fix setext heading IDs in MarkdownRenderer~~ | ~~Done~~ | Completed 2026-02-12 — Added `generateSlug()` + `id` attrs to setext `<h1>`/`<h2>` output. KI-017. |
