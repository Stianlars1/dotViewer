# Handoff — 2026-09-22

## Status

**v1.5.5 is the latest published release (2026-09-14). 1.5.6 is merged and pushed to `main`
(`05718f7`) but NOT published** — publishing needs an explicit go-ahead (`./scripts/publish.sh 1.5.6`).

1.5.6 contents (see CHANGELOG):

- **#31** Settings sub-tabs ignored mouse clicks on a macMini8,1 / macOS 15.7.7. `SettingsTabBar` now uses
  `ViewThatFits`, so the horizontal `ScrollView` is only an overflow fallback; tabs get a full-rect hit
  shape plus a parallel `TapGesture`. **Root cause unconfirmed** — does not reproduce on macOS 26.
- **#24** `isExtensionEnabled` checked a disabled built-in type before custom mappings, so disabling
  GDScript also killed a `.gd` → GAP mapping. Custom mappings (extension, or filename for its own file
  only) now win. Previews, ⌥Space and thumbnails pass the filename.
- **#29** `GnuplotSourceDetector` keys on syntax PARI/GP cannot express (commands at statement start,
  all `set` options + abbreviations, braced blocks, `ARGn`/`MOUSE_X`, `**`), with comments stripped.
  kiryph's 11 unrecognised scripts: 1.5.5 detected 0/11, 1.5.6 detects 11/11.

Verification: 242/242 unit tests; full app scheme builds; all bundles report 1.5.6 (13). The dev build was
deliberately NOT installed or launched (see TCC notes below). An independent review found one real bug
(filename mappings compared against the key) — fixed in `c0ab686` with a regression test.

## What happened to the "left-behind" work

- `fix/issue-31-intel-mac-settings-tabs` (`68b016b`) was the only unreleased code. It had **never been
  built**: the session that made it crashed mid-commit, leaving 0-byte `.git/index.lock`, `.git/HEAD.lock`
  (and an old `objects/maintenance.lock`) plus an index that made `git status` show phantom staged
  reversals. Locks removed, index resynced, tests rewritten, then merged.
- `codex/v1.1.0-victor-feedback`: its 2 unmerged commits (Vercel/GA analytics) are superseded by `main`'s
  `site/components/site-analytics.tsx`. Nothing to merge.
- `v1-legacy`, `claude/research-quicklook-performance-7zcd5`: the v1 app, **no common ancestor** with
  `main`. Archive only — never merge.
- Stale `/private/tmp` worktree entries pruned.

## Next steps

1. **Publish 1.5.6** after approval: `./scripts/publish.sh 1.5.6`, then verify GitHub release assets,
   Homebrew cask and dotviewer.app/download. If it ships on another day, fix the date in the CHANGELOG
   heading first.
2. **Issue replies after publishing**: announce on #24 and #29; post the drafted #31 reply (not yet posted —
   #31 wasn't in the list the user asked to answer) and ask kiryph to confirm on the Mac mini. Keep #31
   open until confirmed.
3. **Optional corpus check** for the Gnuplot detector against gnuplot's `demo/*.dem` and PARI/GP's
   `examples/*.gp` (needs a download — ask first).
4. **Optional #31 check without the reporter**: a macOS 15 VM (e.g. `tart`) can test the OS half of the
   Intel-vs-macOS-15 confound; the Intel half cannot be emulated.
5. **Housekeeping (ask first)**: `v2.5-claude-work` holds only 3,917 staged build artifacts + `.DS_Store`;
   `v2.5-pr26` and `v2.5-status-fix` are clean detached worktrees of merged PRs; 8 local branches are fully
   merged into `main`.
6. Carried over from 2026-08-10: App Store listing still serves 1.4.0 (only the owner can remove it);
   right-click Quick Action for ⌥Space; arrow-key navigation in the panel; Shift+arrow selection in the
   search field; no App-target tests for `SearchBridgeServer` / `SearchKeyInterceptor` /
   `PreviewPanelController`.

## Open questions

- Publish 1.5.6 now, or hold for more changes?
- Post the #31 reply now, or together with the 1.5.6 announcement?

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

`./scripts/publish.sh <version>` — 5 steps: notarized DMG → tag → GitHub release → Homebrew cask.
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
- `dotViewer/App/SettingsTabPage.swift` + `dotViewerTests/SettingsTabBarTests.swift` — #31 (tests send
  real mouse events to an ordered-in offscreen window; SwiftUI ignores clicks on a never-shown window)
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
