# tattali/QLAddict

- Source: https://github.com/tattali/QLAddict
- Summary: SubRip (.srt) subtitle previewer with CSS theme support.
- Primary file types: SubRip subtitles (.srt)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: GPLv3 (LICENSE)
- Feature tags: srt, html, css-themes, qlgenerator

## Directory Tree
```text
QLAddict
|-- assets
|   |-- addic7ed-grey.png
|   |-- calvert.png
|   |-- dark-light.png
|   |-- default.png
|   `-- farran.png
|-- QuickLookAddict
|   |-- themes
|   |   |-- addic7ed-grey.css
|   |   |-- addic7ed.css
|   |   |-- calvert.css
|   |   |-- dark-light.css
|   |   `-- farran.css
|   |-- base.css
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   `-- main.c
|-- QuickLookAddict.xcodeproj
|   |-- project.xcworkspace
|   |   |-- xcshareddata
|   |   |   `-- IDEWorkspaceChecks.plist
|   |   `-- contents.xcworkspacedata
|   |-- xcshareddata
|   |   `-- xcschemes
|   |       `-- QuickLookAddict.xcscheme
|   `-- project.pbxproj
|-- .clang-format
|-- .gitignore
|-- available-themes.md
|-- LICENSE
`-- README.md
```

## Relevant Paths (for dotViewer)
- `QuickLookAddict/GeneratePreviewForURL.m`: builds HTML preview of subtitle content.
- `QuickLookAddict/base.css` and `QuickLookAddict/themes/*.css`: theme system for preview styling.
- `QuickLookAddict/Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Assets, screenshots, and project metadata.

## Architecture Notes
- HTML/CSS preview with theme switch via defaults.

## Performance Tactics
- No heavy parsing; mostly string formatting and CSS.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Theme-switching approach maps well to dotViewer theme preferences.
