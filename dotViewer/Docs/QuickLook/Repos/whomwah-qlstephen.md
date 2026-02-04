# whomwah/qlstephen

- Source: https://github.com/whomwah/qlstephen
- Summary: Plain-text/unknown-extension preview with strong file-size caps and binary detection.
- Primary file types: Plain text, unknown/no-extension files
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE)
- Feature tags: plain-text, unknown-extension, size-limit, qlgenerator, system-delegation

## Directory Tree
```text
qlstephen
|-- QuickLookStephenProject
|   |-- en.lproj
|   |   `-- InfoPlist.strings
|   |-- QuickLookStephen.xcodeproj
|   |   |-- project.xcworkspace
|   |   |   |-- xcshareddata
|   |   |   |   |-- IDEWorkspaceChecks.plist
|   |   |   |   `-- QuickLookStephen.xccheckout
|   |   |   |-- xcuserdata
|   |   |   |   `-- duncan.xcuserdatad
|   |   |   |       `-- WorkspaceSettings.xcsettings
|   |   |   `-- contents.xcworkspacedata
|   |   |-- xcshareddata
|   |   |   `-- xcschemes
|   |   |       `-- QuickLookStephen.xcscheme
|   |   |-- xcuserdata
|   |   |   `-- duncan.xcuserdatad
|   |   |       `-- xcschemes
|   |   |           `-- xcschememanagement.plist
|   |   |-- duncan.pbxuser
|   |   |-- duncan.perspectivev3
|   |   `-- project.pbxproj
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   |-- main.c
|   |-- QLSFileAttributes.h
|   `-- QLSFileAttributes.m
|-- .gitignore
|-- .travis.yml
|-- LICENSE
|-- Makefile
`-- README.md
```

## Relevant Paths (for dotViewer)
- `QuickLookStephenProject/GeneratePreviewForURL.m`: size caps, cancellation checks, URL vs data representation.
- `QuickLookStephenProject/GenerateThumbnailForURL.m`: thumbnail generation.
- `QuickLookStephenProject/QLSFileAttributes.{h,m}`: MIME/encoding detection and file size logic.
- `QuickLookStephenProject/Info.plist`: UTI declarations for unknown text.
- `QuickLookStephenProject/main.c`: generator entry point.

## Non-Relevant Paths (scanned)
- Xcode user data and CI metadata.

## Architecture Notes
- Reads a capped portion of the file and delegates to system preview when possible.

## Performance Tactics
- Hard max file size limit; early cancellation checks.
- Minimal processing for speed.

## Build / Setup Notes
- Standard Xcode project; install .qlgenerator bundle.

## Reuse Notes
- Excellent reference for dotViewer fallback/unknown file path and size-cap strategy.
