# mzp/qltext-jp

- Source: https://github.com/mzp/qltext-jp
- Summary: Japanese text Quick Look generator with encoding detection/decoding.
- Primary file types: Plain text (Shift-JIS, EUC-JP, UTF-8)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE)
- Feature tags: encoding, text, japanese, qlgenerator

## Directory Tree
```text
qltext-jp-repo
|-- qltext-jp
|   |-- GeneratePreviewForURL.c
|   |-- GenerateThumbnailForURL.c
|   |-- Info.plist
|   |-- main.c
|   |-- NSData+DetectEncoding.h
|   `-- NSData+DetectEncoding.m
|-- qltext-jp.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- .gitignore
|-- LICENSE
`-- README.md
```

## Relevant Paths (for dotViewer)
- `qltext-jp/NSData+DetectEncoding.{h,m}`: detects and converts Japanese encodings.
- `qltext-jp/GeneratePreviewForURL.c`: uses encoding detection to render preview.
- `qltext-jp/GenerateThumbnailForURL.c`: thumbnail path.
- `qltext-jp/Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Xcode project files.

## Architecture Notes
- Reads raw bytes, detects encoding, emits text/HTML output.

## Performance Tactics
- Native C processing; minimal overhead.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Encoding-detection logic is valuable for unknown dotfiles in dotViewer.
