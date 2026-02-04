# fabiolecca/colorxml-quicklook

- Source: https://github.com/fabiolecca/colorxml-quicklook
- Summary: XML previewer with indentation and syntax coloring using XSLT.
- Primary file types: XML (.xml, .plist)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: xml, xslt, html, qlgenerator

## Directory Tree
```text
colorxml-quicklook
|-- colorxml-QuickLook-1.1
|   |-- colorxml.qlgenerator
|   |   `-- Contents
|   |       |-- MacOS
|   |       |   `-- colorxml
|   |       |-- Resources
|   |       |   |-- English.lproj
|   |       |   |   `-- InfoPlist.strings
|   |       |   |-- xmlverbatim.xsl
|   |       |   `-- xmlverbatimwrapper.xsl
|   |       `-- Info.plist
|   |-- .DS_Store
|   `-- Colorxml-QuickLook-1.1-readme.rtf
|-- colorxml.xcodeproj
|   |-- fabio.mode1v3
|   |-- fabio.pbxuser
|   `-- project.pbxproj
|-- English.lproj
|   `-- InfoPlist.strings
|-- GeneratePreviewForURL.c
|-- GenerateThumbnailForURL.c
|-- Info.plist
|-- main.c
|-- README
|-- xmlverbatim.xsl
`-- xmlverbatimwrapper.xsl
```

## Relevant Paths (for dotViewer)
- `colorxml-QuickLook-1.1/colorxml.qlgenerator/Contents/Resources/xmlverbatim.xsl`: XSLT formatting rules.
- `colorxml-QuickLook-1.1/colorxml.qlgenerator/Contents/MacOS/colorxml`: main binary.
- `main.c`: generator entry point wrapper.

## Non-Relevant Paths (scanned)
- Packaged .qlgenerator bundle and readme files.

## Architecture Notes
- XSLT-based transformation to pretty HTML.

## Performance Tactics
- Depends on XSLT processor; no explicit size caps.

## Build / Setup Notes
- Includes prebuilt bundle; source is minimal.

## Reuse Notes
- XSLT approach is useful for XML/PLIST pretty-printing in dotViewer.
