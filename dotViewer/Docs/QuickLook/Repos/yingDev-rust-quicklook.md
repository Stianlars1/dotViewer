# yingDev/rust-quicklook

- Source: https://github.com/yingDev/rust-quicklook
- Summary: Rust source previewer using an HTML template (likely with syntax highlight).
- Primary file types: Rust (.rs)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: rust, html, qlgenerator

## Directory Tree
```text
rust-quicklook
|-- rust-quicklook
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   |-- load.html
|   `-- main.c
|-- rust-quicklook.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- README.md
`-- test.rs
```

## Relevant Paths (for dotViewer)
- `rust-quicklook/GeneratePreviewForURL.m`: loads template HTML and injects code.
- `rust-quicklook/load.html`: HTML template (likely includes highlight JS/CSS).
- `rust-quicklook/Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Xcode project metadata.

## Architecture Notes
- Simple HTML template substitution for code previews.

## Performance Tactics
- No size caps; loads file content into memory.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Template substitution pattern for single-language previews.
