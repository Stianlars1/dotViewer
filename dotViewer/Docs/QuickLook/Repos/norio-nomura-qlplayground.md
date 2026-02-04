# norio/nomura-qlplayground

- Source: https://github.com/norio-nomura/qlplayground
- Summary: Swift/Playground previewer using Highlight.js and theme switching via defaults.
- Primary file types: Swift files and Xcode Playgrounds (.swift, .playground)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE)
- Feature tags: swift, playground, highlight.js, html, qlgenerator

## Directory Tree
```text
qlplayground-norio
|-- img
|   |-- preview.png
|   `-- thumbnail.png
|-- qlplayground
|   |-- highlight
|   |   |-- styles
|   |   |   |-- agate.css
|   |   |   |-- androidstudio.css
|   |   |   |-- arta.css
|   |   |   |-- ascetic.css
|   |   |   |-- atelier-cave.dark.css
|   |   |   |-- atelier-cave.light.css
|   |   |   |-- atelier-dune.dark.css
|   |   |   |-- atelier-dune.light.css
|   |   |   |-- atelier-estuary.dark.css
|   |   |   |-- atelier-estuary.light.css
|   |   |   |-- atelier-forest.dark.css
|   |   |   |-- atelier-forest.light.css
|   |   |   |-- atelier-heath.dark.css
|   |   |   |-- atelier-heath.light.css
|   |   |   |-- atelier-lakeside.dark.css
|   |   |   |-- atelier-lakeside.light.css
|   |   |   |-- atelier-plateau.dark.css
|   |   |   |-- atelier-plateau.light.css
|   |   |   |-- atelier-savanna.dark.css
|   |   |   |-- atelier-savanna.light.css
|   |   |   |-- atelier-seaside.dark.css
|   |   |   |-- atelier-seaside.light.css
|   |   |   |-- atelier-sulphurpool.dark.css
|   |   |   |-- atelier-sulphurpool.light.css
|   |   |   |-- brown_paper.css
|   |   |   |-- brown_papersq.png
|   |   |   |-- codepen-embed.css
|   |   |   |-- color-brewer.css
|   |   |   |-- dark.css
|   |   |   |-- darkula.css
|   |   |   |-- default.css
|   |   |   |-- docco.css
|   |   |   |-- far.css
|   |   |   |-- foundation.css
|   |   |   |-- github-gist.css
|   |   |   |-- github.css
|   |   |   |-- googlecode.css
|   |   |   |-- grayscale.css
|   |   |   |-- hopscotch.css
|   |   |   |-- hybrid.css
|   |   |   |-- idea.css
|   |   |   |-- ir_black.css
|   |   |   |-- kimbie.dark.css
|   |   |   |-- kimbie.light.css
|   |   |   |-- magula.css
|   |   |   |-- mono-blue.css
|   |   |   |-- monokai.css
|   |   |   |-- monokai_sublime.css
|   |   |   |-- obsidian.css
|   |   |   |-- paraiso.dark.css
|   |   |   |-- paraiso.light.css
|   |   |   |-- pojoaque.css
|   |   |   |-- pojoaque.jpg
|   |   |   |-- railscasts.css
|   |   |   |-- rainbow.css
|   |   |   |-- school_book.css
|   |   |   |-- school_book.png
|   |   |   |-- solarized_dark.css
|   |   |   |-- solarized_light.css
|   |   |   |-- sunburst.css
|   |   |   |-- tomorrow-night-blue.css
|   |   |   |-- tomorrow-night-bright.css
|   |   |   |-- tomorrow-night-eighties.css
|   |   |   |-- tomorrow-night.css
|   |   |   |-- tomorrow.css
|   |   |   |-- vs.css
|   |   |   |-- xcode.css
|   |   |   `-- zenburn.css
|   |   |-- CHANGES.md
|   |   |-- highlight.pack.js
|   |   |-- LICENSE
|   |   |-- README.md
|   |   `-- README.ru.md
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Highlight.swift
|   |-- Info.plist
|   `-- main.c
|-- qlplayground.xcodeproj
|   |-- xcshareddata
|   |   `-- xcschemes
|   |       `-- qlplayground.xcscheme
|   `-- project.pbxproj
|-- .gitignore
|-- LICENSE
`-- README.md
```

## Relevant Paths (for dotViewer)
- `qlplayground/GeneratePreviewForURL.m`: builds HTML preview with Highlight.js.
- `qlplayground/Highlight.swift`: Swift side utilities for preview rendering.
- `qlplayground/highlight/`: bundled Highlight.js script and theme CSS.
- `qlplayground/Info.plist`: UTI registration.

## Non-Relevant Paths (scanned)
- Screenshots and project scaffolding.

## Architecture Notes
- Reads file contents and injects into Highlight.js HTML template.

## Performance Tactics
- JS-based highlighting; may be slower for large files.

## Build / Setup Notes
- Xcode project; legacy generator.

## Reuse Notes
- Highlight.js theme selection via defaults is a useful preference pattern.
