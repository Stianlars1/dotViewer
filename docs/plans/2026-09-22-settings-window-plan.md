# Settings Window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the main-window Settings/Markdown pages and their custom tab bars with a native Settings window (⌘,) — sidebar of panes, grouped rows with one layout formula, sidebar search.

**Architecture:** A SwiftUI `Settings` scene hosts `SettingsWindow` (`NavigationSplitView`: `List` sidebar + one `Form(.grouped)` per pane). One `@Observable` `SettingsModel` wraps `SharedSettings`. A static `SettingsCatalog` (stable `SettingID`s) powers search and row anchors. The main window keeps Status and File Types and gains a `SettingsLink` footer.

**Tech Stack:** Swift 6, SwiftUI (macOS 15 target), Observation, XCTest, XcodeGen.

**Spec:** `docs/plans/2026-09-22-settings-window-design.md`

## Global Constraints

- Never edit generated `Info.plist`/`.entitlements`/`.xcodeproj` by hand; change `dotViewer/project.yml`, run `xcodegen generate` in `dotViewer/`, commit the regenerated `dotViewer.xcodeproj`.
- `SharedSettings` keys and their sanitising setters stay exactly as they are; settings written by the new UI must reach previews unchanged.
- Row labels and section headers in sentence case; button titles in title case (Apple HIG); no full-width buttons.
- Every on/off control is `Toggle` with `.toggleStyle(.switch)`.
- Tests: `cd dotViewer && xcodegen generate && xcodebuild -project dotViewer.xcodeproj -scheme dotViewerTests -derivedDataPath build test` (currently 247 tests, all passing).
- Never install a development build into `/Applications` (TCC is bound to the code signature). Visual checks use offscreen rendering; a Developer ID build is installed only with the owner's go-ahead.
- Commits: conventional commits, specific files only, no GitHub closing keywords.

## File map

| File | Responsibility |
|---|---|
| `App/Settings/SettingsPane.swift` (new) | pane enum: title, icon, sidebar groups |
| `App/Settings/SettingsCatalog.swift` (new) | `SettingID`, `SettingsEntry`, catalog, search |
| `App/Settings/SettingsModel.swift` (new) | `@Observable` state for every setting, writes through `SharedSettings` |
| `App/Settings/SettingsRows.swift` (new) | `SettingsLabel`, `SettingsSliderRow`, `SettingsStatusRow`, `.settingsAnchor`, Int→Double binding |
| `App/Settings/SettingsWindow.swift` (new) | split view, sidebar (panes or search results), detail routing, highlight |
| `App/Settings/Panes/*.swift` (new, 7) | one `Form` per pane |
| `App/dotViewerApp.swift` | add `Settings` scene |
| `App/ContentView.swift` | drop Markdown/Settings items, add footer `SettingsLink` |
| `App/SettingsView.swift`, `App/MarkdownSettingsView.swift`, `App/SettingsTabPage.swift`, `App/QuickLookFindKeySettings.swift`, `App/PreviewPanelSettings.swift` | delete (folded into panes) |
| `dotViewerTests/SettingsTabBarTests.swift` | delete |
| `dotViewerTests/SettingsCatalogTests.swift`, `SettingsSidebarTests.swift`, `SettingsSnapshotTests.swift` (new) | catalog/search, real-click sidebar, env-gated snapshots |
| `dotViewer/project.yml` | test-target sources |

---

### Task 1: Pane list and settings catalog with search

**Files:**
- Create: `dotViewer/App/Settings/SettingsPane.swift`, `dotViewer/App/Settings/SettingsCatalog.swift`
- Test: `dotViewer/dotViewerTests/SettingsCatalogTests.swift`
- Modify: `dotViewer/project.yml` (test sources: add both files)

**Interfaces — Produces:**
- `enum SettingsPane: String, CaseIterable, Identifiable, Hashable` — `general, appearance, markdown, window, copy, shortcuts, advanced`; `title: String`, `systemImage: String`, `static let groups: [[SettingsPane]]`.
- `enum SettingID: String, CaseIterable, Hashable, Sendable` (one case per catalog row below).
- `struct SettingsEntry: Identifiable, Hashable, Sendable { id: SettingID; pane: SettingsPane; title: String; keywords: [String] }`
- `enum SettingsCatalog { static let entries: [SettingsEntry]; static func entry(_ id: SettingID) -> SettingsEntry; static func search(_ query: String) -> [SettingsEntry]; static func rank(_ matches: [SettingsEntry], tokens: [String]) -> [SettingsEntry] }`

- [x] **Step 1: Write the failing tests** (`SettingsCatalogTests.swift`)

```swift
import XCTest

final class SettingsCatalogTests: XCTestCase {
    func testEverySettingIDHasExactlyOneEntry() {
        let ids = SettingsCatalog.entries.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate catalog entries")
        XCTAssertEqual(Set(ids), Set(SettingID.allCases), "Every SettingID needs a catalog entry")
    }

    func testEveryPaneHasSettings() {
        for pane in SettingsPane.allCases {
            XCTAssertFalse(SettingsCatalog.entries.filter { $0.pane == pane }.isEmpty, "\(pane) has no entries")
        }
    }

    func testGroupsCoverEveryPaneOnce() {
        XCTAssertEqual(SettingsPane.groups.flatMap { $0 }, SettingsPane.allCases)
    }

    func testSearchMatchesTitlesCaseInsensitively() {
        XCTAssertTrue(SettingsCatalog.search("WRAP LONG").map(\.id).contains(.wordWrap))
    }

    func testSearchMatchesKeywords() {
        XCTAssertTrue(SettingsCatalog.search("dark").map(\.id).contains(.theme))
        XCTAssertTrue(SettingsCatalog.search("option space").map(\.id).contains(.spacePanel))
    }

    func testSearchIgnoresDiacritics() {
        XCTAssertTrue(SettingsCatalog.search("thème").map(\.id).contains(.theme))
    }

    func testEveryTokenMustMatch() {
        let ids = SettingsCatalog.search("cache size").map(\.id)
        XCTAssertTrue(ids.contains(.cacheSize))
        XCTAssertFalse(ids.contains(.fontSize), "\"size\" alone must not match when \"cache\" does not")
    }

    func testBlankQueryReturnsNothing() {
        XCTAssertTrue(SettingsCatalog.search("   ").isEmpty)
    }
}
```

- [x] **Step 2: Add sources to the test target and run — expect failure**

In `project.yml` under `dotViewerTests: sources:` add:
```yaml
      - path: App/Settings/SettingsPane.swift
      - path: App/Settings/SettingsCatalog.swift
```
Run the test command. Expected: build FAILS (types not defined).

- [x] **Step 3: Implement `SettingsPane.swift`**

```swift
import Foundation

/// The panes of the Settings window, in sidebar order.
enum SettingsPane: String, CaseIterable, Identifiable, Hashable {
    case general, appearance, markdown, window, copy, shortcuts, advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .markdown: "Markdown"
        case .window: "Window"
        case .copy: "Copy"
        case .shortcuts: "Shortcuts"
        case .advanced: "Advanced"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .markdown: "doc.richtext"
        case .window: "macwindow"
        case .copy: "doc.on.doc"
        case .shortcuts: "keyboard"
        case .advanced: "wrench.and.screwdriver"
        }
    }

    /// Sidebar groups, separated by space like System Settings. Previews, then interaction, then
    /// maintenance (future Updates and Privacy panes join the last group).
    static let groups: [[SettingsPane]] = [
        [.general, .appearance, .markdown, .window],
        [.copy, .shortcuts],
        [.advanced],
    ]
}
```

- [x] **Step 4: Implement `SettingsCatalog.swift`** — `SettingID` cases and entries exactly as this table; `search` folds case/diacritics/width, splits on whitespace, requires every token to occur in `title + pane.title + keywords`; `rank` returns its input (catalog order) and carries a `// TODO(owner):` note — the ranking rule is the owner's call (Task 8).

| ID | Pane | Title | Keywords |
|---|---|---|---|
| fileInfoHeader | general | File info header | header, filename, language, line count, file size |
| previewUnknownFiles | general | Preview unknown file types | unknown, unsupported, extension, registry, routed |
| forceTextForUnknown | general | Show unknown text as plain text | force, plain text, mime, fallback, unknown |
| maxFileSize | general | Maximum file size | large, limit, truncate, kb, size |
| truncationWarning | general | Truncation warning | truncated, large file, notice |
| theme | appearance | Theme | colour, color, dark, light, github, xcode, solarized, atom, tokyo, blackout, syntax |
| codeFont | appearance | Code font | font, monospace, mono, typeface, family, sf mono |
| fontSize | appearance | Font size | text size, zoom, points, pt |
| lineNumbers | appearance | Line numbers | gutter, numbers |
| wordWrap | appearance | Wrap long lines | word wrap, soft wrap, horizontal scroll |
| interfaceTextSize | appearance | Interface text size | app text, dynamic type, larger text, ui, accessibility |
| markdownDefaultMode | markdown | Open Markdown as | raw, rendered, default mode, md |
| markdownRawHighlighting | markdown | Highlight syntax in raw view | raw, syntax, colours, colors |
| markdownInlineImages | markdown | Show images | inline images, pictures |
| markdownTOC | markdown | Table of contents button | toc, outline, headings, navigation |
| markdownTOCOpen | markdown | Open table of contents by default | toc, sidebar, outline |
| markdownFont | markdown | Rendered font | prose, font, typeface, serif, sans |
| markdownMatchCodeSize | markdown | Match code font size | sync, same size |
| markdownFontSize | markdown | Rendered font size | text size, markdown size |
| markdownWidth | markdown | Rendered width | max width, column, line length, measure |
| markdownAlignment | markdown | Rendered alignment | centre, center, left, right, align |
| markdownCustomCSS | markdown | Custom CSS | stylesheet, style, css, override, replace |
| windowSizeMode | window | Window size | quick look window, preview size, auto, fixed, aspect ratio, fit content, remember |
| windowDimensions | window | Window dimensions | width, height, ratio, base width, pixels |
| codeWidth | window | Code width | content width, max width, raw width, line length |
| codeAlignment | window | Code alignment | centre, center, left, right, align |
| markdownRawAlignment | window | Markdown raw alignment | raw, centre, center, align |
| copyBehavior | copy | When you select text | copy, clipboard, auto-copy, selection, copy button, hold, shake, toast, undo |
| copyLineNumbers | copy | Include line numbers | copy, clipboard, gutter |
| findButton | shortcuts | Find button in preview | search, find, magnifier, header |
| findShortcut | shortcuts | ⌘F search | command f, cmd f, find, search, keyboard |
| spacePanel | shortcuts | ⌥Space preview | option space, alt space, panel, ts, typescript, finder |
| accessibilityPermission | shortcuts | Accessibility access | permission, privacy, tcc, grant, keyboard |
| finderPermission | shortcuts | Finder access | automation, apple events, permission, privacy, tcc |
| previewCache | advanced | Preview cache | cache, speed, performance |
| cacheLifetime | advanced | Keep previews for | ttl, cache, expiry, time, seconds |
| cacheSize | advanced | Cache size limit | cache, mb, disk, storage |
| clearCache | advanced | Clear cache | cache, reset, delete, purge |
| performanceLogging | advanced | Performance logging | logs, diagnostics, timing, debug, console |
| uninstall | advanced | Uninstall dotViewer | remove, delete, trash, danger |

```swift
import Foundation

/// Stable identity of every row in Settings — used by search and by `.settingsAnchor`.
enum SettingID: String, CaseIterable, Hashable, Sendable {
    case fileInfoHeader, previewUnknownFiles, forceTextForUnknown, maxFileSize, truncationWarning
    case theme, codeFont, fontSize, lineNumbers, wordWrap, interfaceTextSize
    case markdownDefaultMode, markdownRawHighlighting, markdownInlineImages, markdownTOC, markdownTOCOpen
    case markdownFont, markdownMatchCodeSize, markdownFontSize, markdownWidth, markdownAlignment, markdownCustomCSS
    case windowSizeMode, windowDimensions, codeWidth, codeAlignment, markdownRawAlignment
    case copyBehavior, copyLineNumbers
    case findButton, findShortcut, spacePanel, accessibilityPermission, finderPermission
    case previewCache, cacheLifetime, cacheSize, clearCache, performanceLogging, uninstall
}

struct SettingsEntry: Identifiable, Hashable, Sendable {
    let id: SettingID
    let pane: SettingsPane
    let title: String
    let keywords: [String]
}

enum SettingsCatalog {
    static let entries: [SettingsEntry] = [
        // one SettingsEntry(id:pane:title:keywords:) per table row, in table order
    ]

    private static let byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })

    static func entry(_ id: SettingID) -> SettingsEntry {
        guard let entry = byID[id] else { preconditionFailure("No catalog entry for \(id)") }
        return entry
    }

    static func search(_ query: String) -> [SettingsEntry] {
        let tokens = fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return [] }
        let matches = entries.filter { entry in
            let haystack = fold(([entry.title, entry.pane.title] + entry.keywords).joined(separator: " "))
            return tokens.allSatisfy(haystack.contains)
        }
        return rank(matches, tokens: tokens)
    }

    static func rank(_ matches: [SettingsEntry], tokens: [String]) -> [SettingsEntry] {
        // TODO(owner): order results — see Task 8.
        matches
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }
}
```
(The `entries` array literal is written out in full from the table; the comment above is not left in the file.)

- [x] **Step 5: `xcodegen generate`, run tests — expect PASS** (all prior tests + 8 new).
- [x] **Step 6: Commit** `feat(settings): add settings pane list and searchable catalog`

### Task 2: Settings model

**Files:** Create `dotViewer/App/Settings/SettingsModel.swift`

**Interfaces — Produces:** `@MainActor @Observable final class SettingsModel` with the properties below (names exact), plus `func resetRememberedWindowSize()`, `func saveRememberedSizeAsFixed()`, `func clearPreviewCache()`.

| Property | Type | SharedSettings key/accessor | Extra `didSet` behaviour |
|---|---|---|---|
| theme | String | selectedTheme | |
| fontSize | Double | fontSize | if `syncFontSizes && markdownFontSize != fontSize` → `markdownFontSize = fontSize` |
| codeFontFamily | String | codeFontFamilyName | |
| interfaceTextSize | String | appUIFontSizePreset | |
| showLineNumbers | Bool | showLineNumbers | |
| wordWrap | Bool | wordWrap | |
| syncFontSizes | Bool | syncFontSizes | when turned on → `markdownFontSize = fontSize` |
| markdownFontSize | Double | markdownRenderFontSize | if synced and differs → `fontSize = markdownFontSize` |
| codeWidthMode | String | codeContentWidthMode | |
| codeMaxWidth | Int | codeContentCustomMaxWidth | |
| codeAlignment | String | codeContentAlignment | |
| markdownRawAlignment | String | markdownRawContentAlignment | |
| maxFileSizeKB | Double | maxFileSizeBytes (÷/× 1000) | |
| showTruncationWarning | Bool | showTruncationWarning | |
| showFileInfoHeader | Bool | showFileInfoHeader | |
| windowSizeMode | String | previewWindowSizeMode | |
| windowFixedWidth / windowFixedHeight | Int | previewWindowFixedWidth / Height | |
| windowAspectRatio | String | previewWindowAspectRatio | |
| windowAspectBaseWidth | Int | previewWindowAspectBaseWidth | |
| previewUnknownFiles | Bool | previewAllFileTypes | |
| forceTextForUnknown | Bool | previewForceTextForUnknown | |
| copyBehavior | String | copyBehavior | |
| includeLineNumbersInCopy | Bool | includeLineNumbersInCopy | |
| showSearchButton | Bool | showSearchButton | |
| previewPanelEnabled | Bool | previewPanelEnabled | |
| performanceLogging | Bool | performanceLoggingEnabled | |
| previewCacheEnabled | Bool | previewCacheEnabled | |
| cacheMaxMB | Int | previewCacheMaxMB | |
| cacheTTLSeconds | Int | previewCacheTTLSeconds | |
| markdownDefaultMode | String | markdownDefaultMode | |
| markdownShowImages | Bool | markdownShowInlineImages | |
| markdownRawHighlighting | Bool | markdownUseSyntaxHighlightInRaw | |
| markdownShowTOC | Bool | markdownShowTOC | |
| markdownTOCOpen | Bool | markdownTOCDefaultOpen | |
| markdownFont | String | markdownRenderedFontFamilyName | |
| markdownWidthMode | String | markdownRenderedWidthMode | |
| markdownMaxWidth | Int | markdownRenderedCustomMaxWidth | |
| markdownAlignment | String | markdownRenderedContentAlignment | |
| customCSS | String | markdownCustomCSS | |
| customCSSReplacesBuiltIn | Bool | markdownCustomCSSOverride | |

Pattern (every property the same way; `init` reads all values from `SharedSettings.shared`):

```swift
import Observation
import Shared

@MainActor
@Observable
final class SettingsModel {
    @ObservationIgnored private let store = SharedSettings.shared

    var theme: String { didSet { store.selectedTheme = theme } }
    var fontSize: Double {
        didSet {
            store.fontSize = fontSize
            if syncFontSizes, markdownFontSize != fontSize { markdownFontSize = fontSize }
        }
    }
    // … remaining properties per the table …

    init() {
        theme = store.selectedTheme
        fontSize = store.fontSize
        // … every property …
    }

    func resetRememberedWindowSize() { store.resetPreviewWindowLastSize() }

    func saveRememberedSizeAsFixed() {
        store.copyLastSizeToFixed()
        windowFixedWidth = store.previewWindowFixedWidth
        windowFixedHeight = store.previewWindowFixedHeight
        windowSizeMode = "fixed"
    }

    func clearPreviewCache() { store.previewCacheClearRequested = true }
}
```

- [x] **Step 1:** write the file per the table. **Step 2:** build the app scheme (`xcodebuild -project dotViewer.xcodeproj -scheme dotViewer -derivedDataPath build build`) — expect success. **Step 3:** commit `feat(settings): add observable settings model`.

### Task 3: Row components

**Files:** Create `dotViewer/App/Settings/SettingsRows.swift`; add to test sources.

**Interfaces — Produces:**
- `struct SettingsLabel: View { init(_ title: String, description: String? = nil) }`
- `struct SettingsSliderRow: View { init(_ title: String, description: String? = nil, value: Binding<Double>, in range: ClosedRange<Double>, step: Double, format: @escaping (Double) -> String) }`
- `struct SettingsStatusRow<Actions: View>: View { init(isOK: Bool, title: String, description: String? = nil, @ViewBuilder actions: () -> Actions) }`
- `extension View { func settingsAnchor(_ id: SettingID) -> some View }` — `.id(id)` + accent highlight when `EnvironmentValues.highlightedSetting == id`
- `extension EnvironmentValues { @Entry var highlightedSetting: SettingID? = nil }`
- `extension Binding where Value == Int { var asDouble: Binding<Double> }`

```swift
import SwiftUI

struct SettingsLabel: View {
    private let title: String
    private let description: String?

    init(_ title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct SettingsSliderRow: View {
    let title: String
    var description: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    init(_ title: String, description: String? = nil, value: Binding<Double>,
         in range: ClosedRange<Double>, step: Double, format: @escaping (Double) -> String) {
        self.title = title
        self.description = description
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        LabeledContent {
            HStack(spacing: 10) {
                Slider(value: $value, in: range, step: step)
                    .labelsHidden()
                    .frame(width: 180)
                Text(format(value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 58, alignment: .trailing)
            }
        } label: {
            SettingsLabel(title, description: description)
        }
    }
}

struct SettingsStatusRow<Actions: View>: View {
    let isOK: Bool
    let title: String
    var description: String?
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) { actions() }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: isOK ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(isOK ? Color.green : Color.orange)
                SettingsLabel(title, description: description)
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var highlightedSetting: SettingID? = nil
}

private struct SettingsAnchor: ViewModifier {
    let id: SettingID
    @Environment(\.highlightedSetting) private var highlighted

    func body(content: Content) -> some View {
        content
            .id(id)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(highlighted == id ? 0.16 : 0))
                    .padding(-6)
                    .animation(.easeOut(duration: 0.25), value: highlighted)
            }
    }
}

extension View {
    func settingsAnchor(_ id: SettingID) -> some View { modifier(SettingsAnchor(id: id)) }
}

extension Binding where Value == Int {
    var asDouble: Binding<Double> {
        Binding<Double>(get: { Double(wrappedValue) }, set: { wrappedValue = Int($0.rounded()) })
    }
}
```

- [x] **Step 1:** write the file. **Step 2:** build — success. **Step 3:** commit `feat(settings): add shared settings row components`.

### Task 4: The seven panes

**Files:** Create `dotViewer/App/Settings/Panes/{General,Appearance,Markdown,Window,Copy,Shortcuts,Advanced}Pane.swift`.

**Interfaces — Consumes:** `SettingsModel` via `@Environment(SettingsModel.self)`, row components, `SettingID`. **Produces:** `struct <Name>Pane: View` (no init arguments).

Every pane: `Form { Section(header) { rows } … }.formStyle(.grouped)`; each row ends with `.settingsAnchor(<id>)`; toggles `.toggleStyle(.switch)`; menus `.pickerStyle(.menu)`; segmented as noted. Reference pattern (Appearance, complete):

```swift
import Shared
import SwiftUI

struct AppearancePane: View {
    @Environment(SettingsModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var model = model
        Form {
            Section("Theme") {
                ThemePreview(theme: model.theme, fontFamily: model.codeFontFamily,
                             fontSize: model.fontSize, isDark: colorScheme == .dark)
                    .listRowInsets(EdgeInsets())
                Picker(selection: $model.theme) {
                    ForEach(ThemePalette.selectableThemes) { Text($0.title).tag($0.id) }
                } label: { SettingsLabel("Theme") }
                .settingsAnchor(.theme)
            }
            Section("Code") {
                LabeledContent {
                    HStack(spacing: 8) {
                        if model.codeFontFamily != PreviewFontFamily.defaultCodeFamily {
                            Button("Reset") { model.codeFontFamily = PreviewFontFamily.defaultCodeFamily }
                                .controlSize(.small)
                        }
                        Picker("Code font", selection: $model.codeFontFamily) {
                            ForEach(PreviewFontMenu.codeFontFamilies, id: \.self) {
                                Text(PreviewFontMenu.title(for: $0)).tag($0)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                } label: {
                    SettingsLabel("Font", description: "Code previews, Markdown's raw view and Finder thumbnails.")
                }
                .settingsAnchor(.codeFont)
                SettingsSliderRow("Font size", value: $model.fontSize, in: 10...24, step: 1) { "\(Int($0)) pt" }
                    .settingsAnchor(.fontSize)
                Toggle(isOn: $model.showLineNumbers) { SettingsLabel("Line numbers") }
                    .settingsAnchor(.lineNumbers)
                Toggle(isOn: $model.wordWrap) {
                    SettingsLabel("Wrap long lines", description: "Instead of scrolling sideways.")
                }
                .settingsAnchor(.wordWrap)
            }
            Section("This app") {
                Picker(selection: $model.interfaceTextSize) {
                    ForEach(AppUIFontSizePreset.allCases) { Text($0.title).tag($0.rawValue) }
                } label: {
                    SettingsLabel("Interface text size", description: "dotViewer's own windows. System follows macOS.")
                }
                .settingsAnchor(.interfaceTextSize)
            }
        }
        .formStyle(.grouped)
        .toggleStyle(.switch)
        .pickerStyle(.menu)
    }
}

/// Live sample of the chosen theme, font and size — the old "Theme" tab, now next to the picker.
private struct ThemePreview: View {
    let theme: String
    let fontFamily: String
    let fontSize: Double
    let isDark: Bool

    var body: some View {
        let palette = ThemePalette.palette(for: theme, systemIsDark: isDark)
        let font = Font(PreviewFontResolver.codeFont(familyName: fontFamily, size: fontSize))
        VStack(alignment: .leading, spacing: 2) {
            Text("// Preview").foregroundStyle(Color(hex: palette.comment))
            (Text("func ").foregroundStyle(Color(hex: palette.keyword))
             + Text("greet").foregroundStyle(Color(hex: palette.function))
             + Text("(name: ").foregroundStyle(Color(hex: palette.text))
             + Text("String").foregroundStyle(Color(hex: palette.type))
             + Text(") {").foregroundStyle(Color(hex: palette.text)))
            (Text("    return ").foregroundStyle(Color(hex: palette.keyword))
             + Text("\"Hello, \\(name)!\"").foregroundStyle(Color(hex: palette.string)))
            Text("}").foregroundStyle(Color(hex: palette.text))
        }
        .font(font)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: palette.background))
    }
}
```

Row specification for the other panes (title — description — control — binding — anchor):

**GeneralPane**
- Section "Preview": "File info header" — "Filename, language, line count and size above the preview." — toggle — `showFileInfoHeader` — `.fileInfoHeader`
- Section "Unknown file types": "Preview unknown file types" — "Tries files that open in dotViewer even when their extension isn't in the built-in list." — toggle — `previewUnknownFiles` — `.previewUnknownFiles`; "Show unknown text as plain text" — "Readable files without a useful text type open as plain text." — toggle — `forceTextForUnknown` — `.forceTextForUnknown`
- Section "Large files": "Maximum file size" — "Larger files are cut off in the preview." — slider 10…500 step 10 `"\(Int) KB"` — `maxFileSizeKB` — `.maxFileSize`; "Truncation warning" — "Shows a notice when a preview is cut off." — toggle — `showTruncationWarning` — `.truncationWarning`

**MarkdownPane**
- Section "Opening": "Open Markdown as" — segmented Rendered (`rendered`) / Raw (`raw`), `.fixedSize()` — `markdownDefaultMode` — `.markdownDefaultMode`; "Highlight syntax in raw view" — toggle — `markdownRawHighlighting` — `.markdownRawHighlighting`; "Show images" — "Inline images in rendered Markdown." — toggle — `markdownShowImages` — `.markdownInlineImages`
- Section "Table of contents": "Table of contents button" — "Adds a contents button to the rendered header." — toggle — `markdownShowTOC` — `.markdownTOC`; "Open by default" — toggle, `.disabled(!model.markdownShowTOC)` — `markdownTOCOpen` — `.markdownTOCOpen`
- Section "Rendered text": "Font" — "Prose in rendered Markdown. Inline code keeps the code font." — menu of `PreviewFontMenu.renderedFontFamilies` + Reset (when not `PreviewFontFamily.defaultMarkdownRenderedFamily`) — `markdownFont` — `.markdownFont`; "Match code font size" — toggle — `syncFontSizes` — `.markdownMatchCodeSize`; "Font size" — slider 10…24 step 1 `"\(Int) pt"`, `.disabled(model.syncFontSizes)` — `markdownFontSize` — `.markdownFontSize`; "Width" — segmented Auto (`auto`) / Custom (`custom`) — `markdownWidthMode` — `.markdownWidth`; if custom: "Maximum width" slider 480…2400 step 10 `"\(Int) px"` — `markdownMaxWidth.asDouble`; "Alignment" — segmented Left/Center/Right (`left`/`center`/`right`) — `markdownAlignment` — `.markdownAlignment`
- Section "Custom CSS" (footer: "Off: your CSS is added after the built-in styles. On: only your CSS is used."): "Replace built-in styles" — toggle — `customCSSReplacesBuiltIn`; `TextEditor(text: $model.customCSS)` monospaced `.system(.body, design: .monospaced)`, `frame(minHeight: 160)` — `.markdownCustomCSS`

**WindowPane**
- Section "Quick Look window": "Size" — description = the existing mode description text (copy the `previewWindowSizeModeDescription` switch from `SettingsView.swift`) — menu Fixed/Auto/Aspect ratio/Fit content/Remember (`fixed`/`auto`/`aspect`/`contentFixed`/`remember`) — `windowSizeMode` — `.windowSizeMode`. Then by mode (first row anchored `.windowDimensions`): fixed → "Width" 420…1600 px, "Height" 220…1400 px; contentFixed → "Width", "Maximum height"; aspect → "Ratio" segmented `PreviewSizing.AspectRatio.allKeys`, "Base width" 420…1600 px; remember → `LabeledContent("Remembered size")` with small buttons "Reset" (`resetRememberedWindowSize()`) and "Save as Fixed" (`saveRememberedSizeAsFixed()`). All sliders step 10, `"\(Int) px"`, `…asDouble` bindings.
- Section "Code and raw text" (footer "Applies to code files and Markdown's raw view."): "Width" segmented Auto/Custom — `codeWidthMode` — `.codeWidth`; if custom "Maximum width" 480…2400 px — `codeMaxWidth.asDouble`; "Code alignment" segmented — `codeAlignment` — `.codeAlignment`; "Markdown raw alignment" segmented — `markdownRawAlignment` — `.markdownRawAlignment`

**CopyPane**
- Section "Selecting text": "When you select text" — description = the chosen preset's description — menu of the 8 presets (move the `copyBehaviors` array from `SettingsView.swift` into this file as `private static let presets`) — `copyBehavior` — `.copyBehavior`
- Section "Copied text": "Include line numbers" — "Selections and the header's copy button include line numbers." — toggle — `includeLineNumbersInCopy` — `.copyLineNumbers`

**ShortcutsPane** (keeps the 1.5 s permission poll from `QuickLookFindKeySettings`/`PreviewPanelSettings`, including `SearchKeyInterceptor.shared.start()` when trust appears and the off-main-thread automation check)
- Section "Find in preview": "Find button in preview" — "Adds a search button to the preview header." — toggle — `showSearchButton` — `.findButton`; if on: `SettingsStatusRow(isOK: isSearchActive, title: isSearchActive ? "⌘F search is on" : "⌘F search needs Accessibility access", description: "Press ⌘F in a Quick Look preview to search it.")` — `.findShortcut`
- Section "⌥Space preview": "Preview with ⌥Space" — "Opens dotViewer's own preview of the file selected in Finder, for types macOS won't send to Quick Look (such as .ts)." — toggle — `previewPanelEnabled` — `.spacePanel`
- Section "Permissions" (footer: "Keystrokes are read only after ⌘F or ⌥Space, never stored, and never leave this Mac."): Accessibility status row — "Lets dotViewer see ⌘F and ⌥Space." — actions: "Grant Access…" when missing (prompts), "Open Settings" link-style button (anchor `Privacy_Accessibility`) — `.accessibilityPermission`; Finder status row — "Tells dotViewer which file is selected for ⌥Space. Nothing in Finder changes." — "Grant Access…" when missing, "Open Settings" (`Privacy_Automation`) — `.finderPermission`; under each missing permission: `PermissionTroubleshooting(kind:)`

**AdvancedPane**
- Section "Preview cache": "Preview cache" — "Reuses recently rendered previews." — toggle — `previewCacheEnabled` — `.previewCache`; "Keep previews for" slider 5…600 step 5 `"\(Int) s"`, disabled when cache off — `cacheTTLSeconds.asDouble` — `.cacheLifetime`; "Size limit" slider 10…500 step 10 `"\(Int) MB"`, disabled when off — `cacheMaxMB.asDouble` — `.cacheSize`; `LabeledContent("Cached previews") { Button("Clear Cache") }` — `.clearCache`
- Section "Diagnostics": "Performance logging" — "Writes preview timings to the system log." — toggle — `performanceLogging` — `.performanceLogging`
- Section "Uninstall": `LabeledContent { Button("Uninstall…", role: .destructive) } label: { SettingsLabel("Uninstall dotViewer", description: "Moves dotViewer to the Trash and quits.") }` — `.uninstall`; the button runs the existing `uninstallApp()` alert flow (moved from `SettingsView.swift`)

- [x] **Step 1:** write the seven files. **Step 2:** build app scheme — success. **Step 3:** commit `feat(settings): build the seven settings panes`.

### Task 5: Settings window with sidebar and search

**Files:** Create `dotViewer/App/Settings/SettingsWindow.swift`; Test: `dotViewer/dotViewerTests/SettingsSidebarTests.swift`; `project.yml` test sources: add `App/Settings` (whole folder), `App/PreviewFontMenu.swift`, `App/AppUIFontSizing.swift`, `App/SearchKeyInterceptor.swift`, `App/FinderSelection.swift`, `App/PreviewPanelController.swift`, `App/SearchBridgeServer.swift`, `App/PermissionTroubleshooting.swift`.

**Interfaces — Produces:**
- `struct SettingsWindow: View` (no arguments) — owns `@State model = SettingsModel()`, `@AppStorage("settingsSelectedPane")`.
- `struct SettingsSidebar: View { init(selection: Binding<SettingsPane?>, query: String, onOpen: @escaping (SettingsEntry) -> Void) }` — panes list when `query` is blank, results list otherwise, `ContentUnavailableView.search(text:)` when nothing matches.
- `struct SettingsPaneView: View { init(pane: SettingsPane) }` — routes to the pane view, wraps it in `ScrollViewReader`, scrolls to and highlights `highlightedSetting` from the environment.

```swift
import SwiftUI

struct SettingsWindow: View {
    @AppStorage("settingsSelectedPane") private var storedPane = SettingsPane.general.rawValue
    @State private var selection: SettingsPane?
    @State private var query = ""
    @State private var highlighted: SettingID?
    @State private var model = SettingsModel()

    var body: some View {
        NavigationSplitView {
            SettingsSidebar(selection: $selection, query: query, onOpen: open)
                .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            let pane = selection ?? .general
            SettingsPaneView(pane: pane)
                .environment(model)
                .environment(\.highlightedSetting, highlighted)
                .navigationTitle(pane.title)
        }
        .searchable(text: $query, placement: .sidebar, prompt: "Search")
        .frame(minWidth: 720, minHeight: 500)
        .onAppear { selection = SettingsPane(rawValue: storedPane) ?? .general }
        .onChange(of: selection) { _, pane in if let pane { storedPane = pane.rawValue } }
    }

    private func open(_ entry: SettingsEntry) {
        selection = entry.pane
        highlighted = entry.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            if highlighted == entry.id { highlighted = nil }
        }
    }
}
```

- [x] **Step 1: Write the failing sidebar test** — hosts `SettingsSidebar` with a recording binding in an ordered-in offscreen `NSWindow`, finds the `NSTableView`/`NSOutlineView`, sends real `leftMouseDown`/`leftMouseUp` events to the centre of every row, asserts the recorded selection equals each pane in order; and with `query: "wrap"` asserts clicking the first result calls `onOpen` with `.wordWrap`. (Harness follows `SettingsTabBarTests`' `makeHarness`/event helpers — copy them into the new file before deleting the old one in Task 6.)
- [x] **Step 2:** run — FAIL (types missing). **Step 3:** implement `SettingsWindow.swift` (above + `SettingsSidebar`, `SettingsPaneView`). **Step 4:** run — PASS. **Step 5:** commit `feat(settings): add sidebar settings window with search`.

### Task 6: Wire into the app, remove the old pages

**Files:** Modify `App/dotViewerApp.swift`, `App/ContentView.swift`; delete `App/SettingsView.swift`, `App/MarkdownSettingsView.swift`, `App/SettingsTabPage.swift`, `App/QuickLookFindKeySettings.swift`, `App/PreviewPanelSettings.swift`, `dotViewerTests/SettingsTabBarTests.swift`; `project.yml` test sources: remove `App/SettingsTabPage.swift`.

```swift
// dotViewerApp.body
var body: some Scene {
    WindowGroup {
        ContentView()
            .appUIFontSizing(appUIFontSizePreset)
    }
    Settings {
        SettingsWindow()
            .appUIFontSizing(appUIFontSizePreset)
    }
}
```

```swift
// ContentView: NavigationItem keeps .status and .fileTypes only; sidebar gets a footer
List(NavigationItem.allCases, selection: $selectedItem) { item in
    Label(item.rawValue, systemImage: item.icon).tag(item)
}
.listStyle(.sidebar)
.safeAreaInset(edge: .bottom) { SettingsFooterLink() }

private struct SettingsFooterLink: View {
    var body: some View {
        SettingsLink {
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                Text("Settings")
                Spacer()
                Text("⌘,")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.quaternary))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
}
```

- [x] **Step 1:** make the edits and deletions. **Step 2:** `xcodegen generate`; full test run — PASS (247 − 3 tab-bar tests + new ones). **Step 3:** grep the repo for `SettingsView(`, `MarkdownSettingsView`, `SettingsTabBar` — no hits. **Step 4:** commit `feat(settings): open settings in their own window (⌘,)`.

### Task 7: Snapshots and visual pass

**Files:** Create `dotViewer/dotViewerTests/SettingsSnapshotTests.swift` — skipped unless `DV_SNAPSHOT_DIR` is set; hosts `SettingsWindow` (preselected pane via `UserDefaults.standard` key `settingsSelectedPane`) at 820×640 in light and dark (`NSAppearance(named:)`), renders with `bitmapImageRepForCachingDisplay`/`cacheDisplay`, writes `<pane>-<light|dark>.png`.

- [x] **Step 1:** write the test. **Step 2:** `TEST_RUNNER_DV_SNAPSHOT_DIR=<scratchpad>/snapshots xcodebuild … test -only-testing:dotViewerTests/SettingsSnapshotTests`. **Step 3:** review every PNG against the formula (leading labels, trailing controls, equal insets, no clipped text, consistent section spacing); fix and re-render until clean. **Step 4:** commit `test(settings): render settings panes for review`.

### Task 8: Search ranking (owner's contribution) and docs

- [x] **Step 1:** owner writes `SettingsCatalog.rank(_:tokens:)` (5–10 lines); add a test that pins the chosen order for one query.
- [x] **Step 2:** docs — KNOWN_ISSUES KI-019 (tab bar replaced by a native sidebar list; status stays "awaiting confirmation"), CHANGELOG "Unreleased" entry, CLAUDE.md host-app file list, AGENTS.md work log.
- [x] **Step 3:** full test run — PASS; commit `docs: record the settings window redesign`.
- [x] **Step 4 (owner go-ahead only):** Developer ID build `./scripts/release.sh <ver> --skip-notarize --skip-dmg`, back up `/Applications/dotViewer.app`, install, hands-on check (⌘, and menu item, footer, every pane, search, persistence into a Quick Look preview, interface text sizes).

## Result (2026-09-23)

All tasks done on `feat/settings-window`. Search ranking: titles that contain every typed word first, then pane and keyword matches, each group in catalog order (owner's choice). A local Developer ID 1.5.8 build is installed in `/Applications` (the public 1.5.7 is backed up) and was checked by hand through the accessibility API (`scripts/dotviewer-ax.swift`): ⌘, (a real keystroke), the menu item and the footer open the window; every pane shows the stored values; typed search lists results in the chosen order and opens them; a switch flipped in Settings reaches the Quick Look extension (and was flipped back); Accessibility and Finder access survived the upgrade.

The check found two bugs. Fixed: the sidebar opened at 140 pt and the window at 900 × 532 (`.toolbar(removing:)` must come before the column width; the Settings scene needs `.defaultSize`), now pinned by `SettingsWindowLayoutTests`. Not fixed: "Interface text size" has never had any effect on macOS (KI-020) — a decision for the owner.
