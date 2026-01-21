---
phase: P2-quick-wins
plan: 01
type: execute
wave: 1
depends_on: ["P1-01"]
files_modified:
  - Shared/LanguageDetector.swift
  - QuickLookPreview/Info.plist
  - Shared/SyntaxHighlighter.swift
autonomous: true
---

<objective>
Implement low-effort fixes that reduce overhead and improve file type detection.

Purpose: These quick wins eliminate unnecessary work (content-based detection, auto-detection) and ensure all Xcode file types are handled correctly.

Output: Improved detection, reduced overhead, all Xcode UTIs supported.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/milestones/v1.1-performance-ROADMAP.md
@.planning/phases/P1-diagnostics/DIAGNOSTICS.md
@Shared/LanguageDetector.swift
@QuickLookPreview/Info.plist
@Shared/SyntaxHighlighter.swift
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add missing extension mappings to LanguageDetector</name>
  <files>Shared/LanguageDetector.swift</files>
  <action>
Add direct extension mappings to `extensionMap` to avoid content-based detection:

```swift
// In extensionMap, add to "Data formats" section:
"plist": "xml",
"entitlements": "xml",
"xcconfig": "ini",        // Key-value format
"xcscheme": "xml",
"xcworkspacedata": "xml",
"pbxproj": "ini",         // Actually a weird plist/ini hybrid, ini works better
"storyboard": "xml",
"xib": "xml",
"strings": "ini",         // Key = "Value" format
"stringsdict": "xml",     // XML plist format
"intentdefinition": "xml",
"xcdatamodel": "xml",
"playground": "xml",      // The contents.xcplayground is XML
```

Also add to `dotfileMap`:
```swift
"Podfile": "ruby",
"Fastfile": "ruby",
"Appfile": "ruby",
"Matchfile": "ruby",
"Snapfile": "ruby",
"Scanfile": "ruby",
"Gymfile": "ruby",
"Deliverfile": "ruby",
```

This ensures these file types get direct language mapping without needing content detection.
  </action>
  <verify>Build succeeds</verify>
  <done>All Apple/Xcode file types have direct extension mappings</done>
</task>

<task type="auto">
  <name>Task 2: Add missing Xcode UTIs to QuickLook Info.plist</name>
  <files>QuickLookPreview/Info.plist</files>
  <action>
Add the following system UTIs to the `QLSupportedContentTypes` array. These are SYSTEM UTIs that macOS recognizes - we're not creating custom ones.

Add after the existing Apple-specific section (around line 133):

```xml
<!-- Xcode Project Files -->
<string>com.apple.xcode.entitlements-property-list</string>
<string>com.apple.xcode.xcconfig</string>
<string>com.apple.xcode.xcscheme</string>
<string>com.apple.xcode.xcworkspacedata</string>
<string>com.apple.xcode.pbxproject</string>
<string>com.apple.xcode.playground</string>
<string>com.apple.dt.playground</string>
<string>com.apple.dt.playgroundpage</string>
<string>com.apple.xcode.storyboard</string>
<string>com.apple.xcode.xib</string>
<string>com.apple.xcode.stringsdict</string>
<string>com.apple.dt.document.scripting-definition</string>
<string>com.apple.xcode.intent-definition</string>
<string>com.apple.xcode.xcdatamodel</string>
<string>com.apple.xcode.xcdatamodeld</string>
```

Note: `com.apple.xcode.strings-text` and `com.apple.xcode.plist-text` are already present - do NOT duplicate.
  </action>
  <verify>`plutil -lint QuickLookPreview/Info.plist` passes</verify>
  <done>All Xcode system UTIs added to QLSupportedContentTypes</done>
</task>

<task type="auto">
  <name>Task 3: Ensure language is always passed to HighlightSwift (no auto-detection)</name>
  <files>Shared/SyntaxHighlighter.swift</files>
  <action>
Modify `highlightWithFallback()` to NEVER use automatic mode when we have any language hint.

Current code:
```swift
let mode: HighlightMode
if let lang = language {
    mode = .languageAlias(lang)
} else {
    mode = .automatic
}
```

Change to:
```swift
let mode: HighlightMode
if let lang = language {
    mode = .languageAlias(lang)
} else {
    // NEVER use .automatic - it runs multiple parsers and is 40-60% slower
    // If we don't know the language, use plaintext to avoid auto-detection overhead
    NSLog("[dotViewer PERF] WARNING: No language detected, using plaintext to avoid auto-detection")
    mode = .languageAlias("plaintext")
}
```

Also add a timing log at the start of `highlightWithFallback`:
```swift
NSLog("[dotViewer PERF] highlightWithFallback called - language: \(language ?? "nil"), mode: \(mode)")
```
  </action>
  <verify>Build succeeds</verify>
  <done>Auto-detection disabled - always use explicit language or plaintext</done>
</task>

<task type="auto">
  <name>Task 4: Measure improvement and document</name>
  <files>N/A</files>
  <action>
1. Rebuild the app:
   ```bash
   xcodebuild clean -scheme dotViewer -configuration Debug
   xcodebuild -scheme dotViewer -configuration Debug build
   ```

2. Re-register and restart QuickLook:
   ```bash
   APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "dotViewer.app" -type d 2>/dev/null | head -1)
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "$APP_PATH"
   killall QuickLookUIService 2>/dev/null || true
   ```

3. Re-run the same test files from P1 diagnostics

4. Compare times:
   - Did .plist files get faster? (should skip content detection now)
   - Did unknown files get faster? (should skip auto-detection now)
   - Are all Xcode files now handled by dotViewer?

5. Test UTI handling:
   ```bash
   # Create test files
   touch /tmp/test.entitlements
   echo '<?xml version="1.0"?><plist></plist>' > /tmp/test.entitlements

   # Check UTI
   mdls -name kMDItemContentType /tmp/test.entitlements
   # Should show: com.apple.xcode.entitlements-property-list
   ```

6. Document improvement in SUMMARY.md
  </action>
  <verify>
- All Xcode file types are handled by dotViewer
- No auto-detection warnings in logs for known file types
- Performance improvement documented
  </verify>
  <done>
- Performance improvement measured against P1 baseline
- All Xcode UTIs verified working
- Results documented
  </done>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] `xcodebuild -scheme dotViewer -configuration Debug build` succeeds
- [ ] `plutil -lint QuickLookPreview/Info.plist` passes
- [ ] .plist files show "xml" language in logs (not content-detected)
- [ ] .entitlements files handled by dotViewer (not system)
- [ ] No `.automatic` mode used when language is detected
</verification>

<success_criteria>

- All tasks completed
- All verification checks pass
- Measurable improvement in detection speed
- All Xcode file types handled correctly
  </success_criteria>

<output>
After completion, create `.planning/phases/P2-quick-wins/P2-01-SUMMARY.md`
</output>
