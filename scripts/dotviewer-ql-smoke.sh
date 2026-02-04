#!/usr/bin/env bash
# Script: dotviewer-ql-smoke.sh
# Description: Quick Look smoke test (trigger preview + capture logs).
#
# Usage:
#   ./scripts/dotviewer-ql-smoke.sh [file]
#
# Examples:
#   ./scripts/dotviewer-ql-smoke.sh TestFiles/dotviewer_heartbeat.md
#   ./scripts/dotviewer-ql-smoke.sh TestFiles/test.json

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FILE="${1:-$ROOT_DIR/TestFiles/dotviewer_heartbeat.md}"
[[ "$FILE" = /* ]] || FILE="$ROOT_DIR/$FILE"

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: file not found: $FILE" >&2
  exit 1
fi

CAPTURE="/tmp/dotviewer-ql-smoke-$$.log"
rm -f "$CAPTURE"

echo "Smoke testing Quick Look preview for:"
echo "  $FILE"

/usr/bin/log stream --style syslog --level default --process QuickLookExtension --timeout 12s >"$CAPTURE" 2>&1 &
LPID=$!

sleep 1
/usr/bin/qlmanage -p "$FILE" >/dev/null 2>&1 &
QPID=$!

sleep 5
kill "$QPID" >/dev/null 2>&1 || true
wait "$LPID" >/dev/null 2>&1 || true

echo
echo "Log highlights:"
grep -E "Preview request:|Routing check|HTML built|Heartbeat preview returned|Fallback:" "$CAPTURE" || true

echo
echo "Raw log capture:"
echo "  $CAPTURE"

