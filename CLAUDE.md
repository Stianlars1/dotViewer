# dotViewer

macOS Quick Look extension for syntax-highlighted previews of source code, config files, and dotfiles.

## Prior Work & Context
Before starting any analysis, planning, or research task, ALWAYS ask: 'Is there existing prior work, plans, or research I should read first?' Check for existing plan documents, memory files, and previous session artifacts before doing independent exploration.

## Planning vs Execution
Do NOT spend more than ~20% of session time planning. When a plan exists, move to implementation immediately. If you catch yourself creating plan documents, asking repeated clarifying questions, or 'exiting plan mode' without writing code — STOP and start executing. The user will redirect if the approach is wrong.

## Output Delivery
Always produce a deliverable artifact (code change, document, or concrete answer) within the first ~30 minutes of a session. Never spend an entire session only reading files, writing internal plans, or asking questions without giving the user something tangible.

## Product Direction

Best-in-class Quick Look code previewer for macOS. Typora-quality markdown rendering. Seamless Finder integration with consistent thumbnails and previews. Support every text-based file a developer encounters.

## Build

Requires: Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen), macOS 15.0+, Swift 6.

```bash
# Full rebuild: reset QL cache → xcodegen → clean build → install → register extensions
./scripts/dotviewer-refresh.sh

# Incremental (skip clean + QL reset)
./scripts/dotviewer-refresh.sh --no-clean --no-reset

# Build only, no install/open
./scripts/dotviewer-refresh.sh --no-install --no-open

# Release build
./scripts/dotviewer-refresh.sh --config Release
```

The build workflow is: `xcodegen generate` → `xcodebuild` → `ditto` to `/Applications` → `pluginkit -e use` → `qlmanage -r`.

XcodeGen regenerates the `.xcodeproj`, all `Info.plist` files, and `.entitlements` files from `dotViewer/project.yml`. **Never edit these generated files directly** — all persistent changes go in `project.yml`.

## Architecture

Four targets, defined in `dotViewer/project.yml`:

```
dotViewer.app (host app)
├── QuickLookExtension (app-extension: com.apple.quicklook.preview)
│   └── HighlightXPC (xpc-service: syntax highlighting)
├── QuickLookThumbnailExtension (app-extension: com.apple.quicklook.thumbnail)
└── Shared.framework (shared code used by all targets)
```

### Shared (framework)
Common code linked by every target. Key files:
- `FileTypeRegistry.swift` — maps file extensions/UTIs to languages and grammars
- `FileTypeResolution.swift` — routing logic, `bestKey(...)` for dotfile/multi-dot names
- `FileAttributes.swift` — metadata + `looksTextual` binary detection heuristic
- `FileInspector.swift` — combines UTType, MIME, and byte-level analysis
- `PreviewHTMLBuilder.swift` — generates HTML for Quick Look previews (themes, line numbers, font size)
- `ThemePalette.swift` — 18-token color palette per theme
- `HighlightProtocol.swift` — `@objc` XPC protocol: `highlight(code:language:theme:...)` and `cancel(requestId:)`
- `HighlightXPCClient.swift` — NSXPCConnection wrapper for calling the XPC service
- `SharedSettings.swift` — App Group (`group.stianlars1.dotViewer.shared`) settings sync
- `MarkdownRenderer.swift`, `PlainTextRenderer.swift` — specialized renderers
- `PlistConverter.swift` — binary plist → XML conversion
- `TransportStreamDetector.swift` — MPEG-TS detection to avoid hijacking `.ts` video files
- `SensitiveFileDetector.swift` — warns on `.env`, credentials, keys

### QuickLookExtension
Entry point: `PreviewProvider.swift` (subclass of `QLPreviewProvider`). Uses data-based previews (`QLIsDataBasedPreview: true`).
- `PreviewRequestCoordinator.swift` — orchestrates file inspection → XPC highlight → HTML assembly

### QuickLookThumbnailExtension
Entry point: `ThumbnailProvider.swift` (subclass of `QLThumbnailProvider`).
- `TextThumbnailRenderer.swift` — native CoreGraphics text rendering (no WKWebView)

### HighlightXPC (xpc-service)
Runs out-of-process. Provides syntax highlighting via tree-sitter.
- `main.swift` — `NSXPCListener.service()` setup
- `HighlightService.swift` — implements `HighlightServiceProtocol`
- `TreeSitterHighlighter.swift` — tree-sitter parsing + heuristic fallback for unknown grammars
- `TreeSitterQueries/` — `.scm` highlight query files per language
- `TreeSitterVendor/` — vendored tree-sitter core + language grammars (C sources compiled into the XPC target)
- Bridging header: `HighlightXPC-Bridging-Header.h`

### Host App
Settings UI for the extension (font size, theme). Source in `dotViewer/App/`.
- `dotViewerApp.swift`, `ContentView.swift`, `SettingsView.swift`
- `StatusView.swift` — shows extension registration status
- `Utilities/ExtensionHelper.swift`, `ExtensionStatusChecker.swift`

## Required Features

Canonical scope — what this product must support:

- **Syntax highlighting**: tree-sitter grammars + heuristic fallback, 18-token color palette via `TokenType` enum
- **Markdown**: raw mode (color + size/weight differentiation), rendered mode (Typora-quality HTML with clickable links)
- **Thumbnails**: full-bleed Finder thumbnails with bold/italic token styling, dark mode aware
- **Preview header**: file type badge, file size, copy-to-clipboard button, markdown mode toggle
- **Search**: optional search bar with match highlighting and prev/next navigation (off by default)
- **Line highlighting**: click line numbers to highlight, Shift+click for range selection
- **Responsive sizing**: dynamic preview window dimensions based on content
- **Copy behavior**: 8 configurable presets for how text selections interact with clipboard (auto-copy default)
- **Settings**: font size, theme, word wrap, line numbers, copy behavior, search bar toggle (synced via App Group)
- **Custom file types**: user-defined extension → language mappings
- **File type coverage**: 388 definitions, 561 extensions, 283 filenames
- **Binary gating**: reject binary files, detect MPEG-TS transport streams
- **Sensitive file detection**: warn on .env, credentials, keys
- **Print**: @media print CSS with file title, syntax colors, page breaks

## Key Concepts

- **UTI routing**: Quick Look matches on **exact UTType identifiers** (not conformance). `public.data` in `QLSupportedContentTypes` does NOT catch dynamic UTIs (`dyn.*`). We declare 502 UTIs covering all 561 extensions in DefaultFileTypes.json: 402 custom exports (`com.stianlars1.dotviewer.*`), ~64 system UTIs, ~63 vendor UTIs. Pre-computed `dyn.*` codes were removed (non-functional — encoding mismatch with macOS). Use `scripts/dotviewer-gen-utis.py` to regenerate from DefaultFileTypes.json. See KI-010.
- **Custom file types**: User-added extensions (via Settings) work for highlighting and display name for files that reach our extension. All 561 extensions in DefaultFileTypes.json are pre-declared as UTIs, so most developer files are routed automatically.
- **Multi-dot file resolution**: `FileTypeResolution.bestKey()` tries full name → progressive prefix stripping → bare extension → intermediate segment scanning. For `.claude.json.backup.xxx`, this resolves to `json`.
- **XPC protocol**: `HighlightServiceProtocol` — the QuickLookExtension calls `highlight(code:language:theme:showLineNumbers:requestId:reply:)` on the XPC service. The reply returns HTML as `NSData`.
- **App Group**: Settings (font size, theme) sync between the host app and extensions via `group.stianlars1.dotViewer.shared`.
- **Binary gating**: `FileAttributes.looksTextual` samples bytes to avoid rendering binary files. `TransportStreamDetector` prevents `.ts` video files from being treated as TypeScript.

## Dev Scripts

Source `scripts/dotviewer-aliases.zsh` for shortcuts:

| Alias      | Script                              | Purpose                                    |
|------------|-------------------------------------|--------------------------------------------|
| `dvrefresh`| `dotviewer-refresh.sh`              | Full rebuild + install + register          |
| `dvlogs`   | `dotviewer-logs.sh`                 | Stream/query unified logs by subsystem     |
| `dvql`     | `dotviewer-ql-status.sh`            | Show extension registration status         |
| `dvsmoke`  | `dotviewer-ql-smoke.sh`             | Smoke test: qlmanage + log capture         |
| `dvutis`   | `dotviewer-gen-ql-content-types.sh` | Regenerate UTI list from FileTypeRegistry  |
| `dvgenutis`| `dotviewer-gen-utis.py`             | Generate UTI declarations from JSON registry|
| `dvaudit`  | `dotviewer-gen-default-filetypes.py`| Audit JSON against codebase                |

Log filtering examples:
```bash
./scripts/dotviewer-logs.sh --preview          # QuickLookExtension only
./scripts/dotviewer-logs.sh --xpc              # HighlightXPC only
./scripts/dotviewer-logs.sh --last 10m         # Historical (last 10 minutes)
```

## Testing

### Unit Tests

`dotViewerTests` target with 7 test classes covering Shared framework code:
- `FileTypeRegistryTests` — registry loading, extension/filename lookups
- `FileTypeResolutionTests` — `bestKey()` resolution for dotfiles, multi-dot files
- `ThemePaletteTests` — theme color retrieval, token type coverage
- `MarkdownRendererTests` — rendered HTML output for various markdown constructs
- `PlistConverterTests` — binary plist → XML conversion
- `FileAttributesTests` — `looksTextual` heuristic, file metadata
- `TransportStreamDetectorTests` — MPEG-TS binary detection

Run via: `xcodebuild test -project dotViewer/dotViewer.xcodeproj -scheme dotViewerTests`

### Manual / Log-Based Testing

1. **Smoke test**: `./scripts/dotviewer-ql-smoke.sh TestFiles/test.json` — triggers `qlmanage -p`, captures logs, greps for "HTML built"
2. **E2E test**: `./TestFiles/run_e2e_test.sh` — streams logs while you preview files in Finder
3. **Test files**: `TestFiles/` contains samples for many file types (`.py`, `.js`, `.swift`, `.go`, `.rs`, `.json`, `.yaml`, `.xml`, `.md`, `.env`, `.plist`, etc.)
4. **Manual verification**: select files in Finder → press Space → confirm preview renders with syntax highlighting

After changes, always run `dvrefresh` (or `./scripts/dotviewer-refresh.sh`) to rebuild + reinstall, then verify with `dvsmoke` or Finder preview.

See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for current bugs and [BACKLOG.md](BACKLOG.md) for planned work.

## File Conventions

- Source of truth for project config: `dotViewer/project.yml`
- Bundle ID prefix: `com.stianlars1`
- App Group: `group.stianlars1.dotViewer.shared`
- Dev team: `7F5ZSQFCQ4`
- Log subsystem: `com.stianlars1.dotViewer`
- Adding a new file type: update `DefaultFileTypes.json`, run `python3 scripts/dotviewer-gen-utis.py --apply` to regenerate UTI declarations, update `project.yml` with new output, add tree-sitter grammar + `.scm` query if available

## Research

Reference library of 37 Quick Look extension deep-dives, architecture patterns, and performance research compiled during v2: [docs/research/CLAUDE.md](docs/research/CLAUDE.md).

## Platform-Specific Notes

### macOS Development
When working on macOS/Quick Look features involving system permissions (Accessibility, TCC, sandboxing), research platform limitations FIRST before attempting implementation. Document known dead-ends upfront. Apple's TCC restrictions are strict — never assume permission workarounds will succeed without verification.

## Version History

See [CHANGELOG.md](CHANGELOG.md).
