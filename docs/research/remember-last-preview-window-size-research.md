# Remember Last Preview Window Size Research (2026-04-04)

## Feature
Add a preference that remembers the last Quick Look window size the user manually resized in Finder and reuses that same size for the next dotViewer preview.

Target flow:
1. User opens a file in Finder Quick Look.
2. User manually resizes the native Quick Look window.
3. Resize ends.
4. dotViewer remembers that size.
5. User closes the preview.
6. The next file opens with the same width and height.

## Context Read
- `/Users/stian/Developer/macOS Apps/v2.5/CLAUDE.md`
- `/Users/stian/Developer/macOS Apps/v2.5/AGENTS.md`
- `/Users/stian/Developer/macOS Apps/v2.5/BACKLOG.md`
- `/Users/stian/Developer/macOS Apps/v2.5/dotViewer/QuickLookExtension/PreviewProvider.swift`
- `/Users/stian/Developer/macOS Apps/v2.5/dotViewer/Shared/PreviewSizing.swift`
- `/Users/stian/Developer/macOS Apps/v2.5/dotViewer/Shared/SharedSettings.swift`
- `/Users/stian/Developer/macOS Apps/v2.5/dotViewer/App/SettingsView.swift`
- `/Users/stian/Developer/macOS Apps/v2.5/docs/research/quicklook/01-Architecture-Patterns.md`

## Current State
- dotViewer is a data-based Quick Look preview extension.
- The extension principal class is `PreviewProvider`, a `QLPreviewProvider` subclass.
- `QLIsDataBasedPreview` is `true` in `project.yml`.
- The current setting already supports one shared starting size across all files, but only from the static width/height values saved in settings.
- Manual window drags are not persisted today.

Relevant code:
- `project.yml` declares `QLIsDataBasedPreview: true`
- `PreviewProvider.swift` sends `SharedSettings.previewWindowFixedWidth/Height` into `QLPreviewReply`
- `PreviewSizing.swift` returns either a fixed shared size or a content-derived size
- `SettingsView.swift` exposes `Per File` vs `Same for All Files`

## Official Platform Constraints

### 1. Data-based preview extensions only provide a size hint
Apple documents `QLPreviewReply(contentSize:)` as a size hint, not as ownership of the live panel frame.

Evidence:
- Apple docs URL: `https://developer.apple.com/documentation/quicklookui/qlpreviewreply`
- SDK header: `/Applications/Xcode.app/.../QLPreviewReply.h`
- Header text: `contentSize` is “A hint for the size you would like to display your content at.” Quick Look may use a default size.

Implication:
- The current architecture can suggest an initial size.
- It cannot directly read back the actual final size after the user drags the panel larger or smaller.

### 2. `QLPreviewPanel.displayState` belongs to apps that control the panel
Apple documents `QLPreviewPanel.displayState` and `QLPreviewItem.previewItemDisplayState` for apps that own and control a Quick Look panel.

Evidence:
- Apple docs URLs:
  - `https://developer.apple.com/documentation/quicklookui/qlpreviewpanel`
  - `https://developer.apple.com/documentation/quicklookui/qlpreviewitem`
- SDK headers:
  - `/Applications/Xcode.app/.../QLPreviewPanel.h`
  - `/Applications/Xcode.app/.../QLPreviewItem.h`
- Header text says apps can save and restore display state when switching previews.

Implication:
- This is not an API exposed to a Finder-hosted data-based preview extension.
- dotViewer cannot use `QLPreviewPanel.displayState` in its current extension path.

### 3. dotViewer currently uses `QLPreviewProvider`, not a view controller
Apple states that data-based preview extensions should subclass `QLPreviewProvider`.

Evidence:
- Apple docs URL: `https://developer.apple.com/documentation/quicklookui/qlpreviewprovider`
- SDK header: `/Applications/Xcode.app/.../QLPreviewProvider.h`

Implication:
- The current extension model does not own an AppKit view hierarchy where the window frame can be observed directly.

### 4. A view-based controller could theoretically observe host window resize events
In AppKit, `NSViewController` has `preferredContentSize`, and `NSWindow` posts `NSWindowDidResizeNotification` and `NSWindowDidEndLiveResizeNotification`.

Evidence:
- Apple docs URLs:
  - `https://developer.apple.com/documentation/appkit/nsviewcontroller`
  - `https://developer.apple.com/documentation/appkit/nswindow`
- SDK headers:
  - `/Applications/Xcode.app/.../NSViewController.h`
  - `/Applications/Xcode.app/.../NSWindow.h`

Important caveat:
- Apple does not explicitly document “remember the Finder Quick Look window size from inside a Quick Look preview extension.”
- The feasibility of observing `view.window` inside a Finder-hosted view-based Quick Look controller is therefore an inference from AppKit hosting behavior, not a documented Quick Look feature.

## Ranked Approaches

### Approach A: Keep the current data-based preview and try to remember manual drags anyway
- How it works: Keep `QLPreviewProvider` + `QLPreviewReply`, attempt to infer current size from HTML/JS or existing APIs.
- Requirements: None beyond current architecture.
- Risks:
  - No documented API gives the extension the live resized panel frame.
  - HTML/JS inside the preview cannot query the native Quick Look panel size in a supported way.
  - Any attempt here would be guesswork or a hack with poor durability.
- Complexity: Low/Medium
- Verdict: Avoid

### Approach B: Add another static mode such as “Use last saved custom size”
- How it works: Still use fixed width/height, but maybe populate those values from a previously chosen app setting.
- Requirements: Minor settings/UI changes only.
- Risks:
  - Does not satisfy the requested behavior, because it still does not capture the size from a manual Finder drag.
- Complexity: Low
- Verdict: Possible, but not the requested feature

### Approach C: Migrate the preview extension from data-based to view-based and automatically save the window size after live resize
- How it works:
  - Replace the data-based preview entry point with a view-based `NSViewController` conforming to `QLPreviewingController`.
  - Render the preview inside that controller, most likely with `WKWebView` loading the same generated HTML.
  - When the controller is in a window, observe `NSWindowDidEndLiveResizeNotification`.
  - On resize end, persist the current window/content size to `SharedSettings`.
  - On the next preview, if the new preference is enabled and a saved size exists, set `preferredContentSize` before presentation.
- Requirements:
  - Rework `QuickLookExtension` from data-based to view-based.
  - Add a new preference, for example `rememberLastPreviewWindowSize`.
  - Add persisted `lastPreviewWindowWidth` / `lastPreviewWindowHeight`.
  - Reuse or port the current HTML-based preview into a view controller.
  - Validate that the host respects `preferredContentSize` in Finder Quick Look.
- Risks:
  - This is a substantial architectural change.
  - Apple does not explicitly guarantee this persistence pattern for Quick Look extensions.
  - Finder may ignore or partially honor `preferredContentSize`.
  - Regressions are possible in selection, search, copy behavior, markdown toggle, TOC, performance, and cache behavior.
  - `WKWebView` behavior inside Quick Look extensions must be revalidated end-to-end.
- Complexity: High
- Verdict: Recommended only as a spike/prototype, not as an immediate full implementation

### Approach D: Add a “Save current size” header button inside the preview
- How it works:
  - User clicks a button after resizing.
  - dotViewer saves the current window size as the default shared size.
- Requirements:
  - Same view-based migration as Approach C if the button is expected to read the actual live panel size.
- Risks:
  - In the current data-based architecture the button cannot reliably know the native panel frame.
  - Even after migrating, this is extra UI friction for a flow that should be automatic if possible.
- Complexity: High
- Verdict: Possible only after Approach C. Not recommended as the primary design for the requested flow.

### Approach E: Build a separate app-owned Quick Look panel flow
- How it works: dotViewer hosts its own `QLPreviewPanel` or preview window and persists state there.
- Requirements: Replace Finder’s default Quick Look experience with an app-owned preview flow.
- Risks:
  - Fails the requested Finder spacebar workflow.
  - Adds major product complexity.
- Complexity: High
- Verdict: Avoid

## Recommendation
Do not attempt this inside the current data-based extension.

The only plausible path to the requested behavior is:
1. Prototype a view-based Quick Look preview controller.
2. Verify that the controller can observe the host `NSWindow` resize lifecycle.
3. Verify that saving a size on `NSWindowDidEndLiveResizeNotification` and restoring it through `preferredContentSize` actually works in Finder Quick Look.
4. Only then decide whether to migrate the production preview architecture.

This is a spike-worthy feature, not a safe incremental tweak.

## Recommended Plan

### Phase 0: Feasibility spike
Goal: prove whether Finder-hosted Quick Look can support the flow at all.

Tasks:
1. Create a temporary view-based preview controller in `QuickLookExtension`.
2. Render a simple placeholder preview in an `NSViewController`.
3. Detect whether `view.window` becomes available.
4. Observe:
   - `NSWindowDidResizeNotification`
   - `NSWindowDidEndLiveResizeNotification`
5. Log the observed size on resize end.
6. On next preview, set `preferredContentSize` to the last logged size.
7. Verify whether Finder opens the next file at that remembered size.

Success criteria:
- The controller reliably receives resize-end events.
- The next file opens with the remembered size.
- No major Finder-hosting issues appear.

Failure criteria:
- No access to the effective host window.
- No resize-end events.
- `preferredContentSize` is ignored by Finder Quick Look.

### Phase 1: Real implementation if the spike passes
1. Add a new preference in `SharedSettings`, for example:
   - `rememberLastPreviewWindowSize`
2. Add persisted values:
   - `lastPreviewWindowWidth`
   - `lastPreviewWindowHeight`
3. Add a new settings option alongside the current sizing modes:
   - `Fit to Content`
   - `One Shared Starting Size`
   - `Remember Last Resized Size`
4. Port the current HTML preview output into the view-based controller.
5. Save the window size automatically on `NSWindowDidEndLiveResizeNotification`.
6. Restore through `preferredContentSize` for the next preview.
7. Add tests for settings/state transitions and run manual Finder verification for actual resize persistence.

### Phase 2: Regression verification
Verify all existing behaviors still work:
- syntax-highlighted code previews
- markdown RAW/rendered toggle
- TOC
- copy behavior presets
- search
- preview caching
- dark/light theme handling
- large-file truncation

## Known Dead-Ends / What Not to Try
- Do not try to implement “remember last manual size” in the current `QLPreviewReply(contentSize:)` path. The API only provides a size hint and no documented way to read back the user-resized frame.
- Do not add a header “Save current size” button while staying data-based. The HTML preview does not own the native Quick Look panel frame.
- Do not rely on `QLPreviewPanel.displayState` from the current Finder-hosted extension path. That API is for apps controlling the panel, not for the current dotViewer architecture.

## Open Questions
- If the feature is important enough, are you willing to accept a larger architectural spike that may replace the current data-based preview path with a view-based one?
- If the spike works, do you want the remembered-size mode to replace `Same for All Files`, or sit beside it as a third explicit mode?

## Sources
- Apple Developer docs:
  - `https://developer.apple.com/documentation/quicklookui/qlpreviewreply`
  - `https://developer.apple.com/documentation/quicklookui/qlpreviewprovider`
  - `https://developer.apple.com/documentation/quicklookui/qlpreviewingcontroller`
  - `https://developer.apple.com/documentation/quicklookui/qlpreviewpanel`
  - `https://developer.apple.com/documentation/quicklookui/qlpreviewitem`
  - `https://developer.apple.com/documentation/appkit/nsviewcontroller`
  - `https://developer.apple.com/documentation/appkit/nswindow`
- SDK headers used for verification:
  - `QLPreviewReply.h`
  - `QLPreviewProvider.h`
  - `QLPreviewPanel.h`
  - `QLPreviewItem.h`
  - `NSViewController.h`
  - `NSWindow.h`
