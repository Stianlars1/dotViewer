# toland/qlmarkdown

- Source: https://github.com/toland/qlmarkdown
- Summary: Legacy Markdown Quick Look generator using the Discount C parser to emit HTML.
- Primary file types: Markdown (.md, .markdown)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found (check upstream history before reuse)
- Feature tags: markdown, discount, html, qlgenerator, c

## Directory Tree
```text
qlmarkdown
|-- discount
|-- discount-config
|   |-- blocktags
|   |-- config.h
|   |-- mkdio.h
|   |-- README.markdown
|   |-- update-discount.sh
|   `-- update.sh
|-- en.lproj
|   `-- InfoPlist.strings
|-- QLMarkdown.xcodeproj
|   `-- project.pbxproj
|-- .clang-format
|-- .gitignore
|-- .gitmodules
|-- discount-wrapper.c
|-- discount-wrapper.h
|-- GeneratePreviewForURL.m
|-- GenerateThumbnailForURL.m
|-- Info.plist
|-- main.c
|-- markdown.h
|-- markdown.m
|-- Nautilus_Star.png
|-- Readme.markdown
|-- sample.md
|-- sample.xhtml
`-- styles.css
```

## Relevant Paths (for dotViewer)
- `GeneratePreviewForURL.m` / `GenerateThumbnailForURL.m` / `main.c`: QL generator entry points.
- `discount-wrapper.{c,h}`: thin bridge into Discount.
- `discount/` and `discount-config/`: embedded Discount source and config.
- `styles.css`: preview styling.
- `Info.plist`: UTI declarations.

## Non-Relevant Paths (scanned)
- Samples and images, Xcode project scaffolding.

## Architecture Notes
- Parses Markdown with embedded C library and returns HTML to Quick Look.

## Performance Tactics
- Native C parser avoids JS overhead; no explicit size caps in generator.

## Build / Setup Notes
- Uses embedded Discount source; open Xcode project and build.

## Reuse Notes
- Good minimal example of Discount integration and HTML templating.
