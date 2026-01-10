#!/bin/bash
set -e

APP_NAME="dotViewer"
VERSION="1.0"
DMG_NAME="dotViewer-${VERSION}-Installer"
VOLUME_NAME="Install dotViewer"
BUILD_DIR="build/Release"
OUTPUT_DIR="dist"
BACKGROUND="installer-assets/dmg-background.png"

echo "🔨 Creating DMG installer for $APP_NAME v$VERSION..."

# Check if app exists
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "❌ Error: $BUILD_DIR/$APP_NAME.app not found"
    echo ""
    echo "Please build the app first:"
    echo "  1. Open dotViewer.xcodeproj in Xcode"
    echo "  2. Product > Archive"
    echo "  3. Distribute App > Copy App"
    echo "  4. Save to $BUILD_DIR"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Remove old DMG if exists
rm -f "$OUTPUT_DIR/$DMG_NAME.dmg"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "⚠️  Warning: create-dmg not found. Install with: brew install create-dmg"
    echo ""
    echo "Creating basic DMG without custom styling..."

    # Fallback: Create staging directory
    DMG_DIR="build/dmg-staging"
    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR"

    # Copy app and create Applications symlink
    cp -R "$BUILD_DIR/$APP_NAME.app" "$DMG_DIR/"
    ln -s /Applications "$DMG_DIR/Applications"

    # Create DMG
    hdiutil create -volname "$VOLUME_NAME" \
      -srcfolder "$DMG_DIR" \
      -ov -format UDZO \
      "$OUTPUT_DIR/$DMG_NAME.dmg"

    echo "✅ Basic DMG created: $OUTPUT_DIR/$DMG_NAME.dmg"
    echo ""
    echo "For a styled DMG with custom background, install create-dmg:"
    echo "  brew install create-dmg"
    exit 0
fi

# Verify background image exists
if [ ! -f "$BACKGROUND" ]; then
    echo "⚠️  Warning: Background image not found at $BACKGROUND"
    echo "Creating DMG without custom background..."
    BACKGROUND_ARGS=""
else
    BACKGROUND_ARGS="--background $BACKGROUND"
fi

# Create DMG with create-dmg
create-dmg \
  --volname "$VOLUME_NAME" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --icon "$APP_NAME.app" 150 200 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 500 200 \
  $BACKGROUND_ARGS \
  --no-internet-enable \
  "$OUTPUT_DIR/$DMG_NAME.dmg" \
  "$BUILD_DIR/$APP_NAME.app"

echo "✅ DMG created: $OUTPUT_DIR/$DMG_NAME.dmg"
echo ""
echo "Next steps:"
echo "  1. Open the DMG to verify appearance"
echo "  2. Test installation by dragging to Applications"
echo "  3. Distribute to users!"
