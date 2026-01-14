#!/bin/bash
set -e

# dotViewer DMG Installer Creation Script
# Usage: ./scripts/create-dmg.sh [path-to-app]
#
# Prerequisites:
# - brew install create-dmg
# - Background image at: installer-assets/dmg-background.tiff (multi-res TIFF with 1x and @2x)

APP_NAME="dotViewer"
DMG_NAME="dotViewer-Installer"
VOLUME_NAME="dotViewer"
BUILD_DIR="build"
BACKGROUND="installer-assets/dmg-background.tiff"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=========================================="
echo "  dotViewer DMG Installer Creator"
echo "=========================================="
echo ""

# Check for app path argument or look in build directory
if [ -n "$1" ]; then
    APP_PATH="$1"
else
    APP_PATH="$BUILD_DIR/$APP_NAME.app"
fi

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found"
    echo ""
    echo "Please provide the path to the built app:"
    echo "  ./scripts/create-dmg.sh /path/to/dotViewer.app"
    echo ""
    echo "Or build the app in Xcode first:"
    echo "  1. Open dotViewer.xcodeproj in Xcode"
    echo "  2. Product > Archive"
    echo "  3. Distribute App > Copy App"
    echo "  4. Save to: $BUILD_DIR/"
    exit 1
fi

# Create build directory if needed
mkdir -p "$BUILD_DIR"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "create-dmg not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install create-dmg
    else
        echo "Error: Homebrew not installed."
        echo "Install create-dmg manually: brew install create-dmg"
        exit 1
    fi
fi

# Check for background image
if [ ! -f "$BACKGROUND" ]; then
    echo "Warning: Background image not found at $BACKGROUND"
    echo "Creating DMG without custom background..."
    echo ""

    # Remove old DMG if exists
    rm -f "$BUILD_DIR/$DMG_NAME.dmg"

    # Create simple DMG without background
    create-dmg \
      --volname "$VOLUME_NAME" \
      --window-pos 200 120 \
      --window-size 660 476 \
      --icon-size 128 \
      --icon "$APP_NAME.app" 130 190 \
      --app-drop-link 530 190 \
      --hide-extension "$APP_NAME.app" \
      --no-internet-enable \
      "$BUILD_DIR/$DMG_NAME.dmg" \
      "$APP_PATH"
else
    echo "Using background image: $BACKGROUND"
    echo ""

    # Remove old DMG if exists
    rm -f "$BUILD_DIR/$DMG_NAME.dmg"

    # Create DMG with custom background
    create-dmg \
      --volname "$VOLUME_NAME" \
      --window-pos 200 120 \
      --window-size 660 476 \
      --icon-size 128 \
      --icon "$APP_NAME.app" 130 190 \
      --app-drop-link 530 190 \
      --background "$BACKGROUND" \
      --hide-extension "$APP_NAME.app" \
      --no-internet-enable \
      "$BUILD_DIR/$DMG_NAME.dmg" \
      "$APP_PATH"
fi

echo ""
echo "=========================================="
echo "  DMG created successfully!"
echo "=========================================="
echo ""
echo "  Location: $BUILD_DIR/$DMG_NAME.dmg"
echo ""
echo "  To test:"
echo "    open \"$BUILD_DIR/$DMG_NAME.dmg\""
echo ""
