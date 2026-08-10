# Handoff — 2026-08-10

## Status

**v1.5.2 is published and is the current release.** `main` is clean and pushed, tags `v1.5.0`,
`v1.5.1` and `v1.5.2` all point at commits on `main`. Nothing is in flight.

Three releases went out across 2026-08-07 → 2026-08-10. All verified live: GitHub release,
notarized DMG with the DropDMG installer window, Homebrew cask checksum, and dotviewer.app.

## What shipped

### v1.5.0 — the ⌥Space preview panel

dotViewer's own preview window, for the files macOS will never route to a Quick Look extension.
`.ts` resolves to `public.mpeg-2-transport-stream` (system-declared, conforms to `public.movie`), so
no third-party extension can ever claim it. `Space` is never intercepted — the panel is additive.

The rendering pipeline was **extracted rather than duplicated**:

```
Shared/PreviewContentBuilder.build(url:systemIsDark:enableSearchBridge:forceSearchUI:)
   → .rendered(PreviewRender) | .systemFallback
        ↑                              ↑
  PreviewProvider (Quick Look)   PreviewPanelController (⌥Space)
```

### v1.5.1 — ⌘A / ⌘C, and an editable search field

- **⌘A / ⌘C in Quick Look.** Both previously went to Finder — ⌘A selected every file in the window,
  ⌘C copied the file itself. Selection is scoped to the content view, not the document.
- **The clipboard write moved host-side.** See KI-009; this is the interesting one.
- **The search field became editable.** Arrow keys were being *typed into the query*: AppKit maps
  arrows, Home/End and the function row into the Unicode Private Use Area (U+F700–U+F8FF), which
  passed a control-character filter and appended invisible padding. Clearing the text also closed
  the bar. The caret is now a real element with an insertion point the arrows drive.
- **The TCC signature trap** explained in-app, with the remedy that actually works.

### v1.5.2 — copy confirmations read as successes

`--success` token for both appearances, check mark, motion left alone (it was already right).
Error and hint toasts stay neutral deliberately. Also fixed the "Copied" button label sticking
forever.

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

## Next steps

1. **App Store listing is still live at $4.99 serving 1.4.0**, which can never update — 1.5.0+ needs
   the unsandboxed build. The site no longer links it (`appStoreUrl` is unconditionally `null`), but
   removing the listing needs App Store Connect. **Only you can do this.**
2. **`v2.5-claude-work` worktree** (branch `claude-work`) has **3917 tracked files under
   `dotViewer/build`**, with staged additions. Committed build output is almost certainly not
   intended. Left untouched deliberately — deleting it would destroy tracked content.
3. **Right-click Quick Action** for the ⌥Space panel — the other half of the original design.
4. **Arrow-key navigation between selected files** in the panel. Deferred at v1 (single file only).
5. **Shift+arrow selection in the search field.** The caret model added in 1.5.1 supports a single
   insertion point; extending it to a selection range is the natural follow-up.
6. **No tests** for `SearchBridgeServer`, `SearchKeyInterceptor` or `PreviewPanelController` — they
   live in the App target, which has no test host. `Shared` is covered (180 tests).

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
- `KNOWN_ISSUES.md` — KI-009 now records the real ⌘C fix, not just the workarounds

## Security notes (do not regress)

- The loopback server binds `127.0.0.1` only and rejects non-loopback connections.
- Every request needs the per-session nonce; loopback is not an access control boundary.
  Verified: bad nonce → 403, wrong method → 405, empty body → 400, unknown path → 404.
- The `/clipboard` body is bounded at 16 MB; an unbounded socket read is a memory exhaustion.
- Keys are forwarded only after an explicit ⌘F, and search mode ends when another app activates.
- The panel refuses to follow any link that is not http/https — a previewed file is untrusted input.
- Automation access is used only to read the selected file's path; nothing in Finder is modified.
- Nothing is recorded or persisted.
