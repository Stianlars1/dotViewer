# johan/QuickJSON

- Source: https://github.com/johan/QuickJSON
- Summary: JSON preview using a tiny HTML/JS formatter with folding UI.
- Primary file types: JSON
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE)
- Feature tags: json, html, javascript, folding-ui, qlgenerator

## Directory Tree
```text
QuickJSON
|-- bin
|   |-- cssmin
|   `-- jsmin
|-- json-viewer
|   |-- formatter.js
|   |-- inline.js
|   |-- json.css
|   |-- live.js
|   |-- quicklook.c
|   |-- quicklook.css
|   |-- quicklook.html
|   |-- quicklook.js
|   `-- test.html
|-- QuickJSON
|   |-- en.lproj
|   |   `-- InfoPlist.strings
|   |-- GeneratePreviewForURL.c
|   |-- GenerateThumbnailForURL.m
|   |-- main.c
|   |-- QuickJSON-Info.plist
|   |-- QuickJSON-Prefix.pch
|   |-- quicklookjson.c
|   `-- quicklookjson.h
|-- QuickJSON.xcodeproj
|   `-- project.pbxproj
|-- LICENSE
|-- Rakefile
`-- README.md
```

## Relevant Paths (for dotViewer)
- `QuickJSON/quicklookjson.c`: wraps JSON in an HTML+JS template and sets HTML representation.
- `json-viewer/quicklook.{html,js,css}`: the standalone HTML formatter UI.
- `QuickJSON/GenerateThumbnailForURL.m`: thumbnail generation.
- `QuickJSON/QuickJSON-Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Project files and build scripts.

## Architecture Notes
- Reads JSON data and injects into a self-contained HTML+JS preview.

## Performance Tactics
- No explicit size limit; full JSON loaded in memory.

## Build / Setup Notes
- Standard Xcode generator project.

## Reuse Notes
- Good reference for an inline JS formatter with folding UI.
