# Handoff — 2026-09-23

## Status

**v1.5.8 (15) is the latest published release** (2026-09-23): Settings in their own window (⌘,) with a
sidebar and search, Interface text size that finally works (KI-020), and a main window that keeps its
size across updates. Evidence: `docs/releases/1.5.8-verification.md`. `/Applications` runs the public
1.5.8.

**Website stats phase 1 is live** (deployed 2026-09-23 from `main`): cookieless first-party logging,
the daily GitHub/Homebrew snapshot cron, `/updates/<file>`, `/privacy`, and `/stats` behind Basic Auth
(credentials set by the owner; the page answers with a login prompt). The old rows' identifiers were
scrubbed on the owner's request the same day. Details: §10 of
`docs/plans/2026-09-22-usage-stats-telemetry-updates.md`.

**Consent banner is live** (2026-09-23, `main` at `23a96da`): a cookie card with equal Reject/Accept,
a daily visitor code for everyone without cookies, a visitor-ID cookie and Google Analytics
(`G-F0Q1EGB3EM`) only with consent, consent records, retention in the cron, a Cookies section on
`/privacy`, and a Visitors section on `/stats`. `002` is applied to production and
`NEXT_PUBLIC_GA_MEASUREMENT_ID` is set for Preview and Production. Spec, rollout and the local and live
verification: `docs/plans/2026-09-23-consent-banner-design.md`; task plan:
`docs/plans/2026-09-23-consent-banner-plan.md`. **Roll back only with Vercel's Instant Rollback** —
redeploying a commit from before the banner would bake the GA ID into code that loads GA for everyone.

## Next steps

1. **Owner: look at `/stats` → Visitors.** Consent records 1 and 2 (2026-09-23 11:53 and 11:54 UTC) are
   Claude's live test (Accept, then withdraw everything); they count in the 30-day consent shares.
   Delete them if you prefer (`DELETE FROM analytics_consents WHERE id IN (1, 2)`) — ask first. The
   test page views are logged as bots and never count. The first cron run after the deploy is the
   first with retention; its JSON now carries `retention`.
2. **Wait for kiryph on #31** (issue open). 1.5.8 replaces the tab bar with a native sidebar list, which
   may settle it; ask kiryph to try 1.5.8 on the Intel Mac mini (macOS 15.7.7) — needs the owner's OK
   to post.
3. Stats phase 2 (Sparkle 2.10 in 1.6.0) needs the EdDSA key from the owner first (plan §5.3). Feed URLs
   must use `www.dotviewer.app`: the apex answers 308.
4. Optional corpus check for the Gnuplot detector against gnuplot's `demo/*.dem` and PARI/GP's
   `examples/*.gp` (needs a download — ask first).
5. Still present: the 4 merged remote branches of PRs #2, #26, #27 and #30, and the unmerged
   `codex/v1.1.0-victor-feedback`, `v1-legacy` and `claude/research-quicklook-performance-7zcd5`
   (superseded or v1 history — keep or archive). Two stale Quick Look registrations from old Debug
   builds (1.5.4 in DerivedData, 1.5.6 in an old session scratchpad) show under Status → Extension
   Conflicts; "Resolve All" there removes them.
6. Carried over from 2026-08-10: App Store listing still serves 1.4.0 (only the owner can remove it);
   right-click Quick Action for ⌥Space; arrow-key navigation in the panel; Shift+arrow selection in the
   search field; no App-target tests for `SearchBridgeServer` / `SearchKeyInterceptor` /
   `PreviewPanelController`.

## Open questions

- Which region is the dbHost database in (for `/privacy`)?
- Sparkle: create the EdDSA key (the owner keeps it; Claude must never see it).

## Hard-won platform knowledge (do not re-derive)

**TCC binds to the code signature, not the bundle ID or path.** Two differently signed copies of
dotViewer share `com.stianlars1.dotViewer` but are *separate subjects* to TCC, and System Settings
lists them under one name. The visible, ticked "dotViewer" row can belong to the other copy — so the
app reports "needs Accessibility" against a checked box, the prompt reappears, and granting from it
changes nothing. Toggling the row, or removing and re-adding it, can rebind the wrong copy.

The reliable fix is `tccutil reset Accessibility com.stianlars1.dotViewer` followed by one fresh
grant. Both permission cards now say so and offer to copy the command.

Corollary worth knowing: **a normal same-signature upgrade keeps its permissions** — verified by
upgrading 1.5.0 → 1.5.1 → 1.5.2 in place with the grant intact. Only mixing a dev build with a
release build causes the collision. **Never `ditto` a development build over `/Applications` on a
machine that has a working release install.**

**A Quick Look preview has no user gesture, ever.** WebKit refuses `document.execCommand('copy')`
and the async Clipboard API without one, which is why the copy presets use `mouseup`. Anything the
page cannot do without a gesture must be done by the host app instead — that is the shape of the
⌘C fix and the pattern to reuse.

## Release process

`./scripts/publish.sh <version> [--build-number=<CURRENT_PROJECT_VERSION>]` — 5 steps: notarized DMG →
tag → GitHub release → Homebrew cask. The flag is optional since the bash 3.2 empty-array fix (145c967).
There is deliberately **no App Store stage**; it was removed because the host app is unsandboxed and
that stage ran *after* the release was already live under `set -euo pipefail`.

**The website needs no deploy for a version bump.** It reads the GitHub Releases API with
`cache: "no-store"` (`site/lib/github-release.ts`), so version, DMG name, size, checksum and date
update themselves within ~10s. Only feature *copy* needs a site change.

Local verification build without notarizing:
`./scripts/release.sh <version> --skip-notarize --skip-dmg`, then `ditto` the export
to `/Applications` — Developer ID signed, so the TCC grant survives.

## Known behaviour, by design

- **The ⌥Space panel activates the app.** That is what guarantees it receives ⌘F/Esc;
  `.nonactivatingPanel` keeps Finder frontmost but makes keyboard focus unreliable. Side effect:
  ⌥Space does not close an open panel, since the shortcut is gated on Finder being frontmost.
  Esc, ⌘W and clicking away all close it.
- **⌘C in Quick Look is only intercepted after a ⌘A there.** Otherwise copying a file in Finder
  would silently break whenever a preview was open.
- **⌘F is gated on the "Show Find in Preview" setting**, because entering search mode with no search
  bar on screen would swallow keystrokes invisibly. ⌘A and ⌘C are not gated on it.
- Relative markdown images do not load — WKWebView blocks `file://` subresources. Same as Quick Look
  has always been, so not a regression.

## Key files

- `dotViewer/Shared/PreviewContentBuilder.swift` — the one rendering pipeline
- `dotViewer/Shared/PreviewHTMLBuilder.swift` — HTML/CSS/JS, `window.__dvSearch`, `window.__dvSelection`
- `dotViewer/App/SearchKeyInterceptor.swift` — CGEventTap: ⌘F, ⌥Space, ⌘A, ⌘C, caret editing
- `dotViewer/App/SearchBridgeServer.swift` — loopback SSE + `/clipboard` write endpoint
- `dotViewer/App/PreviewPanelController.swift` — NSPanel + WKWebView
- `dotViewer/App/PermissionTroubleshooting.swift` — the TCC explanation and reset command
- `docs/research/quicklook-search-keyboard-2026-08.md` — every measurement, including dead ends
- `KNOWN_ISSUES.md` — KI-009 now records the real ⌘C fix, not just the workarounds; KI-019 is #31
- `dotViewer/App/Settings/SettingsWindow.swift` + `dotViewer/dotViewerTests/SettingsSidebarTests.swift` —
  #31: the tab bar is replaced by a native sidebar list since 1.5.8 (tests send real mouse events to an
  ordered-in offscreen window; SwiftUI ignores clicks on a never-shown window, and the mouse-up must be
  queued before the down because `NSTableView` tracks the click itself)
- `site/lib/consent/`, `site/components/consent-banner.tsx`, `site/app/api/consent/route.ts` — the
  website's consent banner; `site/lib/stats/visitors.ts` — the `/stats` Visitors figures
- `dotViewer/Shared/FileTypeRegistry.swift` `isExtensionEnabled` — #24 custom-mapping precedence
- `dotViewer/Shared/GnuplotSourceDetector.swift` + `dotViewerTests/GnuplotSourceDetectorTests.swift` — #29

## Security notes (do not regress)

- The loopback server binds `127.0.0.1` only and rejects non-loopback connections.
- Every request needs the per-session nonce; loopback is not an access control boundary.
  Verified: bad nonce → 403, wrong method → 405, empty body → 400, unknown path → 404.
- The `/clipboard` body is bounded at 16 MB; an unbounded socket read is a memory exhaustion.
- Keys are forwarded only after an explicit ⌘F, and search mode ends when another app activates.
- The panel refuses to follow any link that is not http/https — a previewed file is untrusted input.
- Automation access is used only to read the selected file's path; nothing in Finder is modified.
- Nothing is recorded or persisted.
