import Foundation
import SwiftUI
import HighlightSwift
import Highlightr

// MARK: - DEBUG/BENCHMARKING UTILITY
// This file is for performance benchmarking and debugging only.
// It is NOT used in the production highlighting path.
// - Production uses: FastSyntaxHighlighter (primary) + HighlightSwift (fallback)
// - Highlightr dependency exists solely for this benchmark utility
// TODO: P6-01 - Consider excluding this file from Release builds

/// Benchmark utility for comparing syntax highlighter performance
/// Compares: FastSyntaxHighlighter (Swift-native), HighlightSwift (JSCore), Highlightr (JSCore)
struct HighlighterBenchmark: Sendable {

    struct BenchmarkResult: Sendable {
        let highlighter: String
        let language: String
        let lineCount: Int
        let charCount: Int
        let timeMs: Double
        let success: Bool
        let error: String?
    }

    /// Run benchmark on all highlighters for given code
    @MainActor
    static func benchmark(code: String, language: String, iterations: Int = 3) async -> [BenchmarkResult] {
        var results: [BenchmarkResult] = []
        let lineCount = code.components(separatedBy: .newlines).count
        let charCount = code.count

        NSLog("[Benchmark] Starting: language=%@, lines=%d, chars=%d, iterations=%d", language, lineCount, charCount, iterations)

        // 1. Benchmark FastSyntaxHighlighter (Swift-native)
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

        // 2. Benchmark HighlightSwift (JavaScriptCore-based)
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

        // 3. Benchmark Highlightr (JavaScriptCore-based)
        let hrResult = await benchmarkHighlightr(code: code, language: language, iterations: iterations)
        results.append(BenchmarkResult(
            highlighter: "Highlightr",
            language: language,
            lineCount: lineCount,
            charCount: charCount,
            timeMs: hrResult.avgMs,
            success: hrResult.success,
            error: hrResult.error
        ))

        for result in results {
            if result.success {
                NSLog("[Benchmark] %@: %.2fms", result.highlighter, result.timeMs)
            } else {
                NSLog("[Benchmark] %@: FAILED - %@", result.highlighter, result.error ?? "unknown")
            }
        }

        return results
    }

    // MARK: - Individual Benchmarks

    @MainActor
    private static func benchmarkFast(code: String, language: String, iterations: Int) async -> (avgMs: Double, success: Bool, error: String?) {
        let highlighter = FastSyntaxHighlighter()
        let colors = ThemeManager.shared.syntaxColors

        var times: [Double] = []

        for i in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()

            let _ = highlighter.highlight(code: code, language: language, colors: colors)

            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            times.append(elapsed)
            NSLog("[Benchmark] FastSyntaxHighlighter iteration %d: %.2fms", i+1, elapsed)
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
                NSLog("[Benchmark] HighlightSwift iteration %d: %.2fms", i+1, elapsed)
            } catch {
                return (0, false, error.localizedDescription)
            }
        }

        let avg = times.reduce(0, +) / Double(times.count)
        return (avg, true, nil)
    }

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
            NSLog("[Benchmark] Highlightr iteration %d: %.2fms", i+1, elapsed)
        }

        let avg = times.reduce(0, +) / Double(times.count)
        return (avg, true, nil)
    }

    /// Generate a summary table in markdown format
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

    /// Run comprehensive benchmark suite across multiple languages and sizes
    @MainActor
    static func runComprehensiveBenchmarks() async -> [String: [BenchmarkResult]] {
        var allResults: [String: [BenchmarkResult]] = [:]

        // Test languages that FastSyntaxHighlighter supports
        let testLanguages = ["swift", "json", "xml", "python", "bash"]

        // Generate test code for each size
        let sizes: [(name: String, lines: Int)] = [
            ("small", 100),
            ("medium", 500),
            ("large", 1000),
            ("xlarge", 2000)
        ]

        for size in sizes {
            for language in testLanguages {
                // Skip xlarge for bash (not typical use case)
                if size.lines > 1000 && language == "bash" {
                    continue
                }

                let code = generateTestCode(language: language, lines: size.lines)
                let key = "\(size.name)_\(language)"
                let results = await benchmark(code: code, language: language, iterations: 3)
                allResults[key] = results
            }
        }

        return allResults
    }

    /// Generate test code for a specific language and line count
    static func generateTestCode(language: String, lines: Int) -> String {
        switch language {
        case "swift":
            return generateSwiftCode(lines: lines)
        case "json":
            return generateJSONCode(lines: lines)
        case "xml":
            return generateXMLCode(lines: lines)
        case "python":
            return generatePythonCode(lines: lines)
        case "bash":
            return generateBashCode(lines: lines)
        default:
            return generateSwiftCode(lines: lines)
        }
    }

    // MARK: - Code Generators

    private static func generateSwiftCode(lines: Int) -> String {
        var code = """
        import Foundation
        import SwiftUI

        /// A sample Swift file for benchmarking
        /// This file contains typical Swift code patterns
        class BenchmarkClass {
            private var count: Int = 0
            private var name: String = "test"
            private var items: [String] = []

            init(name: String) {
                self.name = name
            }

            func increment() {
                count += 1
            }

            func decrement() {
                count -= 1
            }
        }

        """

        var currentLines = code.components(separatedBy: .newlines).count

        while currentLines < lines {
            code += """

            struct Item\(currentLines): Identifiable {
                let id = UUID()
                var title: String
                var value: Int
                var isActive: Bool = true

                func formatted() -> String {
                    return "\\(title): \\(value)"
                }

                mutating func toggle() {
                    isActive.toggle()
                }
            }

            """
            currentLines = code.components(separatedBy: .newlines).count
        }

        return code
    }

    private static func generateJSONCode(lines: Int) -> String {
        var items: [String] = []
        let itemLines = 5 // Each item takes about 5 lines
        let targetItems = lines / itemLines

        for i in 0..<max(targetItems, 1) {
            items.append("""
                {
                    "id": \(i),
                    "name": "Item \(i)",
                    "value": \(i * 10),
                    "active": \(i % 2 == 0)
                }
            """)
        }

        return """
        {
            "version": "1.0",
            "timestamp": "2026-01-21T10:00:00Z",
            "items": [
        \(items.joined(separator: ",\n"))
            ]
        }
        """
    }

    private static func generateXMLCode(lines: Int) -> String {
        var items: [String] = []
        let itemLines = 6 // Each item takes about 6 lines
        let targetItems = lines / itemLines

        for i in 0..<max(targetItems, 1) {
            items.append("""
                <item id="\(i)">
                    <name>Item \(i)</name>
                    <value>\(i * 10)</value>
                    <active>\(i % 2 == 0)</active>
                </item>
            """)
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <root version="1.0">
            <metadata>
                <created>2026-01-21</created>
                <author>Benchmark</author>
            </metadata>
            <items>
        \(items.joined(separator: "\n"))
            </items>
        </root>
        """
    }

    private static func generatePythonCode(lines: Int) -> String {
        var code = """
        #!/usr/bin/env python3
        \"\"\"
        Sample Python code for benchmarking.
        Contains typical Python patterns and syntax.
        \"\"\"

        import os
        import sys
        from typing import List, Dict, Optional

        class BenchmarkClass:
            \"\"\"A sample class for testing.\"\"\"

            def __init__(self, name: str):
                self.name = name
                self.count = 0
                self.items: List[str] = []

            def increment(self) -> int:
                self.count += 1
                return self.count

            def decrement(self) -> int:
                self.count -= 1
                return self.count

        """

        var currentLines = code.components(separatedBy: .newlines).count

        while currentLines < lines {
            code += """

        def process_item_\(currentLines)(data: Dict[str, any]) -> Optional[str]:
            \"\"\"Process a single item.\"\"\"
            if not data:
                return None

            result = []
            for key, value in data.items():
                if isinstance(value, str):
                    result.append(f"{key}: {value}")
                elif isinstance(value, int):
                    result.append(f"{key}: {value * 2}")

            return ", ".join(result)

        """
            currentLines = code.components(separatedBy: .newlines).count
        }

        return code
    }

    private static func generateBashCode(lines: Int) -> String {
        var code = """
        #!/bin/bash
        # Sample bash script for benchmarking
        # Contains typical shell script patterns

        set -euo pipefail

        # Configuration
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        LOG_FILE="${SCRIPT_DIR}/benchmark.log"

        # Functions
        log_message() {
            local message="$1"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
        }

        check_dependencies() {
            local deps=("curl" "jq" "git")
            for dep in "${deps[@]}"; do
                if ! command -v "$dep" &> /dev/null; then
                    echo "Error: $dep is required but not installed."
                    exit 1
                fi
            done
        }

        """

        var currentLines = code.components(separatedBy: .newlines).count

        while currentLines < lines {
            code += """

        process_item_\(currentLines)() {
            local input="$1"
            local output=""

            if [[ -z "$input" ]]; then
                echo "Error: No input provided"
                return 1
            fi

            # Process the input
            output=$(echo "$input" | tr '[:lower:]' '[:upper:]')
            echo "$output"
        }

        """
            currentLines = code.components(separatedBy: .newlines).count
        }

        return code
    }
}
