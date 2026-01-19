# Roadmap: dotViewer Bug-Fix Release

## Overview

Fix all known bugs in dotViewer (5 user-reported + discovered issues) while maintaining stability, then optimize performance for a smooth user experience.

## Domain Expertise

None

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3...): Planned milestone work
- Decimal phases (e.g., 2.1): Urgent insertions if needed

- [x] **Phase 1: Foundation & UTI Fixes** - Fix data integrity and file type registration
- [x] **Phase 2: UI Bug Fixes** - Fix user-facing UI issues in settings and preview
- [x] **Phase 3: Performance & Syntax Highlighting** - Improve load times (CRITICAL)
- [x] **Phase 4: App Store Preparation** - Enable sandbox with sandbox-compatible extension detection

## Phase Details

### Phase 1: Foundation & UTI Fixes
**Goal**: Fix data integrity (encoding failures) and file type registration issues
**Depends on**: Nothing (first phase)
**Research**: Unlikely (established patterns)
**Plans**: 3 plans

Plans:
- [x] 01-01: Add common dotfiles to QuickLook Info.plist UTI declarations
- [x] 01-02: Fix silent encoding failures in CustomExtension saving
- [x] 01-03: Fix .ts/.tsx QuickLook preview (investigate UTI priority vs Xcode)

### Phase 2: UI Bug Fixes
**Goal**: Fix edit functionality for custom types (Bug #2), uninstall button styling (Bug #3), and markdown toggle (Bug #5)
**Depends on**: Phase 1 (encoding fix required for custom extension work)
**Research**: Unlikely (SwiftUI patterns, internal code)
**Plans**: 3 plans

Plans:
- [x] 02-01: Add edit capability for custom file type extensions
- [x] 02-02: Apply destructive styling to uninstall button
- [x] 02-03: Fix markdown RAW mode toggle hiding content (pre-existing fix)

### Phase 3: Performance & Syntax Highlighting
**Goal**: Fast syntax highlighting + comprehensive file type support
**Depends on**: Phase 2
**Research**: Complete (extensive research conducted 2026-01-16)
**Plans**: 2 plans — COMPLETE

Plans:
- [x] 03-01: FastSyntaxHighlighter (pure Swift regex-based highlighting)
- [x] 03-02: Comprehensive UTI declarations (100+ file extensions)

**Completed (03-01)**: FastSyntaxHighlighter
- Pure Swift regex-based syntax highlighter
- Zero external dependencies
- Supports 20+ languages
- Falls back to HighlightSwift for unsupported languages
- Performance: <50ms for typical files

**Completed (03-02)**: Comprehensive UTI declarations
- Added 100+ file extension UTI declarations
- QuickLook extension supports all new UTIs
- FileTypeRegistry provides language mappings

### Phase 4: App Store Preparation
**Goal**: Re-enable sandbox for App Store distribution
**Depends on**: Phase 3
**Research**: Complete (no public API for extension status in sandbox)
**Plans**: 1 plan — COMPLETE

Plans:
- [x] 04-01: Enable App Sandbox and replace pluginkit with static setup guide

**Completed (04-01)**: App Sandbox Enablement
- Enabled App Sandbox (com.apple.security.app-sandbox: true)
- Replaced pluginkit-based ExtensionStatusChecker with sandbox-safe ExtensionHelper
- StatusView shows static setup guide with numbered steps
- No temporary exception entitlements (App Store compliant)
- App runs without sandbox violations

## Removed/Skipped Items

The following were removed from the roadmap:

**Already implemented:**
- ~~.mjs, .cjs, .mts, .cts mappings~~ — Already in `LanguageDetector.swift:34-40`
- ~~.env syntax highlighting~~ — Already in `LanguageDetector.swift:121, 159-164`

**False issues:**
- ~~Consolidate duplicate initializers~~ — Two initializers serve different purposes (new objects vs Codable)

**Skipped:**
- ~~Phase 3: QA/Verification~~ — Tested during development, not needed as separate phase

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & UTI Fixes | 3/3 | Complete | 2026-01-15 |
| 2. UI Bug Fixes | 3/3 | Complete | 2026-01-16 |
| 3. Performance & Syntax | 2/2 | Complete | 2026-01-19 |
| 4. App Store Preparation | 1/1 | Complete | 2026-01-19 |

**Total Plans:** 9/9 complete (100%)

**MILESTONE COMPLETE** - All 4 phases finished, ready for App Store submission.
