# douglashill/QuickLookCodeSnippet

- Source: https://github.com/douglashill/QuickLookCodeSnippet
- Summary: Xcode `.codesnippet` previewer that renders snippet metadata into HTML.
- Primary file types: Xcode Code Snippets (.codesnippet)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE.txt)
- Feature tags: codesnippet, plist, html, qlgenerator

## Directory Tree
```text
QuickLookCodeSnippet
|-- QuickLookCodeSnippet.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- Resources
|   |-- QuickLookCodeSnippet-Info.plist
|   `-- template.html
|-- Source
|   |-- CodeSnippetConstants.h
|   |-- CodeSnippetConstants.m
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   `-- main.c
|-- .gitignore
|-- License.txt
`-- README.md
```

## Relevant Paths (for dotViewer)
- `Source/GeneratePreviewForURL.m`: reads snippet plist and injects into HTML template.
- `Source/CodeSnippetConstants.h`: key names for snippet plist.
- `Resources/template.html`: preview HTML structure.
- `Resources/QuickLookCodeSnippet-Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Xcode project and workspace metadata.

## Architecture Notes
- Plist -> HTML template; returns HTML to Quick Look.

## Performance Tactics
- Lightweight; no heavy parsing.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Pattern for rendering structured plist data into HTML preview.
