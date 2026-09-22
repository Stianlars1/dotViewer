# Settings window redesign — design

- **Date:** 2026-09-22 · **Branch:** `feat/settings-window` (from `main` at `da5b1f3`)
- **Status:** approved in chat 2026-09-22 (Markdown moves in, switches, sidebar search, build it)

## Problem

Settings live in the main window as a sidebar item ("Settings") and a second one ("Markdown"), each
with a custom horizontal tab bar (`SettingsTabBar`). Seven tabs overflow and clip ("Dang…",
"…earance"). Every setting is hand-laid-out in a `VStack` with a caption `Text` underneath, so labels,
controls, captions, dividers and buttons sit at different positions on every page: popups hug their
labels, sliders span the card, checkboxes lead, a Reset button floats at the far right of a caption
line, one card is narrower than the others, and Danger Zone is a full-width red bar. The custom tab
bar is also the surface of #31 (clicks lost on Intel/macOS 15). There is no `Settings` scene, so the
app menu has no "Settings…" item and ⌘, does nothing.

## Design

### Window and navigation

- `dotViewerApp` gains a SwiftUI **`Settings` scene** → macOS adds *dotViewer → Settings… ⌘,*.
- `SettingsWindow`: `NavigationSplitView` — native `List(selection:)` sidebar (the same control as the
  main window's sidebar, which works on the #31 reporter's Mac), detail = the selected pane. Sidebar
  cannot collapse. Last pane remembered (`@AppStorage`). Window title = pane title. Min size 720×500.
- **Search:** `.searchable(placement: .sidebar)`. With a query, the sidebar lists matching settings
  (title + pane); choosing one opens its pane, scrolls to the row and highlights it briefly. No match →
  "No results". Backed by a static catalog (`SettingsCatalog`) of every setting: stable ID, pane,
  title, keywords.
- **Main window:** sidebar keeps **Status** and **File Types**; a footer row "Settings ⌘," is a
  `SettingsLink`. The Markdown and Settings items are removed.

### Panes

| Section | Pane | Contents (existing `SharedSettings` keys, unchanged) |
|---|---|---|
| Previews | **General** | file info header; unknown files (preview routed, force text); large files (max size, truncation warning) |
| | **Appearance** | live theme preview; theme; code font (+reset), font size, line numbers, word wrap; interface text size |
| | **Markdown** | default mode, raw syntax highlighting, inline images; TOC button + open by default; rendered font (+reset), size / match code size, width + max, alignment; custom CSS |
| | **Window** | Quick Look window size mode + its dimensions; code/raw content width + max; code and raw alignment |
| Interaction | **Copy** | copy behavior (+ description of the chosen preset); line numbers in copies |
| | **Shortcuts** | find button in preview; ⌘F search; ⌥Space panel; one Permissions card (Accessibility, Finder) with status, Grant/Open Settings, troubleshooting |
| Advanced | **Advanced** | preview cache (on, TTL, size, clear); performance logging; uninstall |

Future panes from `2026-09-22-usage-stats-telemetry-updates.md` (Updates, Privacy) slot into this list.

### Visual formula (every pane)

- Each pane is a `Form` with `.formStyle(.grouped)` — the System Settings layout. Sections are
  rounded cards with a header above and an optional footer below for longer explanations.
- **Row:** title (+ optional one-line secondary description) leading; control trailing, vertically
  centred. Components in `SettingsRows.swift`:
  - `SettingsLabel(title, description)`
  - toggles: `Toggle` + `.toggleStyle(.switch)` (switches everywhere, no checkboxes)
  - menus: `Picker` `.menu`; two-to-three options: `.segmented`
  - `SettingsSliderRow`: slider fixed width + monospaced value label trailing
  - `SettingsStatusRow`: permission status icon + text leading, action button trailing
  - buttons are small and trailing (Reset, Clear cache, Uninstall…) — never full width
- `.settingsAnchor(id)` on every row: `.id` for scrolling plus a brief accent highlight for search.
- Appearance's theme preview card stays at the top of that pane (live: theme, font, size).

### State

A single `@Observable @MainActor SettingsModel` owns every value: initialised from
`SharedSettings.shared`, each property's `didSet` writes back through the existing (sanitising)
setters. The coupled pair "code font size ↔ rendered font size" lives in one place instead of being
duplicated and re-read `onAppear` in two views. Permission-polling views keep their own timers.

### Removed

`SettingsView.swift`, `MarkdownSettingsView.swift`, `SettingsTabPage.swift`,
`dotViewerTests/SettingsTabBarTests.swift` (with its `project.yml` source entry).
`QuickLookFindKeySettings` and `PreviewPanelSettings` fold into the Shortcuts pane.

## Testing

- `SettingsCatalogTests`: unique IDs, every pane has entries, search matches titles and keywords
  case- and diacritic-insensitively, empty query returns nothing.
- `SettingsSidebarTests`: host `SettingsWindow` in an offscreen window and select every pane with real
  mouse-down/up events (the #31 method).
- Offscreen snapshots of every pane, light and dark, for review — no install needed.
- Manual pass on a Developer ID build (`release.sh … --skip-notarize --skip-dmg`) only with the
  owner's go-ahead: ⌘, and menu item, footer link, every control persists and reaches previews,
  search, interface text sizes.
- Docs: KNOWN_ISSUES KI-019 (tab bar gone), CHANGELOG, CLAUDE.md host-app file list.
