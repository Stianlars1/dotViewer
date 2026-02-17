# Preview Width and App GUI Font Size Research (2026-02-14)

## Feature
Add user-configurable content width controls for Quick Look previews and add app GUI text-size support in the host macOS app.

## Context Read
- `/Users/stian/Developer/macOS Apps/v2.5/CLAUDE.md`
- `/Users/stian/Developer/macOS Apps/v2.5/KNOWN_ISSUES.md`
- `/Users/stian/Developer/macOS Apps/v2.5/BACKLOG.md` (B-022 exists)
- `/Users/stian/Developer/macOS Apps/v2.5/dotViewer/Shared/PreviewHTMLBuilder.swift`
- `/Users/stian/Developer/macOS Apps/v2.5/dotViewer/App/SettingsView.swift`
- `/Users/stian/Developer/macOS Apps/v2.5/dotViewer/App/MarkdownSettingsView.swift`

## Constraints Discovered
1. Preview and thumbnail rendering are separate pipelines; this request affects the HTML preview pipeline only.
2. Markdown rendered mode currently has hardcoded `max-width: 900px`, while RAW/code has no max-width cap.
3. Preview output is cached (`PreviewCacheKey`), so width settings must participate in cache keys to avoid stale layout.
4. Settings must sync across app/extension via `SharedSettings` (App Group).
5. Host app text currently uses semantic SwiftUI text styles plus a few fixed-size fonts; a global app text-size override should be applied at app-root level.

## Approaches

### Approach A: Add CSS-only hardcoded presets (no settings)
- How it works: Change CSS constants in `PreviewHTMLBuilder`.
- Requirements: None.
- Risks: Does not satisfy user requirement for customization.
- Complexity: Low.
- Verdict: Avoid.

### Approach B: Add per-mode width settings in `SharedSettings` + wire through `PreviewInfo` (recommended)
- How it works: Store mode/value pairs for code/RAW and rendered markdown. Inject into HTML/CSS generation.
- Requirements: `SharedSettings`, `PreviewInfo`, `PreviewProvider`, `PreviewCacheKey`, settings UI updates.
- Risks: Missing cache-key wiring could keep old widths until cache expiry.
- Complexity: Medium.
- Verdict: Recommended.

### Approach C: Add only one global width setting for all preview modes
- How it works: Single max-width applied to both rendered and code views.
- Requirements: Minimal new settings.
- Risks: Fails explicit requirement for separate markdown rendered vs code widths.
- Complexity: Low.
- Verdict: Possible but not aligned with request.

### Approach D: App GUI font control via SwiftUI `dynamicTypeSize` at app root (recommended)
- How it works: Add app text size preset setting with `System` default. Apply chosen dynamic type size at root view.
- Requirements: App setting in `SharedSettings`, picker in Settings, root modifier in `dotViewerApp`.
- Risks: Any fixed-size fonts remain fixed (mainly icons/monospace sample), but semantic text scales.
- Complexity: Low/Medium.
- Verdict: Recommended.

### Approach E: Rewrite all app text to custom scaling helper
- How it works: Replace every `.font(...)` usage with a custom scaler.
- Requirements: broad refactor.
- Risks: High regression risk and unnecessary complexity.
- Complexity: High.
- Verdict: Avoid.

## Recommended Plan
1. Implement Approach B for width controls.
2. Implement Approach D for GUI font scaling with `System` option.
3. Include new width settings in preview cache key.
4. Verify with `dotviewer-refresh`, unit tests, and `dotviewer-ql-smoke`.

## Known Dead-Ends / What Not to Try
- Do not edit generated `Info.plist` files directly; persistent config lives in `project.yml`.
- Do not change thumbnail renderer for this request; scope is Quick Look preview HTML + host app UI settings.

## Open Questions
- None blocking. Current implementation can default to existing behavior: rendered markdown keeps 900px in auto mode; code/RAW remains uncapped in auto mode.
