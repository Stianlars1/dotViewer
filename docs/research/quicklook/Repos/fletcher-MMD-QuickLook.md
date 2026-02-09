# fletcher/MMD-QuickLook

- Source: https://github.com/fletcher/MMD-QuickLook
- Summary: MultiMarkdown/OPML Quick Look generator with embedded MultiMarkdown binary.
- Primary file types: MultiMarkdown, OPML
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (per README; no LICENSE file)
- Feature tags: markdown, opml, html, qlgenerator, embedded-binary

## Directory Tree
```text
MMD-QuickLook
|-- MultiMarkdown QuickLook
|   |-- en.lproj
|   |   `-- InfoPlist.strings
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- main.c
|   |-- multimarkdown
|   |-- MultiMarkdown QuickLook-Info.plist
|   |-- MultiMarkdown QuickLook-Prefix.pch
|   `-- opml2mmd.xslt
|-- MultiMarkdown QuickLook.xcodeproj
|   `-- project.pbxproj
`-- Readme.markdown
```

## Relevant Paths (for dotViewer)
- `MultiMarkdown QuickLook/GeneratePreviewForURL.m`: generator entry; invokes embedded MultiMarkdown.
- `MultiMarkdown QuickLook/GenerateThumbnailForURL.m`: thumbnail path.
- `MultiMarkdown QuickLook/multimarkdown`: embedded parser binary.
- `MultiMarkdown QuickLook/opml2mmd.xslt`: OPML -> Markdown transform.
- `MultiMarkdown QuickLook/MultiMarkdown QuickLook-Info.plist`: UTI declarations.

## Non-Relevant Paths (scanned)
- Project files and release notes.

## Architecture Notes
- Runs embedded MultiMarkdown to HTML, feeds HTML to Quick Look.

## Performance Tactics
- Native embedded binary; no JS; relies on external process invocation.

## Build / Setup Notes
- Xcode project builds generator and includes MultiMarkdown binary.

## Reuse Notes
- Pattern for bundling a parser executable and XSLT transforms.
