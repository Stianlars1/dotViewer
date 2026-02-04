# chockenberry/Provisioning

- Source: https://github.com/chockenberry/Provisioning
- Summary: Provisioning profile previewer that decodes CMS and renders HTML details.
- Primary file types: mobileprovision, ipa, app bundles
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: provisioning, plist, cms, html, external-process

## Directory Tree
```text
Provisioning
|-- Provisioning
|   |-- en.lproj
|   |   `-- InfoPlist.strings
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- main.c
|   |-- Provisioning-Info.plist
|   |-- Provisioning-Prefix.pch
|   `-- template.html
|-- Provisioning.xcodeproj
|   |-- project.xcworkspace
|   |   |-- xcshareddata
|   |   |   `-- Provisioning.xccheckout
|   |   `-- contents.xcworkspacedata
|   |-- xcshareddata
|   |   `-- xcschemes
|   |       |-- Provisioning (Debug).xcscheme
|   |       `-- Provisioning (Release).xcscheme
|   `-- project.pbxproj
|-- .gitignore
|-- build_release
|-- Read Me.rtf
`-- README.md
```

## Relevant Paths (for dotViewer)
- `Provisioning/GeneratePreviewForURL.m`: decodes CMS, extracts plist, renders HTML template.
- `Provisioning/template.html`: HTML template for display.
- `Provisioning/Provisioning-Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Build metadata and README.

## Architecture Notes
- Uses `CMSDecoder` to decode provisioning data; optionally shells out to `unzip` for IPA.

## Performance Tactics
- Processes plist in memory; external unzip only for IPA cases.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Demonstrates CMS decoding and structured HTML output for plist-like data.
