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
- [ ] **Phase 3: Performance & Syntax Highlighting** - Improve load times (CRITICAL)
- [ ] **Phase 4: App Store Preparation** - Enable sandbox with sandbox-compatible extension detection

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
**Goal**: Improve file loading performance (currently 1-2s for 10-30kb files) and evaluate better syntax highlighting libraries
**Depends on**: Phase 2
**Research**: Likely (performance profiling, library evaluation)
**Plans**: 3 plans

Plans:
- [ ] 03-01: Profile and identify performance bottlenecks
- [ ] 03-02: Implement lazy/chunked loading for instant preview
- [ ] 03-03: Evaluate and implement faster syntax highlighting

**Problem**: QuickLook previews take 1-2 seconds for small files (10-30KB). Users expect instant previews.

**Research Findings:**
- Current: HighlightSwift (JavaScript bridge via highlight.js) - SLOW
- Alternative 1: Andre-simon Highlight (native C++) - Fast, used by SourceCodeSyntaxHighlight
- Alternative 2: Pure Swift regex (CodeColors approach) - "Lightning fast"
- Root cause likely: JavaScript execution overhead

**References:**
- SourceCodeSyntaxHighlight: https://github.com/sbarex/SourceCodeSyntaxHighlight
- CodeColors: https://github.com/Oil3/CodeColors-Quicklook-Syntax-Highlighting
- highlight by andre-simon.de: http://andre-simon.de/doku/highlight/en/highlight.php

### Phase 4: App Store Preparation
**Goal**: Re-enable sandbox with sandbox-compatible extension status detection for App Store distribution
**Depends on**: Phase 3
**Research**: Likely (Apple APIs for extension status in sandboxed apps)
**Plans**: 1 plan

Plans:
- [ ] 04-01: Implement sandbox-compatible extension status detection using Apple APIs

**Background**: Sandbox was disabled to allow `pluginkit` shell command to work. For App Store distribution, need to re-enable sandbox and use proper Apple APIs (ExtensionKit, Launch Services, or UTType APIs) to detect extension status.

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
| 3. Performance & Syntax | 0/3 | Not started | - |
| 4. App Store Preparation | 0/1 | Not started | - |

**Total Plans:** 10 → 7 remaining after removing duplicates and skipping QA
