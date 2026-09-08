#!/bin/bash
# Create the styled release installer. An unstyled fallback must never be published silently.
set -euo pipefail

APP_PATH="${1:?Usage: package-dmg.sh <app> <destination> <version> [DropDMG configuration]}"
DESTINATION="${2:?Destination required}"
VERSION="${3:?Version required}"
PROFILE="${4:-dotviewer}"

if ! command -v dropdmg >/dev/null 2>&1; then
    echo "DropDMG is required to preserve the installer layout. Install it before packaging." >&2
    exit 1
fi
if [ ! -d "$APP_PATH" ]; then
    echo "App bundle not found: $APP_PATH" >&2
    exit 1
fi
DMG_PATH="$DESTINATION/dotViewer-$VERSION.dmg"
if [ -e "$DMG_PATH" ]; then
    echo "Installer already exists: $DMG_PATH. Use a clean destination." >&2
    exit 1
fi
mkdir -p "$DESTINATION"

if ! OUTPUT=$(dropdmg --config-name="$PROFILE" --destination="$DESTINATION" --base-name="dotViewer-$VERSION" "$APP_PATH" 2>&1); then
    echo "$OUTPUT" >&2
    echo "DropDMG failed. Resolve its configuration or access before releasing; no unstyled fallback was created." >&2
    exit 1
fi

if [ ! -f "$DMG_PATH" ]; then
    echo "$OUTPUT" >&2
    echo "DropDMG did not produce the expected installer: $DMG_PATH" >&2
    exit 1
fi
printf '%s\n' "$DMG_PATH"
