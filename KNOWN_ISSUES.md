# Known Issues

## KI-001 — .ts files routed as MPEG-2 transport stream

| Field | Value |
|-------|-------|
| **Priority** | Critical |
| **Status** | Won't Fix (macOS limitation) |

**Impact**: TypeScript `.ts` files are previewed by the system video player instead of dotViewer. Users see a black video player frame or an error.

**Root cause**: macOS maps `.ts` → `public.mpeg-2-transport-stream` (conforms to `public.movie`). The built-in video previewer claims `public.movie` with higher priority than any third-party Quick Look extension. Our custom UTI declaration (`com.stianlars1.dotviewer.typescript` claiming `.ts`) doesn't override the system resolution.

**Reproduction**: Select any `.ts` file in Finder → press Space → system video previewer appears instead of dotViewer.

**Workaround**: TypeScript files with `.tsx`, `.cts`, and `.mts` extensions work correctly. The `.ts` extension specifically conflicts because it's also used for MPEG-2 transport streams.

**Acceptance criteria**: N/A — macOS system limitation. Both `public.mpeg-2-transport-stream` and `com.stianlars1.dotviewer.typescript` remain in QLSupportedContentTypes in case future macOS versions allow override.

---

## KI-002 — Finder thumbnail quality/parity with Quick Look preview

| Field | Value |
|-------|-------|
| **Priority** | Medium |
| **Status** | Partially Fixed |

**Impact**: Finder thumbnails (icon view, column view) may not match the visual quality of the spacebar Quick Look preview. Font rendering, color accuracy, and layout differ between the CoreGraphics-based thumbnail path and the HTML-based preview path.

**Root cause**: Thumbnails use native CoreGraphics text rendering (NSAttributedString drawn to NSImage), while previews use WKWebView-rendered HTML. These are fundamentally different rendering pipelines with different font metrics, anti-aliasing, and color handling.

**Progress (2026-02-09)**: Added `ThumbnailSyntaxColorizer` to `TextThumbnailRenderer.swift` — regex-based colorizer that identifies comments, strings, keywords (100+), numbers, and types (CamelCase heuristic) per token. Thumbnails now show multi-color syntax highlighting instead of single-color text, significantly improving visual parity with previews.

**Remaining gap**: Regex-based colorizer is an approximation — it won't match tree-sitter accuracy for all languages. Color mapping uses ThemePalette but font weight/style differences remain.

**Reproduction**: Compare a file's Finder column-view thumbnail with its spacebar Quick Look preview. Colors now match closely; fine rendering differences (anti-aliasing, font metrics) remain.

**Acceptance criteria**: Thumbnails should be visually consistent with preview output — same theme colors, proportional font sizing, and readable syntax highlighting at typical Finder thumbnail sizes.

---

## KI-003 — Markdown RAW mode lacks structure/readability

| Field | Value |
|-------|-------|
| **Priority** | Medium |
| **Status** | Partially Fixed |

**Impact**: When viewing markdown files in raw mode, the preview shows plain source text without meaningful visual structure. Headers, lists, and code blocks are not visually differentiated.

**Root cause**: Raw markdown mode uses the same syntax highlighting pipeline as code files, which doesn't understand markdown semantics (headers, emphasis, lists). Tree-sitter markdown grammar tokens don't map well to the current 18-token CSS palette.

**Progress (2026-02-09)**: Added text-semantic capture mappings in TreeSitterHighlighter.swift (`text.title` → keyword, `text.literal` → string, `text.uri` → link, `text.emphasis` → type, `text.strong` → keyword, `text.reference` → variable). Fixed markdown.scm to remove fenced_code_block from `@text.literal` group. Raw mode now shows basic structural differentiation via colors.

**Remaining gap**: Structure is color-differentiated but not size/weight-differentiated. Headers aren't larger/bolder, code blocks don't have background. This would require CSS-level semantic targeting (e.g., `span.keyword` inside markdown getting different font-weight), which is outside the current token→CSS architecture.

**Reproduction**: Preview any `.md` file with headers, lists, and code blocks → raw mode shows color-coded but not structurally distinct text.

**Acceptance criteria**: Raw mode should visually differentiate markdown structural elements (headers larger/bolder, code blocks with background, lists indented) while still showing the raw markdown syntax characters.

---

## KI-004 — Markdown RENDERED mode styling gap vs Typora

| Field | Value |
|-------|-------|
| **Priority** | Low |
| **Status** | Mostly Fixed |

**Impact**: Rendered markdown preview works but doesn't yet match Typora-quality typography and spacing. Core features render correctly; minor polish remains.

**Root cause (original)**: MarkdownRenderer.swift was a line-by-line custom parser with fundamental bugs (task lists never rendered, every line became its own `<p>`, tables and images not parsed, blockquotes fragmented). CSS styling was incomplete.

**Progress (2026-02-09)**:
- **Parser rewrite**: MarkdownRenderer.swift fully rewritten (~510 lines) with proper two-pass parsing (block-level + character-by-character inline). Supports: ATX/setext headings, fenced code blocks with language labels, GFM tables with alignment, blockquotes (recursive), ordered/unordered/task lists, images, links, bold, italic, bold+italic, strikethrough, inline code, horizontal rules, auto-linking bare URLs.
- **CSS overhaul**: PreviewHTMLBuilder.swift rendered-view CSS rebuilt with theme-aware variables (`--heading`, `--surface`, `--border`, `--link`), per-theme heading colors, table row striping, tighter list spacing, v1-matching heading sizes, code block styling, and task list checkbox support.
- **Toggle routing fix**: `isMarkdown` check changed from key-based to `languageId == "markdown"`, fixing README.md, CHANGELOG.md, and other named markdown files that previously didn't show the RAW/RENDERED toggle.
- **CSS polish pass**: Tightened line-height (1.6→1.7), heading margins, paragraph spacing (16→12px), list spacing (4→2px), blockquote with accent border + background, code blocks with accent left border, HR 2→1px.
- **Table of Contents**: Sidebar TOC with heading navigation, toggleable from preview header. Properly skips fenced code blocks when scanning for headings. Hidden in RAW mode, only shown in RENDERED mode.

**Remaining gap**: Minor typography refinements. Side-by-side with Typora shows dotViewer is now close but not pixel-identical.

**Reproduction**: Preview a complex `.md` file in rendered mode → compare spacing/typography with Typora rendering.

**Acceptance criteria**: Rendered markdown should match Typora/GitHub quality — proper heading hierarchy, styled code blocks, working tables, correct list nesting, and readable typography.

---

## KI-005 — Unknown textual extensions fall back to generic icon

| Field | Value |
|-------|-------|
| **Priority** | High |
| **Status** | Fixed |

**Impact**: Text files with extensions not in our registry (or not mapped to a system UTI in QLSupportedContentTypes) show the generic white document icon instead of a syntax-highlighted thumbnail.

**Root cause**: Quick Look matches on exact UTI, not conformance. If a file's UTI isn't in our QLSupportedContentTypes list, our extension is never called.

**Fix (2026-02-09)**: `public.data` already present in QLSupportedContentTypes for both preview and thumbnail extensions, serving as a catch-all. Combined with `looksTextual` binary gating, this ensures unknown text files get dotViewer previews while binary files are rejected.

---

## KI-006 — Cross-mode consistency drift (Quick Look vs Finder thumbnail)

| Field | Value |
|-------|-------|
| **Priority** | Medium |
| **Status** | Partially Fixed |

**Impact**: The Quick Look spacebar preview and the Finder thumbnail for the same file may show different theme colors, font sizes, or layout. Changes to PreviewHTMLBuilder CSS don't automatically propagate to TextThumbnailRenderer.

**Root cause**: Two separate rendering pipelines — HTML/CSS for previews, CoreGraphics/NSAttributedString for thumbnails. Theme colors are defined in ThemePalette.swift (shared) but applied differently in each renderer.

**Progress (2026-02-09)**: Added `ThumbnailSyntaxColorizer` — thumbnails now use per-token coloring (keywords, strings, comments, numbers, types) matching the same ThemePalette colors used in previews. Visual parity significantly improved.

**Remaining gap**: Font weight/style (bold keywords, italic builtins) not replicated in thumbnail renderer. Regex-based colorizer may disagree with tree-sitter on token boundaries.

**Reproduction**: Change theme in settings → compare spacebar preview colors with Finder thumbnail colors for the same file. Colors now match closely.

**Acceptance criteria**: Both rendering paths should produce visually consistent output for the same file/theme combination.

---

## KI-007 — HTML files rendered by macOS native handler

| Field | Value |
|-------|-------|
| **Priority** | Low |
| **Status** | Won't Fix (macOS limitation) |

**Impact**: `.html` files are rendered as web pages (like a browser) by macOS's built-in Quick Look HTML renderer, instead of showing syntax-highlighted source code.

**Root cause**: macOS Quick Look has a native HTML renderer that claims `public.html` with system priority. Third-party extensions cannot override it.

**Reproduction**: Select any `.html` file → press Space → macOS renders it as a web page.

**Acceptance criteria**: N/A — macOS system limitation. `public.html` remains in QLSupportedContentTypes in case future macOS versions allow override.

---

## KI-008 — 14 duplicate extension warnings in registry

| Field | Value |
|-------|-------|
| **Priority** | Low |
| **Status** | Fixed |

**Impact**: Build-time audit (`dvaudit`) reported 14 duplicate extension warnings where multiple JSON entries claimed the same file extension.

**Fix (2026-02-09)**: Resolved duplicate extensions by choosing canonical owners: removed `.i` from ALAN (kept in C), `.asm` from fasm (kept in Assembly), `.ex` from Euphoria (kept in Elixir), changed `.pro` to `.pri` for QMake (kept `.pro` for Prolog), removed `.cgi` from Ruby (kept in Perl), deduplicated `.bashrc`/`.zshrc` from shell JSON (already in hardcoded shellrc entry), deduplicated case-insensitive filenames (makefile, justfile).

---

## KI-009 — Cmd+C doesn't copy selected text in Quick Look preview

| Field | Value |
|-------|-------|
| **Priority** | High |
| **Status** | Fixed (workaround) |

**Impact**: Users cannot copy selected text from the Quick Look preview window using Cmd+C. Copy button and right-click "Copy" work, but the keyboard shortcut does not.

**Root cause**: Quick Look's host window intercepts keyboard events at the NSResponder chain level before they reach the WKWebView's DOM. The `keydown` and `copy` events never fire in JavaScript. This is a confirmed platform limitation affecting all data-based HTML Quick Look extensions on macOS.

**Fix (2026-02-10)**: Auto-copy on selection — a debounced `mouseup` listener detects text selections and automatically copies them to the clipboard using `navigator.clipboard.writeText()`. Mouse events reach WebKit's DOM (unlike keyboard events), and `mouseup` counts as a trusted user gesture for the Clipboard API. A 150ms debounce ensures triple-click (select line) only triggers one copy. A "Copied selection" toast confirms the action. Works in both code previews and markdown (raw + rendered).

**What still works**: Copy button (copies full file or selection), right-click context menu "Copy" (WKWebView native), selection-aware copy button with dynamic tooltip.

### Approaches Tried (2026-02-09/10)

**1. JavaScript `copy` event listener** — Replaced `keydown` with `copy` DOM event. Result: `copy` event also does not fire because Quick Look intercepts Cmd+C before it reaches the WebKit layer at all.

**2. CGEventTap helper (CopyHelper)** — Built an unsandboxed background app embedded in `Contents/Helpers/` that creates a `CGEventTap` to intercept Cmd+C globally, detect Quick Look via `CGWindowListCopyWindowInfo`, and read selected text via `AXUIElement` Accessibility API. Result: **TCC blocks it**. Detailed findings:

- **Sandbox inheritance**: When a sandboxed app (dotViewer) launches a child process via `Process()` (fork/exec), the child inherits the parent's sandbox. The helper cannot get Accessibility permission.
- **TCC "responsible process" attribution**: Even when launched via `NSWorkspace.openApplication()` (LaunchServices), TCC attributes embedded helpers to the host app. Since dotViewer is sandboxed, the accessibility request is denied.
- **Hardened Runtime required**: TCC requires `flags=0x10000(runtime)` for `AXIsProcessTrustedWithOptions` to show the system prompt. Debug builds default to `flags=0x0`.
- **Bare executables invisible to TCC**: Command-line tools (`type: tool`) without `.app` bundle + Info.plist don't appear in the Accessibility preferences list at all.
- Even after addressing all above (proper `.app` bundle, Hardened Runtime, LaunchServices launch, DistributedNotificationCenter for IPC), the helper still does not appear in the Accessibility list — likely because TCC traces back to the sandboxed parent as the responsible code.

### Approaches NOT Yet Tried

| Approach | Description | Complexity |
|----------|-------------|------------|
| **Independently-installed helper** | Ship CopyHelper.app as a separate app (not embedded), installed to `~/Library/Application Support/` or `/Applications/`. Avoids TCC parent attribution. This is how Peek (commercial QL extension) does it. | Medium |
| **Remove sandbox from host app** | dotViewer is not on the App Store. Removing sandbox lets the host app itself call `CGEventTap`/`AXUIElement` directly — no helper needed. Extensions keep their own sandbox. | Low (but changes security posture) |
| **Unsandboxed XPC service for clipboard** | Add a clipboard-write method to an unsandboxed XPC service. May avoid the keyboard interception problem if the QL extension can detect selections and push to clipboard server-side. | Medium |
| **NSPasteboard from QL extension directly** | Test whether `NSPasteboard.general.setString()` works from the sandboxed Quick Look extension process. If it does, we could write a selection-to-clipboard mechanism without Accessibility at all. | Low |
| **`responsibility_spawnattrs_setdisclaim`** | Undocumented Apple API that lets a parent process disclaim TCC responsibility for a child. Used by Qt Creator and LLDB. Fragile — may break in future macOS versions. | High risk |

### Key Research Sources

- Apple Developer Forums: sandbox inheritance ([thread 123873](https://developer.apple.com/forums/thread/123873)), responsible code attribution ([thread 718728](https://developer.apple.com/forums/thread/718728))
- Apps like Rectangle, Hammerspoon, Raycast all request Accessibility from **unsandboxed** main apps — none use embedded sandboxed helpers
- Peek (BigZLabs) uses a separate independently-installed helper app for Accessibility
- Qt Blog: ["The Curious Case of the Responsible Process"](https://www.qt.io/blog/the-curious-case-of-the-responsible-process) documents `responsibility_spawnattrs_setdisclaim`

**Acceptance criteria**: Cmd+C copies selected text from Quick Look preview without requiring the user to use the copy button or right-click menu.
