# dotViewer Release Guide

Complete step-by-step guide for releasing dotViewer to multiple distribution channels.

---

## Prerequisites

### One-Time Setup

1. **Install Homebrew tools**
   ```bash
   brew install create-dmg
   ```

2. **Store notarization credentials in Keychain**
   ```bash
   xcrun notarytool store-credentials "AC_PASSWORD" \
     --apple-id "your-apple-id@example.com" \
     --team-id "7F5ZSQFCQ4" \
     --password "app-specific-password"
   ```
   - Create app-specific password at: https://appleid.apple.com/account/manage
   - This only needs to be done once

3. **Verify signing certificates**
   ```bash
   security find-identity -v -p codesigning
   ```
   You should see:
   - `Developer ID Application: Your Name (TEAM_ID)` - for direct distribution
   - `Apple Distribution: Your Name (TEAM_ID)` - for App Store

4. **Install GitHub CLI** (for GitHub Releases)
   ```bash
   brew install gh
   gh auth login
   ```

---

## Release Workflow

### Phase 1: Prepare for Release

#### Step 1.1: Clean Build Directory
```bash
cd "/Users/stian/Developer/macOS Apps/dotViewer"
rm -rf build/
rm -rf dist/
```

#### Step 1.2: Verify Version Number
Update version in Xcode project if needed:
- Open `dotViewer.xcodeproj` in Xcode
- Select project root → General → Version
- Or pass version to release script (it will set MARKETING_VERSION)

#### Step 1.3: Verify Assets
```bash
# Check DMG background exists (660x400 PNG)
ls -la installer-assets/dmg-background.png

# Preview it
open installer-assets/dmg-background.png
```

---

### Phase 2: Build for Direct Distribution (GitHub/Website)

#### Step 2.1: Run Release Script
```bash
./scripts/release.sh 1.0
```

This single command:
1. Creates build directory
2. Archives the app (`xcodebuild archive`)
3. Exports with Developer ID signing
4. Creates ZIP for notarization
5. Submits to Apple notary service
6. Waits for notarization approval
7. Staples notarization ticket to app
8. Creates styled DMG with custom background
9. Notarizes the DMG
10. Staples ticket to DMG

**Output:**
- `build/dotViewer.xcarchive` - Archive with dSYMs
- `build/export/dotViewer.app` - Signed & notarized app
- `build/dotViewer-1.0-Installer.dmg` - Final distributable

**Expected duration:** 5-10 minutes (mostly notarization wait time)

#### Step 2.2: Verify the DMG
```bash
# Open DMG to inspect
open "build/dotViewer-1.0-Installer.dmg"
```

Check:
- [ ] Custom background displays correctly
- [ ] App icon appears on left
- [ ] Applications folder alias on right
- [ ] "Drag to Applications" text visible
- [ ] Drag app to Applications works
- [ ] Installed app launches successfully
- [ ] Quick Look extension works (press Space on a code file in Finder)

#### Step 2.3: Verify Notarization
```bash
# Check Gatekeeper approval
spctl --assess --verbose=4 --type execute "build/export/dotViewer.app"
# Should output: "accepted source=Notarized Developer ID"

# Check DMG
spctl --assess --verbose=4 --type install "build/dotViewer-1.0-Installer.dmg"
```

---

### Phase 3: Create GitHub Release

#### Step 3.1: Commit and Tag
```bash
git add -A
git commit -m "Release v1.0"
git tag v1.0
git push origin main --tags
```

#### Step 3.2: Create Release with DMG
```bash
gh release create v1.0 \
  "build/dotViewer-1.0-Installer.dmg" \
  --title "dotViewer 1.0" \
  --notes "$(cat <<'EOF'
## dotViewer 1.0

Quick Look extension for source code and dotfiles.

### Features
- Syntax highlighting for 100+ languages
- Markdown preview with code blocks
- Support for dotfiles (.zshrc, .gitignore, etc.)
- Customizable themes and font sizes

### Installation
1. Download the DMG
2. Open it and drag dotViewer to Applications
3. Launch dotViewer once to register the Quick Look extension
4. Press Space on any code file in Finder to preview

### Requirements
- macOS 13.0 or later
EOF
)"
```

#### Step 3.3: Verify Release
```bash
gh release view v1.0
open "https://github.com/YOUR_USERNAME/dotViewer/releases/tag/v1.0"
```

---

### Phase 4: Build for App Store

#### Step 4.1: Run App Store Build
```bash
./scripts/release.sh 1.0 --app-store
```

This creates a build signed for App Store distribution at:
`build/appstore/dotViewer.app`

#### Step 4.2: Upload via Transporter

1. Download **Transporter** from Mac App Store
2. Open Transporter
3. Drag the `.app` or `.pkg` from `build/appstore/`
4. Click **Deliver**

#### Step 4.3: Alternative: Upload via Command Line
```bash
# First, create an API key at App Store Connect
# https://appstoreconnect.apple.com/access/api

xcrun altool --upload-app \
  -f "build/appstore/dotViewer.app" \
  -t macos \
  --apiKey YOUR_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID
```

#### Step 4.4: Complete App Store Connect Setup

Go to https://appstoreconnect.apple.com and:

1. **App Information**
   - Name: dotViewer
   - Subtitle: Quick Look for Code & Dotfiles
   - Category: Developer Tools

2. **Pricing and Availability**
   - Price: Free (or choose tier)
   - Countries: Select markets

3. **App Privacy**
   - Data collection: None collected

4. **Screenshots** (required sizes)
   - 1280 x 800 (or 2560 x 1600 for Retina)
   - Show app preview, Quick Look in action

5. **Description** (up to 4000 chars)
   ```
   dotViewer brings powerful Quick Look previews to developers. Press Space
   on any code file or dotfile in Finder to see syntax-highlighted previews
   without opening an editor.

   Features:
   • Syntax highlighting for 100+ languages
   • Beautiful Markdown rendering
   • Support for dotfiles (.zshrc, .env, .gitignore)
   • Customizable themes and font sizes
   • Native macOS design
   ```

6. **Keywords** (100 chars max)
   ```
   quick look,syntax,code,preview,developer,dotfiles,markdown,programming
   ```

7. **Support URL**
   - Link to GitHub repo or support page

8. **Privacy Policy URL**
   - Host your PRIVACY.md online

9. **Submit for Review**

---

### Phase 5: Host on Personal Website

#### Step 5.1: Upload DMG
```bash
scp "build/dotViewer-1.0-Installer.dmg" user@yourserver:/var/www/downloads/
```

#### Step 5.2: Update Download Page
Add download link pointing to the DMG with:
- Version number
- File size
- SHA-256 checksum

Generate checksum:
```bash
shasum -a 256 "build/dotViewer-1.0-Installer.dmg"
```

---

## Quick Reference Commands

### Full Release (Direct Distribution)
```bash
./scripts/release.sh 1.0
```

### Full Release (App Store)
```bash
./scripts/release.sh 1.0 --app-store
```

### Skip Notarization (Testing Only)
```bash
./scripts/release.sh 1.0 --skip-notarize
```

### Recreate DMG Only (if you already have a notarized app)
```bash
./scripts/create-dmg.sh build/export/dotViewer.app
```

### Check Notarization Status
```bash
xcrun notarytool history --keychain-profile "AC_PASSWORD"
```

### View Notarization Log (if rejected)
```bash
xcrun notarytool log SUBMISSION_ID --keychain-profile "AC_PASSWORD"
```

---

## Troubleshooting

### "App is damaged" Error
App wasn't properly notarized. Re-run release script without `--skip-notarize`.

### Notarization Rejected
Check the log:
```bash
xcrun notarytool log SUBMISSION_ID --keychain-profile "AC_PASSWORD"
```
Common issues:
- Hardened runtime not enabled
- Unsigned nested frameworks
- Missing entitlements

### DMG Background Not Showing
- Verify image exists at `installer-assets/dmg-background.png`
- Check image is exactly 660x400 pixels
- Ensure `create-dmg` is installed: `brew install create-dmg`

### Quick Look Extension Not Working After Install
1. Launch the main app at least once
2. Or manually register:
   ```bash
   pluginkit -a /Applications/dotViewer.app/Contents/PlugIns/QuickLookPreview.appex
   ```
3. Restart Finder: `killall Finder`

---

## Version Checklist

Before each release, verify:

- [ ] Version number updated
- [ ] CHANGELOG updated (if you have one)
- [ ] All tests pass
- [ ] App runs correctly in release build
- [ ] Quick Look extension works
- [ ] DMG installs correctly
- [ ] Notarization successful
- [ ] GitHub release created (if applicable)
- [ ] App Store submission (if applicable)
- [ ] Website updated (if applicable)

---

## Files Reference

| File | Purpose |
|------|---------|
| `scripts/release.sh` | Main release script |
| `scripts/create-dmg.sh` | Standalone DMG creation |
| `ExportOptions-DevID.plist` | Developer ID export settings |
| `ExportOptions-AppStore.plist` | App Store export settings |
| `installer-assets/dmg-background.png` | DMG window background |
| `PRIVACY.md` | Privacy policy for App Store |
