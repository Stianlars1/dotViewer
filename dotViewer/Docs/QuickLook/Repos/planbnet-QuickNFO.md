# planbnet/QuickNFO

- Source: https://github.com/planbnet/QuickNFO
- Summary: NFO previewer with code-page 437 conversion and HTML output.
- Primary file types: NFO text files
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: nfo, encoding, html, qlgenerator, iconv

## Directory Tree
```text
QuickNFO
|-- English.lproj
|   `-- InfoPlist.strings
|-- examples
|   |-- ACME-NFO.NFO
|   |-- AYL-BUR.NFO
|   |-- AYL-SWE.NFO
|   |-- CPN-BP.NFO
|   |-- CPN-LGC.NFO
|   |-- preview.png
|   |-- readme.txt
|   `-- thumbnails.png
|-- QuickNFO.xcodeproj
|   `-- project.pbxproj
|-- .gitignore
|-- GeneratePreviewForURL.c
|-- GenerateThumbnailForURL.m
|-- Info.plist
|-- main.c
|-- quicklooknfo.c
|-- quicklooknfo.h
|-- QuickNFO.qlgenerator.zip
`-- README.md
```

## Relevant Paths (for dotViewer)
- `quicklooknfo.c`: converts code page 437 to UTF-8 and builds HTML.
- `GenerateThumbnailForURL.m`: thumbnail path.
- `Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Build artifacts and Xcode metadata.

## Architecture Notes
- Uses `iconv` to convert encodings and wraps result in HTML.

## Performance Tactics
- Streamed reads using CFReadStream to avoid large allocations.

## Build / Setup Notes
- C code compiled as generator.

## Reuse Notes
- Encoding conversion and streaming read patterns are directly applicable to dotViewer.
