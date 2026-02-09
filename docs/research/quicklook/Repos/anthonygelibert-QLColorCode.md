# anthonygelibert/QLColorCode

- Source: https://github.com/anthonygelibert/QLColorCode
- Summary: Syntax-highlighting generator powered by the Highlight C++ tool, producing HTML (and optional RTF).
- Primary file types: Source code (many UTIs)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: GPLv3 (COPYING)
- Feature tags: syntax-highlighting, highlight, html, rtf, qlgenerator, defaults, external-process

## Directory Tree
```text
QLColorCode
|-- hl
|   |-- highlight
|   |-- lua
|   `-- lua.hpp
|-- QLColorCode.xcodeproj
|   |-- xcshareddata
|   |   `-- xcschemes
|   |       |-- Package.xcscheme
|   |       `-- Travis.xcscheme
|   `-- project.pbxproj
|-- src
|   |-- colorize.sh
|   |-- Common.h
|   |-- Common.m
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   `-- main.c
|-- test
|   |-- css
|   |   |-- blog-stylesheet.css
|   |   `-- main-stylesheet.css
|   |-- objc
|   |   |-- DMWindowMemoryController.m
|   |   `-- X11BridgeController.m
|   |-- mdlocate.bogus_extension
|   |-- test$var$escaping.py
|   |-- test%%.plist
|   `-- test-encoding.py
|-- .gitignore
|-- .gitmodules
|-- .travis.yml
|-- CHANGELOG.md
|-- COPYING
|-- Info.plist
`-- README.md
```

## Relevant Paths (for dotViewer)
- `src/GeneratePreviewForURL.m`: main preview entry, sets HTML data representation.
- `src/GenerateThumbnailForURL.m`: thumbnail generation path.
- `src/Common.{h,m}`: runs `colorize.sh`, builds env, reads defaults (maxFileSize, themes, font, encoding).
- `src/colorize.sh`: shell pipeline calling Highlight binary with flags.
- `Info.plist`: UTI registrations and bundle settings.
- `hl/`: bundled Highlight binaries and Lua support.

## Non-Relevant Paths (scanned)
- `test/` fixtures, CI metadata, and project files.

## Architecture Notes
- Generator executes a shell script to run Highlight, captures HTML, returns via QLPreviewRequestSetDataRepresentation.
- Supports RTF output when configured via defaults.

## Performance Tactics
- Optional `maxFileSize` preference to cap processing.
- Highlight supports plugins like `reduce_filesize` to shrink output.

## Build / Setup Notes
- Requires Boost headers during build (per README).
- Install via Homebrew/macports or build with Xcode.

## Reuse Notes
- Useful defaults scheme for theme and size controls.
- Shows how to bundle Highlight and drive it via CLI flags.
