# hetima/SublimeSnippetQL

- Source: https://github.com/hetima/SublimeSnippetQL
- Summary: Quick Look generator for Sublime Text snippets (XML) using HTML preview.
- Primary file types: Sublime snippets (.sublime-snippet)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: No license file found
- Feature tags: xml, snippet, html, qlgenerator

## Directory Tree
```text
SublimeSnippetQL
|-- SublimeSnippetQL
|   |-- en.lproj
|   |   `-- InfoPlist.strings
|   |-- Resources
|   |   `-- tmpl.html
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- main.c
|   |-- SublimeSnippetQL-Info.plist
|   `-- SublimeSnippetQL-Prefix.pch
|-- SublimeSnippetQL.xcodeproj
|   `-- project.pbxproj
|-- .gitignore
|-- README.md
`-- screenshot.png
```

## Relevant Paths (for dotViewer)
- `SublimeSnippetQL/GeneratePreviewForURL.m`: parses snippet XML and formats HTML.
- `SublimeSnippetQL/SublimeSnippetQL-Info.plist`: UTI registration.
- `SublimeSnippetQL/main.c`: generator entry.

## Non-Relevant Paths (scanned)
- Project scaffolding.

## Architecture Notes
- Reads XML and outputs HTML with basic styling.

## Performance Tactics
- Lightweight; no heavy dependencies.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Simple XML -> HTML transformation pattern.
