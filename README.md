# dotViewer

Best-in-class Quick Look previewer for developers on macOS.

`dotViewer` turns Finder Quick Look into a full code-and-config viewer: syntax-highlighted previews, markdown raw/rendered modes, quality thumbnails, and highly configurable copy behavior.

## What dotViewer Is

dotViewer is a native macOS app + Quick Look extension suite that lets you:
- Select a file in Finder and press `Space` for an instant syntax-highlighted preview.
- See matching syntax-highlighted thumbnails directly in Finder.
- Read markdown as either raw source or rendered document.
- Customize preview behavior globally from a host app.

You do not need to open VS Code, Xcode, or another editor just to inspect files.

## Who It Is For

dotViewer is built for:
- Developers browsing repositories in Finder.
- DevOps/SRE engineers reading config files, logs, and dotfiles.
- Security-minded users who inspect `.env` and credential-adjacent files and want warnings.
- Teams that want consistent, readable preview behavior across many text file types.

## Why You Need It

Problems dotViewer solves:
- Finder Quick Look is inconsistent for source/config files.
- Unknown or niche extensions often show generic previews.
- Markdown and code require different reading modes.
- Copying from Quick Look is limited by macOS keyboard interception.
- Thumbnail and preview quality usually drift in third-party tools.

dotViewer addresses this with:
- Deep UTI coverage for routing more file types to the extension.
- Tree-sitter + fallback highlighting so unsupported grammars still look useful.
- A dual markdown experience (RAW + RENDERED) with TOC and link handling.
- 8 copy interaction presets designed around real Quick Look platform constraints.
- Two tuned rendering pipelines (HTML for preview, CoreGraphics for thumbnails).

## Why dotViewer Is Different

Compared with many Quick Look plugins:
- It is not plain text only; it provides syntax-aware rendering and token theming.
- It is not markdown-only; it handles code, config, dotfiles, markdown, and more.
- It includes first-class customization (theme, copy style, search, wrap, limits, cache).
- It supports custom file mappings by extension and by exact filename.
- It documents and works around known macOS Quick Look limitations instead of hiding them.

In practice, this makes dotViewer a stronger default daily workflow tool for developers who live in Finder.

## Core Functionality

dotViewer consists of four targets:
- `dotViewer.app` (host settings UI)
- `QuickLookExtension` (spacebar preview)
- `QuickLookThumbnailExtension` (Finder thumbnails)
- `HighlightXPC` (out-of-process syntax highlighting)

Shared code in `Shared.framework` is used by all targets.

## Complete Feature Inventory

### 1) Syntax Highlighting
- Tree-sitter highlighting via `HighlightXPC` for compiled grammar languages.
- Heuristic fallback highlighter for languages without compiled grammar.
- Token model with 16 CSS token classes (`14 semantic + 2 aliases`).
- Theme-aware token colors shared between preview and thumbnail pipelines.
- Auto aliasing for language IDs (for example `csharp -> c_sharp`, `makefile -> make`).

### 2) Markdown Features
- RAW mode: syntax-aware source view.
- RENDERED mode: HTML markdown rendering with structure and typography.
- RENDERED mode with TOC: In RENDERED mode you can click the `sidebar-icon` in the custom dotViewer Quick Look Header to open a left-sided Table of Contents. With active highlight for each new heading, easily see where youre at.
- Supported markdown constructs:
- ATX headings (`#`)
- Setext headings (`===` / `---`)
- Fenced code blocks (triple backtick and `~~~`) with language labels
- GFM tables with alignment
- Ordered/unordered lists
- Task lists (`- [ ]`, `- [x]`)
- Nested blockquotes
- Horizontal rules
- Inline code
- Links and images
- Bold / italic / bold+italic / strikethrough
- Bare URL auto-linking
- Collapsible TOC sidebar in rendered mode (2+ headings).
- Scroll-spy active heading in TOC.
- Resizable TOC sidebar.
- Configurable inline image visibility.
- Custom CSS injection with optional full override mode.
- Print stylesheet with title header, pagination tuning, and link URL expansion.

### 3) Preview UI and Interaction
- Header badge with language display.
- Header metadata: line count + file size.
- Copy button with selection-aware behavior.
- RAW/RENDERED toggle for markdown.
- Optional search button in header.
- Search workflow supports current selection and clipboard paste input.
- Optional TOC toggle for rendered markdown.
- Truncation warning banner when preview is capped by max size.
- Sensitive file warning banner for known secret-like files.
- Unknown type / binary warning banners when relevant.
- Clickable rendered markdown links copy URL/path to clipboard and try to open.
- Line number click highlight.
- Shift-click range line highlight.
- Search highlights with prev/next navigation and result counts.

### 4) Copy System (8 Presets)

Because Quick Look intercepts `Cmd+C` in the host window, dotViewer ships configurable mouse/selection copy workflows.

The presets:

| Preset | Key | How it works | Best for |
|---|---|---|---|
| Auto-copy (default) | `autoCopy` | Copies selected text ~150ms after mouse-up. | Fastest workflow. |
| Floating copy button | `floatingButton` | Shows a small contextual `Copy` button near selection. | Visual confirmation before copy. |
| Toast with copy button | `toastAction` | Shows a toast with `Copy` action for ~4s. | Explicit confirmation. |
| Tap to confirm | `tapToCopy` | Select text, then tap once more within ~3s to copy. | Fewer accidental copies. |
| Hold-to-copy | `holdToCopy` | Copies only if selection drag lasts >500ms. | Deliberate selection workflows. |
| Shake to copy | `shakeToCopy` | After selection, shake cursor left-right (3 reversals, >=30px, ~2s window). | Gesture-based interaction. |
| Auto-copy with undo | `autoCopyUndo` | Auto-copies immediately and offers ~3s Undo toast to restore prior clipboard value. | Safety for clipboard-heavy workflows. |
| Off | `off` | Disables automatic copy behavior. | Manual-copy only environments. |

Copy actions that always remain available (regardless of preset):
- Header copy button.
- Native context menu copy.
- Selection copy sanitization that removes line-number gutter text.

### 5) File Type Support and Routing
- Built-in registry loaded from `DefaultFileTypes.json`.
- Extension and filename matching.
- Multi-dot filename resolution strategy.
- Dotfile-aware resolution.
- Toggle to disable individual built-in file type mappings.
- Custom mapping by extension.
- Custom mapping by filename (for example `Jenkinsfile`, `Dockerfile`).
- Multi-dot extension custom mapping (for example `env.local`).
- Built-in mapping override confirmation for conflicts.

### 6) Finder Thumbnails
- Native CoreGraphics rendering (no WKWebView).
- Tree-sitter token request with fallback colorizer.
- Bold/italic token styling in thumbnails.
- Full-bleed style rendering with header metadata.
- Optional line numbers in thumbnail rendering.
- Dark mode-aware palette handling.

### 7) Safety and Binary Gating
- MIME + UTType + byte-sample inspection.
- `looksTextual` heuristic for binary detection.
- MPEG-TS detector to avoid hijacking `.ts` video files.
- Binary plist detection and XML conversion for previewability.
- Sensitive file detector for common secret-bearing filenames.

### 8) Performance and Stability
- Preview file size cap (default `100 KB`).
- Thumbnail caps (default `24 KB`, `60` lines).
- Preview caching with configurable TTL and size limit.
- Manual cache clear trigger.
- Out-of-process highlighting via XPC for isolation.
- Request cancellation and timeouts in preview/thumbnail paths.

### 9) Host App UX
- Extension status page with setup guidance.
- Quick stats for built-in/custom/disabled type counts.
- Theme preview card.
- One-click extension settings launcher.
- Built-in app uninstall action.

## Customization Guide

Everything is configurable in the host app.

### Appearance
- Theme (`14` options: 4 system-following choices + 10 fixed palettes).
- Font size (`10-24pt`).
- Sync code + markdown render font sizes.
- Show/hide line numbers.
- Word wrap on/off.

### Preview Limits
- Max preview file size (`10-500 KB` range, default `100 KB`).
- Show/hide truncation warning.

### Preview UI
- Show/hide file info header.
- Initial preview window size (`Per File` or `Same for All Files`) with configurable shared width/height.
- Choose one of 8 copy behaviors.
- Include line numbers in copy (manual selection + header copy button).
- Show/hide in-preview search UI.
- Allow preview of unknown file types.
- Force text preview for unknown files when bytes look textual.
- Code and RAW content width mode (`Auto`/`Custom`) with configurable custom max width.
- Code content alignment (advanced): `Left`, `Center`, `Right`.
- Markdown RAW content alignment (advanced): `Left`, `Center`, `Right`.

### Markdown
- Default mode (`RAW` or `RENDERED`).
- Show/hide inline images.
- Use syntax highlighting in RAW mode.
- Show/hide rendered TOC sidebar.
- Set TOC default state (open/hidden) when TOC is enabled.
- Markdown rendered font size.
- Markdown rendered width mode (`Auto`/`Custom`) with configurable custom max width.
- Markdown rendered content alignment (advanced): `Left`, `Center`, `Right`.
- Custom CSS injection.
- Optional built-in CSS override mode.

### File Types
- Enable/disable built-in mappings.
- Add/edit/delete custom mappings.
- Map by extension or by filename.
- Override built-in mapping with confirmation.
- Choose highlight language from picker.

### Performance & Cache
- Toggle performance logging.
- Toggle preview cache.
- Cache TTL (`5-600s`).
- Cache size (`10-500 MB`).
- Clear preview cache action.

## Support Stats (Current Repository State)

These numbers are from the current codebase.

| Metric | Value |
|---|---:|
| Built-in file type entries (`DefaultFileTypes.json`) | `402` |
| Explicit extensions in registry | `592` |
| Filename patterns in registry | `295` |
| Tree-sitter grammar integrations (`TreeSitterHighlighter`) | `53` |
| Tree-sitter query files (`TreeSitterQueries/*.scm`) | `53` |
| Highlight language picker options | `55` |
| Picker options with tree-sitter grammar label | `52` |
| Copy behavior presets | `8` |
| Themes (including system-following pairs) | `14` |
| UTExportedTypeDeclarations in `project.yml` | `573` |
| QLSupportedContentTypes per extension target | `690` |

## Website And Download Analytics

The marketing site in `site/` now records visitor and download intent in three layers:

- Vercel Analytics for aggregated site traffic and custom events
- Optional Google Analytics / Google tag instrumentation when `NEXT_PUBLIC_GOOGLE_TAG_ID` or `NEXT_PUBLIC_GA_MEASUREMENT_ID` is set
- First-party PostgreSQL analytics tables, written through Drizzle, for raw `analytics_page_views` and `analytics_downloads` data

This means download CTA clicks, checksum clicks, and stable `/download/latest` redirects can all be inspected in the database alongside Vercel's hosted analytics views.

Site-specific setup and query examples live in [site/README.md](/Users/stian/Developer/macOS%20Apps/v2.5/site/README.md).

## Known macOS Platform Limitations

These are not dotViewer defects; they are Quick Look routing/host constraints.

- `.ts` conflict: macOS often routes `.ts` to MPEG transport stream preview (`public.mpeg-2-transport-stream`) before third-party code previewers.
- Open With defaults do not change Quick Look routing for system-owned UTIs (they only affect double-click/open behavior).
- `.html` conflict: macOS native HTML renderer takes priority for many `.html` files.
- `Cmd+C` interception: Quick Look host intercepts keyboard copy before WebKit DOM handlers, which is why dotViewer provides copy behavior presets.
- Catch-all unknown extensions: Quick Look extension routing is exact UTI-match based, so truly novel `dyn.*` types are not fully catchable by third-party `.appex` plugins.

See `KNOWN_ISSUES.md` for full technical detail.

## Architecture (Short)

- Preview path: `QuickLookExtension` -> file inspect -> `HighlightXPC` -> HTML assembly (`PreviewHTMLBuilder`).
- Thumbnail path: `QuickLookThumbnailExtension` -> snippet extraction -> tokenization (tree-sitter or fallback) -> CoreGraphics render.
- Shared settings: synchronized via App Group `group.stianlars1.dotViewer.shared`.
- Source of truth for project metadata: `dotViewer/project.yml` (XcodeGen-managed).

## Installation and Usage

Requirements:
- macOS 15.0+
- Xcode + command-line tools
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Swift 6

Build and install:

```bash
# Full rebuild + install + extension registration
./scripts/dotviewer-refresh.sh

# Incremental during development
./scripts/dotviewer-refresh.sh --no-clean --no-reset

# Release build
./scripts/dotviewer-refresh.sh --config Release
```

Smoke test preview:

```bash
./scripts/dotviewer-ql-smoke.sh TestFiles/test.json
```

## Development Notes

- Do not edit generated `Info.plist` or `.entitlements` directly.
- `dotViewer/project.yml` is the source of truth.
- Regenerate/build with XcodeGen before xcodebuild flows.
- If you change file type routing, re-check UTI generation scripts and extension content type lists.

Helpful docs:
- `CLAUDE.md` for architecture and workflow.
- `KNOWN_ISSUES.md` for active limitations and platform constraints.
- `BACKLOG.md` for planned improvements.

## AI Context Pack

If you paste this README into another AI chat, the model should understand:
- dotViewer is a macOS Quick Look developer-focused preview/thumbnail suite.
- It uses dual rendering pipelines (HTML preview, CoreGraphics thumbnail).
- Syntax highlighting is tree-sitter-first with heuristic fallback.
- Markdown supports full raw/rendered workflows with TOC and print styles.
- Copy behavior is intentionally configurable (8 presets) due Quick Look keyboard interception.
- File routing quality is driven by large UTI coverage + registry matching.
- The app is highly configurable and designed for fast Finder-native code inspection.

## License

GPLv3. See `dotViewer/ATTRIBUTION.md` for third-party acknowledgments.
