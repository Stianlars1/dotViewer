#!/bin/bash
set -e

# dotViewer Release Script
# Usage: ./scripts/release.sh [version] [--skip-notarize] [--app-store]
#
# Examples:
#   ./scripts/release.sh 1.0          # Build, notarize, create DMG for v1.0
#   ./scripts/release.sh 1.0 --skip-notarize   # Skip notarization (for testing)
#   ./scripts/release.sh 1.0 --app-store       # Build for App Store submission

VERSION="${1:-1.0}"
SKIP_NOTARIZE=false
APP_STORE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-notarize)
            SKIP_NOTARIZE=true
            ;;
        --app-store)
            APP_STORE=true
            ;;
    esac
done

# Configuration
APP_NAME="dotViewer"
BUNDLE_ID="com.stianlars1.dotViewer"
TEAM_ID="7F5ZSQFCQ4"
KEYCHAIN_PROFILE="AC_PASSWORD"  # Set up with: xcrun notarytool store-credentials

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"

cd "$PROJECT_DIR"

echo "=============================================="
echo "  dotViewer Release Build"
echo "  Version: $VERSION"
echo "  Mode: $([ "$APP_STORE" = true ] && echo "App Store" || echo "Developer ID")"
echo "=============================================="
echo ""

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Archive
echo ""
echo "Creating archive..."

# Archive using project settings (profiles configured in Xcode)
xcodebuild -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="1" \
    -destination "generic/platform=macOS"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "Error: Archive failed"
    exit 1
fi

echo "Archive created at: $ARCHIVE_PATH"

# Export
if [ "$APP_STORE" = true ]; then
    echo ""
    echo "Exporting for App Store..."
    EXPORT_OPTIONS="ExportOptions-AppStore.plist"
    EXPORT_PATH="$BUILD_DIR/appstore"
else
    echo ""
    echo "Exporting for Developer ID distribution..."
    EXPORT_OPTIONS="ExportOptions-DevID.plist"
    EXPORT_PATH="$BUILD_DIR/export"
fi

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS"

APP_PATH="$EXPORT_PATH/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: Export failed"
    exit 1
fi

echo "Exported to: $APP_PATH"

# Verify code signature
echo ""
echo "Verifying code signature..."
codesign -dv --verbose=2 "$APP_PATH" 2>&1 | head -10

# For App Store builds, we're done (upload via Transporter or altool)
if [ "$APP_STORE" = true ]; then
    echo ""
    echo "=============================================="
    echo "  App Store Build Complete"
    echo "=============================================="
    echo ""
    echo "Upload using Transporter app or:"
    echo "  xcrun altool --upload-app -f \"$EXPORT_PATH/$APP_NAME.pkg\" -t macos --apiKey KEY_ID --apiIssuer ISSUER_ID"
    exit 0
fi

# Notarization (Developer ID only)
if [ "$SKIP_NOTARIZE" = false ]; then
    echo ""
    echo "Preparing for notarization..."

    # Create ZIP for notarization
    ZIP_PATH="$BUILD_DIR/$APP_NAME-$VERSION.zip"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    echo "Created: $ZIP_PATH"

    echo ""
    echo "Submitting for notarization..."
    echo "(This may take several minutes)"

    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

    echo ""
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"

    echo ""
    echo "Verifying notarization..."
    spctl --assess --verbose=4 --type execute "$APP_PATH"
fi

# Create DMG
echo ""
echo "Creating DMG installer..."

DMG_NAME="$APP_NAME-$VERSION-Installer.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
BACKGROUND="installer-assets/dmg-background.tiff"

# Check if create-dmg is available
if command -v create-dmg &> /dev/null; then
    # Remove old DMG if exists
    rm -f "$DMG_PATH"

    if [ -f "$BACKGROUND" ]; then
        create-dmg \
            --volname "Install $APP_NAME" \
            --window-pos 200 120 \
            --window-size 660 476 \
            --icon-size 128 \
            --icon "$APP_NAME.app" 130 190 \
            --hide-extension "$APP_NAME.app" \
            --app-drop-link 530 190 \
            --background "$BACKGROUND" \
            --no-internet-enable \
            "$DMG_PATH" \
            "$APP_PATH"
    else
        echo "Warning: Background image not found, creating basic DMG"
        create-dmg \
            --volname "Install $APP_NAME" \
            --window-pos 200 120 \
            --window-size 660 476 \
            --icon-size 128 \
            --icon "$APP_NAME.app" 130 190 \
            --hide-extension "$APP_NAME.app" \
            --app-drop-link 530 190 \
            --no-internet-enable \
            "$DMG_PATH" \
            "$APP_PATH"
    fi
else
    echo "create-dmg not found, creating basic DMG with hdiutil..."
    DMG_DIR="$BUILD_DIR/dmg-staging"
    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR"
    cp -R "$APP_PATH" "$DMG_DIR/"
    ln -s /Applications "$DMG_DIR/Applications"
    hdiutil create -volname "Install $APP_NAME" \
        -srcfolder "$DMG_DIR" \
        -ov -format UDZO \
        "$DMG_PATH"
fi

# Notarize DMG if notarization is enabled
if [ "$SKIP_NOTARIZE" = false ] && [ -f "$DMG_PATH" ]; then
    echo ""
    echo "Notarizing DMG..."
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

    xcrun stapler staple "$DMG_PATH"

    echo ""
    echo "Verifying DMG notarization..."
    spctl --assess --verbose=4 --type install "$DMG_PATH"
fi

echo ""
echo "=============================================="
echo "  Release Build Complete!"
echo "=============================================="
echo ""
echo "  App:    $APP_PATH"
echo "  DMG:    $DMG_PATH"
echo ""
echo "  Distribution:"
echo "    1. Upload DMG to GitHub Releases"
echo "    2. Host DMG on your website"
echo ""
echo "  GitHub Release command:"
echo "    gh release create v$VERSION \"$DMG_PATH\" --title \"$APP_NAME $VERSION\" --notes \"Release notes here\""
echo ""
