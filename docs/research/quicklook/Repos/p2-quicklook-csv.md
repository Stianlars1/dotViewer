# p2/quicklook-csv

- Source: https://github.com/p2/quicklook-csv
- Summary: CSV preview that parses rows and renders an HTML table with row limits and encoding detection.
- Primary file types: CSV
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: Apache-2.0 (LICENSE.txt)
- Feature tags: csv, html-table, row-limit, encoding, qlgenerator

## Directory Tree
```text
quicklook-csv
|-- English.lproj
|   |-- InfoPlist.strings
|   `-- Localizable.strings
|-- German.lproj
|   `-- Localizable.strings
|-- QuickLookCSV.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   |-- pp.pbxuser
|   |-- pp.perspectivev3
|   `-- project.pbxproj
|-- Test
|   |-- test.csv
|   |-- testHeight.csv
|   |-- testMini.csv
|   `-- testWidth.csv
|-- .gitignore
|-- CSVDocument.h
|-- CSVDocument.m
|-- CSVRowObject.h
|-- CSVRowObject.m
|-- GeneratePreviewForURL.m
|-- GenerateThumbnailForURL.m
|-- Info.plist
|-- INSTALL.rtf
|-- LICENSE.txt
|-- main.c
|-- NOTICE.txt
|-- README.md
`-- Style.css
```

## Relevant Paths (for dotViewer)
- `GeneratePreviewForURL.m`: parses CSV, detects encoding, caps rows (`MAX_ROWS`), builds HTML table.
- `CSVDocument.*` and `CSVRowObject.*`: CSV parsing and row representation.
- `Style.css`: preview styling.
- `Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Xcode project metadata.

## Architecture Notes
- Parses CSV into rows, injects metadata (column count, row count) into HTML.

## Performance Tactics
- Row cap (500) prevents huge tables.
- Encoding fallback if UTF-8 fails.

## Build / Setup Notes
- Xcode project; legacy generator.

## Reuse Notes
- Row-cap logic and encoding fallback are directly useful for dotViewer table previews.
