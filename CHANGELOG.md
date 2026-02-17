# Changelog

## v2.5 (2026-02-11) — Current

The production release. Tree-sitter-powered syntax highlighting via XPC service.

- 53 tree-sitter grammars compiled and bundled (C sources in XPC target)
- 388 file type definitions with 561 extensions and 283 filename patterns
- Full-bleed Finder thumbnails via CoreGraphics rendering (NSImage → PNG → imageFileURL)
- Dynamic Quick Look preview window sizing based on line count
- 18-token expanded color palette (tag, attribute, escape, builtin, namespace, parameter)
- Word wrap support (user-configurable)
- Auto-theme dark/light mode detection
- XPC-based out-of-process syntax highlighting service
- Heuristic fallback highlighter for languages without tree-sitter grammars
- Header UI: file type badge, file size, copy-to-clipboard button, markdown mode toggle
- 396 custom UTIs declared (covering all 561 extensions in registry)
- 501 UTIs in QLSupportedContentTypes for both preview and thumbnail extensions
- Developer scripts: dvrefresh, dvlogs, dvql, dvsmoke, dvutis, dvaudit
- Data-driven file type registry loaded from DefaultFileTypes.json
- Binary gating (looksTextual heuristic + MPEG-TS transport stream detection)
- Sensitive file detection (.env, credentials, keys)
- PlistConverter for binary plist → XML previews
- E2E test: 10 of 11 issues fixed (1 won't-fix: .ts system UTI conflict)
- Markdown rendered mode: full parser rewrite with GFM tables, task lists, code block language labels
- Markdown RAW/RENDERED toggle works for all markdown files (README, CHANGELOG, etc.)
- App icon properly compiled into bundle via XcodeGen resources
- Copy button is selection-aware with dynamic tooltip (copies selection when text is selected)
- Configurable copy behavior: 8 presets (auto-copy, floating button, toast action, tap to confirm, hold-to-copy, shake to copy, auto-copy with undo, off)
- Table of Contents sidebar for rendered markdown (toggleable from header, settings-configurable)
- TOC correctly skips fenced code blocks when scanning for headings
- Markdown rendered CSS polish: tighter spacing, accent-border blockquotes/code blocks
- Thumbnail syntax colorization: keywords, strings, comments, numbers, types via regex-based colorizer
- Resolved ~14 duplicate extension warnings in DefaultFileTypes.json
- Markdown settings view: TOC toggle added to dedicated Markdown settings sidebar
- Multi-dot file resolution: intermediate segment scanning (e.g., `.claude.json.backup.xxx` → JSON highlighting)
- Custom extension display names now shown correctly in preview header
- Fixed 5 missing primary extensions in DefaultFileTypes.json (xml, plist, jsonc, ini, log)
- Search in preview: optional search bar with match highlighting and prev/next navigation (off by default, toggle in Settings)
- Line highlighting: click line numbers to highlight, Shift+click for range selection
- TokenType enum with exhaustive color mapping — single source of truth for token→CSS rules
- Thumbnail bold/italic token styling (keywords bold, builtins italic, etc.)
- C/C++ split into separate file types (C++ files now get proper cpp grammar)
- Highlight language aliases for PostgreSQL procedural languages (plperl, plpython, pltcl) and MXML
- Markdown RAW mode: size/weight differentiation via data-language scoped CSS
- Enhanced @media print CSS with file title header, syntax colors, page breaks
- Removed non-functional print button (window.print() is a no-op in Quick Look)
- Fixed Finder thumbnails ignoring dark mode — switched to UserDefaults AppleInterfaceStyle (KI-011)
- Clickable links in rendered markdown preview — click to copy URL to clipboard with toast confirmation (KI-012)
- Synced font sizes: code and rendered markdown share one font size by default (toggle in Settings > Appearance)
- Unit test target with 7 test classes: FileTypeRegistry, FileTypeResolution, ThemePalette, MarkdownRenderer, PlistConverter, FileAttributes, TransportStreamDetector
- Fixed TOC setting non-functional — `markdownShowTOC` now gates entire TOC feature (button, sidebar, resize handle). When OFF, no TOC elements in DOM (KI-018)
- Fixed TOC JavaScript TDZ crash — pre-existing bug where `setMode()` called `updateActiveTOCLink()` before outer-scope `const tocPanel` was initialized, crashing the script and preventing all TOC event listeners from binding (KI-018)
- TOC sidebar font size now syncs with markdown render font size (scales relative to render font size setting)
- TOC toggle icon changed from list-lines to Apple `sidebar.left` style (rectangle with vertical divider)
- Markdown TOC default open/hidden setting (only visible when TOC is enabled)
- Optional “Include line numbers in copy” setting for manual selection + header copy
- Open With Assistant removed after testing; Finder Open With defaults do not change Quick Look routing for system-owned UTIs
- Open-with fallback path removed from the app (feature marked Won't Fix)
- Preview width controls: separate auto/custom max-width settings for code/RAW and markdown rendered mode
- Host app UI text-size preset with System-follow option (`appUIFontSizePreset`)
- File type coverage expansion: 400 definitions, 582 extensions, 295 filename patterns
- UTI coverage expansion: 563 custom exports and 680 QLSupportedContentTypes per extension target
- Added UTI coverage verification script: `scripts/dotviewer-test-uti-coverage.py`

### v2.5 development timeline

- **2026-02-04**: Quick Look extension discovery fix (NSExtension dictionaries, entitlements, signing). Routing/gating/stability improvements (FileTypeResolution.bestKey, looksTextual detection, thumbnail timeout). Developer scripts (dvrefresh, dvlogs, dvql, dvsmoke). Expanded QLSupportedContentTypes to exact UTIs. Heuristic fallback highlighter. Font size sync via App Group.
- **2026-02-05**: Replaced WKWebView thumbnails with native CoreGraphics rendering. MPEG-TS gating for .ts files. Binary plist conversion. Preview UI refresh (copy toast, compact header, auto-theme CSS). Data-driven DefaultFileTypes.json (SourceCodeSyntaxHighlight mappings + extra dotfiles).
- **2026-02-06**: Compiled 53 tree-sitter grammars. Created/validated 53 .scm query files. Expanded color palette to 18 token types. Fixed tree-sitter query loading (removed subdirectory param). Fixed ExtensionStatusChecker false negatives. Added custom UTIs for bat, jsx, fsharp, vb. E2E test pass (10/11). Dynamic preview window sizing. Full-bleed thumbnail rendering with subtle border. Word wrap support.
- **2026-02-09**: App icon fix (added resources to project.yml). MarkdownRenderer.swift full rewrite (~510 lines): two-pass parser with block-level + character-by-character inline processing. Supports ATX/setext headings, fenced code blocks with language labels, GFM tables with alignment, recursive blockquotes, ordered/unordered/task lists, images, bold/italic/bold+italic, strikethrough, auto-linking. PreviewHTMLBuilder CSS overhaul for rendered mode (theme-aware heading colors, table striping, task list checkboxes, tighter spacing, v1-matching heading sizes). Fixed markdown toggle routing — changed `isMarkdown` from key-based to `languageId == "markdown"` so README.md, CHANGELOG.md, and other named files show RAW/RENDERED toggle. Added text-semantic tree-sitter capture mappings for RAW markdown mode. Fixed markdown.scm fenced_code_block overlap. Sprint: Table of Contents sidebar (with code-block-aware heading scanner), rendered CSS polish pass, thumbnail syntax colorizer (ThumbnailSyntaxColorizer with 100+ keywords), resolved 14 duplicate extensions in DefaultFileTypes.json, TOC settings toggle in MarkdownSettingsView.
- **2026-02-10**: Cmd+C CGEventTap helper (CopyHelper) attempted and reverted. Built unsandboxed background .app with CGEventTap + AXUIElement, embedded in Contents/Helpers/. Blocked by macOS TCC: sandbox inheritance from parent, "responsible process" attribution to sandboxed host app, Accessibility list registration failures. See KI-009 for full research findings and untried alternatives.
- **2026-02-10**: Configurable copy behavior presets (KI-009 v2) — 8 selectable modes: auto-copy (default), floating copy button, toast with copy button, tap to confirm, hold-to-copy, shake to copy, auto-copy with undo, off. Setting in SharedSettings synced via App Group. JS generated per-preset via IIFEs in `PreviewHTMLBuilder.buildCopyBehaviorScript()`. Picker added to Settings → Preview UI with dynamic description text.
- **2026-02-10**: Fixed app icon not showing — `project.yml` referenced `dotIcon` but actual asset catalog is `dotViewerIcon.xcassets` / `dotViewerIcon.appiconset`. Updated both `ASSETCATALOG_COMPILER_APPICON_NAME` and resources path.
- **2026-02-12**: Fixed markdown links (KI-012): clicking links now copies URL to clipboard with toast confirmation ("Link copied" / "Path copied"), tooltip on hover. Added font size sync: new `syncFontSizes` setting (default ON) makes code and markdown rendered view share one font size. Toggle in Settings > Appearance, disabled slider with note in Markdown settings when synced. Fixed TOC setting bug (KI-018): `markdownShowTOC` now fully gates the TOC feature + fixed JS TDZ crash. TOC sidebar font size syncs with markdown render font size. TOC toggle icon changed to Apple sidebar.left style.
- **2026-02-14**: Added per-mode preview width controls: code/RAW width (auto/custom) and rendered markdown width (auto/custom), with clamped max-width settings persisted in App Group settings and included in `PreviewCacheKey`. Added host app UI text-size preset (`system`, `xSmall`…`xxxLarge`) applied at app root via `appUIFontSizing`. Added `PreviewHTMLBuilderTests` for width CSS generation paths.
- **2026-02-13**: Expanded file-type and UTI coverage. Default registry grew to 400 entries / 582 extensions / 295 filename patterns (including .firebaserc, .code-workspace, backup/config-variant extensions, apache/cursorrules/nushell/xcfilelist additions). `dotviewer-gen-utis.py` updated to include filename-derived implied extensions, broader vendor/system UTI handling, safe UTI-name normalization, and improved QL list emission. Added `scripts/dotviewer-test-uti-coverage.py` for routing audit.
- **2026-02-11**: Split C/C++ into separate file types — C++ files now get cpp grammar instead of shared C grammar. Added highlight language aliases for plperl, plpython, pltcl, mxml. Added `TokenType` enum as single source of truth for token→CSS mapping — `tokenCSSRules()` generates all CSS from the enum. Thumbnail bold/italic token styling via `NSFont.Weight` and `NSFontDescriptor.SymbolicTraits`. Search in preview: optional search bar (off by default), uses text selection + paste since Quick Look intercepts keyboard input, highlights matches with prev/next navigation. Line highlighting: click line numbers to highlight lines, Shift+click for range selection. Markdown RAW mode now has size/weight differentiation via `data-language="markdown"` scoped CSS. Enhanced @media print: file title header, syntax colors, page breaks; removed non-functional print button. Fixed Finder thumbnail dark mode (KI-011): `systemIsDark()` reads `AppleInterfaceStyle` from UserDefaults instead of unreliable `effectiveAppearance`. Added clickable links in rendered markdown (KI-012): JS click handler resolves relative links against source directory via `data-source-dir`. Unit test target: 7 XCTestCase classes covering FileTypeRegistry, FileTypeResolution, ThemePalette, MarkdownRenderer, PlistConverter, FileAttributes, TransportStreamDetector.
- **2026-02-16**: Removed Open With Assistant (sample files + Finder automation) after testing showed Quick Look routing is unchanged for system-owned UTIs and Finder automation is blocked in sandboxed apps. Open-with fallback UI/handling was later removed from the app and marked Won't Fix. Settings added for markdown TOC default state and line numbers in copy.
- **2026-02-10**: File type routing investigation and fixes. Confirmed Quick Look uses exact UTI matching (not conformance) — `public.data` does NOT act as a catch-all for dynamic UTIs. Fixed `bestKey()` to resolve multi-dot files (`.claude.json.backup.xxx` → `json`) via intermediate segment scanning. Added `displayName(for:)` to FileTypeRegistry so custom extensions show their user-specified name in the header. Fixed 5 missing primary extensions in DefaultFileTypes.json (`xml`, `plist`, `jsonc`, `ini`, `log`). Documented UTI routing limitation as KI-010.
- **2026-02-10**: Exhaustive UTI coverage expansion (B-020 / KI-010). Built `scripts/dotviewer-gen-utis.py` to generate UTI declarations from DefaultFileTypes.json. Expanded from ~78 → 501 QLSupportedContentTypes: 396 `UTExportedTypeDeclarations` for extensions without system UTIs, ~64 system + ~63 vendor UTIs. Initial version included 313 pre-computed `dyn.*` fallback codes, but these were non-functional (0% match rate against macOS dynamic UTIs) and removed in v2. Added 63 new file types (Gleam, GraphQL, Astro, Prisma, Mojo + 58 from sbarex/SourceCodeSyntaxHighlight user requests: shaders, PL/SQL, Bazel, Razor, Liquid, JSON5, JSONL, KML, WSDL, XAML, Apple .strings, Svelte, Odin, Elvish, MQL, Gherkin, SRT, and more). Registry now covers 388 entries with 561 extensions. Clarified Settings toggle descriptions and added explanatory note in custom file types UI.

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
