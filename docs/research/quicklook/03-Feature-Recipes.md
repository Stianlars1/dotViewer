# Feature Recipes (Where To Copy Ideas)

Use this file when implementing a new feature. Each feature lists the best reference repo(s) and the key paths to inspect.

## Unknown / Dotfile Plain-Text Preview
- QLStephen -> `Repos/whomwah-qlstephen.md`
Key paths: `QuickLookStephenProject/GeneratePreviewForURL.m`, `QuickLookStephenProject/QLSFileAttributes.{h,m}`.
- QLGradle -> `Repos/Urucas-QLGradle.md`
Key paths: `QLGradle/GeneratePreviewForURL.m`.

## Encoding Detection (Non-UTF8 / Legacy)
- qltext-jp -> `Repos/mzp-qltext-jp.md`
Key paths: `qltext-jp/NSData+DetectEncoding.{h,m}`.
- QuickNFO -> `Repos/planbnet-QuickNFO.md`
Key paths: `quicklooknfo.c` (code page 437 -> UTF-8).

## Syntax Highlighting (Native)
- SourceCodeSyntaxHighlight -> `Repos/sbarex-SourceCodeSyntaxHighlight.md`
Key paths: `QLExtension/PreviewViewController.swift`, `XPCService/`, `SyntaxHighlightRenderXPC/`, `highlight-wrapper/`.
- QLColorCode -> `Repos/anthonygelibert-QLColorCode.md`
Key paths: `src/Common.{h,m}`, `src/colorize.sh`.
- Highlight library -> `Repos/saalen-highlight.md`
Key paths: `src/`, `langDefs/`, `themes/`.

## Markdown Preview (Modern + Fast)
- QLMarkdown (sbarex) -> `Repos/sbarex-QLMarkdown.md`
Key paths: `QLExtension/PreviewViewController.swift`, `QLMarkdownXPCHelper/`, `cmark-gfm/`, `cmark-extra/`.
- QLMarkdownGFM -> `Repos/Watson1978-QLMarkdownGFM.md`
Key paths: `QLMarkdownGFM/markdown.{m,h}`.
- QLCommonMark -> `Repos/digitalmoksha-QLCommonMark.md`
Key paths: `QLCommonMark/common_mark.{m,h}`.

## Markdown Preview (Legacy / Discount)
- QLMarkdown (toland) -> `Repos/toland-qlmarkdown.md`
Key paths: `discount-wrapper.{c,h}`, `discount/`.
- lookdown (OCDiscount) -> `Repos/qvacua-lookdown.md`
Key paths: `QuickLookDown/MPMarkdownProcessor.{h,m}`.

## JSON Preview (Pretty / Folding)
- QuickJSON -> `Repos/johan-QuickJSON.md`
Key paths: `json-viewer/quicklook.{html,js,css}`.
- QuickLookPrettyJSON -> `Repos/tomnewton-QuickLookPrettyJSON.md`
Key paths: `QuickLookPrettyJSON/GeneratePreviewForURL.m`.

## CSV Table Preview
- quicklook-csv -> `Repos/p2-quicklook-csv.md`
Key paths: `GeneratePreviewForURL.m` (row limits, encoding fallback).

## XML / Plist Pretty Print
- colorxml-quicklook -> `Repos/fabiolecca-colorxml-quicklook.md`
Key paths: `xmlverbatim.xsl` (formatting rules).

## Patch / Diff Rendering
- QLPrettyPatch -> `Repos/atnan-QLPrettyPatch.md`
Key paths: PrettyPatch formatter integration.

## Code Snippet Formats
- Xcode .codesnippet -> `Repos/douglashill-QuickLookCodeSnippet.md`
Key paths: `template.html`, plist keys in `CodeSnippetConstants.h`.
- Sublime snippet -> `Repos/hetima-SublimeSnippetQL.md`
Key paths: `GeneratePreviewForURL.m`.

## Playgrounds & Swift
- inloop-qlplayground -> `Repos/inloop-qlplayground.md`
Key paths: `PlaygroundParser.swift` (multi-page extraction), `PreviewBuilder.swift` (attachments).
- norio-nomura qlplayground -> `Repos/norio-nomura-qlplayground.md`
Key paths: Highlight.js template + theme switch.

## Graph / Visualization
- Graphviz DOT -> `Repos/besi-quicklook-dot.md`
Key paths: `Dot.m` (external `dot` call).
- Vega / Vega-Lite -> `Repos/invokesus-qlvega.md`
Key paths: `Shared.m` (external `vg2svg`/`vl2svg`).
- GeoJSON -> `Repos/irees-quickgeojson.md`
Key paths: `template.html` + JS/CSS attachments.
- GPX -> `Repos/vibrog-quicklook-gpx.md`
Key paths: `template.html` + OpenLayers assets.

## Jupyter / Notebook
- ipynb-quicklook -> `Repos/tuxu-ipynb-quicklook.md`
Key paths: `HTMLPreviewBuilder.m` + `template.html.in`.
- jupyter-notebook-quick-look -> `Repos/jendas1-jupyter-notebook-quick-look.md`
Key paths: `GeneratePreviewForURL.m`.

## Provisioning / App Metadata
- Provisioning -> `Repos/chockenberry-Provisioning.md`
Key paths: `GeneratePreviewForURL.m` (CMS decode + HTML template).

