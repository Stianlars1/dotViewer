#!/bin/bash
set -e

# ============================================================================
#  dotViewer Release Script
# ============================================================================
#
#  Single command to build, sign, notarize, and package dotViewer for release.
#
#  Usage:
#    ./scripts/release.sh [version] [options]
#
#  Options:
#    --app-store       Build for App Store submission (no DMG/notarization)
#    --skip-notarize   Skip notarization (testing only - users will see warnings)
#    --skip-dmg        Build and notarize app only, skip DMG creation
#    --github          Create GitHub release after build (requires gh CLI)
#    --help            Show this help message
#
#  Examples:
#    ./scripts/release.sh 1.0              # Full release: build + notarize + DMG
#    ./scripts/release.sh 1.0 --app-store  # App Store build only
#    ./scripts/release.sh 1.0 --github     # Full release + create GitHub release
#
# ============================================================================

# Terminal colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
#  CONFIGURATION
# ============================================================================

APP_NAME="dotViewer"
BUNDLE_ID="com.stianlars1.dotViewer"
TEAM_ID="7F5ZSQFCQ4"
KEYCHAIN_PROFILE="AC_PASSWORD"       # xcrun notarytool store-credentials
DROPDMG_PROFILE="dotviewer"          # DropDMG configuration name

# ============================================================================
#  ARGUMENT PARSING
# ============================================================================

VERSION=""
SKIP_NOTARIZE=false
SKIP_DMG=false
APP_STORE=false
CREATE_GITHUB_RELEASE=false

print_help() {
    echo ""
    echo "Usage: $0 [version] [options]"
    echo ""
    echo "Arguments:"
    echo "  version           Version number (e.g., 1.0, 1.0.1)"
    echo ""
    echo "Options:"
    echo "  --app-store       Build for App Store submission"
    echo "  --skip-notarize   Skip notarization (testing only)"
    echo "  --skip-dmg        Build app only, skip DMG creation"
    echo "  --github          Create GitHub release after build"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 1.0                        # Full release"
    echo "  $0 1.0.1 --app-store          # App Store build"
    echo "  $0 1.0 --github               # Full release + GitHub"
    echo ""
}

for arg in "$@"; do
    case $arg in
        --skip-notarize)
            SKIP_NOTARIZE=true
            ;;
        --skip-dmg)
            SKIP_DMG=true
            ;;
        --app-store)
            APP_STORE=true
            ;;
        --github)
            CREATE_GITHUB_RELEASE=true
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            if [[ -z "$VERSION" && "$arg" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                VERSION="$arg"
            fi
            ;;
    esac
done

# Require version
if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Version number required${NC}"
    print_help
    exit 1
fi

# ============================================================================
#  DIRECTORY SETUP
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"

if [ "$APP_STORE" = true ]; then
    EXPORT_OPTIONS="ExportOptions-AppStore.plist"
    EXPORT_PATH="$BUILD_DIR/appstore"
    BUILD_MODE="App Store"
else
    EXPORT_OPTIONS="ExportOptions-DevID.plist"
    EXPORT_PATH="$BUILD_DIR/export"
    BUILD_MODE="Developer ID"
fi

if [ "$APP_STORE" = true ]; then
    # App Store exports create a .pkg file
    APP_PATH="$EXPORT_PATH/$APP_NAME.pkg"
else
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
fi
DMG_FILENAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$EXPORT_PATH/$DMG_FILENAME"

cd "$PROJECT_DIR"

# ============================================================================
#  HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

check_prerequisites() {
    local missing=false

    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "xcodebuild not found. Install Xcode."
        missing=true
    fi

    # Check for notarytool (unless skipping)
    if [ "$SKIP_NOTARIZE" = false ] && [ "$APP_STORE" = false ]; then
        if ! xcrun notarytool --version &> /dev/null; then
            print_error "notarytool not found. Requires Xcode 13+."
            missing=true
        fi
    fi

    # Check for dropdmg (unless skipping DMG or App Store)
    if [ "$SKIP_DMG" = false ] && [ "$APP_STORE" = false ]; then
        if ! command -v dropdmg &> /dev/null; then
            print_error "dropdmg not found."
            echo "    Install: DropDMG app → Advanced → Install dropdmg Tool"
            missing=true
        fi
    fi

    # Check for gh CLI if GitHub release requested
    if [ "$CREATE_GITHUB_RELEASE" = true ]; then
        if ! command -v gh &> /dev/null; then
            print_error "gh CLI not found. Install: brew install gh"
            missing=true
        fi
    fi

    # Check export options file exists
    if [ ! -f "$PROJECT_DIR/$EXPORT_OPTIONS" ]; then
        print_error "Export options not found: $EXPORT_OPTIONS"
        missing=true
    fi

    if [ "$missing" = true ]; then
        echo ""
        print_error "Prerequisites check failed. Fix the issues above and try again."
        exit 1
    fi

    print_success "All prerequisites satisfied"
}

# ============================================================================
#  MAIN BUILD PROCESS
# ============================================================================

START_TIME=$(date +%s)

print_header "dotViewer Release Build v$VERSION"
echo "  Mode:    $BUILD_MODE"
echo "  Version: $VERSION"
if [ "$SKIP_NOTARIZE" = true ]; then
    echo -e "  ${YELLOW}Notarization: SKIPPED (testing only)${NC}"
fi
if [ "$SKIP_DMG" = true ]; then
    echo "  DMG: Skipped"
fi
if [ "$CREATE_GITHUB_RELEASE" = true ]; then
    echo "  GitHub: Will create release"
fi
echo ""

# ============================================================================
#  STEP 1: Prerequisites Check
# ============================================================================

print_step "Step 1/8: Checking prerequisites..."
check_prerequisites

# ============================================================================
#  STEP 2: Clean Build Directory
# ============================================================================

print_step "Step 2/8: Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
print_success "Build directory cleaned"

# ============================================================================
#  STEP 3: Archive
# ============================================================================

print_step "Step 3/8: Creating archive..."
echo ""

xcodebuild -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="1" \
    -destination "generic/platform=macOS" \
    -quiet

if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive failed - no archive created"
    exit 1
fi

print_success "Archive created: $ARCHIVE_PATH"

# ============================================================================
#  STEP 4: Export
# ============================================================================

print_step "Step 4/8: Exporting for $BUILD_MODE distribution..."

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -quiet

if [ "$APP_STORE" = true ]; then
    # App Store exports create a .pkg file
    if [ ! -f "$APP_PATH" ]; then
        print_error "Export failed - no pkg created"
        exit 1
    fi
    print_success "Exported: $APP_PATH"

    # Verify pkg signature
    print_step "Step 5/8: Verifying package signature..."
    pkgutil --check-signature "$APP_PATH"
    if [ $? -eq 0 ]; then
        print_success "Package signature valid"
    else
        print_warning "Package signature check returned non-zero"
    fi

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    print_header "App Store Build Complete!"
    echo "  Duration: ${DURATION}s"
    echo ""
    echo "  Package: $APP_PATH"
    echo ""
    echo -e "  ${BOLD}Next Steps:${NC}"
    echo "  1. Open Transporter app"
    echo "  2. Drag the .pkg file to Transporter"
    echo "  3. Click Deliver"
    echo ""
    echo "  Or upload via command line:"
    echo "  xcrun altool --upload-package -f \"$APP_PATH\" -t macos -u YOUR_APPLE_ID -p @keychain:AC_PASSWORD"
    echo ""
    exit 0
fi

if [ ! -d "$APP_PATH" ]; then
    print_error "Export failed - no app created"
    exit 1
fi

print_success "Exported: $APP_PATH"

# ============================================================================
#  STEP 5: Verify Code Signature
# ============================================================================

print_step "Step 5/8: Verifying code signature..."

# Verify the app signature
codesign --verify --deep --strict "$APP_PATH" 2>&1
if [ $? -eq 0 ]; then
    print_success "Code signature valid"
else
    print_error "Code signature verification failed"
    exit 1
fi

# Show signing identity
SIGNING_INFO=$(codesign -dv "$APP_PATH" 2>&1 | grep "Authority" | head -1)
echo "    $SIGNING_INFO"

# ============================================================================
#  STEP 6: Notarize App
# ============================================================================

if [ "$SKIP_NOTARIZE" = false ]; then
    print_step "Step 6/8: Notarizing app..."

    # Create ZIP for notarization
    ZIP_PATH="$BUILD_DIR/$APP_NAME-$VERSION-app.zip"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    echo "    Created ZIP for submission: $(basename "$ZIP_PATH")"

    echo "    Submitting to Apple notary service..."
    echo "    (This typically takes 2-5 minutes)"
    echo ""

    # Submit and wait for notarization
    NOTARY_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait 2>&1)

    NOTARY_STATUS=$?

    if [ $NOTARY_STATUS -ne 0 ]; then
        echo "$NOTARY_OUTPUT"
        print_error "Notarization failed"
        echo ""
        echo "Check the log with:"
        SUBMISSION_ID=$(echo "$NOTARY_OUTPUT" | grep "id:" | head -1 | awk '{print $2}')
        if [ -n "$SUBMISSION_ID" ]; then
            echo "  xcrun notarytool log $SUBMISSION_ID --keychain-profile \"$KEYCHAIN_PROFILE\""
        fi
        exit 1
    fi

    # Check if notarization was successful
    if echo "$NOTARY_OUTPUT" | grep -q "status: Accepted"; then
        print_success "Notarization accepted"
    else
        echo "$NOTARY_OUTPUT"
        print_warning "Notarization status unclear - checking..."
    fi

    # Staple the notarization ticket
    echo "    Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    print_success "Notarization ticket stapled"

    # Verify with Gatekeeper
    echo "    Verifying with Gatekeeper..."
    SPCTL_OUTPUT=$(spctl --assess --verbose=4 --type execute "$APP_PATH" 2>&1)
    if echo "$SPCTL_OUTPUT" | grep -q "accepted"; then
        print_success "Gatekeeper verification passed"
        echo "    $SPCTL_OUTPUT"
    else
        print_warning "Gatekeeper check: $SPCTL_OUTPUT"
    fi

    # Clean up ZIP
    rm -f "$ZIP_PATH"
else
    print_step "Step 6/8: Notarizing app... SKIPPED"
    print_warning "App is not notarized - users will see security warnings"
fi

# ============================================================================
#  STEP 7: Create DMG with DropDMG
# ============================================================================

if [ "$SKIP_DMG" = false ]; then
    print_step "Step 7/8: Creating DMG installer..."

    # Create DMG using DropDMG with the configured profile
    # dropdmg outputs the path to the created file
    echo "    Using DropDMG profile: $DROPDMG_PROFILE"

    DROPDMG_OUTPUT=$(dropdmg \
        --config-name="$DROPDMG_PROFILE" \
        --destination="$EXPORT_PATH" \
        --base-name="$APP_NAME-$VERSION" \
        "$APP_PATH" 2>&1)

    DROPDMG_STATUS=$?

    if [ $DROPDMG_STATUS -ne 0 ]; then
        print_error "DropDMG failed:"
        echo "$DROPDMG_OUTPUT"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Ensure DropDMG app is installed"
        echo "  2. Ensure dropdmg CLI is installed: DropDMG → Advanced → Install dropdmg Tool"
        echo "  3. Ensure '$DROPDMG_PROFILE' configuration exists in DropDMG preferences"
        exit 1
    fi

    # dropdmg outputs the path to created file - extract it
    # The output is typically just the path
    CREATED_DMG=$(echo "$DROPDMG_OUTPUT" | tail -1)

    # Verify DMG was created
    if [ -f "$CREATED_DMG" ]; then
        DMG_PATH="$CREATED_DMG"
        DMG_FILENAME=$(basename "$DMG_PATH")
        print_success "DMG created: $DMG_FILENAME"
    elif [ -f "$DMG_PATH" ]; then
        print_success "DMG created: $DMG_FILENAME"
    else
        # Try to find the DMG
        FOUND_DMG=$(find "$EXPORT_PATH" -name "*.dmg" -type f 2>/dev/null | head -1)
        if [ -n "$FOUND_DMG" ]; then
            DMG_PATH="$FOUND_DMG"
            DMG_FILENAME=$(basename "$DMG_PATH")
            print_success "DMG created: $DMG_FILENAME"
        else
            print_error "DMG creation failed - no DMG file found"
            echo "DropDMG output: $DROPDMG_OUTPUT"
            exit 1
        fi
    fi

    # Show DMG size
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo "    Size: $DMG_SIZE"

    # ========================================================================
    #  STEP 8: Notarize DMG
    # ========================================================================

    if [ "$SKIP_NOTARIZE" = false ]; then
        print_step "Step 8/8: Notarizing DMG..."

        echo "    Submitting DMG to Apple notary service..."

        DMG_NOTARY_OUTPUT=$(xcrun notarytool submit "$DMG_PATH" \
            --keychain-profile "$KEYCHAIN_PROFILE" \
            --wait 2>&1)

        DMG_NOTARY_STATUS=$?

        if [ $DMG_NOTARY_STATUS -ne 0 ]; then
            echo "$DMG_NOTARY_OUTPUT"
            print_error "DMG notarization failed"
            exit 1
        fi

        if echo "$DMG_NOTARY_OUTPUT" | grep -q "status: Accepted"; then
            print_success "DMG notarization accepted"
        fi

        # Staple the DMG
        echo "    Stapling notarization ticket to DMG..."
        xcrun stapler staple "$DMG_PATH"
        print_success "DMG notarization ticket stapled"

        # Verify DMG with Gatekeeper
        echo "    Verifying DMG with Gatekeeper..."
        DMG_SPCTL=$(spctl --assess --verbose=4 --type install "$DMG_PATH" 2>&1)
        if echo "$DMG_SPCTL" | grep -q "accepted"; then
            print_success "DMG Gatekeeper verification passed"
        else
            print_warning "DMG Gatekeeper check: $DMG_SPCTL"
        fi
    else
        print_step "Step 8/8: Notarizing DMG... SKIPPED"
    fi
else
    print_step "Step 7/8: Creating DMG... SKIPPED"
    print_step "Step 8/8: Notarizing DMG... SKIPPED"
fi

# ============================================================================
#  GENERATE CHECKSUMS
# ============================================================================

if [ "$SKIP_DMG" = false ] && [ -f "$DMG_PATH" ]; then
    CHECKSUM_FILE="$DMG_PATH.sha256"
    shasum -a 256 "$DMG_PATH" > "$CHECKSUM_FILE"
    print_success "Checksum generated: $(basename "$CHECKSUM_FILE")"
fi

# ============================================================================
#  CREATE GITHUB RELEASE (if requested)
# ============================================================================

if [ "$CREATE_GITHUB_RELEASE" = true ] && [ -f "$DMG_PATH" ]; then
    print_step "Creating GitHub release..."

    # Check if tag already exists
    if git tag -l "v$VERSION" | grep -q "v$VERSION"; then
        print_warning "Tag v$VERSION already exists - skipping tag creation"
    else
        git tag "v$VERSION"
        print_success "Created tag: v$VERSION"
    fi

    # Create release
    gh release create "v$VERSION" \
        "$DMG_PATH" \
        --title "$APP_NAME $VERSION" \
        --notes "## $APP_NAME $VERSION

Quick Look extension for source code and dotfiles.

### Installation
1. Download the DMG
2. Open it and drag $APP_NAME to Applications
3. Launch $APP_NAME once to register the extension
4. Press Space on any code file in Finder to preview

### Requirements
- macOS 13.0 or later

---
*Built and notarized with Apple Developer ID*"

    print_success "GitHub release created: v$VERSION"
    GITHUB_URL=$(gh release view "v$VERSION" --json url --jq .url)
fi

# ============================================================================
#  FINAL SUMMARY
# ============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_header "Release Build Complete!"

echo "  Version:  $VERSION"
echo "  Duration: ${MINUTES}m ${SECONDS}s"
echo ""
echo -e "${BOLD}  Build Outputs:${NC}"
echo ""
echo "  Archive:  $ARCHIVE_PATH"
echo "  App:      $APP_PATH"

if [ "$SKIP_DMG" = false ] && [ -f "$DMG_PATH" ]; then
    echo "  DMG:      $DMG_PATH"
    echo "  Checksum: $CHECKSUM_FILE"
fi

if [ "$SKIP_NOTARIZE" = false ]; then
    echo ""
    echo -e "  ${GREEN}✓ App notarized and stapled${NC}"
    if [ "$SKIP_DMG" = false ]; then
        echo -e "  ${GREEN}✓ DMG notarized and stapled${NC}"
    fi
else
    echo ""
    echo -e "  ${YELLOW}⚠ Notarization skipped - users will see security warnings${NC}"
fi

if [ -n "$GITHUB_URL" ]; then
    echo ""
    echo -e "  ${GREEN}✓ GitHub release created${NC}"
    echo "    $GITHUB_URL"
fi

echo ""
echo -e "${BOLD}  Quick Verification:${NC}"
echo ""
if [ "$SKIP_DMG" = false ] && [ -f "$DMG_PATH" ]; then
    echo "  # Mount and test DMG"
    echo "  open \"$DMG_PATH\""
fi
echo ""
echo "  # Verify Gatekeeper"
echo "  spctl --assess -v --type execute \"$APP_PATH\""
echo ""

if [ "$CREATE_GITHUB_RELEASE" = false ] && [ "$SKIP_DMG" = false ]; then
    echo -e "${BOLD}  To create GitHub release:${NC}"
    echo ""
    echo "  gh release create v$VERSION \"$DMG_PATH\" --title \"$APP_NAME $VERSION\""
    echo ""
fi

echo ""
