# besi/quicklook-dot

- Source: https://github.com/besi/quicklook-dot
- Summary: Graphviz `.dot` previewer that shells out to `dot` and renders PNG.
- Primary file types: Graphviz DOT (.dot)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: graphviz, external-process, image, qlgenerator

## Directory Tree
```text
quicklook-dot
|-- English.lproj
|   `-- InfoPlist.strings
|-- QuicklookDot.xcodeproj
|   |-- project.xcworkspace
|   |   |-- xcuserdata
|   |   |   `-- besi.xcuserdatad
|   |   |       |-- UserInterfaceState.xcuserstate
|   |   |       `-- WorkspaceSettings.xcsettings
|   |   `-- contents.xcworkspacedata
|   |-- xcuserdata
|   |   `-- besi.xcuserdatad
|   |       `-- xcschemes
|   |           |-- quicklook-dot.xcscheme
|   |           `-- xcschememanagement.plist
|   `-- project.pbxproj
|-- .gitattributes
|-- Dot.h
|-- Dot.m
|-- GeneratePreviewForURL.m
|-- GenerateThumbnailForURL.m
|-- Info.plist
|-- main.c
|-- readme.md
|-- sample.dot
`-- screenshot.png
```

## Relevant Paths (for dotViewer)
- `GeneratePreviewForURL.m`: loads PNG from Dot helper and draws into QL context.
- `Dot.{h,m}`: invokes `dot` CLI via `/usr/bin/env` and captures PNG bytes.
- `Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Xcode workspace/user settings.

## Architecture Notes
- External Graphviz rendering -> PNG -> drawn into QL context.

## Performance Tactics
- External process per preview; output size depends on graph.

## Build / Setup Notes
- Requires Graphviz `dot` available on PATH.

## Reuse Notes
- Template for external CLI rendering + QL context drawing.
