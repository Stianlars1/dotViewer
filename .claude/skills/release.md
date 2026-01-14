---
name: release
description: Guide through dotViewer release workflow for GitHub, App Store, or website distribution
triggers:
  - /release
  - /deploy
  - /publish
---

# dotViewer Release Skill

You are helping the user release dotViewer to multiple distribution channels.

## Context

dotViewer is a macOS Quick Look extension app. The release infrastructure includes:
- `scripts/release.sh` - Main release script (archive, notarize, create DMG)
- `scripts/create-dmg.sh` - Standalone DMG creator
- `ExportOptions-DevID.plist` - Developer ID export config
- `ExportOptions-AppStore.plist` - App Store export config
- `installer-assets/dmg-background.png` - Custom DMG background (660x400)

## Workflow

### Step 1: Gather Requirements

Ask the user:
1. What version number? (e.g., "1.0", "1.1", "2.0")
2. Which distribution channels?
   - GitHub Releases (requires notarized DMG)
   - App Store (requires separate build)
   - Personal website
   - All of the above

### Step 2: Pre-Release Checks

Before building, verify:

```bash
# Check current build directory status
ls -la build/ 2>/dev/null || echo "No build directory yet"

# Verify signing certificates
security find-identity -v -p codesigning | grep -E "(Developer ID|Apple Distribution)"

# Verify notarization credentials exist
xcrun notarytool history --keychain-profile "AC_PASSWORD" 2>&1 | head -5

# Check DMG background exists
ls -la installer-assets/dmg-background.png
```

### Step 3: Build for Direct Distribution

If user wants GitHub/website distribution:

```bash
# Clean previous builds
rm -rf build/

# Run full release (archive, sign, notarize, DMG)
./scripts/release.sh VERSION_NUMBER
```

Expected outputs:
- `build/dotViewer.xcarchive`
- `build/export/dotViewer.app`
- `build/dotViewer-VERSION-Installer.dmg`

After build completes, verify:

```bash
# Check Gatekeeper approval
spctl --assess --verbose=4 --type execute "build/export/dotViewer.app"

# Verify DMG
spctl --assess --verbose=4 --type install "build/dotViewer-VERSION-Installer.dmg"
```

### Step 4: Create GitHub Release

```bash
# Ensure on correct branch
git status

# Tag the release
git tag vVERSION
git push origin --tags

# Create release with DMG
gh release create vVERSION \
  "build/dotViewer-VERSION-Installer.dmg" \
  --title "dotViewer VERSION" \
  --notes "Release notes here"
```

### Step 5: Build for App Store

If user wants App Store submission:

```bash
# Run App Store build
./scripts/release.sh VERSION_NUMBER --app-store
```

Output: `build/appstore/dotViewer.app`

Instruct user to:
1. Open **Transporter** app (from Mac App Store)
2. Drag the app from `build/appstore/`
3. Click **Deliver**

Then complete App Store Connect setup:
- Screenshots (1280x800 or 2560x1600)
- Description, keywords, categories
- Privacy policy URL
- Support URL

### Step 6: Website Distribution

If user wants website hosting:

```bash
# Generate checksum
shasum -a 256 "build/dotViewer-VERSION-Installer.dmg"

# Display for copy/paste
echo "File: dotViewer-VERSION-Installer.dmg"
ls -lh "build/dotViewer-VERSION-Installer.dmg" | awk '{print "Size:", $5}'
```

Then instruct user to upload DMG to their server.

## Troubleshooting

### Notarization Issues

If notarization fails:
```bash
# Get submission history
xcrun notarytool history --keychain-profile "AC_PASSWORD"

# Get detailed log for a submission
xcrun notarytool log SUBMISSION_ID --keychain-profile "AC_PASSWORD"
```

### "App is damaged" Error
The app wasn't properly notarized. Re-run `./scripts/release.sh` without `--skip-notarize`.

### Quick Look Extension Not Working
```bash
# Force re-register
pluginkit -a /Applications/dotViewer.app/Contents/PlugIns/QuickLookPreview.appex

# Restart Finder
killall Finder
```

## Reference

Full documentation: `HOW_TO_RELEASE.md`
