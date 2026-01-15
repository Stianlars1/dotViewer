# UAT Issues: Phase 01 Plan 01

**Tested:** 2026-01-15
**Source:** .planning/phases/01-infoplist-uti-fixes/01-01-SUMMARY.md
**Tester:** User via /gsd:verify-work

## Open Issues

### UAT-001: Extension Status Detection Shows "Not Enabled" When Actually Enabled

**Discovered:** 2026-01-15
**Phase/Plan:** 01-01
**Severity:** Major
**Feature:** Extension status indicator in main app UI
**Description:** The dotViewer app shows "Extension Not Enabled" with red X icon even when the QuickLook extension is actually enabled and working. User can verify the extension works by pressing Space on files in Finder.
**Expected:** Green checkmark with "Extension Enabled" when extension is enabled in System Settings
**Actual:** Red X with "Extension Not Enabled" despite extension being enabled and functional
**Repro:**
1. Install dotViewer from DMG
2. Enable extension in System Settings > Privacy & Security > Extensions > Quick Look
3. Open dotViewer app
4. Observe status shows "Extension Not Enabled"
5. Test QuickLook in Finder - it actually works

**Root Cause:** `ExtensionStatusChecker.swift` line 56 was using `pluginkit -m` which doesn't show all plugins. Changed to `pluginkit -mA` to include all plugins.

**Status:** FIXED - Code change applied, needs rebuild and test

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

**Likely Cause:** User ran `lsregister -kill` which cleared Launch Services database. macOS needs restart to rebuild UTI associations. May also be affected by Xcode claiming TypeScript UTIs.

**Status:** PENDING - User needs to restart Mac to rebuild Launch Services database

## Resolved Issues

[None yet]

---

*Phase: 01-infoplist-uti-fixes*
*Plan: 01*
*Tested: 2026-01-15*
