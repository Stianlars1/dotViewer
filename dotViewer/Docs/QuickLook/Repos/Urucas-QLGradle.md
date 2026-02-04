# Urucas/QLGradle

- Source: https://github.com/Urucas/QLGradle
- Summary: Gradle build file previewer that delegates to system plain-text rendering.
- Primary file types: Gradle (.gradle)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE)
- Feature tags: gradle, plain-text, qlgenerator, system-delegation

## Directory Tree
```text
QLGradle
|-- example
|   `-- build.gradle
|-- QLGradle
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   `-- main.c
|-- QLGradle.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- screen
|   `-- screen.png
|-- .gitignore
|-- LICENSE
|-- Makefile
`-- README.md
```

## Relevant Paths (for dotViewer)
- `QLGradle/GeneratePreviewForURL.m`: delegates to `QLPreviewRequestSetURLRepresentation` as plain text.
- `QLGradle/Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Xcode project files.

## Architecture Notes
- Minimal generator that lets Quick Look handle plain text rendering.

## Performance Tactics
- Fastest possible approach (system delegation).

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Good template for dotViewer fallback: delegate to system for safe types.
