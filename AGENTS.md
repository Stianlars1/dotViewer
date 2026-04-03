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

### Website SEO + launch docs polish
- Outcome: Added an inferred product marketing context, rewrote the homepage and download page copy around dotfiles/config/markdown/plain-text/code preview intent, expanded JSON-LD for software/release discovery, refreshed `site/README.md` with badges and launch documentation, and added changelog entries for the search/docs work. Also linked the creator site and `dbHost` in the website/footer and docs.
- Files: `.agents/product-marketing-context.md`, `site/app/page.tsx`, `site/app/layout.tsx`, `site/app/download/page.tsx`, `site/app/opengraph-image.tsx`, `site/app/manifest.ts`, `site/app/sitemap.ts`, `site/app/robots.ts`, `site/app/page.module.css`, `site/lib/structured-data.ts`, `site/README.md`, `CHANGELOG.md`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
  - `cd site && npm run start -- --hostname 127.0.0.1 --port 3200` → pass
  - `curl http://127.0.0.1:3200/` grep checks for updated title/keywords/JSON-LD/creator/footer text → pass
  - `curl http://127.0.0.1:3200/download` grep checks for updated download metadata and `CollectionPage`/`BreadcrumbList` JSON-LD → pass
- Follow-ups: Keep Vercel env wired with `NEXT_PUBLIC_SITE_URL` and `GITHUB_REPO` so the deployed `/download` page renders live release history instead of local no-env fallback output.

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

### Secret purge + deployment fix
- Outcome: Confirmed the leaked OpenAI key came from an old committed Xcode build artifact at `dotViewer/build/.../XCBuildData/.../task-store.msgpack`, created a local bundle backup, rewrote repository history to remove `dotViewer/build/` from all refs, force-pushed cleaned `main`, re-pointed tag `v2.5`, resolved GitHub secret-scanning alert `#1` as `revoked`, and fixed Vercel production serving by adding [site/vercel.json](/Users/stian/Developer/macOS%20Apps/v2.5/site/vercel.json) with a Next.js framework override before redeploying the prebuilt output.
- Files: `AGENTS.md`, `site/README.md`, `site/vercel.json`
- Verified:
  - `git log --all -- dotViewer/build` → no reachable history left for tracked build artifacts
  - `git rev-list --all | xargs -n 1 git grep -I -l -e 'sk-proj-' -- 2>/dev/null | wc -l` → `0`
  - `git rev-list --all | xargs -n 1 git grep -I -l -e 'sk-' -- 2>/dev/null | wc -l` → `0`
  - `git push --force origin main` + `git push --force origin refs/tags/v2.5` → cleaned history published on GitHub
  - `gh api repos/Stianlars1/dotViewer/secret-scanning/alerts/1` → alert state `resolved` with resolution `revoked`
  - `NEXT_PUBLIC_SITE_URL='https://dotviewer.app' GITHUB_REPO='Stianlars1/dotViewer' vercel build --prod` → produced full `.vercel/output` with functions/routes
  - `vercel deploy --prebuilt --prod --yes` → deployed `dotviewer-r6ar61s3w-stians-applications.vercel.app`
  - `curl -I -s https://dotviewer.app/` → `200`
  - `curl -I -s https://dotviewer.app/download/latest` → `307` to the GitHub DMG asset
  - `curl -s https://dotviewer.app/download` → served the GitHub-backed version history page
- Follow-ups: Create a replacement OpenAI API key anywhere that old key was still configured locally; the leaked key itself is already disabled.

### Release version normalization + fallback DMG signing
- Outcome: Moved shipped bundle versions to XcodeGen-managed `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` so `1.0.0` propagates into all app/extension/framework bundles, and fixed `scripts/release.sh` so the `hdiutil` fallback DMG is explicitly Developer ID signed before notarization when DropDMG automation is blocked. Rebuilt via `./scripts/release.sh 1.0.0`, then replaced the live GitHub `v1.0.0` release assets with the verified script-built DMG and checksum.
- Files: `dotViewer/project.yml`, `dotViewer/App/Info.plist`, `dotViewer/Shared/Info.plist`, `dotViewer/QuickLookExtension/Info.plist`, `dotViewer/HighlightXPC/Info.plist`, `dotViewer/QuickLookThumbnailExtension/Info.plist`, `scripts/release.sh`, `AGENTS.md`
- Verified:
  - `cd dotViewer && xcodegen generate` → pass
  - `./scripts/release.sh 1.0.0` → pass (`App notarized and stapled`, `DMG notarized and stapled`, `DMG Gatekeeper verification passed`)
  - `defaults read dotViewer/build/export/dotViewer.app/Contents/Info CFBundleShortVersionString` → `1.0.0`
  - `spctl --assess --verbose=4 --type execute dotViewer/build/export/dotViewer.app` → accepted (`source=Notarized Developer ID`)
  - `spctl --assess --verbose=4 --type install dotViewer/build/export/dotViewer-1.0.0.dmg` → accepted (`source=Notarized Developer ID`)
  - `shasum -a 256 dotViewer/build/export/dotViewer-1.0.0.dmg` + `cat dotViewer/build/export/dotViewer-1.0.0.dmg.sha256` → matching checksum `cd0e9bc1e509e845d94acf38fac460de9651f68f51782097b049c709a6d4fb8c`
  - `gh release upload v1.0.0 ... --clobber --repo Stianlars1/dotViewer` → replaced release assets
  - `gh release view v1.0.0 --json assets` → GitHub DMG digest matches local checksum
  - `curl -I -L -s https://dotviewer.app/download/latest` → `200` to the updated `dotViewer-1.0.0.dmg` asset
- Follow-ups: DropDMG itself is still blocked by macOS Automation permissions in this environment (`errAEEventNotPermitted`), so the script currently falls back to a correctly signed/notarized `hdiutil` DMG instead of the styled DropDMG layout unless Automation access is granted.

## 2026-03-28

### Download page click-to-download behavior
- Outcome: Removed the automatic download trigger from the website `/download` page so visiting the page no longer starts a DMG download; downloads now begin only from explicit button clicks while `/download/latest` remains the direct asset handoff route.
- Files: `site/app/download/page.tsx`, `site/app/download/download-trigger.tsx`, `AGENTS.md`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
- Follow-ups: Deploy the updated `site/` build when you want the live `/download` page to stop auto-downloading on visit.

### Download page release-title update
- Outcome: Updated the visible `/download` page H1 so a live release now renders as `Download dotViewer 1.0.0 for macOS.` instead of the generic `Download dotViewer for macOS.` title.
- Files: `site/app/download/page.tsx`, `AGENTS.md`
- Verified:
  - `cd site && npm run build` → pass
  - `cd site && npm run typecheck` → pass
- Follow-ups: Deploy the updated `site/` build when you want the live download page title to reflect the current release name.

### Website copy and live-release cleanup
- Outcome: Replaced raw backtick-wrapped filename and route mentions on the homepage and download page with styled inline code, linked the homepage install copy to the real `/download` route, removed pre-launch/fallback wording from the public site, hardened release fetching around the official GitHub repo with stable live fallbacks, and normalized the download-page JSON-LD/software version and release summaries for the shipped `v1.0.0` release.
- Files: `site/app/page.tsx`, `site/app/page.module.css`, `site/app/download/page.tsx`, `site/app/download/page.module.css`, `site/app/layout.tsx`, `site/app/globals.css`, `site/lib/site-config.ts`, `site/lib/github-release.ts`, `site/lib/structured-data.ts`, `site/README.md`, `AGENTS.md`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
  - `cd site && npm run start -- --hostname 127.0.0.1 --port 3200` → pass
  - Playwright browser verification on `http://127.0.0.1:3200/` and `http://127.0.0.1:3200/download` → pages rendered, internal `/download` link present, no console errors
  - Playwright JSON-LD evaluation on `/` and `/download` → homepage graph includes `FAQPage`; download page graph includes `CollectionPage`, `BreadcrumbList`, `ItemList`, `softwareVersion: 1.0.0`, and the live DMG `downloadUrl`
  - `curl -I -s http://127.0.0.1:3200/download/latest` → `307` redirect to the GitHub `dotViewer-1.0.0.dmg` asset
- Follow-ups: Deploy the updated `site/` build so production picks up the copy/link/fallback cleanup.

### Inline code coverage sweep
- Outcome: Expanded the homepage and download-page inline code treatment so the remaining visible file-format and tool-name mentions now render as styled code too, including `JSON`, `YAML`, `XML`, `INI`, `shell scripts`, `log files`, `source code`, `VS Code`, `Xcode`, `Typora`, and `Terminal`.
- Files: `site/app/page.tsx`, `site/app/download/page.tsx`, `AGENTS.md`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
  - `cd site && npm run start -- --hostname 127.0.0.1 --port 3200` → pass
  - Playwright browser verification on `http://127.0.0.1:3200/` and `http://127.0.0.1:3200/download` → inline code rendering updated in the visible copy on both pages, no console errors
- Follow-ups: Deploy the updated `site/` build so production reflects the expanded inline code treatment.

### Hero copy tightening
- Outcome: Reduced repetition in the homepage hero by trimming the repeated file-type list from the main support copy, keeping the benefit statement shorter, and rendering the “Common examples” row as actual inline code items instead of one plain joined text string.
- Files: `site/app/page.tsx`, `AGENTS.md`
- Verified:
  - `cd site && npm run build` → pass
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run start -- --hostname 127.0.0.1 --port 3200` → pass
  - Playwright browser verification on `http://127.0.0.1:3200/` → hero copy rendered with the shorter text and code-styled common examples, no console errors
- Follow-ups: Deploy the updated `site/` build so production reflects the tightened hero copy.

## 2026-04-03

### Custom file-type routing for `.cue` and manpages
- Outcome: Fixed shipped Quick Look routing for Victor’s reported `.cue` and numeric manpage extensions `.1`-`.9`, and clarified in the custom-mapping UI that runtime mappings only affect files that already reach dotViewer.
- Files: `dotViewer/project.yml`, `dotViewer/App/Info.plist`, `dotViewer/QuickLookExtension/Info.plist`, `dotViewer/QuickLookThumbnailExtension/Info.plist`, `dotViewer/Shared/DefaultFileTypes.json`, `dotViewer/App/AddCustomExtensionSheet.swift`, `dotViewer/App/FileTypesView.swift`, `dotViewer/App/SettingsView.swift`, `dotViewer/dotViewerTests/FileTypeRegistryTests.swift`, `dotViewer/dotViewerTests/FileTypeResolutionTests.swift`, `scripts/dotviewer-test-uti-coverage.py`, `BACKLOG.md`, `CHANGELOG.md`, `AGENTS.md`
- Verified:
  - `./scripts/dotviewer-refresh.sh --no-open` → pass
  - `python3 scripts/dotviewer-test-uti-coverage.py --quick` → pass (`Coverage: 700/700 (100.0%)`)
  - `xcodebuild -project dotViewer/dotViewer.xcodeproj -scheme dotViewerTests -derivedDataPath dotViewer/build test` → pass (`113 tests, 0 failures`)
  - `./scripts/dotviewer-ql-smoke.sh /tmp/victor.cue` → pass (`HTML built for victor.cue`)
  - `./scripts/dotviewer-ql-smoke.sh /tmp/victor.1` → pass (`HTML built for victor.1`)
  - manual `qlmanage -p /tmp/victor.2` + log capture → pass (`HTML built for victor.2`)
  - `mdls -name kMDItemContentType -name kMDItemContentTypeTree /tmp/victor.cue /tmp/victor.1 /tmp/victor.2 /tmp/victor.9` → pass (all resolve to shipped `com.stianlars1.dotviewer.*` UTIs)
- Follow-ups: Truly novel extensions still need a shipped UTI update because Quick Look routing remains exact-match only.

### Theme auto-follow variants
- Outcome: Added system-following theme variants for GitHub, Xcode, and Solarized, kept Atom One as the default system theme, and made preview + thumbnail appearance detection use the same macOS interface-style signal so light/dark auto behavior is consistent.
- Files: `dotViewer/Shared/ThemePalette.swift`, `dotViewer/Shared/SystemAppearance.swift`, `dotViewer/Shared/PreviewHTMLBuilder.swift`, `dotViewer/QuickLookExtension/PreviewProvider.swift`, `dotViewer/QuickLookThumbnailExtension/ThumbnailProvider.swift`, `dotViewer/App/SettingsView.swift`, `dotViewer/dotViewer.xcodeproj/project.pbxproj`, `dotViewer/dotViewerTests/ThemePaletteTests.swift`, `dotViewer/dotViewerTests/SystemAppearanceTests.swift`, `dotViewer/dotViewerTests/PreviewHTMLBuilderTests.swift`, `BACKLOG.md`, `CHANGELOG.md`, `AGENTS.md`
- Verified:
  - `cd dotViewer && xcodegen generate` → pass
  - `xcodebuild -project dotViewer/dotViewer.xcodeproj -scheme dotViewerTests -derivedDataPath dotViewer/build test` → pass (`121 tests, 0 failures`)
  - `./scripts/dotviewer-refresh.sh --no-open` → pass
- Follow-ups: The next preview-window sizing change will stay separate; the theme work only covers palette selection and auto light/dark resolution.

### Initial preview window size setting
- Outcome: Added a persistent initial Quick Look window size preference with `Auto` and `Fixed` modes. `Fixed` applies one shared width/height pair across all dotViewer previews instead of re-deriving the window size from each file’s content.
- Files: `dotViewer/Shared/SharedSettings.swift`, `dotViewer/Shared/PreviewSizing.swift`, `dotViewer/QuickLookExtension/PreviewProvider.swift`, `dotViewer/App/SettingsView.swift`, `dotViewer/dotViewer.xcodeproj/project.pbxproj`, `dotViewer/dotViewerTests/PreviewSizingTests.swift`, `BACKLOG.md`, `CHANGELOG.md`, `AGENTS.md`
- Verified:
  - `cd dotViewer && xcodegen generate` → pass
  - `xcodebuild -project dotViewer/dotViewer.xcodeproj -scheme dotViewerTests -derivedDataPath dotViewer/build test` → pass (`125 tests, 0 failures`)
  - `./scripts/dotviewer-refresh.sh --no-open` → pass
- Follow-ups: This controls the initial size hint sent to Quick Look. It does not attempt to persist ad-hoc manual window drags from the system Quick Look panel.

### Website analytics stack
- Outcome: Added Vercel Analytics, env-driven Google tag support, and dbHost-backed first-party analytics for the marketing site, then synced the `1.1.0` release metadata and docs around that new tracking stack. Page views, checksum clicks, release-history downloads, and stable `/download/latest` DMG redirects now carry source-tagged analytics data into PostgreSQL while Vercel Analytics remains active in parallel.
- Files: `site/app/layout.tsx`, `site/app/download/page.tsx`, `site/app/download/latest/route.ts`, `site/app/api/analytics/route.ts`, `site/components/site-analytics.tsx`, `site/components/tracked-download-link.tsx`, `site/lib/analytics/client.ts`, `site/lib/analytics/server.ts`, `site/lib/db/client.ts`, `site/lib/db/schema.ts`, `site/drizzle.config.ts`, `site/package.json`, `site/README.md`, `README.md`, `CHANGELOG.md`, `dotViewer/project.yml`, `scripts/release.sh`, `AGENTS.md`
- Verified:
  - `cd site && npm run typecheck` → pass
  - `cd site && npm run build` → pass
  - `DATABASE_URL=postgresql://... npx drizzle-kit push --force` → pass
  - `curl -X POST http://127.0.0.1:3400/api/analytics ...` for `page_view` and `download` payloads → pass
  - `curl -I http://127.0.0.1:3400/download/latest?source=verification_download_latest` → pass (`307`)
  - PostgreSQL verification query via `pg` client → pass (rows persisted in `analytics_page_views` and `analytics_downloads`)
- Follow-ups: Set `NEXT_PUBLIC_GOOGLE_TAG_ID` or `NEXT_PUBLIC_GA_MEASUREMENT_ID` in production to activate the Google layer live. Vercel Analytics and PostgreSQL persistence are already wired.

## 2026-04-04

### Preview window size wording clarification
- Outcome: Re-reviewed Victor’s feedback and kept the existing shared-size implementation, but clarified the host-app settings copy so the choice reads as `Per File` versus `Same for All Files`. This makes the intent explicit: dotViewer can provide one persistent starting size across previews and file types, but it is not trying to capture ad-hoc manual Quick Look panel drags.
- Files: `dotViewer/App/SettingsView.swift`, `README.md`, `CHANGELOG.md`, `dotViewer/dotViewer.xcodeproj/project.pbxproj`, `AGENTS.md`
- Verified:
  - `cd dotViewer && xcodegen generate` → pass
  - `xcodebuild -project dotViewer/dotViewer.xcodeproj -scheme dotViewerTests -derivedDataPath dotViewer/build test` → pass (`125 tests, 0 failures`)
  - `./scripts/dotviewer-refresh.sh --no-open` → pass
- Follow-ups: If you later want true last-manual-size restoration, that needs a different design and likely host-side panel control rather than only the Quick Look extension’s initial `contentSize` hint.
