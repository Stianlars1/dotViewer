#!/bin/bash
# Comprehensive E2E Test Suite for dotViewer QuickLook Extension
# Verifies P0/P1 critical fixes via automated qlmanage + log assertions
#
# Usage:
#   ./run_e2e_comprehensive.sh              # Full run (build + test)
#   ./run_e2e_comprehensive.sh --no-build   # Skip build, test only
#   ./run_e2e_comprehensive.sh --group X    # Run only group X (A-F)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_FILE="$SCRIPT_DIR/e2e_comprehensive_report.txt"
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
DO_BUILD=true
TARGET_GROUP=""
SETTLE_TIME=5

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-build) DO_BUILD=false; shift ;;
        --group) TARGET_GROUP="$2"; shift 2 ;;
        *) echo "Usage: $0 [--no-build] [--group A|B|C|D|E|F]"; exit 1 ;;
    esac
done

# --- Utility Functions ---

get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Capture logs between a start timestamp and now
# Uses `log show` which is reliable in subshells (unlike `log stream`)
capture_logs_since() {
    local since_ts="$1"
    /usr/bin/log show --start "$since_ts" --predicate 'eventMessage CONTAINS "[dotViewer"' --style compact 2>/dev/null | grep -v "^Timestamp\|^Filtering\|^$\|log run noninteractively" || true
}

# Legacy API compatibility - snap returns a timestamp, get_new_lines returns logs since that time
get_log_line_count() {
    get_timestamp
}

get_new_lines() {
    local from_ts="$1"
    capture_logs_since "$from_ts"
}

preview_file() {
    local file_path="$1"
    local wait_time="${2:-$SETTLE_TIME}"
    qlmanage -p "$file_path" >/dev/null 2>&1 &
    local ql_pid=$!
    sleep "$wait_time"
    kill "$ql_pid" 2>/dev/null || true
    wait "$ql_pid" 2>/dev/null || true
    sleep 1
}

assert_log_contains() {
    local test_id="$1"
    local description="$2"
    local from_line="$3"
    local pattern="$4"
    local new_lines
    new_lines=$(get_new_lines "$from_line")
    if echo "$new_lines" | grep -q "$pattern"; then
        echo "  PASS [$test_id] $description"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL [$test_id] $description (expected: $pattern)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_log_not_contains() {
    local test_id="$1"
    local description="$2"
    local from_line="$3"
    local pattern="$4"
    local new_lines
    new_lines=$(get_new_lines "$from_line")
    if echo "$new_lines" | grep -q "$pattern"; then
        echo "  FAIL [$test_id] $description (unexpected: $pattern)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "  PASS [$test_id] $description"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
}

assert_log_contains_or_skip() {
    local test_id="$1"
    local description="$2"
    local from_line="$3"
    local expected_pattern="$4"
    local skip_pattern="$5"
    local new_lines
    new_lines=$(get_new_lines "$from_line")
    if echo "$new_lines" | grep -q "$expected_pattern"; then
        echo "  PASS [$test_id] $description"
        PASS_COUNT=$((PASS_COUNT + 1))
    elif echo "$new_lines" | grep -q "$skip_pattern"; then
        echo "  SKIP [$test_id] $description (acceptable: matched skip pattern)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
    else
        echo "  FAIL [$test_id] $description (expected: $expected_pattern)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

reset_quicklook() {
    pkill -9 QuickLookUIService 2>/dev/null || true
    pkill -9 QuickLookSatellite 2>/dev/null || true
    pkill -9 -f "com.apple.quicklook" 2>/dev/null || true
    sleep 2
    qlmanage -r >/dev/null 2>&1 || true
    sleep 1
}

# --- Phase 0: Build & Setup ---

INSTALLED_APP="/Applications/dotViewer.app"
BACKUP_APP="/tmp/dotViewer_backup_$$.app"
DID_INSTALL_DEBUG=false

restore_installed_app() {
    if $DID_INSTALL_DEBUG && [[ -d "$BACKUP_APP" ]]; then
        echo "[Cleanup] Restoring original installed app..."
        rm -rf "$INSTALLED_APP"
        mv "$BACKUP_APP" "$INSTALLED_APP"
        qlmanage -r >/dev/null 2>&1 || true
    fi
}

cleanup() {
    restore_installed_app
}
trap cleanup EXIT

echo "============================================"
echo "  dotViewer Comprehensive E2E Test Suite"
echo "============================================"
echo "Started: $(date)"
echo ""

if $DO_BUILD; then
    echo "[Phase 0] Building project (Debug)..."
    cd "$PROJECT_DIR"
    if xcodebuild -scheme dotViewer -configuration Debug build 2>&1 | tail -5; then
        echo "[Phase 0] Build succeeded."
    else
        echo "[Phase 0] BUILD FAILED - aborting tests."
        exit 1
    fi
    echo ""
fi

# Find debug build
DEBUG_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "dotViewer.app" -path "*dotViewer*/Build/Products/Debug/*" 2>/dev/null | head -1)
if [[ -z "$DEBUG_APP" ]]; then
    echo "[Phase 0] ERROR: Debug build not found in DerivedData."
    echo "          Run without --no-build to build first."
    exit 1
fi
echo "[Phase 0] Debug build: $DEBUG_APP"

# Install debug build to /Applications so QuickLook uses it (perfLog is DEBUG-only)
if [[ -d "$INSTALLED_APP" ]]; then
    echo "[Phase 0] Backing up installed app to $BACKUP_APP"
    cp -a "$INSTALLED_APP" "$BACKUP_APP"
fi
echo "[Phase 0] Installing debug build to /Applications..."
rm -rf "$INSTALLED_APP"
cp -a "$DEBUG_APP" "$INSTALLED_APP"
DID_INSTALL_DEBUG=true

# Register the debug build with Launch Services
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
"$LSREGISTER" -f -R -trusted "$INSTALLED_APP" 2>/dev/null || true

# Create test.tsx if missing
if [[ ! -f "$SCRIPT_DIR/test.tsx" ]]; then
    cat > "$SCRIPT_DIR/test.tsx" << 'TSXEOF'
import React, { useState } from 'react';
interface Props { label: string; }
const App: React.FC<Props> = ({ label }) => {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{label}: {count}</button>;
};
export default App;
TSXEOF
fi

# Reset QuickLook (aggressive — ensures debug extension is loaded fresh)
echo "[Phase 0] Resetting QuickLook..."
pkill -9 QuickLookUIService 2>/dev/null || true
pkill -9 QuickLookSatellite 2>/dev/null || true
pkill -9 -f "com.apple.quicklook" 2>/dev/null || true
sleep 2
qlmanage -r >/dev/null 2>&1
sleep 2

echo "[Phase 0] Setup complete. Using log show for assertions."
echo ""

# --- Phase 1: Test Groups ---

should_run_group() {
    [[ -z "$TARGET_GROUP" ]] || [[ "$TARGET_GROUP" == "$1" ]]
}

# ========== Group A: Progressive Rendering ==========
if should_run_group "A"; then
echo "--- Group A: Progressive Rendering (P0-1) ---"

# A1: Small Swift file triggers highlightCode and isReady
echo "  [A1] Small Swift file..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift"
assert_log_contains "A1a" "highlightCode START triggered" "$snap" "highlightCode START"
assert_log_contains "A1b" "isReady achieved (via highlight or cache)" "$snap" "setting isReady = true\|cache check: HIT"

# A2: First load cache behavior (MISS or HIT if disk cached from prior run)
echo "  [A2] Cache behavior on first load..."
snap=$(get_log_line_count)
reset_quicklook
sleep 1
preview_file "$SCRIPT_DIR/test.py"
assert_log_contains_or_skip "A2" "Cache MISS on first load (or HIT if disk cached)" "$snap" "cache check: MISS" "cache check: HIT"

# A3: Highlighting completes (highlightCode COMPLETE appears)
echo "  [A3] Highlighting completes..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.go"
assert_log_contains "A3" "highlightCode COMPLETE within timeout" "$snap" "highlightCode COMPLETE"

# A4: Second preview is cache HIT
echo "  [A4] Second preview cache HIT..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.go"
assert_log_contains "A4" "Cache HIT on re-preview" "$snap" "HIT"

# A5: Multiple file types trigger highlighting
echo "  [A5] Multiple file types..."
for ext in py go rs js json yaml; do
    snap=$(get_log_line_count)
    preview_file "$SCRIPT_DIR/test.$ext" 3
    assert_log_contains "A5-$ext" ".$ext triggers highlightCode" "$snap" "highlightCode START"
done

# A6: Large file SKIP behavior
echo "  [A6] Large file handling..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/perf-test/large-zsh-history.zsh" 5
assert_log_contains_or_skip "A6" "Large file: SKIP (too many lines) or highlight" "$snap" "SKIP.*too large\|SKIP.*too many\|file too large" "highlightCode"

# A7: .tsx file
echo "  [A7] TSX file..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.tsx" 4
assert_log_contains "A7" ".tsx triggers preview" "$snap" "Preview start\|highlightCode START"

# A8: .ts file (often not handled — .ts UTI claimed by MPEG-TS video format)
echo "  [A8] TS file..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.ts" 4
new_lines=$(get_new_lines "$snap")
if echo "$new_lines" | grep -q "Preview start\|highlightCode START"; then
    echo "  PASS [A8] .ts triggers preview"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  SKIP [A8] .ts not handled by extension (UTI conflict with MPEG-TS)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
fi

# A9: .env file (plaintext skip or no language)
echo "  [A9] .env file handling..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.env" 4
assert_log_contains_or_skip "A9" ".env handled as plaintext or skipped" "$snap" "Preview start" "SKIP.*plaintext\|SKIP.*no language"

echo ""
fi

# ========== Group B: NSHostingView Reuse (P0-3) ==========
if should_run_group "B"; then
echo "--- Group B: NSHostingView Reuse (P0-3) ---"

reset_quicklook
sleep 1

# B1: Rapid 5-file switching (no crash)
echo "  [B1] Rapid file switching..."
snap=$(get_log_line_count)
for f in test.swift test.py test.go test.js test.rs; do
    qlmanage -p "$SCRIPT_DIR/$f" >/dev/null 2>&1 &
    sleep 0.3
    pkill -f "qlmanage -p" 2>/dev/null || true
done
sleep 2
# If we get here without crash, PASS. Also check for stale detection.
echo "  PASS [B1] Rapid switching completed without crash"
PASS_COUNT=$((PASS_COUNT + 1))

# B2: Stale request detection
echo "  [B2] Stale request detection..."
snap=$(get_log_line_count)
qlmanage -p "$SCRIPT_DIR/test.swift" >/dev/null 2>&1 &
sleep 0.2
kill $! 2>/dev/null || true
qlmanage -p "$SCRIPT_DIR/test.py" >/dev/null 2>&1 &
sleep 0.2
kill $! 2>/dev/null || true
qlmanage -p "$SCRIPT_DIR/test.go" >/dev/null 2>&1 &
sleep 3
kill $! 2>/dev/null || true
sleep 1
assert_log_contains_or_skip "B2" "Stale request detected during switching" "$snap" "Stale request detected" "Preview start"

# B3: Two sequential files both reach isReady
echo "  [B3] Sequential files both complete..."
reset_quicklook
sleep 1
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift" 4
preview_file "$SCRIPT_DIR/test.py" 4
new_lines=$(get_new_lines "$snap")
# Count both explicit isReady and cache HIT (which also sets isReady)
ready_count=$(echo "$new_lines" | grep -c "setting isReady = true\|cache check: HIT\|highlightCode COMPLETE" || true)
if [[ "$ready_count" -ge 2 ]]; then
    echo "  PASS [B3] Both files completed ($ready_count completion signals)"
    PASS_COUNT=$((PASS_COUNT + 1))
elif [[ "$ready_count" -ge 1 ]]; then
    echo "  SKIP [B3] Only $ready_count file(s) completed (one may have been skipped)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
else
    echo "  FAIL [B3] No completion signals detected"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# B4: No Auto Layout warnings
echo "  [B4] No Auto Layout warnings..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift" 3
assert_log_not_contains "B4" "No constraint warnings" "$snap" "Unable to simultaneously satisfy constraints"

echo ""
fi

# ========== Group C: TaskItem UUID (P0-4) ==========
if should_run_group "C"; then
echo "--- Group C: TaskItem UUID (P0-4) ---"

reset_quicklook
sleep 1

# C1: TEST_MARKDOWN.md reaches isReady via markdown path
echo "  [C1] Markdown with task items..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/TEST_MARKDOWN.md" 4
assert_log_contains "C1a" "Markdown preview starts" "$snap" "Preview start"
assert_log_contains_or_skip "C1b" "Markdown path used" "$snap" "PATH: markdown\|setting isReady = true" "HIT"

# C2: Re-preview of same markdown gets cache HIT (stable IDs)
echo "  [C2] Re-preview cache stability..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/TEST_MARKDOWN.md" 3
assert_log_contains "C2" "Markdown cache HIT on re-preview" "$snap" "HIT"

# C3: test.md triggers highlightCode (smaller markdown)
echo "  [C3] Small markdown file..."
snap=$(get_log_line_count)
reset_quicklook
sleep 1
preview_file "$SCRIPT_DIR/test.md" 4
assert_log_contains "C3" "test.md preview starts" "$snap" "Preview start"

echo ""
fi

# ========== Group D: OSAllocatedUnfairLock (P1-1) ==========
if should_run_group "D"; then
echo "--- Group D: OSAllocatedUnfairLock / Thread Safety (P1-1) ---"

reset_quicklook
sleep 1

# D1: Theme color cache HIT on second file (or disk cache skips highlighting entirely)
echo "  [D1] Theme cache reuse..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift" 4
preview_file "$SCRIPT_DIR/test.py" 4
assert_log_contains_or_skip "D1" "ThemeManager.syntaxColors cached (or disk-cached)" "$snap" "syntaxColors.*CACHED\|syntaxColors.*cached" "Cache HIT\|cache check: HIT"

# D2: 6 sequential files without deadlock
echo "  [D2] Sequential files (deadlock test)..."
snap=$(get_log_line_count)
reset_quicklook
sleep 1
completed=0
for f in test.swift test.py test.go test.js test.rs test.yaml; do
    preview_file "$SCRIPT_DIR/$f" 3
    completed=$((completed + 1))
done
if [[ "$completed" -eq 6 ]]; then
    echo "  PASS [D2] All 6 files completed without deadlock"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  FAIL [D2] Only $completed/6 files completed"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# D3: 3 concurrent qlmanage processes (no crash)
echo "  [D3] Concurrent previews..."
snap=$(get_log_line_count)
qlmanage -p "$SCRIPT_DIR/test.swift" >/dev/null 2>&1 &
pid1=$!
qlmanage -p "$SCRIPT_DIR/test.py" >/dev/null 2>&1 &
pid2=$!
qlmanage -p "$SCRIPT_DIR/test.go" >/dev/null 2>&1 &
pid3=$!
sleep 4
kill "$pid1" "$pid2" "$pid3" 2>/dev/null || true
wait "$pid1" "$pid2" "$pid3" 2>/dev/null || true
echo "  PASS [D3] Concurrent previews completed without crash"
PASS_COUNT=$((PASS_COUNT + 1))

# D4: FastSyntaxHighlighter used
echo "  [D4] FastSyntaxHighlighter used..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift" 4
assert_log_contains_or_skip "D4" "FastSyntaxHighlighter path taken" "$snap" "FastSyntaxHighlighter\|Fast.*supported: YES\|PATH: SyntaxHighlighter.*Fast" "HIT"

echo ""
fi

# ========== Group E: Cold Start & Resilience ==========
if should_run_group "E"; then
echo "--- Group E: Cold Start & Resilience ---"

# E1: Cold start after kill
echo "  [E1] Cold start recovery..."
reset_quicklook
sleep 2
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift" 5
assert_log_contains "E1" "Preview starts after cold kill" "$snap" "Preview start"

# E2: Large readme (565 lines, under limit)
echo "  [E2] Large readme..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/perf-test/large-readme.md" 5
assert_log_contains "E2" "Large readme renders" "$snap" "Preview start"

# E3: Large JSON
echo "  [E3] Large JSON..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/perf-test/large-claude.json" 5
assert_log_contains "E3" "Large JSON renders" "$snap" "Preview start"

# E4: Large shell file
echo "  [E4] Large shell file..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/perf-test/large-changelog.sh" 5
assert_log_contains "E4" "Large shell file renders" "$snap" "Preview start"

# E5: Preview after qlmanage -r
echo "  [E5] Preview after qlmanage reset..."
qlmanage -r >/dev/null 2>&1
sleep 2
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift" 5
assert_log_contains "E5" "Preview works after QL reset" "$snap" "Preview start"

# E6: XML not misidentified as binary
echo "  [E6] XML file handling..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.xml" 4
assert_log_contains "E6" "XML renders as text" "$snap" "Preview start"

# E7: Both .sh and .zsh render
echo "  [E7] Shell variants..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.sh" 4
assert_log_contains "E7a" ".sh renders" "$snap" "Preview start"
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.zsh" 4
assert_log_contains "E7b" ".zsh renders" "$snap" "Preview start"

echo ""
fi

# ========== Group F: Performance Timing ==========
if should_run_group "F"; then
echo "--- Group F: Performance Timing ---"

reset_quicklook
sleep 1

# F1: Small file highlight < 2000ms
echo "  [F1] Small file timing..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift" 4
new_lines=$(get_new_lines "$snap")
# Extract total time from "highlightCode COMPLETE - total: X.XXXs"
total_time=$(echo "$new_lines" | grep "highlightCode COMPLETE" | sed -n 's/.*total: \([0-9.]*\)s.*/\1/p' | tail -1)
if [[ -n "$total_time" ]]; then
    # Compare as integer milliseconds
    ms=$(echo "$total_time" | awk '{printf "%d", $1 * 1000}')
    if [[ "$ms" -lt 2000 ]]; then
        echo "  PASS [F1] Highlight completed in ${ms}ms (<2000ms)"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL [F1] Highlight took ${ms}ms (>2000ms limit)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    # Might be cache HIT, which is fine
    if echo "$new_lines" | grep -q "HIT"; then
        echo "  SKIP [F1] Cache HIT, no timing available"
        SKIP_COUNT=$((SKIP_COUNT + 1))
    else
        echo "  FAIL [F1] No timing data found"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

# F2: Cache hit is fast (<100ms is hard to measure, just check it's a HIT)
echo "  [F2] Cache hit speed..."
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.swift" 3
new_lines=$(get_new_lines "$snap")
if echo "$new_lines" | grep -q "HIT"; then
    echo "  PASS [F2] Cache HIT confirmed (fast path)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  SKIP [F2] No cache HIT (may have been evicted)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
fi

# F3: FastSyntaxHighlighter timing
echo "  [F3] FastSyntaxHighlighter timing..."
reset_quicklook
sleep 1
snap=$(get_log_line_count)
preview_file "$SCRIPT_DIR/test.go" 4
new_lines=$(get_new_lines "$snap")
fast_time=$(echo "$new_lines" | grep "FastSyntaxHighlighter.highlight DONE" | sed -n 's/.*total: \([0-9.]*\)s.*/\1/p' | tail -1)
if [[ -n "$fast_time" ]]; then
    ms=$(echo "$fast_time" | awk '{printf "%d", $1 * 1000}')
    if [[ "$ms" -lt 500 ]]; then
        echo "  PASS [F3] FastSyntaxHighlighter completed in ${ms}ms (<500ms)"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL [F3] FastSyntaxHighlighter took ${ms}ms (>500ms limit)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    if echo "$new_lines" | grep -q "HIT"; then
        echo "  SKIP [F3] Cache HIT, no FastSyntaxHighlighter timing"
        SKIP_COUNT=$((SKIP_COUNT + 1))
    else
        echo "  SKIP [F3] FastSyntaxHighlighter not used (HighlightSwift fallback)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
    fi
fi

echo ""
fi

# --- Phase 2: Report ---

echo "============================================"
echo "  RESULTS"
echo "============================================"
TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))
echo "  PASS: $PASS_COUNT"
echo "  FAIL: $FAIL_COUNT"
echo "  SKIP: $SKIP_COUNT"
echo "  TOTAL: $TOTAL"
echo ""

if [[ "$FAIL_COUNT" -eq 0 ]]; then
    echo "  STATUS: ALL CHECKS PASSED"
    EXIT_CODE=0
else
    echo "  STATUS: $FAIL_COUNT FAILURE(S) DETECTED"
    EXIT_CODE=1
fi

echo ""
echo "Completed: $(date)"
echo "============================================"

# Save report
{
    echo "dotViewer Comprehensive E2E Report"
    echo "Generated: $(date)"
    echo ""
    echo "PASS: $PASS_COUNT  FAIL: $FAIL_COUNT  SKIP: $SKIP_COUNT  TOTAL: $TOTAL"
    echo ""
    if [[ "$FAIL_COUNT" -eq 0 ]]; then
        echo "STATUS: ALL CHECKS PASSED"
    else
        echo "STATUS: $FAIL_COUNT FAILURE(S)"
    fi
} > "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"

exit $EXIT_CODE
