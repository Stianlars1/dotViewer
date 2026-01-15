# dotViewer Bug-Fix Release

## What This Is

A bug-fix release for dotViewer, a macOS app with a QuickLook extension that provides syntax-highlighted previews of dotfiles and source code. This release addresses 5 user-reported bugs plus additional issues discovered during codebase exploration.

## Core Value

Fix all known bugs without breaking existing functionality — every fix must be verified to not regress current behavior.

## Requirements

### Validated

- ✓ QuickLook preview of 70+ file types with syntax highlighting — existing
- ✓ Theme support (10 themes, auto/light/dark modes) — existing
- ✓ Markdown rendering with raw/rendered toggle — existing
- ✓ Custom file type registration via app UI — existing
- ✓ Sensitive file detection and warning banners — existing

### Active

- [ ] Bug #1: Custom file types activate after being added (add common dotfiles to Info.plist)
- [ ] Bug #2: Users can edit custom file types (not just delete)
- [ ] Bug #3: Uninstall button has proper destructive styling
- [ ] Bug #4: TypeScript/JS variants work (.mjs, .cjs, .mts, .cts mappings)
- [ ] Bug #5: Markdown RAW mode toggle doesn't hide content
- [ ] Fix silent encoding failures when saving custom extensions
- [ ] Consolidate duplicate CustomExtension initializers
- [ ] Fix file size bounds checking inconsistency
- [ ] Remove unused import in ContentView

### Out of Scope

- New features — this is a bug-fix only release
- Dynamic UTI registration at runtime — too complex, using pre-registered patterns instead
- Automated test suite — manual QA is the verification method

## Context

**Codebase:**
- Swift 5.0 / SwiftUI / macOS 13.0+
- Two-target architecture: Main app + QuickLook extension
- App Groups for inter-process settings sync
- HighlightSwift for syntax highlighting

**Root Causes Identified:**
- Bug #1: Custom extensions stored in UserDefaults but not declared in QuickLook Info.plist — macOS doesn't route those files to the extension
- Bug #4: LanguageDetector.extensionMap missing .mjs, .cjs, .mts, .cts entries
- Bug #5: Likely SwiftUI view state/focus issue when toggling preview modes

**Key Files:**
- `QuickLookPreview/Info.plist` — UTI registrations
- `Shared/LanguageDetector.swift` — extension → language mapping
- `dotViewer/FileTypesView.swift` — custom extension UI
- `dotViewer/ContentView.swift` — settings UI including uninstall button
- `QuickLookPreview/PreviewContentView.swift` — markdown preview toggle
- `Shared/SharedSettings.swift` — CustomExtension model

## Constraints

- **Non-breaking**: Every fix must be verified to not regress existing functionality
- **Manual QA**: User will test each fix before shipping
- **No automated tests**: Manual verification is the QA process

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pre-register common dotfiles in Info.plist | Dynamic UTI registration too complex for QuickLook | — Pending |
| Comprehensive depth with parallel execution | User wants thorough coverage, efficient execution | — Pending |
| YOLO mode | Auto-approve execution for speed | — Pending |

---
*Last updated: 2026-01-15 after initialization*
