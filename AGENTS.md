# dotViewer — Agent Guide

Instructions and context for AI agents working on this repo.

## Before You Start

1. Read [CLAUDE.md](CLAUDE.md) for architecture, build instructions, and key concepts
2. Check [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for current bugs (don't re-discover known problems)
3. Check [BACKLOG.md](BACKLOG.md) for planned work and priorities

## Key Patterns

- **Source of truth is `project.yml`** — never edit generated Info.plist or .entitlements files
- **Two rendering pipelines** — previews use HTML/CSS (PreviewHTMLBuilder), thumbnails use CoreGraphics (TextThumbnailRenderer). Changes to one may need mirroring in the other
- **UTI routing is exact-match** — adding a file type requires its UTI in QLSupportedContentTypes (both extensions). Use `dvutis` to regenerate
- **XPC embeds Shared.framework** — set `embed: true` in project.yml for the XPC target
- **Tree-sitter grammars compile as C sources** — each grammar uses its own `parser.h` (ABI incompatible across grammars). Set `USE_HEADERMAP: NO` for HighlightXPC
- **.scm query files load flat from Resources/** — do not use `subdirectory:` parameter in `Bundle.main.url(forResource:withExtension:)`
- **Swift 6 strict concurrency** — use explicit capture lists in `Task.detached`, no `await` in autoclosures

## What NOT to Do

- Don't edit Info.plist or .entitlements files directly (XcodeGen regenerates them)
- Don't add `public.mpeg-2-transport-stream` to supported types (hijacks .ts video files)
- Don't use `<>` includes in tree-sitter grammar sources (use `""` for local parser.h)
- Don't attempt to override system UTIs for .html or .ts (macOS limitation, see KI-001, KI-007)
- Don't use `QLThumbnailReply(contextSize:drawing:)` for thumbnails (renders inside document icon frame)
- Don't run `xcodebuild` without `xcodegen generate` first (project.yml is the source of truth)

## Build & Verify Workflow

```bash
# After any code change:
./scripts/dotviewer-refresh.sh          # Full rebuild + install
./scripts/dotviewer-ql-smoke.sh TestFiles/test.json   # Verify preview works

# Incremental during development:
./scripts/dotviewer-refresh.sh --no-clean --no-reset
```

## Work Log

Summary of agent-assisted development. See [CHANGELOG.md](CHANGELOG.md) for full version history.

| Date | Area | Outcome |
|------|------|---------|
| 2026-02-04 | Extension discovery | Fixed NSExtension dictionaries, entitlements, signing via project.yml |
| 2026-02-04 | Routing | Expanded QLSupportedContentTypes to exact UTIs for all major languages |
| 2026-02-04 | Highlighting | Added heuristic fallback highlighter for languages without tree-sitter grammars |
| 2026-02-04 | Dev scripts | Created dvrefresh, dvlogs, dvql, dvsmoke, dvutis |
| 2026-02-04 | Stability | Added FileTypeResolution.bestKey, looksTextual detection, thumbnail timeout |
| 2026-02-05 | Thumbnails | Replaced WKWebView with native CoreGraphics rendering |
| 2026-02-05 | Routing | Added MPEG-TS gating for .ts, binary plist conversion |
| 2026-02-05 | Preview UI | Copy toast, compact header, auto-theme CSS |
| 2026-02-05 | File types | Data-driven DefaultFileTypes.json (325+ entries from SourceCodeSyntaxHighlight) |
| 2026-02-06 | Tree-sitter | Compiled 53 grammars, created 53 .scm query files |
| 2026-02-06 | Color palette | Expanded to 18 token types (tag, attribute, escape, builtin, namespace, parameter) |
| 2026-02-06 | E2E testing | 10/11 issues fixed; added custom UTIs for jsx, fsharp, vb, batch |
| 2026-02-06 | Preview sizing | Dynamic window dimensions based on line count |
| 2026-02-06 | Thumbnails | Full-bleed rendering with subtle border + corner radius |
| 2026-02-06 | Settings | Word wrap support (user-configurable) |
| 2026-02-06 | Docs | Documentation refresh — README, CHANGELOG, KNOWN_ISSUES, BACKLOG, research reorg |
| 2026-02-09 | App icon | Fixed icon not appearing — added `resources:` and `ASSETCATALOG_COMPILER_APPICON_NAME` to project.yml |
| 2026-02-09 | Markdown parser | Full rewrite of MarkdownRenderer.swift (~510 lines) — two-pass parser with GFM tables, task lists, setext headings, code block language labels, recursive blockquotes, auto-linking |
| 2026-02-09 | Markdown CSS | PreviewHTMLBuilder rendered-view CSS overhaul — theme-aware headings, table striping, task list checkboxes, tighter spacing, v1-matching sizes |
| 2026-02-09 | Markdown RAW | Added text-semantic tree-sitter capture mappings in TreeSitterHighlighter; fixed markdown.scm fenced_code_block overlap |
| 2026-02-09 | Markdown routing | Fixed toggle not appearing for README.md/CHANGELOG.md — changed `isMarkdown` from key-based to `languageId == "markdown"` |
| 2026-02-09 | Docs | Updated KNOWN_ISSUES (KI-003, KI-004), CHANGELOG, BACKLOG, AGENTS to reflect current state |
| 2026-02-10 | Cmd+C research | Built CGEventTap helper (CopyHelper.app): unsandboxed background app with AXUIElement + CGEventTap, embedded in Contents/Helpers/, launched via NSWorkspace.openApplication(), status via DistributedNotificationCenter. Failed: TCC sandbox inheritance, responsible process attribution, Accessibility list registration. Reverted. Comprehensive research documented in KI-009 with untried alternatives. |
| 2026-02-10 | Copy behavior presets | KI-009 v2: Added configurable copy behavior with 8 presets (autoCopy, floatingButton, toastAction, tapToCopy, holdToCopy, shakeToCopy, autoCopyUndo, off). SharedSettings.copyBehavior → PreviewInfo → buildCopyBehaviorScript(). Removed hardcoded mouseup auto-copy from both script branches. Each preset is an IIFE. Picker in Settings → Preview UI with dynamic description. |
| 2026-02-10 | Copy behavior fixes | Fixed shakeToCopy (per-event dx comparison replaced with extreme-point tracking for cumulative directional movement). Fixed autoCopyUndo (clipboard.readText() blocked in sandbox; added internal lastCopiedText fallback tracking). |
| 2026-02-10 | App icon fix | project.yml referenced `dotIcon` but actual xcassets is `dotViewerIcon`. Updated ASSETCATALOG_COMPILER_APPICON_NAME and resources path. Icon now compiles into bundle correctly. |
| 2026-02-10 | File type routing | Deep investigation of custom file types and Quick Look UTI routing. Key finding: Quick Look uses exact UTI matching (not conformance) — `public.data` in QLSupportedContentTypes does NOT catch dynamic UTIs. Fixed `bestKey()` multi-dot resolution (intermediate segment scanning), added `displayName(for:)` for custom extension display names, fixed 5 missing primary extensions in DefaultFileTypes.json (xml, plist, jsonc, ini, log). Documented as KI-010. |
| 2026-02-11 | File types | Split C/C++ into separate file type entries — C++ files now get cpp tree-sitter grammar. Added highlight language aliases (plperl→perl, plpython→python, pltcl→tcl, mxml→xml). |
| 2026-02-11 | Token system | Added `TokenType` enum as single source of truth for all token→CSS mapping. `tokenCSSRules()` generates CSS from enum cases. Exhaustive color mapping per theme via `ThemePalette`. |
| 2026-02-11 | Thumbnails | Added bold/italic token styling — keywords bold, builtins italic, types bold, etc. via `NSFont.Weight` and `NSFontDescriptor.SymbolicTraits`. Fixed dark mode (KI-011): `systemIsDark()` reads `AppleInterfaceStyle` from UserDefaults. |
| 2026-02-11 | Preview UI | Search bar: optional (off by default), text selection + paste workflow, highlights matches with prev/next navigation. Line highlighting: click line numbers, Shift+click for range. Markdown RAW CSS: size/weight differentiation. Print CSS: file title header, syntax colors, page breaks. Removed non-functional print button. Clickable markdown links (KI-012): JS handler resolves relative paths against source directory. |
| 2026-02-11 | Testing | Added `dotViewerTests` unit test target with 7 XCTestCase classes: FileTypeRegistry, FileTypeResolution, ThemePalette, MarkdownRenderer, PlistConverter, FileAttributes, TransportStreamDetector. |
| 2026-02-11 | Docs | Documentation audit: fixed KI-005/KI-010 contradiction, updated all docs to reflect 2026-02-11 state. |
| 2026-02-16 | Open With | Attempted “Open With Assistant” for system-owned UTIs; removed after testing due to macOS limitations (Quick Look routing unchanged, Finder automation blocked in sandbox). Open-with fallback view/handling was subsequently removed and marked Won't Fix. Added TOC default open setting and optional line-numbers-in-copy. |
| 2026-02-17 | Roadmap/Backlog triage | Deferred B-011 (test expansion) and B-012 (App Store distribution) to Post-v1; marked B-013 (print/export PDF) as Optional (Low) and non-next-up. Added explicit revisit criteria in BACKLOG. Verified via status consistency grep for B-011/B-012/B-013 across BACKLOG, KNOWN_ISSUES, README, CLAUDE. |
| 2026-02-17 | Preview alignment settings | Added per-variant content alignment controls (left/center/right) for code, markdown RAW, and markdown rendered previews; wired through SharedSettings, PreviewInfo, PreviewCacheKey, and settings UI advanced sections. Verified with `./scripts/dotviewer-refresh.sh`, `./scripts/dotviewer-ql-smoke.sh TestFiles/test.json`, `./scripts/dotviewer-ql-smoke.sh TestFiles/TEST_MARKDOWN.md`, and `xcodebuild -project dotViewer/dotViewer.xcodeproj -scheme dotViewerTests -derivedDataPath dotViewer/build test` (104 tests, 0 failures). |
| 2026-02-17 | Docs sync | Updated README customization sections and CHANGELOG to document per-variant preview alignment controls. Marked B-023 as Done in BACKLOG to match shipped implementation. Verified by grep sweep for `B-023` and alignment setting terms across README/BACKLOG/CHANGELOG. |

## Notes

- XcodeGen regenerates `Info.plist` and `.entitlements` for all extension targets. Persistent changes live in `dotViewer/project.yml`.
- The `.agents/skills/update-agents-md/SKILL.md` skill can be used to append work log entries.

## 2026-02-14

### Preview width + app UI text size controls
- Outcome: Added per-mode preview width customization (separate controls for code/RAW and markdown rendered) and added host-app UI text size setting with a System-follow option.
- Files: `dotViewer/Shared/SharedSettings.swift`, `dotViewer/Shared/PreviewHTMLBuilder.swift`, `dotViewer/Shared/PreviewCache.swift`, `dotViewer/QuickLookExtension/PreviewProvider.swift`, `dotViewer/App/SettingsView.swift`, `dotViewer/App/MarkdownSettingsView.swift`, `dotViewer/App/dotViewerApp.swift`, `dotViewer/App/AppUIFontSizing.swift`, `dotViewer/dotViewerTests/PreviewHTMLBuilderTests.swift`, `docs/research/preview-width-and-app-font-size-research.md`
- Verified:
  - `./scripts/dotviewer-refresh.sh` → pass
  - `xcodebuild -project dotViewer/dotViewer.xcodeproj -scheme dotViewerTests -derivedDataPath dotViewer/build test` → pass (96 tests, 0 failures)
  - `./scripts/dotviewer-ql-smoke.sh TestFiles/test.json` → pass (`HTML built for test.json`)
- Follow-ups: Manual visual check in Finder Quick Look for preferred width values and app text-size presets.

## 2026-02-16

### Open With assistant removal + preview settings tweaks
- Outcome: Removed the Open With Assistant (Finder automation + sample files) after real-world testing showed it doesn’t change Quick Look routing for system-owned UTIs and Finder automation is blocked in sandbox. Open-with fallback code path was later removed from the app and marked Won't Fix. Added Markdown TOC default open/hidden setting and optional “Include line numbers in copy”.
- Files: `dotViewer/App/AssociationAssistant*` (removed), `dotViewer/App/dotViewerApp.swift`, `dotViewer/App/SettingsView.swift`, `dotViewer/App/MarkdownSettingsView.swift`, `dotViewer/Shared/SharedSettings.swift`, `dotViewer/Shared/PreviewHTMLBuilder.swift`, `dotViewer/QuickLookExtension/PreviewProvider.swift`
- Verified: `./scripts/dotviewer-refresh.sh` → pass

## 2026-03-27

### dotViewer launch website
- Outcome: Added a polished Next.js marketing site in `site/` for `dotViewer.app` with a balanced single-page launch layout, live `/download` route, real product coverage stats, install guidance, FAQ, metadata, manifest, sitemap, robots, and JSON-LD.
- Files: `site/app/*`, `site/lib/*`, `site/public/brand/dotviewer-icon-light.png`, `site/package.json`, `site/README.md`, `.gitignore`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
  - Browser check on `http://127.0.0.1:3101` → homepage rendered correctly
  - Browser check on `http://127.0.0.1:3101/download` → `307` fallback to `/#install` with no console errors
- Follow-ups: Set `NEXT_PUBLIC_SITE_URL`, `GITHUB_REPO`, and optional `GITHUB_TOKEN` in deployment so `/download` resolves to the live latest DMG instead of the local install fallback.

### Website layout refinement
- Outcome: Reworked the homepage into a calmer, more spacious Apple-adjacent presentation with a centered hero, a single large showcase, fewer competing card grids, and more generous vertical rhythm after the first pass felt cramped.
- Files: `site/app/page.tsx`, `site/app/page.module.css`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
  - Browser check on `http://127.0.0.1:3101` → redesigned homepage rendered correctly with 0 console warnings/errors
- Follow-ups: Deployment env wiring unchanged (`NEXT_PUBLIC_SITE_URL`, `GITHUB_REPO`, optional `GITHUB_TOKEN`).

### Website screenshot alignment
- Outcome: Rebuilt the homepage around actual dotViewer screenshots so the site now reflects the real Quick Look chrome, markdown raw/rendered states, TOC layout, copy toast, theme controls, file type manager, and status UI instead of invented product mockups.
- Files: `site/app/page.tsx`, `site/app/page.module.css`, `site/public/product/*`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
  - Browser checks on `http://127.0.0.1:3101` at desktop and mobile widths → pass
  - Browser console on `http://127.0.0.1:3101` → 0 errors, 0 warnings
- Follow-ups: Replace the local install fallback links with the real GitHub Releases source during deployment env setup.

### Release download flow + DMG packaging
- Outcome: Replaced the old `/download` redirect with a release-aware `/download` landing page plus `/download/latest` direct asset route, added GitHub release history fetching, fixed site font barrel imports, and hardened `scripts/release.sh` with an `hdiutil` DMG fallback when DropDMG automation permissions are unavailable. Built/exported `dotViewer 2.5`, notarized/stapled the app, packaged a signed DMG manually, notarized/stapled the DMG, generated a SHA-256 checksum, mounted the installer, reinstalled `/Applications/dotViewer.app`, and verified Quick Look registration plus markdown/code smoke-launch coverage from the release build.
- Files: `site/app/download/*`, `site/lib/github-release.ts`, `site/lib/fonts/*`, `site/app/layout.tsx`, `site/app/globals.css`, `site/README.md`, `site/next-env.d.ts`, `scripts/release.sh`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
  - `codesign --verify --deep --strict dotViewer/build/export/dotViewer.app` → pass
  - `spctl --assess --verbose=4 --type execute dotViewer/build/export/dotViewer.app` → accepted (`source=Notarized Developer ID`)
  - `spctl --assess --verbose=4 --type install dotViewer/build/export/dotViewer-2.5.dmg` → accepted (`source=Notarized Developer ID`)
  - Mounted DMG contents showed `dotViewer.app` + `Applications` symlink
  - `./scripts/dotviewer-ql-status.sh` after reinstall → preview + thumbnail extensions registered from `/Applications/dotViewer.app`
  - `./scripts/dotviewer-logs.sh --preview --last 10m | rg 'Preview request|Routing check|Preview route'` → markdown preview request confirmed from the installed release build
- Follow-ups: Push `main` to GitHub, publish the DMG/checksum as a GitHub Release, then verify the live website against that release source.

### GitHub release + Vercel deployment
- Outcome: Pushed the current `main` to `Stianlars1/dotViewer`, preserved the old remote `main` on `v1-legacy`, published GitHub Release `v2.5` with the signed/notarized DMG plus checksum, deployed the site to Vercel project `dotviewer`, attached `dotviewer.app`, and saved production env vars so `/download` and `/download/latest` resolve against GitHub Releases automatically.
- Files: `AGENTS.md`
- Verified:
  - `gh release view v2.5 --repo Stianlars1/dotViewer --json tagName,name,url,isDraft,isPrerelease,publishedAt,assets` → release published with `dotViewer-2.5.dmg` + `.sha256`
  - `curl -I -L -s https://github.com/Stianlars1/dotViewer/releases/download/v2.5/dotViewer-2.5.dmg` → `200 OK` asset download endpoint reachable
  - `curl -I -s http://127.0.0.1:3101/download/latest` → `307` to the GitHub DMG asset
  - `curl -s http://127.0.0.1:3101/download` → rendered release-aware download page with GitHub-backed version history
  - `vercel env ls production` → `NEXT_PUBLIC_SITE_URL` and `GITHUB_REPO` saved on project `dotviewer`
  - `vercel inspect dotviewer-f3xmz3irs-stians-applications.vercel.app` → production deployment ready and aliased to `https://dotviewer.app`
  - `vercel domains inspect dotviewer.app` + `dig +short dotviewer.app A` → domain attached in Vercel, but apex DNS still points to `162.255.119.12` instead of Vercel `76.76.21.21`
- Follow-ups: Change the external apex A record for `dotviewer.app` to `76.76.21.21` or move nameservers to Vercel so the public custom domain resolves to the deployed site.
