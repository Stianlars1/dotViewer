#!/bin/bash
# E2E Test Runner for dotViewer
# This script helps capture logs while testing Quick Look previews

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/e2e_test_results.log"

echo "=== dotViewer E2E Test Runner ===" | tee "$LOG_FILE"
echo "Started at: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Kill any existing QuickLookUIService to ensure fresh state
echo "Resetting QuickLook..." | tee -a "$LOG_FILE"
pkill -9 QuickLookUIService 2>/dev/null || true
qlmanage -r 2>&1 | tee -a "$LOG_FILE"
sleep 1

echo "" | tee -a "$LOG_FILE"
echo "=== Test Files ===" | tee -a "$LOG_FILE"
ls -la "$SCRIPT_DIR"/*.{swift,js,ts,py,go,rs,json,yaml,env,plist,xml,md,sh,zsh} 2>/dev/null | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "=== Starting Log Stream ===" | tee -a "$LOG_FILE"
echo "Press Ctrl+C to stop after testing" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Stream logs from our subsystem
log stream --predicate 'subsystem == "com.stianlars1.dotViewer"' --level debug 2>&1 | while read -r line; do
    echo "$line" | tee -a "$LOG_FILE"
done
