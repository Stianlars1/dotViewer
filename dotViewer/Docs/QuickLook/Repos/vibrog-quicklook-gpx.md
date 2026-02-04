# vibrog/quicklook-gpx

- Source: https://github.com/vibrog/quicklook-gpx
- Summary: GPX previewer using OpenLayers with HTML attachments.
- Primary file types: GPX (XML)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE)
- Feature tags: gpx, xml, html, openlayers, qlgenerator

## Directory Tree
```text
quicklook-gpx
|-- openlayers
|   |-- ol-customized-build.json
|   |-- ol.css
|   `-- ol.js
|-- quicklook-gpx.xcodeproj
|   `-- project.pbxproj
|-- .gitignore
|-- GeneratePreviewForURL.m
|-- GenerateThumbnailForURL.m
|-- Info.plist
|-- LICENSE
|-- main.c
|-- README.md
`-- template.html
```

## Relevant Paths (for dotViewer)
- `GeneratePreviewForURL.m`: injects GPX data into HTML template and attaches `ol.js`/`ol.css`.
- `template.html`: HTML template with `{{GEODATASTRING}}` placeholder.
- `ol.js`, `ol.css`: bundled OpenLayers assets.
- `Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Project files and README.

## Architecture Notes
- Bundles JS/CSS as attachments via `kQLPreviewPropertyAttachmentsKey`.

## Performance Tactics
- No explicit size caps; relies on browser rendering performance.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Good example of QL attachments for HTML preview without file access.
