# Performance, Sandboxing & Compatibility

This document condenses performance and platform constraints observed across the scanned Quick Look plugins.

## Performance Patterns (Proven)

### 1) File Size Caps & Truncation
- **QLStephen**: hard max size with data-representation fallback.
- **QLColorCode**: `maxFileSize` preference.
- **quicklook-csv**: row limit (`MAX_ROWS 500`).

**dotViewer action:** enforce max bytes/lines before parsing/highlighting.

### 2) Early Cancellation
Most generators check `QLPreviewRequestIsCancelled` before and after expensive work.

**dotViewer action:** add fast cancellation checkpoints in both extension and XPC.

### 3) Streaming Reads
- **QuickNFO** uses CFReadStream to avoid large memory spikes.

**dotViewer action:** stream large files and cap memory use.

### 4) Native Parsers (C/C++)
- **cmark-gfm** for Markdown.
- **Highlight** for syntax highlighting.

**dotViewer action:** avoid JS-based parsing for large files; use native libs.

## Sandboxing Constraints (macOS 10.15+)

### App Extension Rules
- Extensions are sandboxed; **external processes are blocked**.
- Many legacy generators (Asciidoctor, Graphviz, Vega) rely on external CLI tools.

### Entitlements Are Part of “It Loads” (Not Just Permissions)
On macOS 15+, missing/incorrect entitlements can prevent a Quick Look app extension from being discovered or instantiated at all.
In practice, Quick Look preview + thumbnail extensions generally need:
- `com.apple.security.app-sandbox` = `true`
- read access for the previewed file (commonly `com.apple.security.files.user-selected.read-only`)
- App Group entitlement if you expect shared settings (`com.apple.security.application-groups`)

### Workarounds
- **XPC helper** with relaxed sandbox (SourceCodeSyntaxHighlight, QLMarkdown).
- **Embedded native libraries** (cmark-gfm, highlight).

## Compatibility Timeline

### macOS 10.15 (Catalina)
- App extensions preferred.
- Some UTIs (e.g., `.xml`, `.plist`) initially restricted for custom QL support.

### macOS 12 (Monterey)
- Data-based `QLPreviewReply` API is recommended for extensions.

### macOS 15 (Sequoia)
- `.qlgenerator` plugins are deprecated/unsupported.
- Extensions must be used for Quick Look previews.
- For many script/source UTIs, Quick Look selection may require an **exact** UTI identifier in `QLSupportedContentTypes`
  (e.g. `public.python-script`, `com.netscape.javascript-source`) rather than relying on conformance to `public.source-code`.
- Some extensions remain system-reserved (not reliably overridable), such as `.txt` and MPEG transport stream types (`.ts`, `.mts`).

## Rendering Engine Tradeoffs

### HTML/WebKit
- Great for rich formatting, but Quick Look WebKit was flaky on macOS 11 (Big Sur) for some plugins.

### RTF/NSTextView
- Used by **SourceCodeSyntaxHighlight** as a stability fallback on macOS 11-12.

### Plain-Text Delegation
- **QLGradle** and **QLStephen** show that letting the system render plain text is extremely fast and safe.

## Quarantine / Installation Issues
- Catalina+ often requires `xattr -d -r com.apple.quarantine` for manually installed plugins.
- App extensions typically need the host app launched once to register.

## dotViewer Recommendations

1. **Adopt an XPC renderer** for syntax highlighting and heavy parsing.
2. **Implement size caps** before highlighting (bytes + line count).
3. **Prefer native libraries** (Highlight, cmark-gfm).
4. **Provide a plain-text fallback** for unknown files and failure cases.
5. **Use HTML attachments** rather than filesystem access when bundling JS/CSS.
