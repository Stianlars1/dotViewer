# tomnewton/QuickLookPrettyJSON

- Source: https://github.com/tomnewton/QuickLookPrettyJSON
- Summary: JSON pretty-printer that injects Google Code Prettify and inline CSS/JS.
- Primary file types: JSON
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: json, html, javascript, prettify, qlgenerator

## Directory Tree
```text
QuickLookPrettyJSON
|-- install
|   `-- QuickLookPrettyJSON.qlgenerator.zip
|-- QuickLookPrettyJSON
|   |-- en.lproj
|   |   `-- InfoPlist.strings
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- main.c
|   |-- QuickLookPrettyJSON-Info.plist
|   `-- QuickLookPrettyJSON-Prefix.pch
|-- QuickLookPrettyJSON.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- .gitignore
`-- README.md
```

## Relevant Paths (for dotViewer)
- `QuickLookPrettyJSON/GeneratePreviewForURL.m`: builds a full HTML page with embedded JS/CSS.
- `QuickLookPrettyJSON/GenerateThumbnailForURL.m`: thumbnail path.
- `QuickLookPrettyJSON/QuickLookPrettyJSON-Info.plist`: UTIs.
- `QuickLookPrettyJSON/main.c`: generator entry point.

## Non-Relevant Paths (scanned)
- `install/` packaging artifacts.

## Architecture Notes
- Reads file into memory, wraps with inline HTML/JS, returns HTML data.

## Performance Tactics
- No explicit size cap; full read into memory.

## Build / Setup Notes
- Xcode project; legacy generator.

## Reuse Notes
- Example of embedding a full JS pretty-printer directly into HTML output.
