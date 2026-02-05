# dotViewer

macOS Quick Look extension for syntax-highlighted previews of source code, config files, and dotfiles.

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

## Key Concepts

- **UTI routing**: Quick Look matches on exact UTType identifiers (not conformance). The `QLSupportedContentTypes` list in `project.yml` must include every UTI we want to handle. Use `scripts/dotviewer-gen-ql-content-types.sh` to regenerate from `FileTypeRegistry`.
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

Log filtering examples:
```bash
./scripts/dotviewer-logs.sh --preview          # QuickLookExtension only
./scripts/dotviewer-logs.sh --xpc              # HighlightXPC only
./scripts/dotviewer-logs.sh --last 10m         # Historical (last 10 minutes)
```

## Testing

No unit test target. Testing is manual + log-based:

1. **Smoke test**: `./scripts/dotviewer-ql-smoke.sh TestFiles/test.json` — triggers `qlmanage -p`, captures logs, greps for "HTML built"
2. **E2E test**: `./TestFiles/run_e2e_test.sh` — streams logs while you preview files in Finder
3. **Test files**: `TestFiles/` contains samples for many file types (`.py`, `.js`, `.swift`, `.go`, `.rs`, `.json`, `.yaml`, `.xml`, `.md`, `.env`, `.plist`, etc.)
4. **Manual verification**: select files in Finder → press Space → confirm preview renders with syntax highlighting

After changes, always run `dvrefresh` (or `./scripts/dotviewer-refresh.sh`) to rebuild + reinstall, then verify with `dvsmoke` or Finder preview.

## File Conventions

- Source of truth for project config: `dotViewer/project.yml`
- Bundle ID prefix: `com.stianlars1`
- App Group: `group.stianlars1.dotViewer.shared`
- Dev team: `7F5ZSQFCQ4`
- Log subsystem: `com.stianlars1.dotViewer`
- Adding a new file type: update `FileTypeRegistry.swift`, add UTI to `QLSupportedContentTypes` in `project.yml` (both preview and thumbnail sections), add tree-sitter grammar + `.scm` query if available
