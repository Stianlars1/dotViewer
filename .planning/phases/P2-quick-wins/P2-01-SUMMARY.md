---
phase: P2-quick-wins
plan: 01
subsystem: detection, highlighting
tags: [plist, xml, xcode, uti, auto-detection, performance]

# Dependency graph
requires:
  - phase: P1-diagnostics
    provides: baseline measurements, bottleneck analysis
provides:
  - Direct extension mappings for Apple/Xcode file types
  - Xcode UTI registration for QuickLook
  - Disabled auto-detection for unknown languages
affects: [P3-cache, P4-highlighter]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Direct extension mapping over content detection"
    - "Explicit language fallback to plaintext over auto-detection"

key-files:
  created: []
  modified:
    - Shared/LanguageDetector.swift
    - QuickLookPreview/Info.plist
    - Shared/SyntaxHighlighter.swift

key-decisions:
  - "Use plaintext as fallback instead of HighlightSwift auto-detection"
  - "Add all Xcode system UTIs rather than custom UTIs"

patterns-established:
  - "Always pass explicit language to highlighter"
  - "Prefer direct mapping over content-based detection"

issues-created: []

# Metrics
duration: 2min
completed: 2026-01-21
---

# Phase P2 Plan 01: Quick Wins Summary

**Direct extension mappings for 12 Apple/Xcode file types, 15 new system UTIs, auto-detection disabled**

## Performance

- **Duration:** 2 min
- **Started:** 2026-01-21T08:17:54Z
- **Completed:** 2026-01-21T08:19:54Z
- **Tasks:** 4
- **Files modified:** 3

## Accomplishments

- Added 12 direct extension mappings to avoid content-based detection for Apple/Xcode files
- Registered 15 Xcode system UTIs to ensure macOS routes these file types to dotViewer
- Disabled expensive HighlightSwift auto-detection mode (40-60% slower)
- Added Ruby/Fastlane build tool dotfile mappings (Podfile, Fastfile, etc.)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add missing extension mappings to LanguageDetector** - `2890f4d` (perf)
2. **Task 2: Add missing Xcode UTIs to QuickLook Info.plist** - `feacc54` (perf)
3. **Task 3: Disable auto-detection in HighlightSwift fallback** - `a51412d` (perf)
4. **Task 4: Measure and verify** - (verification only, no code changes)

## Files Created/Modified

- `Shared/LanguageDetector.swift` - Added extension mappings for plist, entitlements, xcconfig, xcscheme, xcworkspacedata, pbxproj, storyboard, xib, strings, stringsdict, intentdefinition, xcdatamodel, playground; added dotfile mappings for Ruby/Fastlane tools
- `QuickLookPreview/Info.plist` - Added 15 Xcode system UTIs (entitlements, xcconfig, xcscheme, xcworkspacedata, pbxproject, playground, storyboard, xib, stringsdict, intent-definition, xcdatamodel, etc.)
- `Shared/SyntaxHighlighter.swift` - Changed fallback from .automatic to .languageAlias("plaintext") when no language detected

## Decisions Made

1. **Use plaintext fallback over auto-detection** - Auto-detection runs multiple parsers (40-60% slower). Using plaintext ensures consistent fast behavior for unknown files.
2. **Use system UTIs over custom UTIs** - Xcode file types have official Apple UTIs (com.apple.xcode.*). Using these ensures macOS properly recognizes and routes these file types.

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- Build succeeds: YES
- plutil -lint passes: YES
- .entitlements files get UTI `com.apple.xcode.entitlements-property-list`: YES
- .plist files now have direct extension mapping: YES
- No .automatic mode when language is detected: YES

## Expected Improvements

Based on P1 diagnostics:

| Improvement | Expected Impact |
|-------------|-----------------|
| Direct .plist mapping | ~1ms saved (skip content detection) |
| Direct Xcode file mappings | ~1ms per file (skip content detection) |
| Disabled auto-detection | 40-60% reduction when fallback is used |
| Xcode UTI registration | Files now handled by dotViewer instead of system |

Note: These are "quick wins" - incremental improvements. Major performance gains expected in P3 (cache) and P4 (highlighter optimization).

## Issues Encountered

None.

## Next Phase Readiness

- Quick wins complete, ready for P3 (Persistent Cache Implementation)
- All extension mappings in place for proper cache key generation
- Auto-detection disabled eliminates inconsistent behavior
- UTIs registered ensures all target file types route to dotViewer

---
*Phase: P2-quick-wins*
*Completed: 2026-01-21*
