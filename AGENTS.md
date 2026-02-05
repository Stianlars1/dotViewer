# dotViewer v2.5 — Agent Work Log

This file is a lightweight changelog of agent-assisted work in this workspace.

## 2026-02-04

### Quick Look “Extension launches but does nothing” fix
- Fixed Quick Look extension discovery by defining `NSExtension` dictionaries + `QLSupportedContentTypes` via XcodeGen (`dotViewer/project.yml`), since XcodeGen regenerates the extension `Info.plist` files.
- Fixed extension discovery failures caused by missing entitlements by defining sandbox + app group entitlements via XcodeGen (`dotViewer/project.yml`), since XcodeGen regenerates the `.entitlements` files.
- Fixed `DEVELOPMENT_TEAM` mismatch so `xcodebuild -allowProvisioningUpdates` can sign successfully (`dotViewer/project.yml`).
- Verified end-to-end preview pipeline by capturing `log stream` output showing “Preview request …” and “HTML built …” for Markdown/JSON/YAML/XML/Shell files.
- Fixed data-based preview entrypoint to match Apple’s model: preview principal class is now a `QLPreviewProvider` subclass (`PreviewProvider`), which is what Quick Look actually instantiates for `QLPreviewReply`-based previews.

### Routing / Gating / Stability
- Improved dotfile + multi-dot name routing by introducing `FileTypeResolution.bestKey(...)` and using it from preview + thumbnail routing.
- Strengthened “don’t hijack binary files” behavior with sample-based `looksTextual` detection in `FileAttributes` (used as a fallback when UTType/MIME classification is inconclusive).
- Added timeout + cancellation handling in thumbnail HTML rendering to prevent hung thumbnail requests.

### Developer Scripts
- Added/updated scripts under `scripts/` to refresh builds, reset Quick Look caches, and inspect logs/status.
- Added `scripts/dotviewer-aliases.zsh` for convenient `dvrefresh` / `dvlogs` / `dvql` aliases.
- Added `scripts/dotviewer-ql-smoke.sh` to automate “prove it returns HTML” via `qlmanage -p` + log capture.

### Quick Look Routing + Highlighting Parity
- Fixed “works for Markdown/JSON but not most code files” by expanding `QLSupportedContentTypes` to include the **exact** UTIs macOS uses for many source/script formats (e.g. `public.python-script`, `com.netscape.javascript-source`, `public.swift-source`, `org.golang.go-script`, `org.rust-lang.rust-script`) in `dotViewer/project.yml`.
- Added `com.apple.property-list` to `QLSupportedContentTypes` so `.plist` previews route into dotViewer (with binary plists still falling back via internal gating).
- Removed accidental video UTI targeting:
  - Dropped `public.mpeg-2-transport-stream` from Quick Look extension supported types.
  - Updated the custom TypeScript UTI (`com.stianlars1.dotviewer.typescript`) to map only `.cts` and conform only to text/source types.
- Added a fast heuristic fallback highlighter in `dotViewer/HighlightXPC/TreeSitterHighlighter.swift` so code file types without a bundled tree-sitter grammar still get basic token coloring (comments/strings/numbers/keywords).
- Fixed `FileTypeRegistry` mapping so `xml`/`plist`/`svg` use the `xml` tree-sitter grammar (previously mislabeled as `html`).
- Wired the app’s `Font Size` setting into the Quick Look HTML (`dotViewer/Shared/PreviewHTMLBuilder.swift`) so font sizing now syncs via App Group settings.
- Added `scripts/dotviewer-gen-ql-content-types.sh` to generate a best-effort `QLSupportedContentTypes` list from `FileTypeRegistry`.
- Verified routing via `scripts/dotviewer-ql-smoke.sh` for: `.py`, `.js`, `.swift`, `.go`, `.rs`, `.zsh`, `.tsx`, `.md`, `.json`, `.xml`, `.yaml`, `.env`, and `.gitignore` (all showed “HTML built …” logs).

## Notes
- XcodeGen regenerates `dotViewer/App/Info.plist`, `dotViewer/QuickLookExtension/Info.plist`, `dotViewer/QuickLookThumbnailExtension/Info.plist`, and the `.entitlements` files. Persistent changes for those live in `dotViewer/project.yml`.
- To keep this file fresh, use the repo-local skill: `.agents/skills/update-agents-md/SKILL.md`.

## 2026-02-05

### Default File Types Expansion
- Outcome: Added a data-driven default filetypes catalog (SourceCodeSyntaxHighlight mappings + extra dotfiles) and wired the registry to load JSON with filename support.
- Files: dotViewer/Shared/DefaultFileTypes.json, dotViewer/Shared/FileTypeRegistry.swift, dotViewer/Shared/FileTypeModels.swift, dotViewer/project.yml, scripts/dotviewer-gen-default-filetypes.py, scripts/dotviewer-gen-ql-content-types.sh
- Verified: (not run) — data file generation only.
- Follow-ups: Run xcodegen/build to embed the new resource and refresh QL content types if needed.

### Standalone Plan Handoff
- Outcome: Added a self-contained implementation handoff document for starting a fresh thread without prior chat context.
- Files: handoff/dotviewer-plan-handoff.md
- Verified:
  - test -f handoff/dotviewer-plan-handoff.md && wc -l handoff/dotviewer-plan-handoff.md → pass (185 lines)
- Follow-ups: Use the starter prompt in the handoff document for new-thread execution.
