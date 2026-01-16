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
- ✓ TypeScript/JS variants (.mjs, .cjs, .mts, .cts mappings) — already implemented
- ✓ .env file syntax highlighting — already implemented

### Completed (Phase 1 & 2)

- [x] Bug #1: Custom file types activate after being added — 01-01 done
- [x] Bug #2: Users can edit custom file types — 02-01 done
- [x] Bug #3: Uninstall button has proper destructive styling — 02-02 done
- [x] Bug #4: TypeScript/TSX QuickLook preview works — 01-03 done
- [x] Bug #5: Markdown RAW mode toggle doesn't hide content — pre-existing fix
- [x] Fix silent encoding failures when saving custom extensions — 01-02 done

### Active (Phase 3)

- [ ] Performance: QuickLook preview loads in <200ms (currently 1-2s)
- [ ] Evaluate faster syntax highlighting alternatives

### Deferred (Phase 4)

- [ ] App Store: Re-enable sandbox with proper extension detection APIs

### Out of Scope

- New features — this is a bug-fix only release
- Dynamic UTI registration at runtime — too complex, using pre-registered patterns instead
- Automated test suite — manual QA is the verification method

## Context

**Codebase:**
- Swift 5.0 / SwiftUI / macOS 13.0+
- Two-target architecture: Main app + QuickLook extension
- App Groups for inter-process settings sync
- HighlightSwift for syntax highlighting (JS-based, slow)

**Performance Issue Identified:**
- 1-2 seconds to load 10-30KB files
- Root cause: HighlightSwift uses JavaScript (highlight.js) with bridge overhead
- Alternatives: andre-simon Highlight (native C++), pure Swift regex

**Key Files:**
- `QuickLookPreview/Info.plist` — UTI registrations
- `Shared/LanguageDetector.swift` — extension → language mapping
- `Shared/SharedSettings.swift` — CustomExtension model & encoding
- `Shared/SyntaxHighlighter.swift` — highlighting integration
- `QuickLookPreview/PreviewViewController.swift` — file loading
- `QuickLookPreview/PreviewContentView.swift` — highlighting orchestration

## Constraints

- **Non-breaking**: Every fix must be verified to not regress existing functionality
- **Manual QA**: User will test each fix before shipping
- **No automated tests**: Manual verification is the QA process

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pre-register common dotfiles in Info.plist | Dynamic UTI registration too complex for QuickLook | ✓ Done in 01-01 |
| Fix encoding failures before UI work | Data integrity is foundational | ✓ Done in 01-02 |
| Extension name not editable in edit sheet | Serves as unique identifier | ✓ Done in 02-01 |
| Skip QA phase | Tested during development | Removed from roadmap |
| Prioritize performance over App Store | User retention depends on fast previews | Phase 3 = Performance |
| Profile before library switch | Confirm JS bridge is the actual bottleneck | Planned in 03-01 |

---
*Last updated: 2026-01-16 after Phase 2 completion and roadmap reorg*
