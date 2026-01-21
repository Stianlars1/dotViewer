---
phase: P5-advanced-optimizations
plan: 01
type: execute
wave: 1
depends_on: ["P4-02"]
files_modified:
  - QuickLookPreview/PreviewContentView.swift
  - Shared/ProgressiveHighlighter.swift (new, if needed)
autonomous: false
conditional: true
---

<objective>
Implement advanced optimizations if P1-P4 didn't meet the <500ms target.

Purpose: This phase is CONDITIONAL - only execute if performance target is not met after P4.

Output: Additional optimizations to meet performance target.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
@~/.claude/get-shit-done/references/checkpoints.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/milestones/v1.1-performance-ROADMAP.md
@.planning/phases/P4-highlighter-evaluation/P4-02-SUMMARY.md
@.planning/phases/P4-highlighter-evaluation/BENCHMARK_RESULTS.md
@QuickLookPreview/PreviewContentView.swift
</context>

<tasks>

<task type="checkpoint:decision" gate="blocking">
  <decision>Is this phase needed?</decision>
  <context>
Check the performance results from P4-02:
- Did Info.plist (2000 lines) highlight in <500ms?
- Are all performance targets met?

If YES → Skip this phase, proceed to P6
If NO → Continue with advanced optimizations
  </context>
  <options>
    <option id="skip">
      <name>Skip - Performance targets met</name>
      <pros>Less work, targets achieved</pros>
      <cons>None if targets are truly met</cons>
    </option>
    <option id="progressive">
      <name>Implement progressive rendering</name>
      <pros>Show content immediately, highlight in background</pros>
      <cons>More complex UI state management</cons>
    </option>
    <option id="webview">
      <name>Implement WKWebView approach</name>
      <pros>Proven fast (SourceCodeSyntaxHighlight uses this)</pros>
      <cons>Significant architectural change</cons>
    </option>
    <option id="optimize-regex">
      <name>Single-pass regex optimization</name>
      <pros>Keep current architecture, just optimize</pros>
      <cons>May have diminishing returns</cons>
    </option>
  </options>
  <resume-signal>Select: skip, progressive, webview, or optimize-regex</resume-signal>
</task>

<task type="auto">
  <name>Task 2: Implement chosen optimization (if not skipped)</name>
  <files>QuickLookPreview/PreviewContentView.swift, Shared/ProgressiveHighlighter.swift</files>
  <action>
**If progressive rendering:**

Create a progressive highlighting system:

```swift
/// Progressive highlighter that shows content immediately and highlights in chunks
actor ProgressiveHighlighter {
    private let chunkSize = 100  // lines per chunk
    private let highlighter = SyntaxHighlighter()

    struct ChunkResult {
        let startLine: Int
        let endLine: Int
        let highlighted: AttributedString
    }

    /// Highlight code progressively, yielding chunks as they complete
    func highlightProgressively(
        code: String,
        language: String?,
        colors: SyntaxColors
    ) -> AsyncStream<ChunkResult> {
        AsyncStream { continuation in
            Task {
                let lines = code.components(separatedBy: .newlines)
                var currentLine = 0

                while currentLine < lines.count {
                    let endLine = min(currentLine + chunkSize, lines.count)
                    let chunkLines = lines[currentLine..<endLine]
                    let chunkCode = chunkLines.joined(separator: "\n")

                    // Highlight this chunk
                    // ... highlighting logic ...

                    continuation.yield(ChunkResult(
                        startLine: currentLine,
                        endLine: endLine,
                        highlighted: chunkHighlighted
                    ))

                    currentLine = endLine
                }

                continuation.finish()
            }
        }
    }
}
```

Update PreviewContentView to:
1. Show plain text immediately
2. Replace chunks as they're highlighted
3. Smooth visual transition

**If WKWebView approach:**

Create HTML-based rendering:
1. Create WebKit view wrapper
2. Use highlight.js directly in web context
3. Style with CSS matching current themes
4. Extract text for copy/paste

**If optimize-regex:**

Implement single-pass highlighting:
1. Combine all patterns into one regex with capture groups
2. Single pass through the string
3. Identify token type from capture group
4. Apply colors based on token type
  </action>
  <verify>Build succeeds and optimization shows improvement</verify>
  <done>Chosen optimization implemented</done>
</task>

<task type="auto">
  <name>Task 3: Verify performance meets target</name>
  <files>N/A</files>
  <action>
Final performance verification:

1. Clear cache:
   ```bash
   rm -rf ~/Library/Group\ Containers/group.no.skreland.dotViewer/Library/Caches/HighlightCache/*
   ```

2. Rebuild and test with Info.plist

3. Measure:
   - Time to first visible content
   - Time to complete highlighting
   - Overall user experience

4. Target:
   - First content visible: <100ms
   - Complete highlighting: <500ms for 2000 lines

5. If still not meeting target, repeat with different approach
  </action>
  <verify>Performance target achieved</verify>
  <done>
- Performance target met
- Ready for integration phase
  </done>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] Decision made (skip or implement)
- [ ] If implemented: Build succeeds
- [ ] Performance target achieved (<500ms for 2000 lines)
</verification>

<success_criteria>

- Decision made based on P4 results
- If optimization implemented, performance target met
- Ready for integration phase
  </success_criteria>

<output>
After completion, create `.planning/phases/P5-advanced-optimizations/P5-01-SUMMARY.md`
</output>
