# Research Library Guide

Reference library for Quick Look extension development, compiled during dotViewer v2. Contains deep-dive analyses of 37 open-source Quick Look extensions plus performance and competitor research.

## How to Use

1. **Building a feature?** Check [quicklook/03-Feature-Recipes.md](quicklook/03-Feature-Recipes.md) — maps features to reference implementations
2. **Architecture question?** See [quicklook/01-Architecture-Patterns.md](quicklook/01-Architecture-Patterns.md) for patterns across 37 repos
3. **Performance concern?** Read [performance.md](performance.md) and [quicklook/02-Performance-Sandboxing-Compatibility.md](quicklook/02-Performance-Sandboxing-Compatibility.md)
4. **Specific repo?** Browse [quicklook/Repos/](quicklook/Repos/) for individual deep-dives (directory tree, key paths, architecture notes)
5. **Full source list**: [quicklook/00-Source-Index.md](quicklook/00-Source-Index.md)

## Research by Relevance to dotViewer

### Core references (directly inform our architecture)
These repos shaped dotViewer's design decisions:
- **sbarex-SourceCodeSyntaxHighlight** — tree-sitter + XPC architecture, file type registry design, UTI handling
- **whomwah-qlstephen** — plain text / unknown extension handling, "catch-all" UTI approach
- **saalen-highlight** — syntax highlighting engine integration patterns
- **github-cmark-gfm** — GitHub-flavored markdown parsing (relevant for rendered mode)
- **sbarex-QLMarkdown** — markdown Quick Look with rendered/raw toggle, theme support

### Markdown rendering (inform our markdown work)
Relevant for KI-003/KI-004 (markdown quality improvements):
- **sbarex-QLMarkdown** — most feature-complete markdown QL extension (CSS themes, code highlighting)
- **digitalmoksha-QLCommonMark** — CommonMark rendering approach
- **qvacua-lookdown** — lightweight markdown preview
- **fletcher-MMD-QuickLook** — MultiMarkdown rendering
- **Watson1978-QLMarkdownGFM** — GitHub Flavored Markdown variant
- **toland-qlmarkdown** — original/classic markdown QL (simpler approach)

### Format-specific (useful if adding format support)
- **tomnewton-QuickLookPrettyJSON** — JSON pretty-printing and validation
- **p2-quicklook-csv** — CSV table rendering
- **anthonygelibert-QLColorCode** — highlight.js-based code coloring (older approach)
- **fabiolecca-colorxml-quicklook** — XML-specific rendering

### Low relevance (niche/outdated, preserved for completeness)
Includes plugins for: GPX maps, Vega charts, ANSI art, Jupyter notebooks, Java .class files, Xcode playgrounds, Gradle files, provisioning profiles, NFO files, dot graphs, GeoJSON, and more. See [quicklook/00-Source-Index.md](quicklook/00-Source-Index.md) for the full list.

## Licensing Reminder

Many Quick Look plugins are GPL-licensed. Before incorporating any code, always check the specific repo's license. Prefer reusing **ideas and patterns** over direct code copying. dotViewer is GPLv3 — see [dotViewer/ATTRIBUTION.md](../../dotViewer/ATTRIBUTION.md).

## Other Research

- [performance.md](performance.md) — Quick Look extension performance research (file size limits, caching, XPC offloading, native rendering)
- [competitors.md](competitors.md) — dotViewer vs. competitor analysis (why v1 was slow, what makes competitors fast)
