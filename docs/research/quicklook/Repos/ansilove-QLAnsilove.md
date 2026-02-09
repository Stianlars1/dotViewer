# ansilove/QLAnsilove

- Source: https://github.com/ansilove/QLAnsilove
- Summary: Text-mode art previewer for ANSI/ASCII formats using the AnsiLove framework.
- Primary file types: ANSI/ASCII art (.ans, .nfo, .asc, etc.)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: BSD-3-Clause (LICENSE)
- Feature tags: ansi, ascii-art, framework, qlgenerator, bitmap

## Directory Tree
```text
QLAnsilove
|-- QLAnsilove
|   |-- Frameworks
|   |   `-- AnsiLove.framework
|   |       |-- Headers
|   |       |   |-- ALAnsiGenerator.h
|   |       |   |-- ALSauceMachine.h
|   |       |   `-- AnsiLove.h
|   |       |-- Resources
|   |       |   |-- en.lproj
|   |       |   |   `-- InfoPlist.strings
|   |       |   `-- Info.plist
|   |       |-- Versions
|   |       |   |-- 6
|   |       |   |   |-- Headers
|   |       |   |   |   |-- ALAnsiGenerator.h
|   |       |   |   |   |-- ALSauceMachine.h
|   |       |   |   |   `-- AnsiLove.h
|   |       |   |   |-- Resources
|   |       |   |   |   |-- en.lproj
|   |       |   |   |   |   `-- InfoPlist.strings
|   |       |   |   |   `-- Info.plist
|   |       |   |   |-- AnsiLove
|   |       |   |   |-- libgd.3.dylib
|   |       |   |   `-- libpng16.16.dylib
|   |       |   `-- Current
|   |       |       |-- Headers
|   |       |       |   |-- ALAnsiGenerator.h
|   |       |       |   |-- ALSauceMachine.h
|   |       |       |   `-- AnsiLove.h
|   |       |       |-- Resources
|   |       |       |   |-- en.lproj
|   |       |       |   |   `-- InfoPlist.strings
|   |       |       |   `-- Info.plist
|   |       |       |-- AnsiLove
|   |       |       |-- libgd.3.dylib
|   |       |       `-- libpng16.16.dylib
|   |       `-- AnsiLove
|   |-- QLAnsilove
|   |   |-- GeneratePreviewForURL.m
|   |   |-- GenerateThumbnailForURL.m
|   |   |-- Info.plist
|   |   |-- main.c
|   |   `-- Shared.h
|   `-- QLAnsilove.xcodeproj
|       |-- project.xcworkspace
|       |   `-- contents.xcworkspacedata
|       `-- project.pbxproj
|-- .gitignore
|-- alpha_king-QLAnsilove.ans
|-- LICENSE
|-- Makefile
|-- README.markdown
`-- rendered-folder-example.png
```

## Relevant Paths (for dotViewer)
- `QLAnsilove/QLAnsilove/GeneratePreviewForURL.m`: invokes AnsiLove to render images.
- `QLAnsilove/Frameworks/AnsiLove.framework`: bundled rendering engine.
- `QLAnsilove/QLAnsilove/Info.plist`: UTI declarations.

## Non-Relevant Paths (scanned)
- Framework build artifacts and images.

## Architecture Notes
- Generator uses a bundled framework to render ANSI/ASCII art to images.

## Performance Tactics
- Native rendering; performance depends on file size and bitmap output.

## Build / Setup Notes
- Xcode project with embedded framework.

## Reuse Notes
- Framework-bundling pattern for heavy renderers.
