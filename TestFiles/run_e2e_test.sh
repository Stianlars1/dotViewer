#!/bin/bash
# E2E Test Runner for dotViewer
# This script helps capture logs while testing Quick Look previews
#
# Usage:
#   ./run_e2e_test.sh           # Interactive mode - streams logs while you test
#   ./run_e2e_test.sh --quick   # Quick test - just resets QL and shows test files
#   ./run_e2e_test.sh --build   # Build project first, then run tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$SCRIPT_DIR/e2e_test_results.log"
BUILD_MODE=false
QUICK_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD_MODE=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--build] [--quick]"
            exit 1
            ;;
    esac
done

echo "=== dotViewer E2E Test Runner ===" | tee "$LOG_FILE"
echo "Started at: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Build if requested
if $BUILD_MODE; then
    echo "=== Building Project ===" | tee -a "$LOG_FILE"
    cd "$PROJECT_DIR"
    if xcodebuild -scheme dotViewer -configuration Debug build 2>&1 | tee -a "$LOG_FILE"; then
        echo "Build successful!" | tee -a "$LOG_FILE"
    else
        echo "Build FAILED!" | tee -a "$LOG_FILE"
        exit 1
    fi
    echo "" | tee -a "$LOG_FILE"
fi

# Kill any existing QuickLookUIService to ensure fresh state
echo "=== Resetting QuickLook ===" | tee -a "$LOG_FILE"
pkill -9 QuickLookUIService 2>/dev/null || true
qlmanage -r 2>&1 | tee -a "$LOG_FILE"
sleep 1

echo "" | tee -a "$LOG_FILE"
echo "=== Test Files Available ===" | tee -a "$LOG_FILE"

# List test files by category
echo "Source Code:" | tee -a "$LOG_FILE"
ls -la "$SCRIPT_DIR"/*.{swift,js,ts,py,go,rs,java,rb,php} 2>/dev/null | tee -a "$LOG_FILE" || true

echo "" | tee -a "$LOG_FILE"
echo "Config/Data:" | tee -a "$LOG_FILE"
ls -la "$SCRIPT_DIR"/*.{json,yaml,yml,toml,xml,plist} 2>/dev/null | tee -a "$LOG_FILE" || true

echo "" | tee -a "$LOG_FILE"
echo "Shell/Scripts:" | tee -a "$LOG_FILE"
ls -la "$SCRIPT_DIR"/*.{sh,zsh,bash} 2>/dev/null | tee -a "$LOG_FILE" || true

echo "" | tee -a "$LOG_FILE"
echo "Documentation:" | tee -a "$LOG_FILE"
ls -la "$SCRIPT_DIR"/*.md 2>/dev/null | tee -a "$LOG_FILE" || true

echo "" | tee -a "$LOG_FILE"
echo "Sensitive Files (should show warning banner):" | tee -a "$LOG_FILE"
ls -la "$SCRIPT_DIR"/*.env* "$SCRIPT_DIR"/credentials* "$SCRIPT_DIR"/*.pem "$SCRIPT_DIR"/*.key 2>/dev/null | tee -a "$LOG_FILE" || echo "  (none found)" | tee -a "$LOG_FILE"

if $QUICK_MODE; then
    echo "" | tee -a "$LOG_FILE"
    echo "=== Quick Mode Complete ===" | tee -a "$LOG_FILE"
    echo "Test files are ready. Use Finder to preview them with spacebar." | tee -a "$LOG_FILE"
    exit 0
fi

echo "" | tee -a "$LOG_FILE"
echo "=== Starting Log Stream ===" | tee -a "$LOG_FILE"
echo "Instructions:" | tee -a "$LOG_FILE"
echo "  1. Open Finder and navigate to: $SCRIPT_DIR" | tee -a "$LOG_FILE"
echo "  2. Select files and press Spacebar to preview" | tee -a "$LOG_FILE"
echo "  3. Logs will appear below" | tee -a "$LOG_FILE"
echo "  4. Press Ctrl+C to stop" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Stream logs from our subsystem
log stream --predicate 'subsystem == "com.stianlars1.dotViewer"' --level debug 2>&1 | while read -r line; do
    echo "$line" | tee -a "$LOG_FILE"
done
