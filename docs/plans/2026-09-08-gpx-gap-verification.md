# PR #26 verification

Validated on macOS 26.4.1 / Xcode 26.6. Original app was 1.5.2 (8); updated locally to Developer ID signed 1.5.3 (10). No public release or merge.

- XCTest: 204 tests, 0 failures. Logs `/tmp/dotviewer-pr26-all-tests.log`; retained result bundles `/tmp/dotviewer-pr26-test-results/`.
- Python: 3 shipped-routing tests plus 7 generator metadata tests pass. Initial routing run had 6 failures before the fixes.
- GAP highlighting regressions initially failed (8 assertions) before adding grammars/injections. Resolution tests initially failed on GAP `.gd` detection.
- UTI audit: 711/711 effective coverage, including 19 export-based cases. Actual GPX UTI on this Mac remains `com.topografix.gpx`; both extension declarations now support it.
- Full archive/export: `./scripts/release.sh 1.5.3 --build-number=10 --skip-notarize --skip-dmg`; strict signature verification passes. Designated signing requirement matches the original installed app. Keyboard interception resumed with no new permission grant.
- Finder Space: GPX shows XML label and colors; `.gpx` dotfile also works. GAP test transcripts show highlighted commands/directives and plain expected output. `.gd` GAP declarations show GAP; `test-godot.gd` remains GDScript.
- Preview logs: `.g`, `.gi`, `.gd`, `.tst`; real upstream `gap-system/gap` files `lib/addcoset.gd` and `tst/teststandard/algebra.tst` produce HTML. Upstream samples were only viewed, never executed.
- Option + Space: shared rendering path and active keyboard interception checked; manual user confirmation requested because native UI automation activates the settings window while attempting the global shortcut.
- Thumbnail limitation: QLThumbnailGenerator used the system plain-text generator for GAP and returned QLThumbnailErrorDomain/102 for GPX; no dotViewer thumbnail request was observed. Updated declarations and empty-token handling are covered by tests, but native thumbnail output is not approved. This is separate from the verified Space preview behavior.

Fixtures for manual checks: `/tmp/dotviewer-pr26-qa/`, copied from `TestFiles/` plus upstream GAP samples. Original app backup: `/tmp/dotviewer-pr26-original-1.5.2.review-bundle`.
