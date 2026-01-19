# dotViewer

## What This Is

A macOS app with a QuickLook extension that provides syntax-highlighted previews of dotfiles and source code. Supports 100+ file extensions with fast, native Swift syntax highlighting.

## Core Value

Fast, beautiful code previews in Finder — press Space on any code file to see syntax-highlighted content instantly.

## Current State (v1.0)

**Shipped:** 2026-01-19

**Capabilities:**
- QuickLook preview of 100+ file types with syntax highlighting
- FastSyntaxHighlighter: <50ms native Swift highlighting for 20+ languages
- Theme support (10 themes, auto/light/dark modes)
- Markdown rendering with raw/rendered toggle
- Custom file type registration via app UI
- Sensitive file detection and warning banners
- App Sandbox enabled for Mac App Store

**Tech Stack:**
- Swift 5.0 / SwiftUI / macOS 13.0+
- Two-target architecture: Main app + QuickLook extension
- App Groups for inter-process settings sync
- FastSyntaxHighlighter (primary) + HighlightSwift (fallback)

**Codebase:**
- 5,426 lines of Swift
- 48 files

## Requirements

### Validated

- QuickLook preview of 100+ file types with syntax highlighting — v1.0
- Theme support (10 themes, auto/light/dark modes) — v1.0
- Markdown rendering with raw/rendered toggle — v1.0
- Custom file type registration via app UI — v1.0
- Sensitive file detection and warning banners — v1.0
- TypeScript/JS variants (.mjs, .cjs, .mts, .cts mappings) — v1.0
- .env file syntax highlighting — v1.0
- Bug #1: Custom file types activate after being added — v1.0
- Bug #2: Users can edit custom file types — v1.0
- Bug #3: Uninstall button has proper destructive styling — v1.0
- Bug #4: TypeScript/TSX QuickLook preview works — v1.0
- Bug #5: Markdown RAW mode toggle doesn't hide content — v1.0
- Performance: QuickLook preview loads in <50ms — v1.0
- App Sandbox enabled for Mac App Store — v1.0

### Active

None — milestone complete, ready for new requirements.

### Out of Scope

- Dynamic UTI registration at runtime — too complex, using pre-registered patterns instead
- Automated test suite — manual QA is the verification method
- Video chat integration — not relevant to code preview tool

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pre-register common dotfiles in Info.plist | Dynamic UTI registration too complex for QuickLook | Done in 01-01 |
| Fix encoding failures before UI work | Data integrity is foundational | Done in 01-02 |
| Extension name not editable in edit sheet | Serves as unique identifier | Done in 02-01 |
| Skip QA phase | Tested during development | Removed from roadmap |
| Prioritize performance over App Store | User retention depends on fast previews | Phase 3 = Performance |
| Abandon Syntect/Rust approach | 3 failed integration attempts, complexity too high | Pivoted to FastSyntaxHighlighter |
| Abandon Tree-sitter + Neon | Similar complexity to Syntect (10+ packages, query files) | Pivoted to FastSyntaxHighlighter |
| FastSyntaxHighlighter | Pure Swift regex approach, zero dependencies, proven codebase pattern | Done in 03-01 |
| Static setup guide over live detection | No sandbox-friendly API for extension status | Done in 04-01 |

## Constraints

- **App Store compliance**: Must maintain sandbox for distribution
- **Manual QA**: User tests each release before shipping
- **No automated tests**: Manual verification is the QA process

---
*Last updated: 2026-01-19 after v1.0 milestone*
