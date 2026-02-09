# clydeclements/AsciiDocQuickLook

- Source: https://github.com/clydeclements/AsciiDocQuickLook
- Summary: Quick Look generator for AsciiDoc that shells out to Asciidoctor and returns HTML.
- Primary file types: AsciiDoc (.adoc, .asciidoc)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE.txt)
- Feature tags: asciidoc, html, external-process, qlgenerator, preferences

## Directory Tree
```text
AsciiDocQuickLook
|-- AsciiDocQuickLook
|   |-- AsciiDocManager.swift
|   |-- AsciiDocQuickLook-Bridging-Header.h
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   `-- main.c
|-- AsciiDocQuickLook.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- .gitignore
|-- LICENSE.txt
`-- README.adoc
```

## Relevant Paths (for dotViewer)
- `AsciiDocQuickLook/AsciiDocManager.swift`: runs `Process` to invoke `asciidoctor`, supports a user-defined converter via defaults, and returns HTML data.
- `AsciiDocQuickLook/GeneratePreviewForURL.m`: Quick Look entry point; calls the manager and sets HTML representation.
- `AsciiDocQuickLook/GenerateThumbnailForURL.m`: thumbnail pipeline using the same converter.
- `AsciiDocQuickLook/Info.plist`: UTI declarations and bundle metadata for AsciiDoc files.
- `AsciiDocQuickLook/main.c`: generator entry point wiring.

## Non-Relevant Paths (scanned)
- Xcode project files, README, and LICENSE.

## Architecture Notes
- Generator launches an external `asciidoctor` process and captures stdout as HTML.
- Uses QLPreviewRequestSetDataRepresentation with `text/html` preview properties.

## Performance Tactics
- External process spawn per preview; no caching.
- Sandbox constraints apply in modern app extensions; this pattern would need XPC to remain viable.

## Build / Setup Notes
- Requires Asciidoctor installed on the system (default `/usr/local/bin/asciidoctor`).
- Default installer path is `/Library/QuickLook` (README notes sandbox limitations for user folder).

## Reuse Notes
- Good reference for external converter overrides via defaults and HTML output plumbing.
- Use the same pattern only in a non-sandboxed XPC helper for modern extensions.
