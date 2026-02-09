# atnan/QLPrettyPatch

- Source: https://github.com/atnan/QLPrettyPatch
- Summary: Patch/diff previewer using PrettyPatch formatter from WebKit.
- Primary file types: Diff/Patch (.patch, .diff)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: BSD-style (LICENSE)
- Feature tags: diff, patch, html, formatter, qlgenerator

## Directory Tree
```text
QLPrettyPatch
|-- QLPrettyPatch
|   |-- en.lproj
|   |   `-- InfoPlist.strings
|   |-- main.c
|   |-- QLPrettyPatch-Info.plist
|   |-- QLPrettyPatch-Prefix.pch
|   `-- QLPrettyPatch.m
|-- QLPrettyPatch.xcodeproj
|   |-- xcshareddata
|   |   `-- xcschemes
|   |       |-- Install.xcscheme
|   |       `-- QLPrettyPatch.xcscheme
|   `-- project.pbxproj
|-- .gitignore
|-- LICENSE
|-- README.md
`-- Screenshot.png
```

## Relevant Paths (for dotViewer)
- `QLPrettyPatch/main.c`: generator entry point.
- `QLPrettyPatch/QLPrettyPatch-Info.plist`: UTI registration for patch files.
- `PrettyPatch` formatter assets (bundled in build or fetched from WebKit).

## Non-Relevant Paths (scanned)
- Screenshots and release notes.

## Architecture Notes
- Wraps PrettyPatch output into HTML preview.

## Performance Tactics
- Formatting is lightweight; no heavy assets.

## Build / Setup Notes
- Xcode generator project with Install target.

## Reuse Notes
- Good reference for diff/patched formatting and HTML templating.
