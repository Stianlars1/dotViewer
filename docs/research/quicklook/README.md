# dotViewer Quick Look Reference Library

This folder is a curated, deep-dive knowledge base for building and maintaining dotViewer's Quick Look capabilities. It includes full repo scans, architectural patterns, performance guidance, and feature-to-reference mappings so we can quickly locate reusable code and proven designs.

## How To Use This Library

1. **Start with the Source Index**: `dotViewer/Docs/QuickLook/00-Source-Index.md`. This lists every source and links to each per-repo deep-dive.
2. **Find a Feature Recipe**: `dotViewer/Docs/QuickLook/03-Feature-Recipes.md`. Look up the feature you need and jump to the repo paths that implement it.
3. **Review Architecture & Performance Guidance**: `dotViewer/Docs/QuickLook/01-Architecture-Patterns.md`, `dotViewer/Docs/QuickLook/02-Performance-Sandboxing-Compatibility.md`, and internal research `dotViewer/QUICKLOOK_PERFORMANCE_RESEARCH.md`, `dotViewer/DOTVIEWER_VS_COMPETITORS_ANALYSIS.md`.
4. **Open the Repo Deep-Dive**: `dotViewer/Docs/QuickLook/Repos/<owner>-<repo>.md`. Each repo doc includes a full directory tree, relevant paths with TL;DRs, architecture/performance notes, and build/reuse considerations.

## Licensing Reminder
Many Quick Look plugins are GPL-licensed. Before copying code, always check the license and consider whether we can reuse ideas vs. direct code.

## Notes on Scope
- Focus is on **text/code/markup/config/dotfiles** and **unknown-extension** text handling.
- Media-only plugins are excluded unless they contain transferable Quick Look architecture patterns.

## dotViewer Quick Look Debugging Checklist (macOS 15+)

### 0) Know what XcodeGen overwrites
dotViewer uses **XcodeGen**. It regenerates:
- `dotViewer/QuickLookExtension/Info.plist`
- `dotViewer/QuickLookThumbnailExtension/Info.plist`
- the `*.entitlements` files

So persistent changes to extension registration/entitlements must be made in:
`dotViewer/project.yml`.

### 1) Confirm the extensions are discovered
Use PlugInKit to check what Quick Look is currently using:

```bash
pluginkit -m -v -i com.stianlars1.dotViewer.QuickLookPreview
pluginkit -m -v -i com.stianlars1.dotViewer.QuickLookThumbnail
```

If either one shows up without a leading `+`, enable it:

```bash
pluginkit -e use -i com.stianlars1.dotViewer.QuickLookPreview
pluginkit -e use -i com.stianlars1.dotViewer.QuickLookThumbnail
```

If you have multiple registered copies (common during development), list duplicates:

```bash
pluginkit -m -ADv | grep -i dotviewer
```

### 2) Reset Quick Look caches (forces re-load)
```bash
qlmanage -r
qlmanage -r cache
```

### 2.5) Confirm Quick Look will *route* the UTI to dotViewer (content type matching)
Quick Look routing is driven by the preview/thumbnail extension `Info.plist`:
`NSExtension -> NSExtensionAttributes -> QLSupportedContentTypes`.

In practice on macOS 15+, dotViewer only gets called when the file’s **primary UTI**
(`kMDItemContentType`) is **explicitly listed** in `QLSupportedContentTypes` (conformance
to `public.source-code` / `public.text` is not sufficient for many script/source UTIs).

Check the file’s UTI:
```bash
mdls -name kMDItemContentType TestFiles/test.py
mdls -name kMDItemContentType TestFiles/test.swift
```

If you see something like `public.python-script` / `public.swift-source` / `com.netscape.javascript-source`,
make sure that exact identifier is present in `dotViewer/project.yml` under both:
- `QuickLookExtension -> ... -> QLSupportedContentTypes`
- `QuickLookThumbnailExtension -> ... -> QLSupportedContentTypes`

Helper: generate a best-effort list from the current `FileTypeRegistry`:
```bash
./scripts/dotviewer-gen-ql-content-types.sh
```

### 2.6) Know the “unmanageable” extensions (system reserved)
Some extensions/UTIs are reserved by macOS and cannot reliably be overridden by third‑party Quick Look extensions.
Common gotchas:
- `.txt` often stays on the system previewer (`public.plain-text`)
- `.ts` / `.mts` are reserved for MPEG transport streams (`public.mpeg-2-transport-stream` / `public.avchd-mpeg-2-transport-stream`)

Workaround: prefer TypeScript’s `.tsx` and `.cts` where possible (dotViewer handles those).

### 3) Verify the extension can actually be instantiated
Two common “loads then immediately tears down” causes:
1. Missing `NSExtension` dictionary in the extension `Info.plist` (no principal class / supported content types).
2. Missing required entitlements for Quick Look app extensions (especially sandboxing).

### 4) Entitlements sanity-check (critical)
Quick Look app extensions should be sandboxed and able to read the previewed file.
From a built app:

```bash
codesign -d --entitlements :- dotViewer.app/Contents/PlugIns/QuickLookExtension.appex
codesign -d --entitlements :- dotViewer.app/Contents/PlugIns/QuickLookThumbnailExtension.appex
```

dotViewer expects to share settings via App Groups:
`group.stianlars1.dotViewer.shared`.

### 5) Use the built-in heartbeat file
Use a heartbeat file to prove dotViewer is returning HTML at all (DEBUG builds):
- `TestFiles/dotviewer_heartbeat.md` (recommended)
- `TestFiles/dotviewer_heartbeat.txt`

If Finder chooses the system previewer for one of them, try the other.

### 6) Stream logs while triggering a preview
```bash
/usr/bin/log stream --level default --process QuickLookExtension
```

## Helpful Scripts
Repo scripts live in `scripts/`:
- `scripts/dotviewer-refresh.sh` (reset QL, clean, build, install, launch)
- `scripts/dotviewer-ql-status.sh` (show which extensions are registered/active)
- `scripts/dotviewer-logs.sh` (stream/query dotViewer logs)
- `scripts/dotviewer-ql-smoke.sh` (trigger `qlmanage -p` + capture logs)
- `scripts/dotviewer-gen-ql-content-types.sh` (generate UTIs to add to `QLSupportedContentTypes`)

Optional: source `scripts/dotviewer-aliases.zsh` from your `~/.zshrc` for `dvrefresh`, `dvlogs`, `dvql`, `dvsmoke`, `dvutis`.
