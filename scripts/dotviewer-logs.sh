#!/usr/bin/env bash
# Script: dotviewer-logs.sh
# Description: Stream or query dotViewer logs.
# Usage: ./scripts/dotviewer-logs.sh [options]

set -euo pipefail
IFS=$'\n\t'

PREDICATE='subsystem == "com.stianlars1.dotViewer"'
# NOTE: /usr/bin/log "level" is inclusive-at-and-below.
# "default" includes default+info+debug (recommended for app extension debugging).
LEVEL="default"
MODE="stream"
LAST="1h"
PROCESS=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --stream           Stream logs (default)
  --last <duration>  Show historical logs, e.g. 10m, 1h, 1d
  --level <level>    Stream level (default: default)
  --process <name>   Filter by process name (e.g. QuickLookExtension)
  --preview          Shortcut for --process QuickLookExtension
  --thumbnail        Shortcut for --process QuickLookThumbnailExtension
  --xpc              Shortcut for --process HighlightXPC
  --category <cat>   Filter by category
  -h, --help         Show this help message
EOF
}

error() {
  echo "ERROR: $*" >&2
  exit 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stream)
        MODE="stream"
        shift
        ;;
      --last)
        MODE="show"
        LAST="${2:-}"
        [[ -n "$LAST" ]] || error "--last requires a value"
        shift 2
        ;;
      --level)
        LEVEL="${2:-}"
        [[ -n "$LEVEL" ]] || error "--level requires a value"
        shift 2
        ;;
      --process)
        PROCESS="${2:-}"
        [[ -n "$PROCESS" ]] || error "--process requires a value"
        shift 2
        ;;
      --preview)
        PROCESS="QuickLookExtension"
        shift
        ;;
      --thumbnail)
        PROCESS="QuickLookThumbnailExtension"
        shift
        ;;
      --xpc)
        PROCESS="HighlightXPC"
        shift
        ;;
      --category)
        local category="${2:-}"
        [[ -n "$category" ]] || error "--category requires a value"
        PREDICATE="$PREDICATE AND category == \"$category\""
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        error "Unknown argument: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  if [[ "$MODE" == "show" ]]; then
    args=(/usr/bin/log show --predicate "$PREDICATE" --last "$LAST")
    if [[ -n "$PROCESS" ]]; then
      args+=(--process "$PROCESS")
    fi
    "${args[@]}"
  else
    args=(/usr/bin/log stream --level "$LEVEL" --predicate "$PREDICATE")
    if [[ -n "$PROCESS" ]]; then
      args+=(--process "$PROCESS")
    fi
    "${args[@]}"
  fi
}

main "$@"
