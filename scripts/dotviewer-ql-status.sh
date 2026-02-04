#!/usr/bin/env bash
# Script: dotviewer-ql-status.sh
# Description: Show Quick Look registration status for dotViewer extensions.
# Usage: ./scripts/dotviewer-ql-status.sh

set -euo pipefail
IFS=$'\n\t'

echo "Quick Look preview (effective):"
pluginkit -m -v -i com.stianlars1.dotViewer.QuickLookPreview || true

echo
echo "Quick Look thumbnail (effective):"
pluginkit -m -v -i com.stianlars1.dotViewer.QuickLookThumbnail || true

echo
echo "All registered dotViewer Quick Look plug-ins (duplicates included):"
pluginkit -m -ADv | grep -i dotviewer || true
