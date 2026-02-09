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
| **Priority** | Critical |
| **Status** | Open |

**Impact**: Finder thumbnails (icon view, column view) may not match the visual quality of the spacebar Quick Look preview. Font rendering, color accuracy, and layout differ between the CoreGraphics-based thumbnail path and the HTML-based preview path.

**Root cause**: Thumbnails use native CoreGraphics text rendering (NSAttributedString drawn to NSImage), while previews use WKWebView-rendered HTML. These are fundamentally different rendering pipelines with different font metrics, anti-aliasing, and color handling.

**Reproduction**: Compare a file's Finder column-view thumbnail with its spacebar Quick Look preview. Note differences in font rendering, spacing, and color saturation.

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
| **Priority** | High |
| **Status** | Partially Fixed |

**Impact**: Rendered markdown preview works but doesn't yet match Typora-quality typography and spacing. Core features render correctly; polish and edge cases remain.

**Root cause (original)**: MarkdownRenderer.swift was a line-by-line custom parser with fundamental bugs (task lists never rendered, every line became its own `<p>`, tables and images not parsed, blockquotes fragmented). CSS styling was incomplete.

**Progress (2026-02-09)**:
- **Parser rewrite**: MarkdownRenderer.swift fully rewritten (~510 lines) with proper two-pass parsing (block-level + character-by-character inline). Supports: ATX/setext headings, fenced code blocks with language labels, GFM tables with alignment, blockquotes (recursive), ordered/unordered/task lists, images, links, bold, italic, bold+italic, strikethrough, inline code, horizontal rules, auto-linking bare URLs.
- **CSS overhaul**: PreviewHTMLBuilder.swift rendered-view CSS rebuilt with theme-aware variables (`--heading`, `--surface`, `--border`, `--link`), per-theme heading colors, table row striping, tighter list spacing, v1-matching heading sizes, code block styling, and task list checkbox support.
- **Toggle routing fix**: `isMarkdown` check changed from key-based to `languageId == "markdown"`, fixing README.md, CHANGELOG.md, and other named markdown files that previously didn't show the RAW/RENDERED toggle.

**Remaining gap**: Spacing and typography refinements to approach Typora-level polish. Line height, paragraph spacing, heading weight/margins, and overall rhythm need further tuning based on side-by-side comparison.

**Reproduction**: Preview a complex `.md` file in rendered mode → compare spacing/typography with Typora rendering.

**Acceptance criteria**: Rendered markdown should match Typora/GitHub quality — proper heading hierarchy, styled code blocks, working tables, correct list nesting, and readable typography.

---

## KI-005 — Unknown textual extensions fall back to generic icon

| Field | Value |
|-------|-------|
| **Priority** | High |
| **Status** | Open |

**Impact**: Text files with extensions not in our registry (or not mapped to a system UTI in QLSupportedContentTypes) show the generic white document icon instead of a syntax-highlighted thumbnail.

**Root cause**: Quick Look matches on exact UTI, not conformance. If a file's UTI isn't in our QLSupportedContentTypes list, our extension is never called. Files with unknown extensions often get `public.data` or `dyn.` UTIs that we can't enumerate in advance.

**Reproduction**: Create a file with an uncommon extension (e.g., `.myconfig`) containing text → Finder shows generic icon, spacebar preview may use system plain text viewer.

**Acceptance criteria**: Any file that `looksTextual` should get a dotViewer thumbnail and preview, regardless of extension. This likely requires adding `public.data` or a catch-all UTI to QLSupportedContentTypes (with binary gating to reject actual binary files).

---

## KI-006 — Cross-mode consistency drift (Quick Look vs Finder thumbnail)

| Field | Value |
|-------|-------|
| **Priority** | High |
| **Status** | Open |

**Impact**: The Quick Look spacebar preview and the Finder thumbnail for the same file may show different theme colors, font sizes, or layout. Changes to PreviewHTMLBuilder CSS don't automatically propagate to TextThumbnailRenderer.

**Root cause**: Two separate rendering pipelines — HTML/CSS for previews, CoreGraphics/NSAttributedString for thumbnails. Theme colors are defined in ThemePalette.swift (shared) but applied differently in each renderer. Any CSS change requires a corresponding CoreGraphics change.

**Reproduction**: Change theme in settings → compare spacebar preview colors with Finder thumbnail colors for the same file.

**Acceptance criteria**: Both rendering paths should produce visually consistent output for the same file/theme combination. Theme palette changes should automatically apply to both paths.

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
| **Status** | Open |

**Impact**: Build-time audit (`dvaudit`) reports 14 duplicate extension warnings where multiple JSON entries claim the same file extension. Only the first-loaded entry wins for each extension.

**Root cause**: Inherited from the original SourceCodeSyntaxHighlight import. Some extensions legitimately belong to multiple languages (e.g., `.m` for Objective-C and MATLAB), and the current resolution is first-loaded-wins.

**Reproduction**: Run `./scripts/dotviewer-gen-default-filetypes.py` (dvaudit) → see duplicate extension warnings in output.

**Acceptance criteria**: Either resolve duplicates by choosing a canonical owner for each extension, or add explicit priority/precedence to the JSON schema so the resolution is intentional rather than load-order-dependent.

---

## KI-009 — Cmd+C doesn't copy selected text in Quick Look preview

| Field | Value |
|-------|-------|
| **Priority** | High |
| **Status** | Open |

**Impact**: Users cannot copy selected text from the Quick Look preview window using Cmd+C. Text can be visually selected but the keyboard shortcut does nothing.

**Root cause**: Quick Look data-based previews (`QLPreviewReply` with HTML content) render in a sandboxed web view that doesn't pass standard keyboard shortcuts through to the HTML content. The copy-to-clipboard button in the header copies the entire file, but there's no way to copy a text selection via Cmd+C.

**Reproduction**: Preview any file → select text in the preview window → press Cmd+C → paste elsewhere → nothing was copied.

**Acceptance criteria**: Cmd+C should copy the currently selected text from the Quick Look preview to the system clipboard. If this is a Quick Look sandbox limitation, document it as such and ensure the existing copy button is prominently discoverable.
