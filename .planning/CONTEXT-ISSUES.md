# dotViewer - Critical Issues Context

## Overview
dotViewer is a macOS QuickLook extension for syntax-highlighted preview of developer files.
Two critical issues need to be addressed.

---

## ISSUE 1: Performance Problem - Large File Highlighting Takes 15+ Seconds

### Symptoms
- Opening `Info.plist` (50KB, 1940 lines) shows spinner "Highlighting 1940 lines..."
- Takes ~15 seconds in Finder preview pane
- Takes another ~15 seconds when pressing spacebar (full QuickLook window)
- Total: 30 seconds of waiting for ONE file preview

### Root Cause Analysis
The highlighting logic in `QuickLookPreview/PreviewContentView.swift` has these thresholds:
- **Line 171-179**: Files >2000 lines skip highlighting entirely (show plain text)
- **Line 92**: Files >500 lines show the loading indicator with "Highlighting X lines..."
- **Line 225**: Timeout is set to 2 seconds... but it's not working effectively

The 1940-line Info.plist falls JUST UNDER the 2000-line threshold, so it attempts full syntax highlighting via HighlightSwift library. XML/plist files are particularly slow because:
1. HighlightSwift runs complex regex patterns
2. XML has deeply nested structures
3. The SwiftUI AttributedString manipulation is O(n) for each highlighting pass

### Key Code Locations
- `QuickLookPreview/PreviewContentView.swift:151-279` - `highlightCode()` async function
- `QuickLookPreview/PreviewContentView.swift:171` - `maxLinesForHighlighting = 2000`
- `QuickLookPreview/PreviewContentView.swift:225` - `timeoutNanoseconds = 2_000_000_000` (2 sec timeout)

### Potential Fixes
1. **Lower the threshold**: Change `maxLinesForHighlighting` from 2000 to something like 500-1000
2. **Size-based threshold**: Skip highlighting for files over 20-30KB regardless of line count
3. **Language-specific limits**: XML/JSON/plist files should have lower thresholds (they're slow to parse)
4. **Fix the timeout**: The 2-second timeout isn't being respected - investigate why
5. **Progressive rendering**: Show plain text immediately, then highlight in background
6. **Cache aggressively**: Store highlighted results to avoid re-processing on spacebar

---

## ISSUE 2: Some File Types Not Handled (Missing UTIs)

### Symptoms
- `.entitlements` files not previewed by dotViewer
- Falls back to macOS default (plain file icon)
- Other file types in `/private/tmp/dotviewer-test/` also not handled

### Root Cause
macOS assigns system UTIs to certain file extensions. The QuickLook extension's `QLSupportedContentTypes` array must include these EXACT system UTIs, not just custom ones.

### Example: .entitlements file
```bash
$ mdls -name kMDItemContentType "/path/to/file.entitlements"
kMDItemContentType = "com.apple.xcode.entitlements-property-list"
```

This UTI (`com.apple.xcode.entitlements-property-list`) is **NOT** in `QuickLookPreview/Info.plist`.

### How to Find Missing UTIs
For any file that's not being handled:
```bash
mdls -name kMDItemContentType -name kMDItemContentTypeTree "/path/to/file"
```

### Key File
- `QuickLookPreview/Info.plist` - Contains `QLSupportedContentTypes` array
- Currently has 323 UTIs but missing Xcode-specific ones like:
  - `com.apple.xcode.entitlements-property-list` (.entitlements)
  - `com.apple.xcode.strings-text` (.strings)
  - `com.apple.xcode.xcconfig` (.xcconfig)
  - And potentially others

### Known Missing UTIs to Add
```xml
<string>com.apple.xcode.entitlements-property-list</string>
<string>com.apple.xcode.strings-text</string>
<string>com.apple.xcode.xcconfig</string>
<string>com.apple.xcode.plist</string>
<string>com.apple.xcode.xcscheme</string>
<string>com.apple.xcode.xcworkspacedata</string>
<string>com.apple.xcode.pbxproject</string>
```

---

## Architecture Reference

### QuickLook Extension Files
```
QuickLookPreview/
├── Info.plist              # UTI declarations (QLSupportedContentTypes)
├── PreviewViewController.swift  # Entry point, file loading
├── PreviewContentView.swift     # SwiftUI view, highlighting logic
├── MarkdownStyles.swift
└── MarkdownWebView.swift
```

### Main App Files
```
dotViewer/
├── Info.plist              # UTExportedTypeDeclarations (custom UTIs)
├── FileTypeRegistry.swift  # File type definitions
└── ...
```

### Flow
1. User selects file in Finder
2. macOS checks file's UTI against `QLSupportedContentTypes`
3. If match → calls `PreviewViewController.preparePreviewOfFile()`
4. Controller reads file, passes to `PreviewContentView`
5. View shows spinner while `highlightCode()` runs async
6. After highlighting completes (or times out), content fades in

---

## Recent Commits (for context)
- `7296ded` - feat(ui): make file type categories collapsible
- `998808b` - feat(quicklook): expand UTI support to 323 types for bulletproof coverage

---

## Summary: What Needs to Be Done

### Priority 1: Performance Fix
- Lower highlighting threshold for large files
- Consider file size in KB, not just line count
- Apply stricter limits for XML/JSON/plist (slow languages)
- Ensure 2-second timeout actually aborts highlighting
- Show plain text immediately, highlight in background if time permits

### Priority 2: Missing UTIs
- Add all Xcode-related UTIs to `QuickLookPreview/Info.plist`
- Test with: `mdls -name kMDItemContentType <file>` for any missing file type
- Rebuild and re-register the app after plist changes

### Testing
After fixes:
1. Rebuild: `xcodebuild -scheme dotViewer -configuration Debug build`
2. Re-register: `lsregister -f -R /path/to/dotViewer.app`
3. Kill QuickLook: `killall QuickLookUIService` (or reboot)
4. Test files in Finder and with spacebar
