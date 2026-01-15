# Roadmap: dotViewer Bug-Fix Release

## Overview

Fix all known bugs in dotViewer (5 user-reported + 4 discovered issues) while maintaining stability. Each phase groups related fixes for efficient testing, culminating in a verification pass to ensure no regressions.

## Domain Expertise

None

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, 4): Planned milestone work
- Decimal phases (e.g., 2.1): Urgent insertions if needed

- [ ] **Phase 1: Info.plist & UTI Fixes** - Fix file type registration and language detection
- [ ] **Phase 2: UI Bug Fixes** - Fix user-facing UI issues in settings and preview
- [ ] **Phase 3: Code Quality Fixes** - Address silent failures and code inconsistencies
- [ ] **Phase 4: Verification & Polish** - Final QA pass ensuring no regressions

## Phase Details

### Phase 1: Info.plist & UTI Fixes
**Goal**: Fix custom file type activation (Bug #1) and TypeScript/JS variant detection (Bug #4)
**Depends on**: Nothing (first phase)
**Research**: Unlikely (Info.plist configuration, established patterns)
**Plans**: 2 plans

Plans:
- [ ] 01-01: Add common dotfiles to QuickLook Info.plist UTI declarations
- [ ] 01-02: Add .mjs, .cjs, .mts, .cts mappings to LanguageDetector.extensionMap

### Phase 2: UI Bug Fixes
**Goal**: Fix edit functionality for custom types (Bug #2), uninstall button styling (Bug #3), and markdown toggle (Bug #5)
**Depends on**: Phase 1
**Research**: Unlikely (SwiftUI patterns, internal code)
**Plans**: 3 plans

Plans:
- [ ] 02-01: Add edit capability for custom file type extensions
- [ ] 02-02: Apply destructive styling to uninstall button
- [ ] 02-03: Fix markdown RAW mode toggle hiding content

### Phase 3: Code Quality Fixes
**Goal**: Fix silent encoding failures, consolidate duplicate initializers, fix bounds checking, remove unused import
**Depends on**: Phase 2
**Research**: Unlikely (code cleanup, established patterns)
**Plans**: 2 plans

Plans:
- [ ] 03-01: Fix silent encoding failures in CustomExtension saving
- [ ] 03-02: Consolidate duplicate initializers, fix bounds checking, remove unused import

### Phase 4: Verification & Polish
**Goal**: Final verification pass ensuring all fixes work and no regressions introduced
**Depends on**: Phase 3
**Research**: Unlikely (QA verification)
**Plans**: 1 plan

Plans:
- [ ] 04-01: Comprehensive QA checklist and verification

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Info.plist & UTI Fixes | 0/2 | Not started | - |
| 2. UI Bug Fixes | 0/3 | Not started | - |
| 3. Code Quality Fixes | 0/2 | Not started | - |
| 4. Verification & Polish | 0/1 | Not started | - |
