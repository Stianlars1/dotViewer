#!/bin/bash
set -euo pipefail

# ============================================================================
#  dotViewer Release Script
# ============================================================================
#
#  Build, sign, notarize, and package dotViewer for release.
#
#  Usage:
#    ./scripts/release.sh [version] [options]
#
#  Options:
#    --app-store              Build for App Store submission (no DMG/notarization)
#    --skip-notarize          Skip notarization (testing only)
#    --skip-dmg               Build and notarize app only, skip DMG creation
#    --github                 Create GitHub release after build (requires gh CLI)
#    --build-number=<number>  Override CURRENT_PROJECT_VERSION for this build
#    --help                   Show this help message
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

APP_NAME="dotViewer"
TEAM_ID="7F5ZSQFCQ4"
KEYCHAIN_PROFILE="AC_PASSWORD"
DROPDMG_PROFILE="dotviewer"

VERSION=""
SKIP_NOTARIZE=false
SKIP_DMG=false
APP_STORE=false
CREATE_GITHUB_RELEASE=false
BUILD_NUMBER=""

create_manual_dmg() {
    local staging_dir="$BUILD_DIR/dmg-staging"
    local temp_dmg="$BUILD_DIR/$APP_NAME-$VERSION-temp.dmg"

    rm -rf "$staging_dir" "$temp_dmg" "$DMG_PATH"
    mkdir -p "$staging_dir"

    ditto "$APP_PATH" "$staging_dir/$APP_NAME.app"
    ln -s /Applications "$staging_dir/Applications"

    print_warning "Using hdiutil fallback to create DMG"

    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$staging_dir" \
        -fs HFS+ \
        -format UDRW \
        "$temp_dmg" \
        -quiet

    hdiutil convert \
        "$temp_dmg" \
        -format UDZO \
        -imagekey zlib-level=9 \
        -o "$DMG_PATH" \
        -quiet

    rm -f "$temp_dmg"
    rm -rf "$staging_dir"
}

sign_dmg_if_needed() {
    if codesign --verify --verbose=2 "$DMG_PATH" >/dev/null 2>&1; then
        print_success "DMG signature already present"
        return
    fi

    local signing_identity
    local signing_hash
    signing_identity=$(codesign -dvvv "$APP_PATH" 2>&1 \
        | sed -n 's/^Authority=//p' \
        | grep '^Developer ID Application:' \
        | head -1 || true)

    if [ -z "$signing_identity" ]; then
        print_error "Could not determine Developer ID Application identity for DMG signing"
        exit 1
    fi

    signing_hash=$(security find-identity -v -p codesigning \
        | awk -v subject="$signing_identity" 'index($0, "\"" subject "\"") { print $2; exit }')

    if [ -z "$signing_hash" ]; then
        print_error "Could not resolve a codesigning fingerprint for: $signing_identity"
        exit 1
    fi

    print_step "Signing DMG installer..."
    codesign --force --sign "$signing_hash" --timestamp "$DMG_PATH"
    print_success "DMG signed: $signing_identity ($signing_hash)"

    if codesign --verify --verbose=2 "$DMG_PATH" >/dev/null 2>&1; then
        print_success "DMG signature verification passed"
    else
        print_error "DMG signature verification failed"
        exit 1
    fi
}

extract_distribution_log_path() {
    local output="$1"

    printf '%s\n' "$output" \
        | sed -n 's/.*Created bundle at path "\(.*\.xcdistributionlogs\)".*/\1/p' \
        | tail -1
}

latest_distribution_log_path() {
    local temp_root="${TMPDIR:-/tmp}"

    find "$temp_root" -maxdepth 1 -type d -name "*.xcdistributionlogs" -print0 2>/dev/null \
        | xargs -0 stat -f '%m %N' 2>/dev/null \
        | sort -nr \
        | head -1 \
        | cut -d' ' -f2-
}

diagnose_export_failure() {
    local export_output="$1"
    local log_bundle
    local provisioning_log
    local app_store_log
    local account
    local missing_profiles

    log_bundle="$(extract_distribution_log_path "$export_output")"

    if [ -z "$log_bundle" ] || [ ! -d "$log_bundle" ]; then
        log_bundle="$(latest_distribution_log_path)"
    fi

    echo ""
    print_error "Export failed"

    if [ -n "$log_bundle" ] && [ -d "$log_bundle" ]; then
        echo "  Distribution logs: $log_bundle"
    else
        print_warning "Could not locate Xcode distribution logs for deeper diagnostics"
        return
    fi

    provisioning_log="$log_bundle/IDEDistributionProvisioning.log"
    app_store_log="$log_bundle/IDEDistributionAppStoreConnect.log"

    if [ -f "$provisioning_log" ]; then
        account="$(sed -n "s/.*username='\\([^']*\\)'.*/\\1/p" "$provisioning_log" | head -1)"
        missing_profiles="$(sed -n "s/.*No profiles for '\\([^']*\\)'.*/\\1/p" "$provisioning_log" | sort -u)"

        if grep -q "FORBIDDEN_ERROR.PLA_NOT_ACCEPTED" "$provisioning_log"; then
            echo "  Apple Developer portal access is still blocked for team $TEAM_ID."
            if [ -n "$account" ]; then
                echo "  Account used: $account"
            fi
            echo "  Apple returned FORBIDDEN_ERROR.PLA_NOT_ACCEPTED while Xcode requested"
            echo "  Mac App Store signing assets for this archive."
            echo ""
            echo "  This is not a stale export flag in this script."
            echo "  App Store Connect access is working, but Developer portal provisioning"
            echo "  for team $TEAM_ID is still denied by Apple."
            echo ""
            echo "  Next steps:"
            echo "    1. Accept the latest Apple Developer Program License Agreement on"
            echo "       developer.apple.com for team $TEAM_ID."
            echo "    2. In Xcode > Settings > Accounts, sign out and back in for the"
            echo "       account above, then restart Xcode."
            echo "    3. Re-run: ./scripts/release.sh $VERSION --app-store"
        fi

        if [ -n "$missing_profiles" ]; then
            echo ""
            echo "  Missing Mac App Store provisioning profiles:"
            while IFS= read -r bundle_id; do
                [ -n "$bundle_id" ] && echo "    - $bundle_id"
            done <<< "$missing_profiles"
        fi
    fi

    if [ -f "$app_store_log" ] && grep -q "fetched 1 items, total 1 items" "$app_store_log"; then
        echo ""
        echo "  App Store Connect app lookup succeeded."
        echo "  The blocker is provisioning/certificate access, not the app record."
    fi
}

print_help() {
    cat <<USAGE

Usage: $0 [version] [options]

Arguments:
  version           Version number (e.g., 1.1.0, 1.1.1)

Options:
  --app-store       Build for App Store submission
  --skip-notarize   Skip notarization (testing only)
  --skip-dmg        Build app only, skip DMG creation
  --github          Create GitHub release after build
  --build-number=N  Override CURRENT_PROJECT_VERSION for this build
  --help            Show this help message

Examples:
  $0 1.1.0
  $0 1.1.1 --app-store
  $0 1.1.0 --github
  $0 1.2.0 --app-store --build-number=3

USAGE
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
        --build-number=*)
            BUILD_NUMBER="${arg#*=}"
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

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Version number required${NC}"
    print_help
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$REPO_DIR/dotViewer"
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

EXPORT_OPTIONS_PATH="$PROJECT_DIR/$EXPORT_OPTIONS"

if [ "$APP_STORE" = true ]; then
    APP_PATH="$EXPORT_PATH/$APP_NAME.pkg"
else
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
fi

DMG_FILENAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$EXPORT_PATH/$DMG_FILENAME"

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

    if ! command -v xcodebuild >/dev/null 2>&1; then
        print_error "xcodebuild not found. Install Xcode."
        missing=true
    fi

    if [ "$SKIP_NOTARIZE" = false ] && [ "$APP_STORE" = false ]; then
        if ! xcrun notarytool --version >/dev/null 2>&1; then
            print_error "notarytool not found. Requires Xcode 13+."
            missing=true
        fi
    fi

    if [ "$SKIP_DMG" = false ] && [ "$APP_STORE" = false ]; then
    if ! command -v dropdmg >/dev/null 2>&1 && ! command -v hdiutil >/dev/null 2>&1; then
        print_error "Neither dropdmg nor hdiutil is available for DMG creation."
        missing=true
    fi
    fi

    if [ "$CREATE_GITHUB_RELEASE" = true ]; then
        if ! command -v gh >/dev/null 2>&1; then
            print_error "gh CLI not found. Install: brew install gh"
            missing=true
        fi
    fi

    if [ ! -f "$EXPORT_OPTIONS_PATH" ]; then
        print_error "Export options not found: $EXPORT_OPTIONS_PATH"
        missing=true
    fi

    if [ "$missing" = true ]; then
        echo ""
        print_error "Prerequisites check failed. Fix the issues above and try again."
        exit 1
    fi

    print_success "All prerequisites satisfied"
}

START_TIME=$(date +%s)

print_header "dotViewer Release Build v$VERSION"
echo "  Mode:    $BUILD_MODE"
echo "  Version: $VERSION"
if [ -n "$BUILD_NUMBER" ]; then
    echo "  Build:   $BUILD_NUMBER"
fi
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

print_step "Step 1/8: Checking prerequisites..."
check_prerequisites

print_step "Step 2/8: Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
print_success "Build directory cleaned"

print_step "Step 3/8: Creating archive..."
echo ""

XCODEBUILD_VERSION_ARGS=(MARKETING_VERSION="$VERSION")
if [ -n "$BUILD_NUMBER" ]; then
    XCODEBUILD_VERSION_ARGS+=(CURRENT_PROJECT_VERSION="$BUILD_NUMBER")
fi

xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    archive \
    "${XCODEBUILD_VERSION_ARGS[@]}" \
    -destination "generic/platform=macOS" \
    -quiet

if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive failed - no archive created"
    exit 1
fi

print_success "Archive created: $ARCHIVE_PATH"

print_step "Step 4/8: Exporting for $BUILD_MODE distribution..."

set +e
EXPORT_OUTPUT=$(xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -allowProvisioningUpdates \
    -quiet 2>&1)
EXPORT_STATUS=$?
set -e

if [ -n "$EXPORT_OUTPUT" ]; then
    echo "$EXPORT_OUTPUT"
fi

if [ "$EXPORT_STATUS" -ne 0 ]; then
    diagnose_export_failure "$EXPORT_OUTPUT"
    exit "$EXPORT_STATUS"
fi

if [ "$APP_STORE" = true ]; then
    if [ ! -f "$APP_PATH" ]; then
        print_error "Export failed - no pkg created"
        exit 1
    fi
    print_success "Exported: $APP_PATH"

    print_step "Step 5/8: Verifying package signature..."
    if pkgutil --check-signature "$APP_PATH" >/dev/null 2>&1; then
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
    exit 0
fi

if [ ! -d "$APP_PATH" ]; then
    print_error "Export failed - no app created"
    exit 1
fi

print_success "Exported: $APP_PATH"

print_step "Step 5/8: Verifying code signature..."
if codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1; then
    print_success "Code signature valid"
else
    print_error "Code signature verification failed"
    exit 1
fi

SIGNING_INFO=$(codesign -dv "$APP_PATH" 2>&1 | grep "Authority" | head -1 || true)
if [ -n "$SIGNING_INFO" ]; then
    echo "    $SIGNING_INFO"
fi

if [ "$SKIP_NOTARIZE" = false ]; then
    print_step "Step 6/8: Notarizing app..."

    ZIP_PATH="$BUILD_DIR/$APP_NAME-$VERSION-app.zip"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    echo "    Created ZIP for submission: $(basename "$ZIP_PATH")"

    echo "    Submitting to Apple notary service..."
    echo ""

    NOTARY_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait 2>&1) || {
        echo "$NOTARY_OUTPUT"
        print_error "Notarization failed"
        exit 1
    }

    if echo "$NOTARY_OUTPUT" | grep -q "status: Accepted"; then
        print_success "Notarization accepted"
    else
        echo "$NOTARY_OUTPUT"
        print_warning "Notarization status unclear"
    fi

    echo "    Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    print_success "Notarization ticket stapled"

    SPCTL_OUTPUT=$(spctl --assess --verbose=4 --type execute "$APP_PATH" 2>&1 || true)
    if echo "$SPCTL_OUTPUT" | grep -q "accepted"; then
        print_success "Gatekeeper verification passed"
    else
        print_warning "Gatekeeper check: $SPCTL_OUTPUT"
    fi

    rm -f "$ZIP_PATH"
else
    print_step "Step 6/8: Notarizing app... SKIPPED"
    print_warning "App is not notarized - users will see security warnings"
fi

if [ "$SKIP_DMG" = false ]; then
    print_step "Step 7/8: Creating DMG installer..."
    if command -v dropdmg >/dev/null 2>&1; then
        echo "    Using DropDMG profile: $DROPDMG_PROFILE"

        DROPDMG_OUTPUT=$(dropdmg \
            --config-name="$DROPDMG_PROFILE" \
            --destination="$EXPORT_PATH" \
            --base-name="$APP_NAME-$VERSION" \
            "$APP_PATH" 2>&1) || {
            print_warning "DropDMG failed:"
            echo "$DROPDMG_OUTPUT"
            create_manual_dmg
        }

        CREATED_DMG=$(echo "${DROPDMG_OUTPUT:-}" | tail -1)

        if [ -f "$CREATED_DMG" ]; then
            DMG_PATH="$CREATED_DMG"
            DMG_FILENAME=$(basename "$DMG_PATH")
            print_success "DMG created: $DMG_FILENAME"
        elif [ -f "$DMG_PATH" ]; then
            print_success "DMG created: $DMG_FILENAME"
        else
            FOUND_DMG=$(find "$EXPORT_PATH" -name "*.dmg" -type f 2>/dev/null | head -1)
            if [ -n "$FOUND_DMG" ]; then
                DMG_PATH="$FOUND_DMG"
                DMG_FILENAME=$(basename "$DMG_PATH")
                print_success "DMG created: $DMG_FILENAME"
            elif [ -f "$DMG_PATH" ]; then
                print_success "DMG created: $DMG_FILENAME"
            else
                create_manual_dmg
                print_success "DMG created: $DMG_FILENAME"
            fi
        fi
    else
        create_manual_dmg
        print_success "DMG created: $DMG_FILENAME"
    fi

    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    sign_dmg_if_needed
    echo "    Size: $DMG_SIZE"

    if [ "$SKIP_NOTARIZE" = false ]; then
        print_step "Step 8/8: Notarizing DMG..."

        DMG_NOTARY_OUTPUT=$(xcrun notarytool submit "$DMG_PATH" \
            --keychain-profile "$KEYCHAIN_PROFILE" \
            --wait 2>&1) || {
            echo "$DMG_NOTARY_OUTPUT"
            print_error "DMG notarization failed"
            exit 1
        }

        if echo "$DMG_NOTARY_OUTPUT" | grep -q "status: Accepted"; then
            print_success "DMG notarization accepted"
        fi

        echo "    Stapling notarization ticket to DMG..."
        xcrun stapler staple "$DMG_PATH"
        print_success "DMG notarization ticket stapled"

        DMG_SPCTL=$(spctl --assess --verbose=4 --type install "$DMG_PATH" 2>&1 || true)
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

if [ "$SKIP_DMG" = false ] && [ -f "$DMG_PATH" ]; then
    CHECKSUM_FILE="$DMG_PATH.sha256"
    shasum -a 256 "$DMG_PATH" > "$CHECKSUM_FILE"
    print_success "Checksum generated: $(basename "$CHECKSUM_FILE")"
fi

if [ "$CREATE_GITHUB_RELEASE" = true ] && [ -f "${DMG_PATH:-}" ]; then
    print_step "Creating GitHub release..."

    if git tag -l "v$VERSION" | grep -q "v$VERSION"; then
        print_warning "Tag v$VERSION already exists - skipping tag creation"
    else
        git tag "v$VERSION"
        print_success "Created tag: v$VERSION"
    fi

    gh release create "v$VERSION" \
        "$DMG_PATH" \
        --title "$APP_NAME $VERSION" \
        --notes "$(cat <<NOTES
## $APP_NAME $VERSION

Quick Look extension for syntax-highlighted previews of source code, config files, and dotfiles.

### Installation
1. Download the DMG
2. Open it and drag $APP_NAME to Applications
3. Launch $APP_NAME once to register the Quick Look extension
4. Press Space on any code file in Finder to preview

### Requirements
- macOS 15.0 or later

---
*Built and notarized with Apple Developer ID*
NOTES
)"

    print_success "GitHub release created: v$VERSION"
    GITHUB_URL=$(gh release view "v$VERSION" --json url --jq .url)
fi

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

if [ "$SKIP_DMG" = false ] && [ -f "${DMG_PATH:-}" ]; then
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

if [ -n "${GITHUB_URL:-}" ]; then
    echo ""
    echo -e "  ${GREEN}✓ GitHub release created${NC}"
    echo "    $GITHUB_URL"
fi

echo ""
echo -e "${BOLD}  Quick Verification:${NC}"
echo ""
if [ "$SKIP_DMG" = false ] && [ -f "${DMG_PATH:-}" ]; then
    echo "  # Mount and test DMG"
    echo "  open \"$DMG_PATH\""
    echo ""
fi
echo "  # Verify Gatekeeper"
echo "  spctl --assess -v --type execute \"$APP_PATH\""
echo ""

if [ "$CREATE_GITHUB_RELEASE" = false ] && [ "$SKIP_DMG" = false ] && [ -f "${DMG_PATH:-}" ]; then
    echo -e "${BOLD}  To create GitHub release later:${NC}"
    echo ""
    echo "  gh release create v$VERSION \"$DMG_PATH\" --title \"$APP_NAME $VERSION\""
    echo ""
fi

echo ""
