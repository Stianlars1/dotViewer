---
name: release
description: Guide through dotViewer release workflow - single command for complete release
triggers:
  - /release
  - /deploy
  - /publish
---

# dotViewer Release Skill

You are helping the user release dotViewer to multiple distribution channels.

## Context

dotViewer is a macOS Quick Look extension app. The release uses a **single command** that handles everything:

```bash
./scripts/release.sh <version> [options]
```

This command performs:
1. Clean build directory
2. Archive the app
3. Export with Developer ID signing
4. Notarize app with Apple
5. Create DMG with DropDMG ("dotviewer" profile)
6. Notarize DMG with Apple
7. Generate SHA-256 checksum

## Prerequisites

Before first release, ensure:
1. **DropDMG CLI installed**: Open DropDMG → Advanced → "Install dropdmg Tool"
2. **DropDMG "dotviewer" profile configured**: Contains layout, background, signing settings
3. **Notarization credentials stored**: `xcrun notarytool store-credentials "AC_PASSWORD"`
4. **Signing certificates available**: `security find-identity -v -p codesigning`

## Release Commands

### Full Release (GitHub/Website)

```bash
./scripts/release.sh 1.0
```

Creates ready-to-distribute files:
- `build/export/dotViewer.app` - Notarized app
- `build/export/dotViewer-1.0.dmg` - Notarized DMG installer
- `build/export/dotViewer-1.0.dmg.sha256` - Checksum

### With GitHub Release

```bash
./scripts/release.sh 1.0 --github
```

After building, also:
- Creates git tag `v1.0`
- Creates GitHub release with DMG attached

### App Store Build

```bash
./scripts/release.sh 1.0 --app-store
```

Creates `build/appstore/dotViewer.app` for upload via Transporter.

### Testing Options

```bash
# Skip notarization (faster, for testing)
./scripts/release.sh 1.0 --skip-notarize

# Skip DMG creation (app only)
./scripts/release.sh 1.0 --skip-dmg
```

## Workflow

### Step 1: Gather Requirements

Ask the user:
1. What version number? (e.g., "1.0", "1.1", "2.0")
2. Which distribution channels?
   - GitHub Releases (`--github` flag)
   - Personal website (manual upload of DMG)
   - App Store (`--app-store` flag)

### Step 2: Pre-Release Checks

```bash
# Verify signing certificates
security find-identity -v -p codesigning | grep -E "(Developer ID|Apple Distribution)"

# Verify notarization credentials
xcrun notarytool history --keychain-profile "AC_PASSWORD" 2>&1 | head -5

# Verify DropDMG CLI
which dropdmg || echo "DropDMG CLI not installed"
```

### Step 3: Run Release

```bash
./scripts/release.sh VERSION
```

Watch the output - it shows progress through all 8 steps.

### Step 4: Verify Output

```bash
# Check DMG opens correctly
open build/export/dotViewer-VERSION.dmg

# Verify Gatekeeper acceptance
spctl --assess --verbose=4 --type install "build/export/dotViewer-VERSION.dmg"
```

### Step 5: Distribute

For GitHub (if not using `--github` flag):
```bash
gh release create vVERSION \
  "build/export/dotViewer-VERSION.dmg" \
  --title "dotViewer VERSION" \
  --notes "Release notes here"
```

For website: Upload DMG and checksum file to hosting.

## Troubleshooting

### "dropdmg: command not found"
Install CLI from DropDMG app → Advanced tab → "Install dropdmg Tool"

### "Configuration 'dotviewer' not found"
Create the configuration in DropDMG app → Configurations tab

### Notarization Issues
```bash
# Get submission history
xcrun notarytool history --keychain-profile "AC_PASSWORD"

# Get detailed log for specific submission
xcrun notarytool log SUBMISSION_ID --keychain-profile "AC_PASSWORD"
```

### "App is damaged" Error
The app/DMG wasn't properly notarized. Re-run without `--skip-notarize`.

### Quick Look Extension Not Working After Install
```bash
pluginkit -a /Applications/dotViewer.app/Contents/PlugIns/QuickLookPreview.appex
killall Finder
```

## Reference

Full documentation: `HOW_TO_RELEASE.md`
