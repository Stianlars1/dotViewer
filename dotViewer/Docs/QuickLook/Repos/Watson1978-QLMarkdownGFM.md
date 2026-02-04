# Watson1978/QLMarkdownGFM

- Source: https://github.com/Watson1978/QLMarkdownGFM
- Summary: GitHub-flavored Markdown previewer using cmark-gfm and HTML templates.
- Primary file types: Markdown
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: BSD-3-Clause (LICENSE)
- Feature tags: markdown, cmark-gfm, html, qlgenerator

## Directory Tree
```text
QLMarkdownGFM
|-- cmark
|   |-- include
|   |   |-- cmark-gfm-core-extensions.h
|   |   |-- cmark-gfm-extension_api.h
|   |   |-- cmark-gfm.h
|   |   |-- cmark-gfm_export.h
|   |   |-- cmark-gfm_version.h
|   |   `-- config.h
|   `-- lib
|       |-- libcmark-gfm-extensions.a
|       `-- libcmark-gfm.a
|-- images
|   |-- preview.png
|   `-- thumbnail.png
|-- QLMarkdownGFM
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   |-- main.c
|   |-- markdown.h
|   |-- markdown.m
|   `-- styles.css
|-- QLMarkdownGFM.xcodeproj
|   |-- project.xcworkspace
|   |   |-- xcshareddata
|   |   |   `-- IDEWorkspaceChecks.plist
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- QLMarkdownGFM.xcworkspace
|   |-- xcshareddata
|   |   `-- IDEWorkspaceChecks.plist
|   `-- contents.xcworkspacedata
|-- .gitignore
|-- entitlements.plist
|-- Gemfile
|-- Gemfile.lock
|-- install-cmark.sh
|-- LICENSE
|-- Podfile
|-- Podfile.lock
|-- README.md
`-- release.sh
```

## Relevant Paths (for dotViewer)
- `QLMarkdownGFM/GeneratePreviewForURL.m`: renders Markdown to HTML via cmark-gfm.
- `QLMarkdownGFM/markdown.{m,h}`: wrapper around cmark-gfm libs.
- `cmark/`: bundled cmark-gfm static libs and headers.
- `QLMarkdownGFM/styles.css`: preview styling.
- `QLMarkdownGFM/Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Release scripts and screenshot assets.

## Architecture Notes
- C library rendering to HTML with static assets.

## Performance Tactics
- Native parser; good for large Markdown files.

## Build / Setup Notes
- Includes install script for cmark-gfm; Xcode project.

## Reuse Notes
- A clean example of bundling cmark-gfm for fast Markdown previews.
