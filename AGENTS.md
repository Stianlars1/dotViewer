# dotViewer — Agent Guide

Instructions and context for AI agents working on this repo.

## Before You Start

1. Read [CLAUDE.md](CLAUDE.md) for architecture, build instructions, and key concepts
2. Check [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for current bugs (don't re-discover known problems)
3. Check [BACKLOG.md](BACKLOG.md) for planned work and priorities

## Key Patterns

- **Source of truth is `project.yml`** — never edit generated Info.plist or .entitlements files
- **Two rendering pipelines** — previews use HTML/CSS (PreviewHTMLBuilder), thumbnails use CoreGraphics (TextThumbnailRenderer). Changes to one may need mirroring in the other
- **UTI routing is exact-match** — adding a file type requires its UTI in QLSupportedContentTypes (both extensions). Use `dvutis` to regenerate
- **XPC embeds Shared.framework** — set `embed: true` in project.yml for the XPC target
- **Tree-sitter grammars compile as C sources** — each grammar uses its own `parser.h` (ABI incompatible across grammars). Set `USE_HEADERMAP: NO` for HighlightXPC
- **.scm query files load flat from Resources/** — do not use `subdirectory:` parameter in `Bundle.main.url(forResource:withExtension:)`
- **Swift 6 strict concurrency** — use explicit capture lists in `Task.detached`, no `await` in autoclosures

## What NOT to Do

- Don't edit Info.plist or .entitlements files directly (XcodeGen regenerates them)
- Don't add `public.mpeg-2-transport-stream` to supported types (hijacks .ts video files)
- Don't use `<>` includes in tree-sitter grammar sources (use `""` for local parser.h)
- Don't attempt to override system UTIs for .html or .ts (macOS limitation, see KI-001, KI-007)
- Don't use `QLThumbnailReply(contextSize:drawing:)` for thumbnails (renders inside document icon frame)
- Don't run `xcodebuild` without `xcodegen generate` first (project.yml is the source of truth)

## Build & Verify Workflow

```bash
# After any code change:
./scripts/dotviewer-refresh.sh          # Full rebuild + install
./scripts/dotviewer-ql-smoke.sh TestFiles/test.json   # Verify preview works

# Incremental during development:
./scripts/dotviewer-refresh.sh --no-clean --no-reset
```

## Work Log

Summary of agent-assisted development. See [CHANGELOG.md](CHANGELOG.md) for full version history.

| Date | Area | Outcome |
|------|------|---------|
| 2026-02-04 | Extension discovery | Fixed NSExtension dictionaries, entitlements, signing via project.yml |
| 2026-02-04 | Routing | Expanded QLSupportedContentTypes to exact UTIs for all major languages |
| 2026-02-04 | Highlighting | Added heuristic fallback highlighter for languages without tree-sitter grammars |
| 2026-02-04 | Dev scripts | Created dvrefresh, dvlogs, dvql, dvsmoke, dvutis |
| 2026-02-04 | Stability | Added FileTypeResolution.bestKey, looksTextual detection, thumbnail timeout |
| 2026-02-05 | Thumbnails | Replaced WKWebView with native CoreGraphics rendering |
| 2026-02-05 | Routing | Added MPEG-TS gating for .ts, binary plist conversion |
| 2026-02-05 | Preview UI | Copy toast, compact header, auto-theme CSS |
| 2026-02-05 | File types | Data-driven DefaultFileTypes.json (325+ entries from SourceCodeSyntaxHighlight) |
| 2026-02-06 | Tree-sitter | Compiled 53 grammars, created 53 .scm query files |
| 2026-02-06 | Color palette | Expanded to 18 token types (tag, attribute, escape, builtin, namespace, parameter) |
| 2026-02-06 | E2E testing | 10/11 issues fixed; added custom UTIs for jsx, fsharp, vb, batch |
| 2026-02-06 | Preview sizing | Dynamic window dimensions based on line count |
| 2026-02-06 | Thumbnails | Full-bleed rendering with subtle border + corner radius |
| 2026-02-06 | Settings | Word wrap support (user-configurable) |
| 2026-02-06 | Docs | Documentation refresh — README, CHANGELOG, KNOWN_ISSUES, BACKLOG, research reorg |
| 2026-02-09 | App icon | Fixed icon not appearing — added `resources:` and `ASSETCATALOG_COMPILER_APPICON_NAME` to project.yml |
| 2026-02-09 | Markdown parser | Full rewrite of MarkdownRenderer.swift (~510 lines) — two-pass parser with GFM tables, task lists, setext headings, code block language labels, recursive blockquotes, auto-linking |
| 2026-02-09 | Markdown CSS | PreviewHTMLBuilder rendered-view CSS overhaul — theme-aware headings, table striping, task list checkboxes, tighter spacing, v1-matching sizes |
| 2026-02-09 | Markdown RAW | Added text-semantic tree-sitter capture mappings in TreeSitterHighlighter; fixed markdown.scm fenced_code_block overlap |
| 2026-02-09 | Markdown routing | Fixed toggle not appearing for README.md/CHANGELOG.md — changed `isMarkdown` from key-based to `languageId == "markdown"` |
| 2026-02-09 | Docs | Updated KNOWN_ISSUES (KI-003, KI-004), CHANGELOG, BACKLOG, AGENTS to reflect current state |

## Notes

- XcodeGen regenerates `Info.plist` and `.entitlements` for all extension targets. Persistent changes live in `dotViewer/project.yml`.
- The `.agents/skills/update-agents-md/SKILL.md` skill can be used to append work log entries.
