# Roadmap: dotViewer Bug-Fix Release

## Overview

Fix all known bugs in dotViewer (5 user-reported + discovered issues) while maintaining stability. Each phase groups related fixes for efficient testing, culminating in a verification pass to ensure no regressions.

## Domain Expertise

None

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3...): Planned milestone work
- Decimal phases (e.g., 2.1): Urgent insertions if needed

- [ ] **Phase 1: Foundation & UTI Fixes** (In progress) - Fix data integrity and file type registration
- [ ] **Phase 2: UI Bug Fixes** - Fix user-facing UI issues in settings and preview
- [ ] **Phase 3: Verification & Polish** - Final QA pass ensuring no regressions
- [ ] **Phase 4: App Store Preparation** - Enable sandbox with sandbox-compatible extension detection
- [ ] **Phase 5: Performance & Syntax Highlighting** - Improve load times and evaluate better highlighting libraries

## Phase Details

### Phase 1: Foundation & UTI Fixes
**Goal**: Fix data integrity (encoding failures) and file type registration issues
**Depends on**: Nothing (first phase)
**Research**: Unlikely (established patterns)
**Plans**: 3 plans

Plans:
- [x] 01-01: Add common dotfiles to QuickLook Info.plist UTI declarations
- [x] 01-02: Fix silent encoding failures in CustomExtension saving
- [ ] 01-03: Fix .ts/.tsx QuickLook preview (investigate UTI priority vs Xcode)

**Note**: 01-02 was moved from Phase 3 (was 03-01) because it's foundational — must be fixed before any custom extension UI work.

### Phase 2: UI Bug Fixes
**Goal**: Fix edit functionality for custom types (Bug #2), uninstall button styling (Bug #3), and markdown toggle (Bug #5)
**Depends on**: Phase 1 (encoding fix required for custom extension work)
**Research**: Unlikely (SwiftUI patterns, internal code)
**Plans**: 3 plans (can parallelize)

Plans:
- [ ] 02-01: Add edit capability for custom file type extensions
- [ ] 02-02: Apply destructive styling to uninstall button
- [ ] 02-03: Fix markdown RAW mode toggle hiding content

### Phase 3: Verification & Polish
**Goal**: Final verification pass ensuring all fixes work and no regressions introduced
**Depends on**: Phase 2
**Research**: Unlikely (QA verification)
**Plans**: 1 plan

Plans:
- [ ] 03-01: Comprehensive QA checklist and verification

### Phase 4: App Store Preparation
**Goal**: Re-enable sandbox with sandbox-compatible extension status detection for App Store distribution
**Depends on**: Phase 3
**Research**: Likely (Apple APIs for extension status in sandboxed apps)
**Plans**: 1 plan

Plans:
- [ ] 04-01: Implement sandbox-compatible extension status detection using Apple APIs

**Background**: Sandbox was disabled to allow `pluginkit` shell command to work. For App Store distribution, need to re-enable sandbox and use proper Apple APIs (ExtensionKit, Launch Services, or UTType APIs) to detect extension status.

### Phase 5: Performance & Syntax Highlighting
**Goal**: Improve file loading performance (currently 1-2s for 10-30kb files) and evaluate better syntax highlighting libraries
**Depends on**: Phase 4
**Research**: Likely (performance profiling, library evaluation)
**Plans**: 2 plans

Plans:
- [ ] 05-01: Investigate and fix slow file loading (profile, identify bottlenecks)
- [ ] 05-02: Evaluate syntax highlighting alternatives (HighlightSwift vs highlight/andre-simon.de)

**References:**
- SourceCodeSyntaxHighlight: https://github.com/sbarex/SourceCodeSyntaxHighlight
- highlight by andre-simon.de: http://andre-simon.de/doku/highlight/en/highlight.php

## Removed Items (Already Done or False Issues)

The following were removed from the roadmap after codebase analysis:
- ~~01-02: .mjs, .cjs, .mts, .cts mappings~~ — Already implemented in `LanguageDetector.swift:34-40`
- ~~01-04: .env syntax highlighting~~ — Already implemented in `LanguageDetector.swift:121, 159-164`
- ~~03-02: Consolidate duplicate initializers~~ — False issue: two initializers serve different purposes (new objects vs Codable)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & UTI Fixes | 2/3 | In progress | - |
| 2. UI Bug Fixes | 0/3 | Not started | - |
| 3. Verification & Polish | 0/1 | Not started | - |
| 4. App Store Preparation | 0/1 | Not started | - |
| 5. Performance & Syntax | 0/2 | Not started | - |

**Total Plans:** 10 (reduced from 14 after removing already-done items)
