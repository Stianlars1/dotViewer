---
phase: 04-app-store-prep
plan: 01
subsystem: infra
tags: [sandbox, app-store, entitlements, swiftui]

# Dependency graph
requires:
  - phase: 03-performance
    provides: FastSyntaxHighlighter, comprehensive UTI support
provides:
  - App Sandbox enabled for Mac App Store compliance
  - Sandbox-safe ExtensionHelper replacing pluginkit-based checker
  - Static setup guide UI for extension enablement
affects: [app-store-submission]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Static setup guide instead of live status detection (sandbox-compatible)"
    - "ExtensionHelper singleton for sandbox-safe operations"

key-files:
  created: []
  modified:
    - dotViewer/dotViewer.entitlements
    - dotViewer/ExtensionStatusChecker.swift
    - dotViewer/ContentView.swift

key-decisions:
  - "Static setup guide instead of live status detection (no sandbox-friendly API exists)"
  - "Removed pluginkit shell command execution entirely"
  - "Quick Stats always visible (not conditional on extension status)"

patterns-established:
  - "Sandbox-compatible extension helper pattern"

issues-created: []

# Metrics
duration: 5min
completed: 2026-01-19
---

# Phase 4 Plan 1: App Sandbox & Static Setup Guide Summary

**Enabled App Sandbox for Mac App Store compliance by replacing pluginkit-based status detection with a static setup guide UI**

## Performance

- **Duration:** 5 min
- **Started:** 2026-01-19T09:45:00Z
- **Completed:** 2026-01-19T09:50:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Enabled App Sandbox (com.apple.security.app-sandbox: true)
- Replaced pluginkit shell command with sandbox-safe ExtensionHelper
- Created user-friendly static setup guide in StatusView
- Verified sandbox compliance with no violations

## Task Commits

Each task was committed atomically:

1. **Task 1: Enable App Sandbox in main app entitlements** - `bcb8117` (feat)
2. **Task 2: Replace ExtensionStatusChecker with static setup guide** - `750fcdd` (feat)
3. **Task 3: Verify sandbox compliance and test build** - No commit (verification only)

## Files Created/Modified
- `dotViewer/dotViewer.entitlements` - Changed app-sandbox from false to true
- `dotViewer/ExtensionStatusChecker.swift` - Replaced with simple ExtensionHelper class
- `dotViewer/ContentView.swift` - StatusView now shows static setup guide

## Decisions Made
- **Static setup guide over live detection**: No public sandbox-friendly API exists to detect QuickLook extension status. Industry standard for sandboxed Mac App Store apps is to show static setup instructions.
- **Quick Stats always visible**: Removed conditional display based on extension status since we can no longer detect it.
- **Removed notification handlers**: onAppear and didBecomeActiveNotification handlers removed since there's no status to refresh.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## Next Phase Readiness
- App is now fully sandbox-compliant
- Ready for Mac App Store submission
- No remaining plans in Phase 4
- Milestone complete

---
*Phase: 04-app-store-prep*
*Completed: 2026-01-19*
