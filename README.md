# dotViewer

A macOS Quick Look extension that adds syntax-highlighted previews for source code, config files, and dotfiles. Select any file in Finder, press Space, and get a beautifully highlighted preview — no app launch needed.

## Features


### Syntax highlighting 
53 tree-sitter grammars with heuristic fallback for unknown languages

### Markdown preview 
raw/rendered toggle with Typora-quality rendered mode (GFM tables, task lists, TOC sidebar, clickable links)

### Quick Look integration 
spacebar preview from Finder, Path Finder, or any Quick Look host

### Finder thumbnails 
full-bleed syntax-highlighted thumbnails with bold/italic styling and dark mode support

### Search 
optional search bar with match highlighting and prev/next navigation

### Line highlighting 
click line numbers to highlight, Shift+click for range selection

### 10+ themes 
with automatic dark/light mode detection

### Header UI 
file type badge, file size, copy-to-clipboard button, markdown mode toggle

### Smart copy 
8 configurable copy behavior presets (auto-copy, floating button, tap-to-confirm, shake, and more)

### Configurable 
font size, word wrap, line numbers, theme, copy behavior, search toggle via host app

### Custom file types 
register your own extensions and assign highlight languages

### Broad coverage 
388 file type definitions, 561 extensions, 283 filename patterns

## Screenshots

*Coming soon.*

## Requirements

- macOS 15.0+
- Xcode (with command-line tools)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Swift 6

## Install

Build from source:

```bash
# Full rebuild, install to /Applications, register extensions
./scripts/dotviewer-refresh.sh

# Incremental (skip clean + Quick Look cache reset)
./scripts/dotviewer-refresh.sh --no-clean --no-reset

# Release build
./scripts/dotviewer-refresh.sh --config Release
```

After install, select any supported file in Finder and press Space to preview.

## Architecture

```
dotViewer.app (host app — settings UI)
├── QuickLookExtension (spacebar preview)
│   └── HighlightXPC (tree-sitter syntax highlighting, runs out-of-process)
├── QuickLookThumbnailExtension (Finder thumbnail generation)
└── Shared.framework (file type registry, HTML builder, settings, utilities)
```

See [CLAUDE.md](CLAUDE.md) for detailed architecture, key files, and development guide.

## License

GPLv3. See [dotViewer/ATTRIBUTION.md](dotViewer/ATTRIBUTION.md) for third-party acknowledgments.
