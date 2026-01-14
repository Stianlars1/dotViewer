#!/bin/bash
set -e

# dotViewer DMG Notarization Script
# Usage: ./scripts/notarize_app.sh [--dmg <path>] [--skip-staple]
#
# Examples:
#   ./scripts/notarize_app.sh                              # Notarize default DMG in build/
#   ./scripts/notarize_app.sh --dmg ~/Desktop/MyApp.dmg    # Notarize custom DMG
#   ./scripts/notarize_app.sh --skip-staple                # Submit but don't staple

# Configuration
APP_NAME="dotViewer"
KEYCHAIN_PROFILE="AC_PASSWORD"  # Set up with: xcrun notarytool store-credentials

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

# Defaults
SKIP_STAPLE=false
CUSTOM_DMG=""

# Parse arguments
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
            echo ""
            echo "Options:"
            echo "  --dmg <path>    Path to custom .dmg file to notarize"
            echo "  --skip-staple   Submit for notarization but skip stapling"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Determine DMG path
if [ -n "$CUSTOM_DMG" ]; then
    DMG_PATH="$CUSTOM_DMG"
else
    # Find the most recent DMG in build directory
    DMG_PATH=$(find "$BUILD_DIR" -name "*.dmg" -type f 2>/dev/null | head -1)
fi

# Validate DMG exists
if [ -z "$DMG_PATH" ] || [ ! -f "$DMG_PATH" ]; then
    echo "Error: No DMG file found."
    echo ""
    if [ -n "$CUSTOM_DMG" ]; then
        echo "The specified file does not exist: $CUSTOM_DMG"
    else
        echo "No DMG found in $BUILD_DIR"
        echo "Either build a DMG first or provide a custom path with --dmg <path>"
    fi
    exit 1
fi

cd "$PROJECT_DIR"

echo "=============================================="
echo "  dotViewer DMG Notarization"
echo "=============================================="
echo ""
echo "DMG: $DMG_PATH"
echo ""

echo "Submitting for notarization..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait

if [ "$SKIP_STAPLE" = false ]; then
    echo ""
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH"
fi

echo ""
echo "Verifying notarization..."
spctl --assess --verbose=4 --type install "$DMG_PATH"

echo ""
echo "=============================================="
echo "  Notarization Complete!"
echo "=============================================="
echo ""
echo "Notarized DMG: $DMG_PATH"
echo ""
