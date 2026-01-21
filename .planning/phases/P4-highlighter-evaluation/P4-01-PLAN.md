---
phase: P4-highlighter-evaluation
plan: 01
type: execute
wave: 1
depends_on: ["P3-02"]
files_modified:
  - dotViewer.xcodeproj/project.pbxproj
  - Shared/HighlighterBenchmark.swift (new)
  - .planning/phases/P4-highlighter-evaluation/BENCHMARK_RESULTS.md
autonomous: true
---

<objective>
Benchmark all available syntax highlighting approaches to make a data-driven decision on which to use.

Purpose: We need quantitative data comparing FastSyntaxHighlighter, HighlightSwift, and Highlightr to understand actual performance characteristics and make the right choice.

Output: BENCHMARK_RESULTS.md with comparative data and recommendation.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/milestones/v1.1-performance-ROADMAP.md
@.planning/phases/P1-diagnostics/DIAGNOSTICS.md
@.planning/phases/P3-persistent-cache/CACHE_RESULTS.md
@Shared/SyntaxHighlighter.swift
@Shared/FastSyntaxHighlighter.swift
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add Highlightr package dependency</name>
  <files>dotViewer.xcodeproj/project.pbxproj</files>
  <action>
Add Highlightr as a Swift Package dependency to enable benchmarking.

In Xcode (or via Package.swift if available):

**Swift Package URL:** `https://github.com/raspu/Highlightr`
**Version:** Latest (up to next major)

If there's no Package.swift, add via Xcode:
1. File → Add Package Dependencies
2. Enter: https://github.com/raspu/Highlightr
3. Add to both targets: dotViewer and QuickLookPreview

Alternative: Use HighlighterSwift (more maintained):
**URL:** `https://github.com/smittytone/HighlighterSwift`

Add both packages for comparison.

Verify with:
```bash
xcodebuild -scheme dotViewer -showBuildSettings 2>&1 | grep -i highligh
```
  </action>
  <verify>Both packages resolve and build succeeds</verify>
  <done>Highlightr and/or HighlighterSwift added as dependencies</done>
</task>

<task type="auto">
  <name>Task 2: Create HighlighterBenchmark utility</name>
  <files>Shared/HighlighterBenchmark.swift</files>
  <action>
Create a benchmark utility that tests all three highlighter approaches:

```swift
import Foundation
import SwiftUI
import HighlightSwift
// import Highlightr  // Uncomment when package is added
// import HighlighterSwift  // Uncomment when package is added

/// Benchmark utility for comparing syntax highlighter performance
struct HighlighterBenchmark {

    struct BenchmarkResult {
        let highlighter: String
        let language: String
        let lineCount: Int
        let charCount: Int
        let timeMs: Double
        let success: Bool
        let error: String?
    }

    /// Run benchmark on all highlighters for given code
    static func benchmark(code: String, language: String, iterations: Int = 3) async -> [BenchmarkResult] {
        var results: [BenchmarkResult] = []
        let lineCount = code.components(separatedBy: .newlines).count
        let charCount = code.count

        NSLog("[Benchmark] Starting: language=\(language), lines=\(lineCount), chars=\(charCount)")

        // 1. Benchmark FastSyntaxHighlighter
        if FastSyntaxHighlighter.isSupported(language) {
            let fastResult = await benchmarkFast(code: code, language: language, iterations: iterations)
            results.append(BenchmarkResult(
                highlighter: "FastSyntaxHighlighter",
                language: language,
                lineCount: lineCount,
                charCount: charCount,
                timeMs: fastResult.avgMs,
                success: fastResult.success,
                error: fastResult.error
            ))
        } else {
            results.append(BenchmarkResult(
                highlighter: "FastSyntaxHighlighter",
                language: language,
                lineCount: lineCount,
                charCount: charCount,
                timeMs: 0,
                success: false,
                error: "Language not supported"
            ))
        }

        // 2. Benchmark HighlightSwift
        let hsResult = await benchmarkHighlightSwift(code: code, language: language, iterations: iterations)
        results.append(BenchmarkResult(
            highlighter: "HighlightSwift",
            language: language,
            lineCount: lineCount,
            charCount: charCount,
            timeMs: hsResult.avgMs,
            success: hsResult.success,
            error: hsResult.error
        ))

        // 3. Benchmark Highlightr (when added)
        // let hrResult = await benchmarkHighlightr(code: code, language: language, iterations: iterations)
        // results.append(...)

        for result in results {
            NSLog("[Benchmark] \(result.highlighter): \(result.success ? "\(result.timeMs)ms" : "FAILED: \(result.error ?? "unknown")")")
        }

        return results
    }

    // MARK: - Individual Benchmarks

    private static func benchmarkFast(code: String, language: String, iterations: Int) async -> (avgMs: Double, success: Bool, error: String?) {
        let highlighter = FastSyntaxHighlighter()
        let colors = SyntaxColors.forTheme("atomOneDark", systemIsDark: true)

        var times: [Double] = []

        for i in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()

            let _ = highlighter.highlight(code: code, language: language, colors: colors)

            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            times.append(elapsed)
            NSLog("[Benchmark] FastSyntaxHighlighter iteration \(i+1): %.2fms", elapsed)
        }

        let avg = times.reduce(0, +) / Double(times.count)
        return (avg, true, nil)
    }

    private static func benchmarkHighlightSwift(code: String, language: String, iterations: Int) async -> (avgMs: Double, success: Bool, error: String?) {
        let highlight = Highlight()

        var times: [Double] = []

        for i in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()

            do {
                let mode: HighlightMode = .languageAlias(language)
                let _ = try await highlight.request(code, mode: mode, colors: .dark(.atomOne))
                let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                times.append(elapsed)
                NSLog("[Benchmark] HighlightSwift iteration \(i+1): %.2fms", elapsed)
            } catch {
                return (0, false, error.localizedDescription)
            }
        }

        let avg = times.reduce(0, +) / Double(times.count)
        return (avg, true, nil)
    }

    /*
    // Uncomment when Highlightr is added
    private static func benchmarkHighlightr(code: String, language: String, iterations: Int) async -> (avgMs: Double, success: Bool, error: String?) {
        guard let highlightr = Highlightr() else {
            return (0, false, "Failed to initialize Highlightr")
        }

        highlightr.setTheme(to: "atom-one-dark")

        var times: [Double] = []

        for i in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()

            let _ = highlightr.highlight(code, as: language)

            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            times.append(elapsed)
            NSLog("[Benchmark] Highlightr iteration \(i+1): %.2fms", elapsed)
        }

        let avg = times.reduce(0, +) / Double(times.count)
        return (avg, true, nil)
    }
    */

    /// Generate a summary table
    static func formatResults(_ results: [BenchmarkResult]) -> String {
        var output = "| Highlighter | Language | Lines | Time (ms) | Status |\n"
        output += "|-------------|----------|-------|-----------|--------|\n"

        for r in results {
            let status = r.success ? "OK" : "FAILED"
            let time = r.success ? String(format: "%.1f", r.timeMs) : "-"
            output += "| \(r.highlighter) | \(r.language) | \(r.lineCount) | \(time) | \(status) |\n"
        }

        return output
    }
}
```
  </action>
  <verify>Build succeeds</verify>
  <done>HighlighterBenchmark utility created</done>
</task>

<task type="auto">
  <name>Task 3: Run comprehensive benchmarks and create results document</name>
  <files>.planning/phases/P4-highlighter-evaluation/BENCHMARK_RESULTS.md</files>
  <action>
Run benchmarks across multiple file types and sizes. You can either:

A) Add a temporary benchmark trigger to the main app, or
B) Run benchmarks via command line test

**Test Matrix:**

| Size | Lines | Languages to Test |
|------|-------|-------------------|
| Small | 100 | swift, json, xml, python, bash |
| Medium | 500 | swift, json, xml, python, bash |
| Large | 1000 | swift, json, xml, python |
| XLarge | 2000 | swift, xml (Info.plist case) |

**Create test files:**
```bash
# Create test directory
mkdir -p /tmp/highlight-benchmark

# Generate test files of various sizes
# (Use existing sample files or generate with lorem-ipsum-like code)
```

**Run benchmarks and capture output** via Console.app log stream or by adding output to a file.

**Create BENCHMARK_RESULTS.md:**

```markdown
# Highlighter Benchmark Results

## Test Environment
- macOS: [version]
- Hardware: [Mac model]
- Date: 2026-01-21

## Methodology
- Each test run 3 times, averaged
- Cold start (no caching)
- Time measured from function entry to AttributedString return

## Results

### Small Files (100 lines)

| Highlighter | Swift | JSON | XML | Python | Bash |
|-------------|-------|------|-----|--------|------|
| FastSyntaxHighlighter | Xms | Xms | Xms | Xms | Xms |
| HighlightSwift | Xms | Xms | Xms | Xms | Xms |
| Highlightr | Xms | Xms | Xms | Xms | Xms |

### Medium Files (500 lines)

[Same table format]

### Large Files (1000 lines)

[Same table format]

### XLarge Files (2000 lines - Info.plist scenario)

| Highlighter | Swift | XML |
|-------------|-------|-----|
| FastSyntaxHighlighter | Xms | Xms |
| HighlightSwift | Xms | Xms |
| Highlightr | Xms | Xms |

## Analysis

### Performance Ranking
1. [Best]: [Highlighter] - avg Xms
2. [Second]: [Highlighter] - avg Xms
3. [Third]: [Highlighter] - avg Xms

### Language-Specific Findings
- XML: [observations]
- JSON: [observations]
- Swift: [observations]

### Memory Usage
[If measurable, include memory consumption]

### Scaling Behavior
[How does performance scale with file size?]

## Recommendation

Based on the benchmark data:

**Primary Highlighter:** [Recommendation]
- Reason: [data-driven justification]

**Fallback Highlighter:** [Recommendation]
- When to use: [criteria]

## Decision
[ ] FastSyntaxHighlighter (current)
[ ] HighlightSwift (current fallback)
[ ] Highlightr (alternative)
[ ] Hybrid approach (specify)
```
  </action>
  <verify>BENCHMARK_RESULTS.md exists with quantitative data</verify>
  <done>
- Comprehensive benchmarks run
- All highlighters tested
- Performance ranking established
- Data-driven recommendation made
  </done>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] Build succeeds with new package dependencies
- [ ] HighlighterBenchmark.swift compiles
- [ ] Benchmarks run successfully
- [ ] BENCHMARK_RESULTS.md contains quantitative comparison
- [ ] Clear recommendation for primary highlighter
</verification>

<success_criteria>

- All tasks completed
- All verification checks pass
- Quantitative performance data for all highlighters
- Clear, data-driven recommendation
  </success_criteria>

<output>
After completion, create `.planning/phases/P4-highlighter-evaluation/P4-01-SUMMARY.md`
</output>
