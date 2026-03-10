#!/bin/bash
set -euo pipefail

# dotViewer DMG Notarization Script (v2.5)
# Usage: ./scripts/notarize_app.sh [--dmg <path>] [--skip-staple]

KEYCHAIN_PROFILE="AC_PASSWORD"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$REPO_DIR/dotViewer/build"

SKIP_STAPLE=false
CUSTOM_DMG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dmg)
            CUSTOM_DMG="$2"
            shift 2
            ;;
        --skip-staple)
            SKIP_STAPLE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dmg <path>] [--skip-staple]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -n "$CUSTOM_DMG" ]; then
    DMG_PATH="$CUSTOM_DMG"
else
    DMG_PATH=$(find "$BUILD_DIR" -name "*.dmg" -type f 2>/dev/null | head -1 || true)
fi

if [ -z "${DMG_PATH:-}" ] || [ ! -f "$DMG_PATH" ]; then
    echo "Error: No DMG file found."
    exit 1
fi

echo "=============================================="
echo "  dotViewer DMG Notarization"
echo "=============================================="
echo "DMG: $DMG_PATH"

echo "Submitting for notarization..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait

if [ "$SKIP_STAPLE" = false ]; then
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH"
fi

echo "Verifying notarization..."
spctl --assess --verbose=4 --type install "$DMG_PATH"

echo "Notarization complete: $DMG_PATH"
