# irees/quickgeojson

- Source: https://github.com/irees/quickgeojson
- Summary: GeoJSON preview using Mapbox/Leaflet assets and HTML template injection.
- Primary file types: GeoJSON (.geojson)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: geojson, html, mapbox, leaflet, qlgenerator

## Directory Tree
```text
quickgeojson
|-- quickgeojson
|   |-- en.lproj
|   |   `-- InfoPlist.strings
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- icons-000000@2x.png
|   |-- leaflet-omnivore.min.js
|   |-- main.c
|   |-- mapbox.v2.1.4.css
|   |-- mapbox.v2.1.4.js
|   |-- quickgeojson-Info.plist
|   |-- quickgeojson-Prefix.pch
|   `-- template.html
|-- quickgeojson.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- sample_files
|   |-- SanFranciscoPopulation.topojson
|   `-- test.geojson
|-- .gitignore
|-- README.md
|-- screenshot1.png
`-- screenshot2.png
```

## Relevant Paths (for dotViewer)
- `quickgeojson/GeneratePreviewForURL.m`: reads GeoJSON, injects into HTML template, attaches CSS/JS.
- `quickgeojson/template.html`: HTML template with `{{GEOJSON}}` placeholder.
- `mapbox.v2.1.4.js/css`, `leaflet-omnivore.min.js`: bundled assets.
- `quickgeojson-Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Screenshots and Xcode metadata.

## Architecture Notes
- HTML template + attachments via `kQLPreviewPropertyAttachmentsKey`.

## Performance Tactics
- Depends on JS rendering; no explicit size caps.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Template-plus-attachment strategy is reusable for rich HTML previews.
