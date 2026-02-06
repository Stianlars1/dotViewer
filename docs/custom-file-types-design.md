# Design: Improving User-Custom File Type Support

## Status

Draft -- focused on improvements to the existing custom types system.

## Context: What Already Works

dotViewer already has a functional custom file type system:

- **Model**: `CustomExtension` in `FileTypeModels.swift` -- stores `extensionName`, `displayName`, `highlightLanguage`.
- **Storage**: `SharedSettings.customExtensions` persists a `[CustomExtension]` array in App Group UserDefaults, accessible by both the host app and Quick Look extensions.
- **Registry integration**: `FileTypeRegistry.highlightLanguage(for:)` checks custom extensions first, before built-in types. `FileTypeResolution.bestKey(for:)` calls `highlightLanguage(for:)`, so custom extensions participate in routing.
- **UI**: `FileTypesView` has an "Add Custom" button, a "Custom" disclosure group with edit/delete per entry. `AddCustomExtensionSheet` and `EditCustomExtensionSheet` provide forms with extension field, display name, and a language picker (`HighlightLanguage.all`, 30 options).
- **Validation**: Reserved system extensions are blocked, length limits enforced, duplicate detection for both built-in and custom types.
- **`isKnownType` bug**: Already fixed by the team lead -- `PreviewProvider.swift` and `ThumbnailProvider.swift` now check `highlightLanguage(for:)` in addition to `fileType(for:)`.

## Issue 1: `HighlightLanguage.all` is out of sync with available grammars

### Current state

Three separate lists define "available languages" at different layers:

| Layer | Where | Count | What it contains |
|-------|-------|-------|-----------------|
| **Tree-sitter grammars (compiled)** | `project.yml` HighlightXPC sources + `TreeSitterHighlighter.loadConfigs()` | 14 | swift, python, javascript, typescript, tsx, json, yaml, markdown, bash, html, css, xml, ini, toml |
| **Tree-sitter grammars (vendored but not compiled)** | `TreeSitterVendor/` directories | ~15 more | c, cpp, c-sharp, go, java, kotlin, lua, perl, php, r, ruby, rust, scala, sql, dockerfile |
| **Picker list** | `HighlightLanguage.all` in `FileTypeModels.swift` | 30 | The 14 compiled + 16 others (c, cpp, csharp, diff, dockerfile, go, graphql, java, kotlin, lua, makefile, nginx, objectivec, perl, php, ruby, rust, scala, scss, sql) |
| **DefaultFileTypes.json** | `highlightLanguage` field across 300+ entries | ~200 distinct values | abap, actionscript, ada, applescript, ... (vast long tail) |

The key mismatch: **the picker offers 30 languages, but only 14 have tree-sitter grammars with `.scm` query files**. The other 16 in the picker (and the ~170 from DefaultFileTypes.json) fall through to the heuristic fallback highlighter.

### What happens when a user picks a language without a tree-sitter grammar

The flow in `TreeSitterHighlighter.highlight()`:

1. Looks up `configs[language]` -- not found for non-compiled languages.
2. If language is not "plaintext" and not empty, runs `fallbackHighlightCaptures()`.
3. The fallback scanner highlights comments (`//`, `#`, `--`, `/* */`), strings, numbers, and ~80 common keywords.
4. Returns HTML with `tok-comment`, `tok-string`, `tok-number`, `tok-keyword` spans.

**This is acceptable behavior.** The heuristic highlighter produces reasonable results for most programming languages. It is significantly better than plain text. Users are not left with zero highlighting.

### Recommendation

**Do NOT restrict the picker to only compiled grammars.** The heuristic fallback is good enough that users benefit from mapping any extension to any language -- even one without a tree-sitter grammar. However, the UI should clearly communicate the quality tier.

Specific changes:

**A. Add a visual indicator in the language picker.**
Group or annotate languages by highlighting quality:

- Languages with tree-sitter grammars (14): show as-is, no annotation needed -- these are the default/best.
- Languages in the picker but without tree-sitter: show a subtle "(basic)" suffix. Example: `"Go (basic)"`, `"Rust (basic)"`.
- Alternatively, use section headers in the picker: "Full Highlighting" and "Basic Highlighting".

This sets correct expectations without limiting functionality.

**B. Keep `HighlightLanguage.all` as a curated list, not auto-generated.**
Auto-generating from DefaultFileTypes.json would produce ~200 entries, most of which are obscure (ABAP, COBOL, Fortran77). The curated list of 30 covers the languages users are most likely to want. If a user needs a language not in the picker, they can still get heuristic highlighting by picking any similar language, or "Plain Text" for no highlighting.

**C. Update the picker when new grammars are compiled.**
When the grammar-expander task (Task #1) adds new compiled grammars (e.g., go, rust, c, cpp, ruby, etc.), `HighlightLanguage.all` should be updated to reflect that those languages now have full tree-sitter support. Remove the "(basic)" suffix for newly compiled languages. This is a manual process tied to the build -- not a runtime concern.

**D. Consider adding 5-10 more languages to the picker.**
Currently missing from the picker but commonly requested: `hcl` (Terraform), `toml` (already compiled but not in picker -- wait, it IS in the compiled list but NOT in `HighlightLanguage.all`), `dockerfile` (in picker, not compiled -- but vendored). Also consider: `elixir`, `r`, `dart`, `nix`.

Specifically, `toml` IS compiled with a tree-sitter grammar but is NOT in `HighlightLanguage.all`. This should be added immediately.

## Issue 2: Filename-based mappings

### The problem

Users encounter files that have no extension or whose identity is determined by the full filename:

- `Dockerfile`, `Dockerfile.dev`, `Dockerfile.prod`
- `Jenkinsfile`
- `Brewfile`, `Gemfile`, `Rakefile`
- `Caddyfile`, `Vagrantfile`, `Procfile`
- `.gitignore`, `.dockerignore`, `.eslintrc`
- `Makefile`, `CMakeLists.txt`
- `justfile`, `Taskfile`

The built-in `DefaultFileTypes.json` and legacy list handle many of these via the `filenames` field in `SupportedFileType`. But the **custom extension system has no filename support** -- `CustomExtension` only has `extensionName`.

### How existing filename resolution works

`FileTypeResolution.bestKey(for:)` already tries filename-based lookup:

1. Tries `pathExtension` (e.g., "dev" for `Dockerfile.dev`).
2. Tries full filename without leading dot (e.g., "dockerfile.dev").
3. Tries filename prefix before first dot (e.g., "dockerfile").

At each step, it checks `registry.highlightLanguage(for:candidate)` and `registry.fileType(for:candidate)`.

The built-in registry maps filenames to types during init by adding filename entries to `extensionToType`. But `highlightLanguage(for:)` only checks custom extensions by `extensionName` -- it does not check against filenames.

### Recommendation

**Add a `matchType` discriminator to `CustomExtension`**, allowing either extension or filename matching:

```swift
public struct CustomExtension: Identifiable, Codable, Hashable {
    public let id: UUID
    public var extensionName: String      // used for extension matching
    public var filenameMatch: String?     // NEW: used for filename matching (e.g., "Jenkinsfile")
    public var displayName: String
    public var highlightLanguage: String
}
```

Make `filenameMatch` optional so existing serialized data decodes without migration.

**Registry changes:**

In `FileTypeRegistry.highlightLanguage(for:)`, after checking `extensionName`, also check `filenameMatch`:

```swift
public func highlightLanguage(for ext: String) -> String? {
    let lowered = ext.lowercased()
    let customs = SharedSettings.shared.customExtensions
    // Check extension match
    if let custom = customs.first(where: { $0.extensionName == lowered }) {
        return custom.highlightLanguage
    }
    // Check filename match
    if let custom = customs.first(where: { $0.filenameMatch?.lowercased() == lowered }) {
        return custom.highlightLanguage
    }
    return extensionToType[lowered]?.highlightLanguage
}
```

This works because `FileTypeResolution.bestKey(for:)` already passes the full filename (without leading dot) as a candidate to `highlightLanguage(for:)`. So if a user adds a custom mapping with `filenameMatch: "jenkinsfile"`, and the file is named `Jenkinsfile`, the bestKey method will try candidate `"jenkinsfile"` and find the custom mapping.

**UI changes in `AddCustomExtensionSheet`:**

Add a segmented picker at the top:

```
Match by:  [ Extension ]  [ Filename ]
```

- **Extension mode** (default): current behavior. Shows `"."` prefix, text field placeholder "Extension (e.g. tsx)".
- **Filename mode**: hides `"."` prefix, text field placeholder "Filename (e.g. Jenkinsfile)". Saves to `filenameMatch` instead of `extensionName`.

Validation for filename mode:
- Allow dots (e.g., `docker-compose.yml` -- though this is better as an extension mapping).
- Allow leading dots (e.g., `.prettierrc`).
- Block reserved system filenames (`.DS_Store`, `Thumbs.db`).
- Max length ~60 characters.

**Display in FileTypesView:**

Filename-based custom entries show the filename directly (e.g., `Jenkinsfile`) instead of `.ext` format. Use a different icon or badge to distinguish from extension-based entries.

### Priority

Medium. Most common filenames are already in `DefaultFileTypes.json`. This is a nice-to-have for edge cases like `Jenkinsfile` or custom internal filenames.

## Issue 3: Cannot override built-in type mappings

### The problem

`AddCustomExtensionSheet.addExtension()` blocks adding an extension that exists in the built-in registry:

```swift
if FileTypeRegistry.shared.fileType(for: ext) != nil {
    errorMessage = "This extension is already supported as a built-in type."
    showError = true
    return
}
```

This prevents users from overriding the highlight language for built-in types. Example: a user wants `.conf` files highlighted as YAML instead of the built-in INI mapping.

### Why overrides work at the registry level but are blocked by the UI

`FileTypeRegistry.highlightLanguage(for:)` checks custom extensions **before** built-in types. So if a custom extension for "conf" exists, it wins. The UI is the only thing preventing this.

### Recommendation

**Replace the hard block with a confirmation warning.**

In `addExtension()`:

```swift
if let builtIn = FileTypeRegistry.shared.fileType(for: ext) {
    // Show confirmation instead of blocking
    overrideTarget = builtIn  // triggers a confirmation alert
    return
}
```

The confirmation alert:

> "`.conf` is already mapped to **INI/Config**. Adding a custom mapping will override the built-in highlighting for all `.conf` files. Continue?"
>
> [Cancel] [Override]

**Display overridden types distinctly in FileTypesView:**

- Show an "Override" badge (blue) instead of the default orange custom badge.
- Include the original built-in language in the subtitle: "Overrides built-in: INI/Config".
- Add a "Reset to Default" context menu option that deletes the custom entry, restoring the built-in mapping.

### Priority

Medium-high. This is a common user expectation and low effort to implement.

## Issue 4: UX improvements to AddCustomExtensionSheet

### 4a. Auto-suggest display name

When the user types an extension, auto-fill the display name if the extension is recognizable. For example:
- User types "prisma" -> suggest "Prisma" as display name.
- User types "hurl" -> suggest "Hurl" as display name.

Simple heuristic: capitalize the first letter of the extension. This saves a step for the common case where the display name matches the extension.

Implementation: add an `onChange(of: extensionName)` handler that sets `displayName` if it is currently empty or was auto-generated (track with a boolean `displayNameIsAutoGenerated`).

### 4b. Show a preview of what highlighting will look like

Below the language picker, show a small code sample rendered with the selected language's highlighting. This helps users pick the right language for unfamiliar mappings (e.g., "should I use YAML or INI for my config format?").

This requires calling the XPC highlighter from the host app, which adds complexity. **Defer this to a later phase.** A simpler alternative: show 2-3 lines of static text indicating which token types the language covers (e.g., "Highlights: keywords, strings, comments, types").

### 4c. Improve the language picker ordering

Currently `HighlightLanguage.all` is alphabetical. Better ordering:
1. "Plain Text" always first (it is currently).
2. Group by highlighting quality: tree-sitter languages first, then heuristic-only.
3. Within each group, alphabetical.

### 4d. Search/filter in the language picker

With 30 items, the macOS `.menu` picker style is manageable. If the list grows beyond ~40, consider switching to a searchable picker or a list with a filter field. For now, the current approach is fine.

### Priority

Low. These are polish items. The existing sheet is functional.

## Issue 5: Edge cases and robustness

### 5a. Custom extension with dots in the name

The `cleanedExtension` strips leading dots but the `invalidExtensionChars` includes `.` as invalid. This means users cannot add multi-dot extensions like `env.local` through the Add sheet, even though `FileTypeResolution.bestKey(for:)` supports them.

**Fix:** Allow dots within the extension name (remove `.` from `invalidExtensionChars`). Keep the existing `..` rejection. Add validation that the extension doesn't start or end with a dot after trimming.

This lets users add mappings for `env.local`, `env.production`, etc.

### 5b. SharedSettings.customExtensions read frequency

`FileTypeRegistry.highlightLanguage(for:)` reads `SharedSettings.shared.customExtensions` on every call. This means every preview request deserializes the JSON from UserDefaults. With 0-50 custom extensions this is negligible (~0.1ms). If the list grows large, consider caching the decoded array with a generation counter. **No action needed now.**

### 5c. What happens if a user deletes a custom extension while a preview is in progress

The preview uses the language ID that was resolved at request start. Deleting the custom extension mid-preview does not affect the in-flight request. The next preview will use the updated settings. **No issue.**

### 5d. Race between host app writes and extension reads

`SharedSettings` uses `NSLock` for thread safety within a process. Between processes (host app vs. Quick Look extension), UserDefaults handles synchronization via `CFPreferencesAppSynchronize`. There may be a brief window where a newly added custom extension is not visible to the extension. A `qlmanage -r` (Quick Look reset) or simply re-previewing the file resolves this. **Acceptable behavior, document if users report issues.**

## Summary: Recommended Changes by Priority

### P0 -- Do now (already done by team lead)

- [x] Fix `isKnownType` check in `PreviewProvider.swift` and `ThumbnailProvider.swift`.

### P1 -- Small, high-value improvements

1. **Add `toml` to `HighlightLanguage.all`.** It has a compiled tree-sitter grammar but is missing from the picker. One-line addition.

2. **Allow dots in extension names.** Remove `.` from `invalidExtensionChars` in `AddCustomExtensionSheet`. Enables `env.local` etc. ~5 lines changed.

3. **Allow overriding built-in types.** Replace hard block in `addExtension()` with a confirmation dialog. ~20 lines changed.

4. **Fix display name for custom types in preview header.** In `PreviewProvider`, look up `customExtensions` for display name when `fileType(for:)` returns nil. ~3 lines changed.

### P2 -- Medium-value improvements

5. **Add "(basic)" annotation to non-tree-sitter languages in picker.** Helps users understand highlighting quality tiers. ~10 lines changed in `HighlightLanguage.all`.

6. **Auto-suggest display name from extension.** Add `onChange` handler in `AddCustomExtensionSheet`. ~10 lines.

7. **Filename-based custom mappings.** Add `filenameMatch` field, UI mode toggle, registry lookup. ~50-80 lines across 3-4 files.

### P3 -- Lower priority

8. **Import/export custom types as JSON.** ~40-60 lines for NSSavePanel/NSOpenPanel integration in FileTypesView.

9. **"Reset to Default" for overridden built-in types.** Context menu in custom extension rows. ~15 lines.

10. **Preview sample in Add sheet.** Requires XPC call from host app. Significant complexity for marginal UX gain. Defer.

## Appendix: Grammar Coverage Comparison

### Compiled tree-sitter grammars (full highlighting, 14 languages)

bash, css, html, ini, javascript, json, markdown, python, swift, toml, tsx, typescript, xml, yaml

### Vendored but not yet compiled (~15 grammars in TreeSitterVendor/)

c, cpp, c-sharp, dockerfile, go, java, kotlin, lua, perl, php, r, ruby, rust, scala, sql

Note: Task #1 (grammar-expander) is actively adding more of these.

### In HighlightLanguage.all picker but not compiled (heuristic fallback)

c, cpp, csharp, diff, dockerfile, go, graphql, java, kotlin, lua, makefile, nginx, objectivec, perl, php, ruby, rust, scala, scss, sql

### In picker AND compiled (best quality)

bash, css, html, ini, javascript, json, markdown, python, swift, typescript, tsx, xml, yaml

### Missing from picker but compiled

**toml** -- should be added to picker immediately.
