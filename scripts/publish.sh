#!/bin/bash
set -euo pipefail

# ============================================================================
#  dotViewer Publish Script
# ============================================================================
#
#  Full release pipeline: build DMG → notarize → GitHub release → App Store pkg.
#
#  Usage:
#    ./scripts/publish.sh <version>
#
#  What it does (in order):
#    1. Runs release.sh <version> to build, sign, notarize the DMG + checksum
#    2. Extracts release notes from CHANGELOG.md for that version
#    3. Creates a git tag v<version> and pushes it
#    4. Creates a GitHub release with the DMG, checksum, and changelog notes
#    5. Runs release.sh <version> --app-store to build the .pkg for Transporter
#    6. Prints the Transporter drag-and-deliver instructions
#
#  Prerequisites:
#    - gh CLI authenticated (brew install gh && gh auth login)
#    - Apple notarization keychain profile configured (AC_PASSWORD)
#    - Xcode with signing identity for Developer ID + App Store
#
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
    echo -e "${RED}Usage: $0 <version>${NC}"
    echo ""
    echo "Example: $0 1.3.0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$REPO_DIR/dotViewer"
EXPORT_PATH="$PROJECT_DIR/build/export"
DMG_PATH="$EXPORT_PATH/dotViewer-$VERSION.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"
APPSTORE_PKG="$PROJECT_DIR/build-appstore/appstore/dotViewer.pkg"
CHANGELOG="$REPO_DIR/CHANGELOG.md"

# Homebrew tap for auto-updating `brew install --cask stianlars1/tap/dotviewer`.
# Override with HOMEBREW_TAP_DIR env var; defaults to sibling directory.
HOMEBREW_TAP_DIR="${HOMEBREW_TAP_DIR:-$REPO_DIR/../homebrew-tap}"
HOMEBREW_CASK_FILE="$HOMEBREW_TAP_DIR/Casks/dotviewer.rb"

# ── Step 0: Preflight checks ──────────────────────────────────────────────

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  dotViewer Publish Pipeline — v$VERSION${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo ""

if ! command -v gh >/dev/null 2>&1; then
    echo -e "${RED}Error: gh CLI not found. Install with: brew install gh${NC}"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}Error: gh CLI not authenticated. Run: gh auth login${NC}"
    exit 1
fi

# Check we're on a clean working tree (allow untracked files)
if [ -n "$(git diff --cached --name-only)" ] || [ -n "$(git diff --name-only)" ]; then
    echo -e "${YELLOW}Warning: You have uncommitted changes.${NC}"
    echo "  Consider committing before publishing so the tag points to the right commit."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ── Step 1: Extract release notes from CHANGELOG ──────────────────────────

echo -e "${BOLD}Step 1/7:${NC} Extracting release notes from CHANGELOG.md..."

RELEASE_NOTES=""
if [ -f "$CHANGELOG" ]; then
    # Extract everything between "## v<VERSION>" and the next "## " heading
    RELEASE_NOTES=$(awk -v ver="## v$VERSION" '
        $0 ~ ver { found=1; next }
        found && /^## / { exit }
        found { print }
    ' "$CHANGELOG" | sed '/^$/{ N; /^\n$/d; }' | sed '1{ /^$/d; }')
fi

if [ -z "$RELEASE_NOTES" ]; then
    echo -e "${YELLOW}  No CHANGELOG entry found for v$VERSION — using generic notes${NC}"
    RELEASE_NOTES="dotViewer $VERSION

Quick Look extension for syntax-highlighted previews of source code, config files, and dotfiles.

### Installation
1. Download the DMG
2. Open it and drag dotViewer to Applications
3. Launch dotViewer once to register the Quick Look extension
4. Press Space on any code file in Finder to preview

### Requirements
- macOS 15.0 or later"
else
    echo -e "${GREEN}  ✓ Found release notes ($(echo "$RELEASE_NOTES" | wc -l | tr -d ' ') lines)${NC}"
fi

# ── Step 2: Build DMG (Developer ID) ──────────────────────────────────────

echo ""
echo -e "${BOLD}Step 2/7:${NC} Building Developer ID release (DMG + notarize)..."
echo ""

"$SCRIPT_DIR/release.sh" "$VERSION"

if [ ! -f "$DMG_PATH" ]; then
    echo -e "${RED}Error: DMG not found at $DMG_PATH${NC}"
    exit 1
fi

if [ ! -f "$CHECKSUM_PATH" ]; then
    echo -e "${RED}Error: Checksum not found at $CHECKSUM_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓ DMG ready: $DMG_PATH${NC}"
echo -e "${GREEN}  ✓ Checksum ready: $CHECKSUM_PATH${NC}"

# ── Step 3: Git tag ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Step 3/7:${NC} Creating git tag v$VERSION..."

if git tag -l "v$VERSION" | grep -q "v$VERSION"; then
    echo -e "${YELLOW}  Tag v$VERSION already exists — skipping tag creation${NC}"
else
    git tag "v$VERSION"
    echo -e "${GREEN}  ✓ Created tag v$VERSION${NC}"
fi

echo "  Pushing tag to origin..."
git push origin "v$VERSION" 2>/dev/null || echo -e "${YELLOW}  Tag already on remote or push skipped${NC}"

# ── Step 4: GitHub release ────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Step 4/7:${NC} Creating GitHub release..."

EXISTING_RELEASE=$(gh release view "v$VERSION" --json tagName --jq .tagName 2>/dev/null || true)

if [ "$EXISTING_RELEASE" = "v$VERSION" ]; then
    echo -e "${YELLOW}  Release v$VERSION already exists — uploading/replacing assets${NC}"
    gh release upload "v$VERSION" \
        "$DMG_PATH" \
        "$CHECKSUM_PATH" \
        --clobber
else
    gh release create "v$VERSION" \
        "$DMG_PATH" \
        "$CHECKSUM_PATH" \
        --title "dotViewer $VERSION" \
        --notes "$(cat <<EOF
$RELEASE_NOTES

---
### Installation
1. Download **dotViewer-$VERSION.dmg**
2. Open the DMG and drag **dotViewer** to Applications
3. Launch dotViewer once to register the Quick Look extensions
4. Press Space on any code file in Finder

**Requirements:** macOS 15.0 or later
*Signed and notarized with Apple Developer ID*
EOF
)"
fi

GITHUB_URL=$(gh release view "v$VERSION" --json url --jq .url 2>/dev/null || echo "")
echo -e "${GREEN}  ✓ GitHub release published${NC}"
if [ -n "$GITHUB_URL" ]; then
    echo "    $GITHUB_URL"
fi

# ── Step 5: Update Homebrew tap (stianlars1/tap) ──────────────────────────

echo ""
echo -e "${BOLD}Step 5/7:${NC} Updating Homebrew tap cask..."

HOMEBREW_PUSHED=""
HOMEBREW_SKIP_REASON=""

if [ ! -d "$HOMEBREW_TAP_DIR/.git" ]; then
    HOMEBREW_SKIP_REASON="tap directory not found at $HOMEBREW_TAP_DIR (set HOMEBREW_TAP_DIR to override)"
elif [ ! -f "$HOMEBREW_CASK_FILE" ]; then
    HOMEBREW_SKIP_REASON="cask file not found at $HOMEBREW_CASK_FILE"
else
    # Compute DMG sha256 directly (avoids depending on CHECKSUM_PATH file format).
    DMG_SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
    if [ -z "$DMG_SHA256" ] || [ ${#DMG_SHA256} -ne 64 ]; then
        echo -e "${RED}  Error: failed to compute DMG SHA256${NC}"
        exit 1
    fi
    echo "  DMG SHA256: $DMG_SHA256"

    # Update version and sha256 lines in the cask. BSD sed requires '' after -i.
    sed -i '' -E "s/^(  version) \"[^\"]+\"/\\1 \"$VERSION\"/" "$HOMEBREW_CASK_FILE"
    sed -i '' -E "s/^(  sha256) \"[a-f0-9]{64}\"/\\1 \"$DMG_SHA256\"/" "$HOMEBREW_CASK_FILE"

    # Verify the edits took.
    if ! grep -q "version \"$VERSION\"" "$HOMEBREW_CASK_FILE"; then
        echo -e "${RED}  Error: version not updated in $HOMEBREW_CASK_FILE${NC}"
        exit 1
    fi
    if ! grep -q "sha256 \"$DMG_SHA256\"" "$HOMEBREW_CASK_FILE"; then
        echo -e "${RED}  Error: sha256 not updated in $HOMEBREW_CASK_FILE${NC}"
        exit 1
    fi

    pushd "$HOMEBREW_TAP_DIR" >/dev/null

    if git diff --quiet -- "Casks/dotviewer.rb"; then
        echo -e "${YELLOW}  No changes to commit (cask already at v$VERSION + matching sha256)${NC}"
    else
        git add "Casks/dotviewer.rb"
        git commit -m "dotviewer $VERSION" >/dev/null
        echo -e "${GREEN}  ✓ Committed bump to v$VERSION${NC}"

        if git remote | grep -q .; then
            BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
            if git push origin "$BRANCH" 2>/dev/null; then
                HOMEBREW_PUSHED="yes"
                echo -e "${GREEN}  ✓ Pushed to $(git remote get-url origin)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Push failed — commit is local only. Push manually with:${NC}"
                echo "      (cd \"$HOMEBREW_TAP_DIR\" && git push origin $BRANCH)"
            fi
        else
            echo -e "${YELLOW}  ⚠ No git remote configured. Commit is local only.${NC}"
            echo "      Add a remote: (cd \"$HOMEBREW_TAP_DIR\" && git remote add origin git@github.com:stianlars1/homebrew-tap.git)"
        fi
    fi

    popd >/dev/null
fi

if [ -n "$HOMEBREW_SKIP_REASON" ]; then
    echo -e "${YELLOW}  Skipped: $HOMEBREW_SKIP_REASON${NC}"
fi

# ── Step 6: Build App Store pkg ───────────────────────────────────────────

echo ""
echo -e "${BOLD}Step 6/7:${NC} Building App Store package..."
echo ""

"$SCRIPT_DIR/release.sh" "$VERSION" --app-store

if [ -f "$APPSTORE_PKG" ]; then
    echo -e "${GREEN}  ✓ App Store package ready: $APPSTORE_PKG${NC}"
else
    echo -e "${YELLOW}  ⚠ App Store package not found — check the output above${NC}"
fi

# ── Step 7: Summary ───────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Publish Complete — dotViewer v$VERSION${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}  Outputs:${NC}"
echo "    DMG:        $DMG_PATH"
echo "    Checksum:   $CHECKSUM_PATH"
if [ -n "$GITHUB_URL" ]; then
    echo "    GitHub:     $GITHUB_URL"
fi
if [ -f "$APPSTORE_PKG" ]; then
    echo "    App Store:  $APPSTORE_PKG"
fi
if [ -n "$HOMEBREW_PUSHED" ]; then
    echo "    Homebrew:   brew upgrade --cask stianlars1/tap/dotviewer"
elif [ -z "$HOMEBREW_SKIP_REASON" ] && [ -d "$HOMEBREW_TAP_DIR/.git" ]; then
    echo "    Homebrew:   local commit only — push to update users"
fi
echo ""
echo -e "${BOLD}  Remaining manual step:${NC}"
echo "    Open Transporter → drag $APPSTORE_PKG → click Deliver"
echo ""
echo -e "${BOLD}  Verification:${NC}"
echo "    gh release view v$VERSION --json tagName,name,assets"
echo "    curl -I -s https://dotviewer.app/download/latest"
echo ""
