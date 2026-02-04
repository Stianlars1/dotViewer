# Quick Look Architecture Patterns (Synthesis)

This document synthesizes architecture patterns across all scanned Quick Look plugins, highlighting how to structure dotViewer's preview stack and where to borrow proven approaches.

## 1) Plugin Types & OS Compatibility

## Legacy Quick Look Generators (`.qlgenerator`)
- Entry points: `GeneratePreviewForURL.*`, `GenerateThumbnailForURL.*`, `main.c`.
- Used by most older plugins (QLStephen, QLColorCode, QLMarkdownGFM, etc.).
- macOS 15 Sequoia deprecates `.qlgenerator` (see Eclectic Light + MJTsai links in Source Index).

## Modern Quick Look App Extensions (`.appex`)
- Entry points: `QLPreviewingController` (view-based) or `QLPreviewReply` (data-based).
- For data-based previews, the preview principal class should subclass `QLPreviewProvider` and implement `providePreview(for:completionHandler:)` (Swift may import this as an async `providePreview(for:)`).
- Examples: **sbarex/SourceCodeSyntaxHighlight**, **sbarex/QLMarkdown**.
- Sandboxed; external processes are blocked unless moved to a helper/XPC service.

**dotViewer recommendation:** Treat `.qlgenerator` repos as patterns only. Implement via app extension + XPC.

## 2) Rendering Pipelines

### A. HTML (Most Common)
Used by QLMarkdown (toland), QLCommonMark, QLMarkdownGFM, QuickJSON, QuickLookPrettyJSON, QLAddict, quicklook-csv, ipynb-quicklook, quickgeojson, quicklook-gpx, etc.

**Key patterns:**
- **Template + placeholder substitution**: `template.html` with `{{DATA}}` placeholder (ipynb-quicklook, quickgeojson, quicklook-gpx).
- **Inline HTML/JS/CSS**: QuickJSON and QuickLookPrettyJSON embed all assets directly in the HTML string.
- **Bundled assets attached via QLPreview properties**: inloop/qlplayground uses `kQLPreviewPropertyAttachmentsKey` to attach JS/CSS without filesystem access.

### B. Plain Text Delegation
- Example: **QLGradle** delegates to `QLPreviewRequestSetURLRepresentation` with `kUTTypePlainText`.
- Example: **QLStephen** delegates when size is small, falls back to data representation when large.

### C. Image/Vector Drawn Previews
- Example: **quicklook-dot** renders DOT -> PNG and draws into a QL context.
- Example: **QLAnsilove** renders ANSI art to image via embedded framework.

### D. RTF / NSTextView (modern fallback)
- Example: **SourceCodeSyntaxHighlight** uses RTF for stability on macOS 11-12 (noting WebKit bugs in Quick Look).

## 3) Heavy Processing & Sandboxing

### External Processes (Legacy Pattern)
- AsciiDocQuickLook -> `asciidoctor`
- QLColorCode -> `highlight` CLI
- quicklook-dot -> `dot`
- qlvega -> `vg2svg` / `vl2svg`
- Java-Class-QuickLook -> `java -jar`

**In app extensions, external processes are not allowed.**

### XPC Helper Pattern (Modern)
- **SourceCodeSyntaxHighlight** and **QLMarkdown** offload rendering to XPC helpers.
- XPC services can be configured with different sandbox rules and terminate after preview closes.

**dotViewer recommendation:** heavy parsing/highlighting should move into a dedicated XPC helper, mirroring sbarex's architecture.

## 4) UTI Registration & Dynamic UTIs

- Most plugins declare UTIs in `Info.plist` via `UTImportedTypeDeclarations` and `CFBundleDocumentTypes`.
- Some plugins explicitly support **dynamic UTIs** (e.g., QLMarkdown and SourceCodeSyntaxHighlight handle dynamic UTIs for unassociated file types).
- In practice on macOS 15+, **Quick Look routing may require exact UTType identifiers in `QLSupportedContentTypes`**.
  For example, a `.py` file’s primary UTI is typically `public.python-script` (which *conforms* to `public.source-code`),
  but dotViewer still won’t be invoked unless `public.python-script` is explicitly listed.

**dotViewer recommendation:** Keep a robust UTI resolution layer with fallbacks for dynamic UTIs and unknown extensions.
Also treat `dotViewer/project.yml` as the source of truth for extension registration, and keep `QLSupportedContentTypes`
in sync with the real UTIs seen on your system (`mdls -name kMDItemContentType <file>`).

## 5) Configuration & Preferences

- **NSUserDefaults** for user-set theme, fonts, max file size, etc. (QLColorCode, QLAddict, qlplayground).
- **Custom theme files** loaded from bundle or user support directories (QLMarkdown, SourceCodeSyntaxHighlight).

**dotViewer recommendation:** centralize preferences in the app and sync to extension/XPC via shared defaults or IPC.

## 6) Suggested Architecture for dotViewer

### Recommended Flow
1. **Quick Look Extension** detects file type, reads basic metadata, and delegates heavy work.
2. **XPC Renderer** performs parsing, highlighting, or conversion (highlight/cmark/tree-sitter).
3. **Preview Reply** returns HTML with attached assets, RTF for stability on older macOS versions, or plain-text delegation for unknown file types.

### Concrete Pattern Sources
- XPC + Highlight: `Repos/sbarex-SourceCodeSyntaxHighlight.md`
- Markdown extension + cmark-gfm: `Repos/sbarex-QLMarkdown.md`
- Plain text fallback + size caps: `Repos/whomwah-qlstephen.md`
- HTML attachments for JS/CSS: `Repos/inloop-qlplayground.md`
