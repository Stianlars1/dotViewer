---
phase: P4-highlighter-evaluation
plan: 02
type: execute
wave: 2
depends_on: ["P4-01"]
files_modified:
  - Shared/SyntaxHighlighter.swift
  - Shared/FastSyntaxHighlighter.swift (potentially)
autonomous: false
---

<objective>
Implement the highlighter solution chosen based on P4-01 benchmark results.

Purpose: Replace or optimize the current highlighting approach based on data-driven decision from benchmarks.

Output: Optimized syntax highlighting implementation.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
@~/.claude/get-shit-done/references/checkpoints.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/milestones/v1.1-performance-ROADMAP.md
@.planning/phases/P4-highlighter-evaluation/BENCHMARK_RESULTS.md
@.planning/phases/P4-highlighter-evaluation/P4-01-SUMMARY.md
@Shared/SyntaxHighlighter.swift
@Shared/FastSyntaxHighlighter.swift
</context>

<tasks>

<task type="checkpoint:decision" gate="blocking">
  <decision>Select primary highlighting approach based on benchmark data</decision>
  <context>
Based on BENCHMARK_RESULTS.md from P4-01, we need to decide which highlighting approach to use.

Review the benchmark results and select one of the following options:
  </context>
  <options>
    <option id="keep-fast">
      <name>Keep FastSyntaxHighlighter as primary</name>
      <pros>Already integrated, pure Swift, no dependencies, works offline</pros>
      <cons>May be slower for certain languages, less accurate highlighting</cons>
    </option>
    <option id="switch-highlightr">
      <name>Switch to Highlightr as primary</name>
      <pros>Claimed 50ms/500 lines, mature library, 185 languages</pros>
      <cons>JavaScriptCore overhead, dependency on highlight.js</cons>
    </option>
    <option id="switch-highlighterswift">
      <name>Switch to HighlighterSwift as primary</name>
      <pros>Most maintained, latest highlight.js, security updates</pros>
      <cons>Similar to Highlightr - JavaScriptCore based</cons>
    </option>
    <option id="hybrid">
      <name>Hybrid approach (optimize FastSyntaxHighlighter)</name>
      <pros>Keep Fast for supported languages, optimize regex approach</pros>
      <cons>More implementation work, maintain two highlighters</cons>
    </option>
  </options>
  <resume-signal>Select: keep-fast, switch-highlightr, switch-highlighterswift, or hybrid</resume-signal>
</task>

<task type="auto">
  <name>Task 2: Implement chosen highlighter solution</name>
  <files>Shared/SyntaxHighlighter.swift, Shared/FastSyntaxHighlighter.swift</files>
  <action>
Based on the decision from Task 1, implement the chosen approach:

**If keep-fast or hybrid:**
Optimize FastSyntaxHighlighter:
1. Reduce number of regex passes
2. Use more efficient pattern matching
3. Consider single-pass approach with combined patterns
4. Profile and optimize the index mapping

**If switch-highlightr:**
1. Create wrapper around Highlightr
2. Update SyntaxHighlighter to use Highlightr as primary
3. Keep FastSyntaxHighlighter as fallback for offline/speed

**If switch-highlighterswift:**
1. Replace HighlightSwift import with HighlighterSwift
2. Update API calls to match HighlighterSwift interface
3. Configure optimal settings (preload, theme pre-processing)

**For any option:**
- Ensure timing logs are preserved
- Maintain the same public API
- Update theme handling if needed
- Ensure language mappings work
  </action>
  <verify>Build succeeds and basic highlighting works</verify>
  <done>Chosen highlighter approach implemented</done>
</task>

<task type="auto">
  <name>Task 3: Verify performance improvement</name>
  <files>N/A</files>
  <action>
Run the same benchmarks from P4-01 with the new implementation:

1. Rebuild and test:
   ```bash
   xcodebuild clean -scheme dotViewer -configuration Debug
   xcodebuild -scheme dotViewer -configuration Debug build
   ```

2. Clear the highlight cache to test fresh highlighting:
   ```bash
   rm -rf ~/Library/Group\ Containers/group.no.skreland.dotViewer/Library/Caches/HighlightCache/*
   ```

3. Run benchmarks again using HighlighterBenchmark

4. Compare results:
   - Info.plist (2000 lines XML): Before Xms → After Xms
   - Target: <500ms for first highlight

5. If target not met, go back to Task 2 and try alternative approach
  </action>
  <verify>
- Info.plist highlights in <500ms on first view
- Performance meets target from milestone
  </verify>
  <done>
- Performance verified against target
- Improvement documented
  </done>
</task>

<task type="auto">
  <name>Task 4: Clean up and remove unused code</name>
  <files>Shared/SyntaxHighlighter.swift, Shared/HighlighterBenchmark.swift</files>
  <action>
Based on final decision:

1. If switched to different highlighter:
   - Remove unused highlighter package dependency
   - Remove or archive FastSyntaxHighlighter if not needed
   - Clean up imports

2. Remove benchmark code from production:
   - Keep HighlighterBenchmark.swift but exclude from release builds
   - Or move to a separate test target

3. Remove excessive logging:
   - Keep essential performance logs
   - Remove iteration-level benchmark logs
   - Keep cache hit/miss logs for debugging

4. Update any documentation or comments
  </action>
  <verify>Build succeeds, no unused code warnings</verify>
  <done>
- Unused code removed
- Clean implementation ready
  </done>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] `xcodebuild -scheme dotViewer -configuration Debug build` succeeds
- [ ] Info.plist (2000 lines) highlights in <500ms
- [ ] Performance target met
- [ ] Clean codebase with no unused dependencies
</verification>

<success_criteria>

- All tasks completed
- All verification checks pass
- Performance target (<500ms for 2000 lines) achieved
- Data-driven decision implemented
- Clean, maintainable code
  </success_criteria>

<output>
After completion, create `.planning/phases/P4-highlighter-evaluation/P4-02-SUMMARY.md`
</output>
