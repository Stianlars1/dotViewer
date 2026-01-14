#!/bin/bash
set -e

# Generate DMG background TIFF from the main @2x source image
# Usage: ./scripts/generate-dmg-background.sh
#
# Source: installer-assets/dmg-background_main.png (1320x800 @2x)
# Output: installer-assets/dmg-background.tiff (multi-res TIFF)

cd "$(dirname "$0")/.."

SOURCE="installer-assets/dmg-background_main.png"
OUTPUT_1X="installer-assets/dmg-background.png"
OUTPUT_2X="installer-assets/dmg-background@2x.png"
OUTPUT_TIFF="installer-assets/dmg-background.tiff"

if [ ! -f "$SOURCE" ]; then
    echo "Error: Source image not found: $SOURCE"
    exit 1
fi

echo "Generating DMG background from: $SOURCE"

# Create 1x version (660x400)
echo "  Creating 1x version..."
sips -z 400 660 "$SOURCE" --out "$OUTPUT_1X" > /dev/null

# Create @2x version with 144 DPI
echo "  Creating @2x version with 144 DPI..."
sips -s dpiWidth 144 -s dpiHeight 144 "$SOURCE" --out "$OUTPUT_2X" > /dev/null

# Bundle into multi-resolution TIFF
echo "  Bundling into TIFF..."
tiffutil -cathidpicheck "$OUTPUT_1X" "$OUTPUT_2X" -out "$OUTPUT_TIFF"

echo ""
echo "Created: $OUTPUT_TIFF"
echo "  - 1x: 660x400 @ 72 DPI"
echo "  - 2x: 1320x800 @ 144 DPI"
