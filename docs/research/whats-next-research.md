# What's Next for dotViewer — Research Summary

_Date: 2026-02-11_

## Current State

dotViewer v2.5 is feature-complete for its core mission: a best-in-class Quick Look code previewer with 53 tree-sitter grammars, 388 file type definitions, configurable copy behavior, and markdown rendering. The last week of development (2026-02-04 → 2026-02-10) was an intense sprint that shipped the full tree-sitter pipeline, exhaustive UTI coverage, markdown parser rewrite, and copy behavior presets.

**Uncommitted work**: ~8,600 lines across 16 files from the Feb 10 session (UTI expansion, copy behavior presets, custom file types UX, doc updates). This should be committed before starting new work.

---

## Priority Tiers

### Tier 1 — Ship-readiness (High Impact, Actionable Now)

| ID | Item | Why Now |
|----|------|---------|
| **COMMIT** | Commit uncommitted changes | ~8,600 lines of working code sitting unstaged. Risk of loss. |
| B-011 | **Automated test suite** | Zero tests. Every change is verified manually. Adding unit tests for FileTypeRegistry, FileTypeResolution, and the markdown parser would catch regressions and enable faster iteration. |
| B-012 | **App Store distribution** | The product is functionally complete. Shipping to the App Store would reach users and validate the product. Requires: sandboxing review, notarization, screenshots, App Store listing, privacy policy. |
| B-031 | **DefaultFileTypes.json audit** | 5 missing primaries were fixed, but ~250 entries are unaudited. Some may have wrong aliases, missing extensions, or incorrect language IDs. The `dvaudit` script exists but hasn't been run comprehensively. |

### Tier 2 — Quality Polish (Medium Impact)

| ID | Item | What Remains |
|----|------|-------------|
| B-002 | **Markdown RAW structural readability** | Color differentiation done. Remaining: CSS-level size/weight for headers (larger/bolder), code block backgrounds. Requires extending the token→CSS architecture to support markdown-specific styling. |
| B-032 | **ThemePalette↔CSS token sync** | Currently manual mirror between ThemePalette.swift, PreviewHTMLBuilder CSS, and TextThumbnailRenderer. A change in one can silently drift from the others. Could be automated or at least validated by a build-time check. |
| KI-002/KI-006 | **Thumbnail↔preview visual parity** | Colors match (via ThumbnailSyntaxColorizer). Remaining gap: font weight/style not replicated, regex-based colorizer may disagree with tree-sitter on token boundaries. Would need tree-sitter in the thumbnail path (expensive) or accepting the current approximation. |
| B-001 | **Markdown rendered polish** | Parser rewritten, CSS overhauled. Remaining: minor typography differences vs Typora (spacing, font weights, nested list indentation). Diminishing returns — already "good enough" for most users. |

### Tier 3 — Feature Expansion (Nice to Have)

| ID | Item | Notes |
|----|------|-------|
| B-015 | **Search within preview (Cmd+F)** | Would significantly improve usability for long files. Requires JS-based search overlay since the Quick Look host window intercepts keyboard events (same constraint as Cmd+C). Would need a mouse-triggered search button in the header. |
| B-014 | **Line number highlighting** | Click line number to highlight, URL fragment for deep linking. Useful for sharing/referencing specific lines. Straightforward JS+CSS implementation. |
| B-013 | **Print / export to PDF** | From v1 requirements. Would need a print-optimized CSS stylesheet and a way to trigger it from the preview (header button?). Quick Look's sandboxing may limit where the PDF can be saved. |
| B-016 | **Additional tree-sitter grammars** | 177 file types use heuristic fallback. Adding grammars for popular languages (HCL/Terraform, Zig, Svelte, Prisma) would improve accuracy. Each grammar requires: C source compilation + .scm query file. |
| B-018 | **Custom theme editor** | Let users create/modify color palettes in the host app. Medium complexity — needs a color picker UI and persistence to App Group. Low urgency since 10+ built-in themes cover most preferences. |

### Tier 4 — Technical Debt (Low Urgency)

| ID | Item | Notes |
|----|------|-------|
| B-030 | 177 file types without grammar | Expected — heuristic fallback is adequate. Grammars can be added incrementally. |
| B-033 | Temp PNG cleanup | OS handles this. Explicit cleanup would be cleaner but not functionally necessary. |
| B-017 | Performance benchmarking | Would be useful for regression detection but the XPC architecture already ensures responsive previews. |

---

## Strategic Options

### Option A: Ship to App Store (B-012)
The product is functionally rich and stable. Packaging for distribution would:
- Validate the product with real users
- Force a quality pass (sandboxing review, error handling, edge cases)
- Provide motivation for polish items

**Prerequisites**: Commit current work, add screenshots, write App Store description, review sandboxing constraints, notarize, test on clean macOS install.

**Risk**: App Store review may reject due to Quick Look extension limitations or sandboxing edge cases. Non-sandboxed distribution (DMG/Homebrew) is an alternative.

### Option B: Test Suite First (B-011)
Before shipping or adding features, establish a safety net:
- Unit tests for FileTypeRegistry (extension → language resolution)
- Unit tests for FileTypeResolution (bestKey, multi-dot, dotfiles)
- Unit tests for MarkdownRenderer (parser correctness)
- Integration tests for XPC service (highlight request → HTML response)
- Snapshot tests for thumbnails (visual regression detection)

**Benefit**: Enables confident iteration on everything else.

### Option C: Polish Pass (B-001, B-002, KI-002/006)
Close remaining known issues to get the product to a "no rough edges" state:
- Markdown RAW size/weight differentiation
- Markdown rendered final typography pass
- Thumbnail rendering improvements

**Risk**: Diminishing returns — current state is already good.

### Option D: Feature Expansion (B-015, B-014, B-013)
Add user-facing features that differentiate dotViewer from competitors:
- Search within preview (most impactful)
- Line highlighting
- PDF export

**Benefit**: Competitive differentiation. **Risk**: Scope creep before shipping.

---

## Known Dead-Ends (Do NOT Attempt)

| Approach | Why Not |
|----------|---------|
| Override `.ts` UTI routing | macOS system limitation (KI-001). `public.mpeg-2-transport-stream` always wins. |
| Override `.html` UTI routing | macOS system limitation (KI-007). Built-in HTML renderer has priority. |
| Embedded CGEventTap helper for Cmd+C | TCC sandbox inheritance blocks it (KI-009). Would need independently-installed helper. |
| Pre-computed `dyn.*` UTI codes | Encoding doesn't match macOS. 0% match rate. Already removed. |
| `QLThumbnailReply(contextSize:drawing:)` | Renders inside document icon frame — unusable for full-bleed thumbnails. |
| WKWebView in view-based QL extension | WebContent process crashes in sandbox. Only `quicklookd` has the entitlements. |

---

## Open Questions

1. **Distribution strategy**: App Store (sandboxed) vs direct distribution (DMG/Homebrew, can be unsandboxed)? This affects what features are possible (e.g., unsandboxed enables the Cmd+C helper approach).
2. **Priority**: Ship first and iterate, or polish/test first?
3. **Scope**: Is the current feature set sufficient for a v1 release, or are there must-have features missing?
4. **Branding/marketing**: Screenshots, website, product page needed?
