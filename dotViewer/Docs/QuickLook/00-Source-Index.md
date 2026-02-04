# Quick Look Source Index

This index lists every explicit source from the prompt (plus relevant linked repos), and points to the deep-dive docs in `Repos/`.

## Quick Navigation
- Deep-dive repo docs live in: `dotViewer/Docs/QuickLook/Repos/`
- Architecture synthesis: `dotViewer/Docs/QuickLook/01-Architecture-Patterns.md`
- Performance & compatibility: `dotViewer/Docs/QuickLook/02-Performance-Sandboxing-Compatibility.md`
- Feature recipes: `dotViewer/Docs/QuickLook/03-Feature-Recipes.md`

## Summary Lists (Meta)
- **Mac-QuickLook list** (master index of plugins): https://github.com/haokaiyang/Mac-QuickLook?tab=readme-ov-file
- **Quick Look plugins list (developer-focused)**: https://github.com/sindresorhus/quick-look-plugins

## Deep-Dive Repos (Code)
Each item below has a full directory tree and relevant-paths summary.

- AsciiDoc: `Repos/clydeclements-AsciiDocQuickLook.md`
- Syntax highlight (Highlight + QL): `Repos/anthonygelibert-QLColorCode.md`
- QLColorCode extra UTIs: `Repos/BrianGilbert-QLColorCode-extra.md`
- Markdown (Discount): `Repos/toland-qlmarkdown.md`
- MultiMarkdown / OPML: `Repos/fletcher-MMD-QuickLook.md`
- Plain/unknown files: `Repos/whomwah-qlstephen.md`
- JSON (pretty): `Repos/tomnewton-QuickLookPrettyJSON.md`
- JSON (folding UI): `Repos/johan-QuickJSON.md`
- CSV: `Repos/p2-quicklook-csv.md`
- CommonMark (cmark): `Repos/digitalmoksha-QLCommonMark.md`
- Subtitles (.srt): `Repos/tattali-QLAddict.md`
- Playgrounds (SyntaxHighlighter): `Repos/inloop-qlplayground.md`
- Playgrounds/Swift (Highlight.js): `Repos/norio-nomura-qlplayground.md`
- Diff/Patch: `Repos/atnan-QLPrettyPatch.md`
- ANSI/ASCII art: `Repos/ansilove-QLAnsilove.md`
- Vega/Vega-Lite: `Repos/invokesus-qlvega.md`
- GPX (OpenLayers): `Repos/vibrog-quicklook-gpx.md`
- Japanese text encodings: `Repos/mzp-qltext-jp.md`
- NFO text: `Repos/planbnet-QuickNFO.md`
- GeoJSON (Mapbox/Leaflet): `Repos/irees-quickgeojson.md`
- Graphviz DOT: `Repos/besi-quicklook-dot.md`
- Xcode Code Snippets: `Repos/douglashill-QuickLookCodeSnippet.md`
- Rust: `Repos/yingDev-rust-quicklook.md`
- Gradle (system delegation): `Repos/Urucas-QLGradle.md`
- Sublime Snippets: `Repos/hetima-SublimeSnippetQL.md`
- Java .class decompiler: `Repos/jaroslawhartman-Java-Class-QuickLook.md`
- Markdown (GFM + cmark-gfm): `Repos/Watson1978-QLMarkdownGFM.md`
- Modern app extension: `Repos/sbarex-SourceCodeSyntaxHighlight.md`
- Modern app extension (Markdown): `Repos/sbarex-QLMarkdown.md`
- Markdown app + generator: `Repos/qvacua-lookdown.md`
- Highlight library (C++): `Repos/saalen-highlight.md`
- cmark-gfm library (C): `Repos/github-cmark-gfm.md`
- Jupyter notebooks: `Repos/tuxu-ipynb-quicklook.md`
- Jupyter notebooks (alt): `Repos/jendas1-jupyter-notebook-quick-look.md`
- Provisioning profiles: `Repos/chockenberry-Provisioning.md`
- XML pretty print: `Repos/fabiolecca-colorxml-quicklook.md`
- Missing repo placeholder: `Repos/laptrinhcomvn-ltquicklooks.md`

## Sources Without Public Code (Summaries)
These are still useful for context, behavior, and compatibility changes.

- **QuickLookJSON** (binary download only): http://www.sagtau.com/quicklookjson.html  
  A classic JSON Quick Look plugin distributed as a binary bundle.
- **Quick Look Enscript** (blog + GPL note): https://www.dribin.org/dave/blog/archives/2007/11/14/quick_look_enscript/  
  Describes using `enscript` to generate HTML for source preview; notes GPL licensing.
- **Apple Quick Look docs**: https://developer.apple.com/documentation/QuickLook  
  Official API reference for preview/thumbnails and extension behavior.
- **Sequoia Quick Look changes**: https://eclecticlight.co/2024/10/31/how-sequoia-has-changed-quicklook-and-its-thumbnails/  
  Notes macOS 15 changes and deprecation of legacy generator plugins.
- **Quick Look history & thumbnails**: https://eclecticlight.co/2024/11/02/a-brief-history-of-icons-thumbnails-and-quicklook/  
  Context on how Quick Look and thumbnails evolved.
- **Quick Look internals (mints update)**: https://eclecticlight.co/2024/11/04/how-does-quicklook-create-thumbnails-and-previews-with-an-update-to-mints/  
  Deeper dive into preview generation flow and system behavior.
- **Sequoia: generator plug-ins deprecated**: https://mjtsai.com/blog/2024/11/05/sequoia-no-longer-supports-quicklook-generator-plug-ins/  
  Confirms `.qlgenerator` deprecation in macOS 15.
- **dos2unix**: https://waterlan.home.xs4all.nl/dos2unix.html  
  Utility reference for line-ending conversion (useful for text normalization).
- **UTI origins**: https://stackoverflow.com/questions/16943819/where-do-uti-come-from/18014903#18014903  
  Explains how UTIs are derived and registered.
- **File provider extension debugging**: https://stackoverflow.com/questions/66546696/how-to-enable-and-debug-a-macos-file-provider-extension  
  Extension debugging tips relevant to extension workflows.
- **pluginkit output prefixes**: https://stackoverflow.com/questions/34898903/what-do-the-prefixes-in-the-output-of-macos-pluginkit-mean/36839118#36839118  
  Decodes `pluginkit` output for extension troubleshooting.
- **TidBITS discussion**: https://talk.tidbits.com/t/what-are-your-favorite-quick-look-extensions/29323  
  Community list of recommended Quick Look extensions and behaviors.
- **Reddit list of plugins**: https://www.reddit.com/r/macapps/comments/1f00bbx/11_useful_plugins_for_quicklook/  
  Community suggestions and plugin popularity snapshots.

## Additional Prompt-Linked Libraries
- **Highlight (official site)**: http://andre-simon.de/doku/highlight/en/highlight.php  
  Overview of the Highlight engine, themes, and supported outputs.
- **Discount (Markdown C impl)**: https://www.pell.portland.or.us/~orc/Code/markdown/  
  Original Discount parser used by older Markdown Quick Look plugins.

## Missing / Unavailable Repos
- `laptrinhcomvn/ltquicklooks` from Mac-QuickLook list: repo not found at time of scan (see `Repos/laptrinhcomvn-ltquicklooks.md`).
