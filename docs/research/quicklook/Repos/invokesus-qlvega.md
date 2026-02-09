# invokesus/qlvega

- Source: https://github.com/invokesus/qlvega
- Summary: Vega/Vega-Lite previewer that runs `vg2svg`/`vl2svg` and returns SVG/HTML.
- Primary file types: Vega / Vega-Lite JSON
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: vega, json, svg, external-process, qlgenerator

## Directory Tree
```text
qlvega
|-- qlvega
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   |-- main.c
|   |-- Shared.h
|   `-- Shared.m
|-- qlvega.xcodeproj
|   |-- project.xcworkspace
|   |   |-- xcuserdata
|   |   |   `-- invokesus.xcuserdatad
|   |   |       `-- UserInterfaceState.xcuserstate
|   |   `-- contents.xcworkspacedata
|   |-- xcshareddata
|   |   `-- xcschemes
|   |       |-- Package.xcscheme
|   |       `-- qlvega.xcscheme
|   |-- xcuserdata
|   |   `-- invokesus.xcuserdatad
|   |       `-- xcschemes
|   |           `-- xcschememanagement.plist
|   `-- project.pbxproj
|-- qlvega.rb
`-- README.md
```

## Relevant Paths (for dotViewer)
- `qlvega/GeneratePreviewForURL.m`: entry point, calls `renderSVG` and returns HTML.
- `qlvega/Shared.{h,m}`: shell execution of `vg2svg`/`vl2svg` and UTI detection.
- `qlvega/Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Xcode project files and README assets.

## Architecture Notes
- Runs external CLI to render JSON -> SVG, then displays SVG via HTML.
- Uses defaults to set text encoding.

## Performance Tactics
- External process per preview; heavy for large specs.

## Build / Setup Notes
- Requires `vg2svg`/`vl2svg` on PATH; uses `/usr/bin/env`.

## Reuse Notes
- Reference for invoking external renderers and handling Vega-Lite detection.
