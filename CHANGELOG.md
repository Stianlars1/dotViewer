# Changelog

## v2.5 (2026-02-09) — Current

The production release. Tree-sitter-powered syntax highlighting via XPC service.

- 53 tree-sitter grammars compiled and bundled (C sources in XPC target)
- 325+ file type definitions with 480+ extensions and 277+ filename patterns
- Full-bleed Finder thumbnails via CoreGraphics rendering (NSImage → PNG → imageFileURL)
- Dynamic Quick Look preview window sizing based on line count
- 18-token expanded color palette (tag, attribute, escape, builtin, namespace, parameter)
- Word wrap support (user-configurable)
- Auto-theme dark/light mode detection
- XPC-based out-of-process syntax highlighting service
- Heuristic fallback highlighter for languages without tree-sitter grammars
- Header UI: file type badge, file size, copy-to-clipboard button, markdown mode toggle
- 6 custom UTIs declared (typescript, env, batch, jsx, fsharp, vb)
- ~78 UTIs in QLSupportedContentTypes for both preview and thumbnail extensions
- Developer scripts: dvrefresh, dvlogs, dvql, dvsmoke, dvutis, dvaudit
- Data-driven file type registry loaded from DefaultFileTypes.json
- Binary gating (looksTextual heuristic + MPEG-TS transport stream detection)
- Sensitive file detection (.env, credentials, keys)
- PlistConverter for binary plist → XML previews
- E2E test: 10 of 11 issues fixed (1 won't-fix: .ts system UTI conflict)
- Markdown rendered mode: full parser rewrite with GFM tables, task lists, code block language labels
- Markdown RAW/RENDERED toggle works for all markdown files (README, CHANGELOG, etc.)
- App icon properly compiled into bundle via XcodeGen resources
- Cmd+C copies selected text from Quick Look preview (JS keyboard handler + clipboard API)
- Table of Contents sidebar for rendered markdown (toggleable from header, settings-configurable)
- TOC correctly skips fenced code blocks when scanning for headings
- Markdown rendered CSS polish: tighter spacing, accent-border blockquotes/code blocks
- Thumbnail syntax colorization: keywords, strings, comments, numbers, types via regex-based colorizer
- Resolved ~14 duplicate extension warnings in DefaultFileTypes.json
- Markdown settings view: TOC toggle added to dedicated Markdown settings sidebar

### v2.5 development timeline

- **2026-02-04**: Quick Look extension discovery fix (NSExtension dictionaries, entitlements, signing). Routing/gating/stability improvements (FileTypeResolution.bestKey, looksTextual detection, thumbnail timeout). Developer scripts (dvrefresh, dvlogs, dvql, dvsmoke). Expanded QLSupportedContentTypes to exact UTIs. Heuristic fallback highlighter. Font size sync via App Group.
- **2026-02-05**: Replaced WKWebView thumbnails with native CoreGraphics rendering. MPEG-TS gating for .ts files. Binary plist conversion. Preview UI refresh (copy toast, compact header, auto-theme CSS). Data-driven DefaultFileTypes.json (SourceCodeSyntaxHighlight mappings + extra dotfiles).
- **2026-02-06**: Compiled 53 tree-sitter grammars. Created/validated 53 .scm query files. Expanded color palette to 18 token types. Fixed tree-sitter query loading (removed subdirectory param). Fixed ExtensionStatusChecker false negatives. Added custom UTIs for bat, jsx, fsharp, vb. E2E test pass (10/11). Dynamic preview window sizing. Full-bleed thumbnail rendering with subtle border. Word wrap support.
- **2026-02-09**: App icon fix (added resources to project.yml). MarkdownRenderer.swift full rewrite (~510 lines): two-pass parser with block-level + character-by-character inline processing. Supports ATX/setext headings, fenced code blocks with language labels, GFM tables with alignment, recursive blockquotes, ordered/unordered/task lists, images, bold/italic/bold+italic, strikethrough, auto-linking. PreviewHTMLBuilder CSS overhaul for rendered mode (theme-aware heading colors, table striping, task list checkboxes, tighter spacing, v1-matching heading sizes). Fixed markdown toggle routing — changed `isMarkdown` from key-based to `languageId == "markdown"` so README.md, CHANGELOG.md, and other named files show RAW/RENDERED toggle. Added text-semantic tree-sitter capture mappings for RAW markdown mode. Fixed markdown.scm fenced_code_block overlap. Sprint: Cmd+C keyboard copy handler, Table of Contents sidebar (with code-block-aware heading scanner), rendered CSS polish pass, thumbnail syntax colorizer (ThumbnailSyntaxColorizer with 100+ keywords), resolved 14 duplicate extensions in DefaultFileTypes.json, TOC settings toggle in MarkdownSettingsView.

## v2.5-claude-work (2026-01, abandoned)

Attempted XPC-based rewrite from v1. Hit sandbox reliability issues with the XPC connection lifecycle. Design work carried forward to v2.5.

## v2 (2026-01, research only)

Research phase — no shipped code.

- Competitor analysis of 37 Quick Look extensions (deep-dive repo scans)
- Architecture patterns document (XPC, sandboxing, performance)
- Feature recipes mapped to reference implementations
- Performance research (file size limits, caching, native rendering)
- Decision: tree-sitter + XPC rewrite (carried forward to v2.5)

## v1.1 (2026-01-21) — Performance Overhaul

- Two-tier cache (memory + disk) for highlighted output
- Single-pass regex optimization replacing multi-pass approach
- Achieved <500ms for 2000-line files (actual ~50ms measured)
- Resolved JavaScript-based highlighting bottleneck identified in v1

## v1 (2026-01-19) — Initial Release

- Quick Look extension with FastSyntaxHighlighter + HighlightSwift fallback
- 100+ file types, 10 themes
- Markdown raw/rendered toggle
- Custom file type registration UI in host app
- Sensitive file detection (.env, credentials)
- Settings sync via App Group (font size, theme, line numbers)
- Performance bottleneck identified: JavaScript-based highlighting via HighlightSwift
