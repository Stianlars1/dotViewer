# UAT Issues: Phase 01 Plan 01

**Tested:** 2026-01-15
**Source:** .planning/phases/01-infoplist-uti-fixes/01-01-SUMMARY.md
**Tester:** User via /gsd:verify-work

## Open Issues

None.

## Resolved Issues

### UAT-002: TypeScript/TSX Files Not Previewing

**Discovered:** 2026-01-15
**Resolved:** 2026-01-15
**Phase/Plan:** 01-03
**Severity:** Major
**Feature:** QuickLook preview for .ts/.tsx files
**Description:** Despite UTI declarations being present in Info.plist for TypeScript files, QuickLook shows document icon instead of code preview.
**Expected:** Code preview with syntax highlighting for .ts and .tsx files
**Actual:** Generic document icon, no preview content

**Root Cause:** On systems without Xcode, macOS identifies `.ts` files as `public.mpeg-2-transport-stream` (MPEG-2 video) rather than TypeScript. The `.ts` extension is shared between TypeScript and MPEG-2 Transport Stream formats.

**Resolution:** Added `com.microsoft.typescript` UTI declaration to dotViewer/Info.plist and added both `com.microsoft.typescript` and `public.mpeg-2-transport-stream` to QuickLookPreview/Info.plist QLSupportedContentTypes. This ensures TypeScript files preview correctly on both developer and non-developer Macs.

**Status:** RESOLVED

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
