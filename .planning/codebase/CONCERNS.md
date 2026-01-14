# Codebase Concerns

**Analysis Date:** 2026-01-14

## Tech Debt

**Large Monolithic View File:**
- Issue: `QuickLookPreview/PreviewContentView.swift` is 1,371 lines
- Why: Rapid development without refactoring
- Impact: Difficult to maintain, test, and navigate
- Fix approach: Split into separate views: `CodePreviewView.swift`, `MarkdownPreviewView.swift`, `PreviewHeaderView.swift`, `SecurityBannerView.swift`

**Duplicate Theme Resolution Logic:**
- Issue: Same theme switch statement in two places
- Files: `Shared/ThemeManager.swift`, `Shared/SyntaxHighlighter.swift`
- Impact: Maintenance burden - theme changes require updates in both locations
- Fix approach: Extract to single source of truth, reference from both locations

**String-Based Theme Selection:**
- Issue: Theme names are magic strings scattered throughout code
- Files: `Shared/ThemeManager.swift`, `Shared/SyntaxHighlighter.swift`, `dotViewer/ContentView.swift`
- Impact: Type-unsafe, prone to typos, no compile-time checking
- Fix approach: Create `Theme` enum with associated values

**Large ContentView File:**
- Issue: `dotViewer/ContentView.swift` is 539 lines with multiple views
- Why: Views added incrementally without extraction
- Impact: File navigation is difficult
- Fix approach: Extract `StatusView`, `SettingsView` to separate files

## Known Bugs

**Vim Script Highlighting Limited:**
- Symptoms: `.vimrc` shows no syntax highlighting colors
- Trigger: Open any Vim script file
- Files: `Shared/LanguageDetector.swift`
- Workaround: None (displays as monochrome text)
- Root cause: HighlightSwift/highlight.js has limited Vim script support
- Status: ⏸️ **DEFERRED** - Library limitation, not blocking v1.0

## Security Considerations

**Sensitive File Exposure:**
- Risk: `.env` files with API keys visible in Quick Look thumbnails
- Files: `QuickLookPreview/PreviewContentView.swift`
- Current mitigation: Security warning banner shown in full preview
- Recommendations: Consider masking sensitive values like `API_KEY=sk-****` in compact preview mode

**Missing Security Check for .npmrc:**
- Risk: `.npmrc` often contains auth tokens but isn't flagged as sensitive
- File: `QuickLookPreview/PreviewContentView.swift`
- Current mitigation: None
- Recommendations: Expand sensitive file detection to include `.npmrc`, `.yarnrc`

## Performance Bottlenecks

**Resolved - Large File Performance:**
- Problem: Opening 11,000+ line files took 1-1.5 minutes
- Files: `QuickLookPreview/PreviewViewController.swift`
- Status: ✅ **FIXED** - Now uses UTF-8 byte scanning for O(n) line counting
- Verified: 75,000+ line files load in <2 seconds

**Potential - Line Number Rendering:**
- Problem: Creates individual Text view for each line number
- File: `QuickLookPreview/PreviewContentView.swift`
- Measurement: Not profiled, but creates up to 5000 views
- Cause: ForEach over line range
- Improvement path: Use Canvas or single AttributedString

**Potential - Markdown UUID Regeneration:**
- Problem: `parseMarkdownBlocks()` may generate new UUIDs on every render
- File: `QuickLookPreview/PreviewContentView.swift`
- Impact: Breaks SwiftUI identity system, causes visual glitches
- Improvement path: Memoize parsed blocks in @State

## Fragile Areas

**Extension Status Detection:**
- Files: `dotViewer/ExtensionStatusChecker.swift`
- Why fragile: Spawns external process (`pluginkit`), parses text output
- Common failures: Process hangs, output format changes
- Safe modification: Add explicit timeout, validate output format
- Test coverage: Manual only

**Theme Resolution Chain:**
- Files: `Shared/ThemeManager.swift`, `Shared/SyntaxHighlighter.swift`
- Why fragile: Duplicate logic, string-based theme names
- Common failures: Theme mismatch between app and extension
- Safe modification: Extract to single source, use enum

## Scaling Limits

**Preview File Size:**
- Current capacity: Configurable 10KB-50MB via settings
- Limit: >2000 lines skips syntax highlighting for performance
- Symptoms at limit: Preview shows plain text, no colors
- Scaling path: Already optimized with O(n) line counting

## Dependencies at Risk

**HighlightSwift:**
- Risk: Third-party dependency for core functionality
- Impact: Syntax highlighting would break if library abandoned
- Migration plan: Alternative libraries exist (SwiftSyntaxHighlight)
- Status: Currently maintained

## Missing Critical Features

**No Automated Tests:**
- Problem: No unit tests, integration tests, or UI tests
- Current workaround: Manual QA documented in `QA_FINDINGS.md`
- Blocks: Refactoring confidence, regression prevention
- Implementation complexity: Medium - need XCTest target setup

## Test Coverage Gaps

**SharedSettings Thread Safety:**
- What's not tested: Concurrent access from app and extension
- Risk: Race conditions could corrupt settings
- Priority: High
- Difficulty to test: Need multi-threaded test harness

**FileTypeRegistry Lookup Performance:**
- What's not tested: O(1) lookup guarantee
- Risk: Performance regression if data structure changes
- Priority: Medium
- Difficulty to test: Low - simple unit tests

**LanguageDetector Heuristics:**
- What's not tested: Content-based detection accuracy
- Risk: False positives/negatives in language detection
- Priority: Medium
- Difficulty to test: Low - test with sample files

## Documentation Gaps

**Complex Heuristics Undocumented:**
- File: `Shared/LanguageDetector.swift`
- Issue: `detectFromContent()` has complex logic without inline comments
- Impact: Difficult to modify detection rules
- Fix: Add comments explaining detection patterns

## Debug Code Remaining

**NSLog/print Statements:**
- File: `QuickLookPreview/PreviewViewController.swift`
- Issue: Debug logging still uses NSLog/print instead of os.log
- Impact: Inconsistent logging, harder to filter in Console.app
- Fix: Replace with `DotViewerLogger` calls

---

*Concerns audit: 2026-01-14*
*Update as issues are fixed or new ones discovered*
