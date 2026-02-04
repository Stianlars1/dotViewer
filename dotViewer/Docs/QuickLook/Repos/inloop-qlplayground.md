# inloop/qlplayground

- Source: https://github.com/inloop/qlplayground
- Summary: Playground previewer that extracts Swift source and renders with SyntaxHighlighter.
- Primary file types: Xcode Playgrounds (.playground)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE)
- Feature tags: playground, swift, html, syntaxhighlighter, qlgenerator

## Directory Tree
```text
qlplayground
|-- QLPlayground
|   |-- QLPlayground
|   |   |-- highlight
|   |   |   |-- css
|   |   |   |   |-- shCore.css
|   |   |   |   `-- theme.css
|   |   |   |-- js
|   |   |   |   |-- brush.js
|   |   |   |   `-- shCore.js
|   |   |   |-- format.html
|   |   |   `-- LICENSE
|   |   |-- GeneratePreviewForURL.m
|   |   |-- GenerateThumbnailForURL.m
|   |   |-- Info.plist
|   |   |-- main.c
|   |   |-- PlaygroundParser.swift
|   |   `-- PreviewBuilder.swift
|   |-- QLPlayground.xcodeproj
|   |   |-- project.xcworkspace
|   |   |   `-- contents.xcworkspacedata
|   |   `-- project.pbxproj
|   `-- qlmanage
|-- .gitignore
|-- LICENSE
|-- qlplayground-screen-1.png
`-- README.md
```

## Relevant Paths (for dotViewer)
- `QLPlayground/PlaygroundParser.swift`: extracts `Contents.swift` from single or multi-page playgrounds.
- `QLPlayground/PreviewBuilder.swift`: builds HTML, sets attachments for JS/CSS with `kQLPreviewPropertyAttachmentsKey`.
- `QLPlayground/GeneratePreviewForURL.m`: QL entry point.
- `QLPlayground/Resources/`: HTML template + SyntaxHighlighter assets.
- `QLPlayground/Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Screenshots and Xcode project files.

## Architecture Notes
- Reads Swift sources, renders into HTML template, attaches JS/CSS resources via QL attachments.

## Performance Tactics
- In-process HTML build; no external process.

## Build / Setup Notes
- Xcode project; install generated .qlgenerator.

## Reuse Notes
- Great example of QL attachments for bundling JS/CSS without file system access.
