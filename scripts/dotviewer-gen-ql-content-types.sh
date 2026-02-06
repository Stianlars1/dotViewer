#!/usr/bin/env bash
# Script: dotviewer-gen-ql-content-types.sh
# Description: Generate a best-effort `QLSupportedContentTypes` list for dotViewer from FileTypeRegistry.
#
# Why: On macOS 15+, Quick Look preview selection appears to require an *exact* content type match
# (e.g. `public.python-script`, `com.netscape.javascript-source`), not just conformance to
# `public.source-code` / `public.text`. This script helps keep the list in `dotViewer/project.yml` current.
#
# Usage:
#   ./scripts/dotviewer-gen-ql-content-types.sh
#
# Output:
#   Prints YAML list items (`- <uti>`) to stdout.

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly DEFAULT_TYPES_JSON="$ROOT_DIR/dotViewer/Shared/DefaultFileTypes.json"

if [[ ! -f "$DEFAULT_TYPES_JSON" ]]; then
  echo "ERROR: default filetypes not found: $DEFAULT_TYPES_JSON" >&2
  exit 1
fi

tmp_json="$(mktemp -t dotviewer-ql-exts.XXXXXX.json)"
trap 'rm -f "$tmp_json"' EXIT

python3 - "$DEFAULT_TYPES_JSON" "$tmp_json" <<'PY'
import json
import sys
from pathlib import Path

registry_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])

data = json.loads(registry_path.read_text(encoding="utf-8"))
exts = []
for item in data:
    exts.extend(item.get("extensions", []))

seen = set()
ordered = []
for ext in exts:
    if ext not in seen:
        seen.add(ext)
        ordered.append(ext)

# Only single-part extensions are meaningful for UTType(filenameExtension:).
# Multi-dot types (e.g. env.local) are usually typed as public.data and are covered by public.data.
single = [e for e in ordered if "." not in e]

out_path.write_text(json.dumps(single, indent=2), encoding="utf-8")
PY

swift - "$tmp_json" <<'SWIFT'
import Foundation
import UniformTypeIdentifiers

let jsonURL = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try Data(contentsOf: jsonURL)
let exts = try JSONDecoder().decode([String].self, from: data)

func isTextual(_ type: UTType) -> Bool {
    type.conforms(to: .text) || type.conforms(to: .sourceCode) || type.conforms(to: .script) || type.conforms(to: .shellScript)
}

var utis = Set<String>()

// Always include public.data for dotfiles/unknown-extension previews.
utis.insert(UTType.data.identifier)
// Some important “data” UTIs are still text-based in practice (e.g. XML plists).
utis.insert("com.apple.property-list")

for ext in exts {
    if let type = UTType(filenameExtension: ext), isTextual(type) {
        utis.insert(type.identifier)
    }
}

for uti in utis.sorted() {
    print("- \(uti)")
}
SWIFT
