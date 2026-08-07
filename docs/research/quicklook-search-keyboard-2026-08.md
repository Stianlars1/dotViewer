# Quick Look in-preview search (Cmd+F) — 2026-08 research

**Question**: Has anything changed (macOS 26, new APIs, WebKit, forums) that lets a Quick Look
preview extension accept `Cmd+F` and typed keyboard input?

**Short answer**: No new API. Apple still ships nothing for this. The only shipping product that
solves it (Peek) does so with an **Accessibility-privileged helper process** that intercepts the
shortcut and relays it to the extension. That path is available to us, but it is not free.

---

## 1. What the platform says (current, verified 2026-08-07)

| Claim | Source | Status |
|---|---|---|
| `QLPreviewingController`'s view "supports no interaction"; no API to add interactive UI | Apple Frameworks Engineer, [forums/thread/767288](https://developer.apple.com/forums/thread/767288) (Nov 2024) | Still the official answer |
| "Quick Look extensions are **not** able to respond to any keyboard shortcuts" | [Peek product docs](https://bigzlabs.com/peek) | Confirms our KI-009 finding |
| WKWebView inside a QL appex died with `does not have permission to communicate with network resources` | [WebKit bug 219632](https://bugs.webkit.org/show_bug.cgi?format=multiple&id=219632) | **Fixed** in r271895 (2021-01-26) |
| QL extensions do **not** honour `com.apple.security.network.client` | WebKit team, same bug | Still true — the working workaround is `com.apple.security.temporary-exception.mach-lookup.global-name = com.apple.nsurlsessiond` |

macOS 26 Tahoe added nothing to Quick Look extension APIs relevant to keyboard or find. No new
`QLPreviewReply` capability, no find-bar hook, no `QLSupportsInteraction`-style key.

## 2. How Peek actually does it

Peek is the only Quick Look extension on the market with working `Cmd+F`, `Cmd+G`, `Cmd+L`,
`Cmd+A`, `Cmd+C` inside the preview. Its own documentation states the mechanism:

> Quick Look extensions are not able to respond to any keyboard shortcuts, so to overcome this,
> Peek must intercept supported keyboard shortcuts and deliver them to the Quick Look extension.
> Granting Accessibility Access permission is necessary to enable this functionality.

Observable details:

- A separate **"Peek Helper"** process holds the Accessibility grant.
- The helper **terminates itself after a short delay** (their stated anti-keylogger posture).
- Peek is sandboxed and ships on the Mac App Store, so an App Store build **can** reach this —
  contrary to the conclusion we drew in KI-009 approach 2.
- Peek explicitly cannot support `.txt`, `.html`, `.pdf`, Office, iWork — UTI ownership, same
  wall as our KI-005/KI-010.

This is the same "independently-installed helper" approach already listed under KI-009
*Approaches NOT Yet Tried*. The new information is confirmation that it works from a sandboxed,
App-Store-distributed parent.

## 3. Competitor architecture check (local, 2026-08-07)

`QLMarkdown.app` (sbarex), installed on this machine, for reference:

```
NSExtensionPointIdentifier : com.apple.quicklook.preview
NSExtensionPrincipalClass  : Markdown_QL_Extension.PreviewViewController
QLIsDataBasedPreview       : true          # same as dotViewer
QLSupportsSearchableItems  : false
```

Entitlements of interest:

```
com.apple.security.network.client                                = true
com.apple.security.temporary-exception.mach-lookup.global-name   = [ com.apple.nsurlsessiond, ... ]
com.apple.security.cs.disable-library-validation                 = true
```

It links `WebKit.framework` and carries the WebKit-219632 mach-lookup workaround. It has **no**
search feature. So: no competitor solves this without Accessibility.

## 4a. PROBE RESULT — measured 2026-08-07, macOS 26.4, Safari/605.1.15

Instrumented preview (`PreviewHTMLBuilder.buildKeyboardProbe()`, enabled for filenames starting
`dvprobe`), driven with **real hardware keypresses** in Finder's spacebar preview:

```
focus: document.hasFocus() = YES
active: #dvprobe-input
autofocus took: YES

11 keydown Cmd+Shift+Meta  code=MetaLeft   trusted=true  on=#dvprobe-input
10 keydown Shift+Shift     code=ShiftLeft  trusted=true  on=#dvprobe-input
 9 focus  on=#dvprobe-input
 8 blur   on=#dvprobe-input
 3 probe ready
 2 focusin on=#dvprobe-input
 1 focus  on=#dvprobe-input
```

| Question | Answer |
|---|---|
| Does the web view get focus? | **Yes.** `document.hasFocus()` = YES |
| Can an `<input>` hold focus? | **Yes.** Programmatic `.focus()` sticks; `activeElement` = the input |
| Do modifier keydowns reach the DOM? | **Yes.** `Shift`, `Meta`, `trusted=true` |
| Do character keys reach the DOM as `keydown`? | **No** |
| Do character keys reach the DOM at all? | **Yes — via the text-input path.** See correction below |
| Does `Cmd+V` / the `paste` event fire? | **No** |

### Correction (screen recording, Finder Space preview, 2026-08-07)

A frame-by-frame capture shows the first reading was too pessimistic. Typing `a` produces:

```
20 input        data="a"  on=#dvprobe-input
19 beforeinput  data="a"  on=#dvprobe-input
18 textInput    data="a"  on=#dvprobe-input
```

and the character genuinely appears in the focused `<input>`. So WebKit's text insertion
(`insertText:` → `beforeinput`/`textInput`/`input`) **does** reach the page. Only `keydown` for
character keys is missing — which is why JS cannot `preventDefault()` them.

Finder's type-select fires *as well*, swapping the previewed file, which is what makes this
unusable in practice rather than merely awkward.

**Consequence for the design**: the event tap must **swallow** character keys (return `nil`), not
pass them through. Passing them would deliver every keystroke twice — once natively into the page,
once over SSE. Swallowing suppresses type-select and de-duplicates at the same time.

### Localhost channel confirmed in Finder (not just qlmanage)

The same capture shows `fetch OK`, `xhr OK 200` and a running `sse MSG — tick 0…4` inside Finder's
spacebar preview, origin `x-apple-ql-id2://1bbc3115-9cea-4c86-8be0-5046a1713d34`.

**Interpretation.** The event pipe into WebKit is alive and the web content holds first responder.
What breaks is narrower than KI-009 claimed: Finder's **type-select (typeahead)** consumes character
keys at the panel level, above the remote view, and never forwards them. Command chords go to
Finder's main menu. Only modifier-only keydowns leak through.

This kills Tier 1a (no typing without upstream interception) but **shrinks Tier 2**: the search
`<input>` is already focusable and ready to receive text. A helper does not need to own a search UI —
it needs to stop Finder eating the keys and get them into the page.

## 4b. Synthetic key injection — measured 2026-08-07, NEGATIVE

`TestFiles/qlkeypost auto` posts a synthetic `a` with `CGEventPostToPid` at each Quick Look host.
`AXIsProcessTrusted` = true, so posting was permitted.

| Target | Result |
|---|---|
| `QuickLookUIService` pids 19906 / 31076 / 50150 | **Nothing.** Probe counter frozen at 7 events, three runs |
| `Finder` pid | **Delivered** — type-select fired and swapped the previewed file |
| `quicklookd` | Process does not exist on macOS 26.4 |

So the Quick Look host receives posted events but does not forward them into the remote web view.
Targeted posting works in general (Finder proves it); the remote view is simply not in the path.

**Consequence**: a helper cannot inject keystrokes into a data-based preview. If we stay data-based,
the helper must own the search field in its own window and move the query to the page over a side
channel (clipboard + synthetic click on the search button).

## 4c. Untested branch — view-based preview responder chain

Everything above measures the **data-based** path, where the extension owns no view. View-based
(`QLIsDataBasedPreview: false` + an `NSViewController` conforming to `QLPreviewingController`) has a
responder chain we have never instrumented, and KI-009 approach 3 recorded that `Cmd+A` / `Cmd+C`
*did* reach an `NSTextView` there through action messages — so the extension's view is in the chain.

If a view we own can become first responder and consume `keyDown:`, Finder's type-select never runs,
because type-select only fires when nothing in the responder chain claims the key. That would give
native typing with **no Accessibility permission at all**, and would work in the App Store build too.

Two independent questions, worth testing in that order:

1. **Does `keyDown:` reach an NSView inside a QL preview extension?** Test with a bare view-based
   extension, no WebKit involved — isolates the responder question.
2. **Does WKWebView load inside the appex?** Needed to keep the HTML pipeline. KI-009 approach 4 said
   no, but that conclusion predates checking [WebKit 219632](https://bugs.webkit.org/show_bug.cgi?format=multiple&id=219632)
   (fixed r271895) and was missing the `com.apple.nsurlsessiond` mach-lookup exception that QLMarkdown
   ships. Probably wrong.

If (1) passes we get real `Cmd+F`-class UX for free. If (1) fails, fall back to the Accessibility
helper with its own panel.

## 4d. View-based responder — measured 2026-08-07, NEGATIVE

`ProbePreviewViewController` (view-based, `QLIsDataBasedPreview: false`), real hardware keys:

```
2 events   firstResponder=NSServiceViewControllerWindow   keyWindow=true
2  viewDidAppear  window=NSServiceViewControllerWindow
1  preparePreviewOfFile  dvprobe.md
```

`makeFirstResponder(probeView)` fails — retried 8 times on a timer and again on click, never accepted.
No `keyDown:`, no `flagsChanged:`, no `performKeyEquivalent:`. Typing `a` still triggered Finder's
type-select and swapped the previewed file.

`NSServiceViewControllerWindow` is the remote-view-service window: the extension's view lives across
a process boundary and the host keeps first responder unconditionally. **View-based reaches the
keyboard less well than data-based**, where at least WebKit's internal focus landed on an `<input>`.

This also corrects KI-009 approach 3: its `Cmd+A` / `Cmd+C` success was never first responder. Those
arrive as *action messages* from Finder's Edit menu targeting `nil`, which the responder chain
forwards across the boundary. Action messages travel; raw key events do not.

**Every in-extension path is now measured and closed.**

## 4e. Localhost channel — measured 2026-08-07, POSITIVE ✅

The preview page has a live, long-running JS runtime (`setInterval` keeps firing). It can also open
network connections. Against `scratchpad/probe-server.py`:

```
HIT /ping?via=fetch   Origin: x-apple-ql-id2://e2972128-a2fa-41ee-b71e-1e40d7c68e57
HIT /ping?via=xhr     Origin: x-apple-ql-id2://…
HIT /events           Origin: x-apple-ql-id2://…
HIT /report?ch=fetch&detail=pong%2013%3A47%3A55
HIT /report?ch=xhr&detail=200%3Apong%2013%3A47%3A55
HIT /report?ch=sse&detail=tick%200 … tick%206
```

| Channel | Works | Notes |
|---|---|---|
| `fetch` | ✅ | Response body readable — page echoed it back |
| `XMLHttpRequest` | ✅ | Status 200 + body readable |
| `EventSource` (SSE) | ✅ | **Held open, one push per second, continuously delivered** |

The page's origin is `x-apple-ql-id2://<uuid>` — a fresh UUID per preview. `Access-Control-Allow-Origin: *`
is accepted. No App Transport Security block for `http://127.0.0.1`.

**This is the transfer channel.** A helper does not need clipboard hacks, synthetic clicks, or the
WebKit "Lim inn" confirmation Peek's users have to click. It can push a query straight into the page.

### Resulting design

1. **Helper** — unsandboxed, Accessibility-granted, background:
   - `CGEventTap` intercepts `Cmd+F` while a dotViewer Quick Look preview is frontmost, and
     **swallows** it so Finder's own Find window never opens.
   - Enters search mode: swallows subsequent character keys (this is what stops type-select from
     swapping the file) and streams them to the page over SSE.
   - `Esc`, `Enter`, `Shift+Enter`, `Cmd+G`, `Cmd+V` handled the same way — for paste it reads
     `NSPasteboard` directly, so no clipboard confirmation UI.
2. **Preview page** — opens an `EventSource` to the helper and drives the existing search machinery
   (`buildSearchScript`) live as characters arrive.

Net UX: `Cmd+F` → type → live incremental highlight. What was originally asked for.

### Security constraints — non-negotiable for this design

A local socket that streams keystrokes is a keylogger-shaped component and must be scoped hard:

- Bind `127.0.0.1` only, never `0.0.0.0`.
- **Random port per session**, shared to the extension via the App Group — not a fixed guessable port.
- **Per-preview nonce** generated at HTML build time, required on every request; the helper rejects
  connections that don't present it. Otherwise any local process could subscribe to the stream.
- Stream keys **only while search mode is active** (after an explicit `Cmd+F`), never at rest.
- Helper idles out and exits, as Peek's does.
- Ship it off by default with a clear explanation of why Accessibility is requested.

> Safety note: never post via `CGEvent.post(tap: .cgSessionEventTap)` unless the target window is
> known to be frontmost — the event is indistinguishable from real typing and lands in whatever app
> has focus. Learned the hard way; the `auto` mode no longer does this.

## 4. What is actually unknown (and cheap to settle)

KI-009 established that `Cmd+C` and the `copy` DOM event never fire in our data-based preview.
It did **not** establish the following, and all of it changes the design:

1. Do **unmodified** key events (`a`, `/`, `Escape`, arrows) reach the WKWebView DOM at all?
   Our existing `Escape` handler in `PreviewHTMLBuilder.swift:2138` has never been verified to fire.
2. Can a real `<input>` in the preview take focus and receive typed text? The current search UI
   uses a `<span id="search-query">` precisely because prior work assumed it cannot.
3. Does the `paste` DOM event fire, i.e. would `Cmd+V` work if focus were obtainable?
4. Does behaviour differ between Finder's spacebar panel, Finder column-view preview pane, and
   `qlmanage -p`?

These are all answerable with one instrumented debug build — an on-page event log rendered into
the preview itself, since we cannot attach a debugger or read a JS console inside `quicklookd`.

## 5. Options, ranked by cost

### Tier 0 — Probe (prerequisite, cheap)

Ship a debug-only `?dvdebug` HTML block that renders every `keydown`/`keyup`/`keypress`/`focus`/
`blur`/`paste`/`beforeinput` event into a visible list in the preview. Preview a file, press keys,
screenshot. Settles §4 definitively on macOS 26.4.

### Tier 1a — Native typing, if any key events arrive (best case, no permissions)

If plain keys reach the DOM:

- Replace `<span id="search-query">` with a real `<input>`.
- Bind `/` (and `f`) as the open-search key — `Cmd+F` itself is claimed by Finder's own File → Find
  menu item and will never reach us without a helper.
- Type-to-search with live incremental highlight, `Enter`/`Shift+Enter` for next/previous, `Esc` closes.

Result: `/` → type → done. Close to the requested UX, zero permissions, zero new processes.

### Tier 1b — Friction removal, if no key events arrive (guaranteed fallback)

Independent of Tier 0, all of these are worth doing:

- Search icon click → read clipboard immediately (drops "click Paste" from the flow).
- Double-click a word → highlight every occurrence and populate the search bar (Xcode/VS Code behaviour).
- Selecting text already triggers auto-copy; also offer auto-search-on-selection.

Cuts today's 5-step flow to 1–2 clicks. Does not deliver typing.

### Tier 2 — Peek parity: real `Cmd+F` (expensive, permission-gated)

Unsandboxed helper app + Accessibility grant + `CGEventTap`:

1. Helper detects the Quick Look window is frontmost (`CGWindowListCopyWindowInfo`).
2. Intercepts `Cmd+F`, swallows it so Finder does not open a search window.
3. Relays into the preview. Relay mechanism depends on the Tier 0 result:
   - *If plain keys reach the DOM*: helper only needs to synthesize the "open search" trigger
     (a click on a known hotspot, or a plain keystroke). Typing then flows natively. **Small.**
   - *If no keys reach the DOM*: the helper must own the search field in its own `NSPanel` and
     drive the page over a side channel, or we move to a view-based preview and inject via
     `evaluateJavaScript` over XPC. **Large**, and view-based means re-testing the WKWebView-in-appex
     path (WebKit 219632 is fixed, so KI-009 approach 4's conclusion is probably wrong — it was
     missing the `com.apple.nsurlsessiond` mach-lookup exception QLMarkdown ships).

Distribution constraint: the DMG/Developer ID build could simply unsandbox the **host app** and skip
the helper entirely. The Mac App Store build cannot, and needs the Peek-style separately-installed
helper. That is a product decision, not a technical one.

## 6. Recommendation

Do Tier 0 first — it is a few hours and it decides whether Tier 1a (cheap, no permissions, ~90% of
the requested UX) is available. Do Tier 1b regardless. Only commit to Tier 2 if the user wants
literal `Cmd+F` and accepts an Accessibility prompt.

## Related

- `KNOWN_ISSUES.md` → KI-009 (Cmd+C), KI-005/KI-010 (UTI routing)
- `dotViewer/Shared/PreviewHTMLBuilder.swift` — search UI at ~L170, search JS at ~L1950–2150

## Sources

- [Apple Developer Forums — add buttons above QuickLook preview in QLPreviewingController](https://developer.apple.com/forums/thread/767288)
- [WebKit Bug 219632 — WKWebView in QuickLook appex](https://bugs.webkit.org/show_bug.cgi?format=multiple&id=219632)
- [sbarex/QLTest — Quick Look extension bug catalogue](https://github.com/sbarex/QLTest)
- [Peek — Big Z Labs](https://bigzlabs.com/peek)
- [Apple Developer Forums — WKWebView requires com.apple.security.network.client for local content](https://developer.apple.com/forums/thread/116359)
