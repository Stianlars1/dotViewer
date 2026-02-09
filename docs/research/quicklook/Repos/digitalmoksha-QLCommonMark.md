# digitalmoksha/QLCommonMark

- Source: https://github.com/digitalmoksha/QLCommonMark
- Summary: CommonMark/Markdown generator using cmark and Bootstrap styling.
- Primary file types: Markdown
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE)
- Feature tags: markdown, cmark, bootstrap, html, qlgenerator

## Directory Tree
```text
QLCommonMark
|-- QLCommonMark
|   |-- cmark
|   |   |-- cmark.h
|   |   |-- cmark_export.h
|   |   |-- cmark_version.h
|   |   `-- libcmark.a
|   |-- Resources
|   |   `-- themes
|   |       `-- bootstrap
|   |           |-- css
|   |           |   |-- bootstrap-theme.min.css
|   |           |   |-- bootstrap-theme.min.custom.css
|   |           |   |-- bootstrap.min.css
|   |           |   `-- custom.min.css
|   |           `-- fonts
|   |               |-- glyphicons-halflings-regular.eot
|   |               |-- glyphicons-halflings-regular.svg
|   |               |-- glyphicons-halflings-regular.ttf
|   |               |-- glyphicons-halflings-regular.woff
|   |               `-- glyphicons-halflings-regular.woff2
|   |-- common_mark.h
|   |-- common_mark.m
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   |-- main.c
|   `-- shared.h
|-- QLCommonMark.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- .gitignore
|-- LICENSE
`-- README.md
```

## Relevant Paths (for dotViewer)
- `QLCommonMark/GeneratePreviewForURL.m`: renders Markdown via cmark to HTML.
- `QLCommonMark/common_mark.{m,h}`: wrapper around cmark static library.
- `QLCommonMark/Resources/themes/bootstrap/`: HTML theme assets.
- `QLCommonMark/cmark/`: bundled cmark static lib headers.

## Non-Relevant Paths (scanned)
- Xcode project files and screenshots.

## Architecture Notes
- Embedded C library renders Markdown to HTML, then returns HTML to Quick Look.

## Performance Tactics
- Native C parsing (fast, low overhead).

## Build / Setup Notes
- Static cmark library bundled in repo; build with Xcode.

## Reuse Notes
- Good reference for bundling a static markdown parser and theming via local assets.
