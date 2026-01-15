# UAT Issues: Phase 01 Plan 01

**Tested:** 2026-01-15
**Source:** .planning/phases/01-infoplist-uti-fixes/01-01-SUMMARY.md
**Tester:** User via /gsd:verify-work

## Open Issues

### UAT-002: TypeScript/TSX Files Not Previewing

**Discovered:** 2026-01-15
**Phase/Plan:** 01-01
**Severity:** Major
**Feature:** QuickLook preview for .ts/.tsx files
**Description:** Despite UTI declarations being present in Info.plist for TypeScript files, QuickLook shows document icon instead of code preview.
**Expected:** Code preview with syntax highlighting for .ts and .tsx files
**Actual:** Generic document icon, no preview content
**Repro:**
1. Navigate to a .ts or .tsx file in Finder
2. Press Space to invoke QuickLook
3. See document icon instead of code preview

**Likely Cause:** User ran `lsregister -kill` which cleared Launch Services database. May also be affected by Xcode claiming TypeScript UTIs with higher priority.

**Status:** PENDING - Needs re-test after sandbox fix and rebuild

## Resolved Issues

### UAT-001: Extension Status Detection Shows "Not Enabled" When Actually Enabled

**Discovered:** 2026-01-15
**Resolved:** 2026-01-15
**Phase/Plan:** 01-01
**Severity:** Major
**Feature:** Extension status indicator in main app UI
**Description:** The dotViewer app shows "Extension Not Enabled" with red X icon even when the QuickLook extension is actually enabled and working.

**Root Cause:** App sandbox was accidentally enabled in commit `b5db124` ("gwip before screenshots"). Sandboxed apps cannot run shell commands like `pluginkit`, causing the status check to silently fail.

**Resolution:** Disabled sandbox in `dotViewer.entitlements` (set `com.apple.security.app-sandbox` to `false`). Added Phase 5 to roadmap for future App Store preparation with sandbox-compatible detection.

**Status:** RESOLVED

---

*Phase: 01-infoplist-uti-fixes*
*Plan: 01*
*Tested: 2026-01-15*
