# dotViewer Release Guide

Complete guide for releasing dotViewer to GitHub, website, and App Store.

---

## Quick Start

**Full Release (one command):**
```bash
./scripts/release.sh 1.0
```

This single command performs the complete release process:
1. Cleans build directory
2. Archives the app
3. Exports with Developer ID signing
4. Notarizes the app with Apple
5. Creates DMG installer with DropDMG
6. Notarizes the DMG with Apple
7. Generates SHA-256 checksum
8. Outputs ready-to-distribute files

**With GitHub Release:**
```bash
./scripts/release.sh 1.0 --github
```

---

## Prerequisites (One-Time Setup)

### 1. Install DropDMG CLI

1. Purchase and install [DropDMG](https://c-command.com/dropdmg/) from C-Command
2. Open DropDMG app
3. Go to **Advanced** tab
4. Click **"Install dropdmg Tool"**
5. This installs `/usr/local/bin/dropdmg`

Verify installation:
```bash
which dropdmg
# Should output: /usr/local/bin/dropdmg
```

### 2. Configure DropDMG Profile

The release script uses a saved DropDMG configuration named `dotviewer`.

**To create/verify this configuration:**

1. Open DropDMG app
2. Go to **Configurations** tab
3. Create/edit configuration named `dotviewer` with:
   - **Format:** zlib (compressed, read-only)
   - **Signing Identity:** Developer ID Application: Your Name (7F5ZSQFCQ4)
   - **Layout:** Your custom layout (configured in DropDMG's Layouts tab)
   - **Internet Enabled:** Disabled (recommended)

**Layout (configured in DropDMG GUI):**
The `dotviewer` profile stores all layout settings internally:
- Custom purple gradient background
- App icon on left, Applications folder on right
- "Drag to Applications to install" visual
- Window size and positioning

All DMG design is handled by DropDMG - no external background files needed.

### 3. Store Notarization Credentials

Store your Apple ID credentials securely in Keychain:

```bash
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "your-apple-id@example.com" \
  --team-id "7F5ZSQFCQ4" \
  --password "app-specific-password"
```

**To get an app-specific password:**
1. Go to https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. Under Security → App-Specific Passwords, click **Generate Password**
4. Use this password in the command above

### 4. Verify Signing Certificates

```bash
security find-identity -v -p codesigning
```

You should see:
- `Developer ID Application: Your Name (7F5ZSQFCQ4)` - for direct distribution
- `Apple Distribution: Your Name (7F5ZSQFCQ4)` - for App Store

### 5. Install GitHub CLI (Optional)

For automatic GitHub release creation:
```bash
brew install gh
gh auth login
```

---

## Release Commands Reference

### Full Release (GitHub/Website)

```bash
./scripts/release.sh <version>
```

**Example:**
```bash
./scripts/release.sh 1.0
```

**What it does:**
| Step | Action | Output |
|------|--------|--------|
| 1 | Check prerequisites | Validates tools are installed |
| 2 | Clean build | Removes `build/` directory |
| 3 | Archive | Creates `build/dotViewer.xcarchive` |
| 4 | Export | Creates `build/export/dotViewer.app` |
| 5 | Verify signature | Validates code signing |
| 6 | Notarize app | Submits to Apple, waits, staples ticket |
| 7 | Create DMG | Uses DropDMG with `dotviewer` profile |
| 8 | Notarize DMG | Submits DMG to Apple, waits, staples |

**Final outputs:**
```
build/
├── dotViewer.xcarchive          # Archive with dSYMs
└── export/
    ├── dotViewer.app            # Notarized app
    ├── dotViewer-1.0.dmg        # Notarized DMG installer
    └── dotViewer-1.0.dmg.sha256 # Checksum file
```

**Duration:** ~5-10 minutes (mostly notarization wait time)

### App Store Build

```bash
./scripts/release.sh <version> --app-store
```

**Example:**
```bash
./scripts/release.sh 1.0 --app-store
```

Creates a build signed for App Store submission. Does not create DMG or notarize (App Store handles this).

**Output:** `build/appstore/dotViewer.app`

### With GitHub Release

```bash
./scripts/release.sh <version> --github
```

After building and notarizing, automatically:
1. Creates git tag `v<version>`
2. Creates GitHub release with DMG attached
3. Adds release notes

### Skip Options (Testing Only)

```bash
# Skip notarization (faster, but users will see security warnings)
./scripts/release.sh 1.0 --skip-notarize

# Build app only, no DMG
./scripts/release.sh 1.0 --skip-dmg
```

---

## Step-by-Step Walkthrough

### Direct Distribution Release

**1. Ensure code is ready:**
```bash
# Run any final tests
# Verify app works in Release configuration
```

**2. Run release script:**
```bash
./scripts/release.sh 1.0
```

**3. Watch the output:**
```
══════════════════════════════════════════════════════════════
  dotViewer Release Build v1.0
══════════════════════════════════════════════════════════════

  Mode:    Developer ID
  Version: 1.0

▶ Step 1/8: Checking prerequisites...
✓ All prerequisites satisfied

▶ Step 2/8: Cleaning build directory...
✓ Build directory cleaned

▶ Step 3/8: Creating archive...
✓ Archive created: build/dotViewer.xcarchive

▶ Step 4/8: Exporting for Developer ID distribution...
✓ Exported: build/export/dotViewer.app

▶ Step 5/8: Verifying code signature...
✓ Code signature valid

▶ Step 6/8: Notarizing app...
    (This typically takes 2-5 minutes)
✓ Notarization accepted
✓ Notarization ticket stapled
✓ Gatekeeper verification passed

▶ Step 7/8: Creating DMG installer...
✓ DMG created: dotViewer-1.0.dmg
    Size: 5.2M

▶ Step 8/8: Notarizing DMG...
✓ DMG notarization accepted
✓ DMG notarization ticket stapled
✓ DMG Gatekeeper verification passed

✓ Checksum generated: dotViewer-1.0.dmg.sha256

══════════════════════════════════════════════════════════════
  Release Build Complete!
══════════════════════════════════════════════════════════════
```

**4. Verify the DMG manually:**
```bash
open build/export/dotViewer-1.0.dmg
```

Check:
- [ ] Custom background displays correctly
- [ ] App icon appears on left
- [ ] Applications folder alias on right
- [ ] Drag-to-install works
- [ ] Installed app launches
- [ ] Quick Look extension works (Space on code file)

**5. Distribute:**

**GitHub Release:**
```bash
# If you didn't use --github flag:
gh release create v1.0 \
  "build/export/dotViewer-1.0.dmg" \
  --title "dotViewer 1.0" \
  --notes "Release notes here..."
```

**Website:**
```bash
# Upload DMG to your server
scp "build/export/dotViewer-1.0.dmg" user@server:/var/www/downloads/
```

### App Store Release

**1. Build for App Store:**
```bash
./scripts/release.sh 1.0 --app-store
```

**2. Upload via Transporter:**
1. Download **Transporter** from Mac App Store
2. Open Transporter
3. Drag `build/appstore/dotViewer.app` into Transporter
4. Click **Deliver**

**3. Complete App Store Connect setup:**
- Go to https://appstoreconnect.apple.com
- Fill in app metadata, screenshots, description
- Submit for review

---

## Troubleshooting

### "App is damaged" Error

**Cause:** App wasn't properly notarized.

**Fix:** Re-run without `--skip-notarize`:
```bash
./scripts/release.sh 1.0
```

### Notarization Rejected

**Check the log:**
```bash
xcrun notarytool log <SUBMISSION_ID> --keychain-profile "AC_PASSWORD"
```

**Common issues:**
- Hardened Runtime not enabled in Xcode
- Unsigned nested frameworks
- Missing entitlements
- Third-party code without valid signature

### DropDMG Fails

**Error:** "dropdmg not found"
```bash
# Install the CLI tool:
# Open DropDMG app → Advanced → Install dropdmg Tool
```

**Error:** "Configuration 'dotviewer' not found"
```bash
# Create the configuration in DropDMG app:
# Open DropDMG → Configurations → Create "dotviewer"
```

### DMG Background Not Showing

1. Verify DropDMG configuration exists with layout
2. Check layout references correct background image
3. Ensure background is 660x400 PNG

### Quick Look Extension Not Working

After installing from DMG:
1. Launch the main app at least once
2. Or manually register:
   ```bash
   pluginkit -a /Applications/dotViewer.app/Contents/PlugIns/QuickLookPreview.appex
   killall Finder
   ```

### Notarization Takes Too Long

Normal: 2-10 minutes. If stuck:
```bash
# Check history
xcrun notarytool history --keychain-profile "AC_PASSWORD"
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `scripts/release.sh` | Main release script (build, notarize, DMG) |
| `scripts/notarize_app.sh` | Standalone DMG notarization utility |
| `ExportOptions-DevID.plist` | Developer ID export settings |
| `ExportOptions-AppStore.plist` | App Store export settings |
| `PRIVACY.md` | Privacy policy for App Store |

---

## Version Checklist

Before each release:

- [ ] Version number updated in script argument
- [ ] All code changes committed
- [ ] App runs correctly in Release build
- [ ] Quick Look extension works
- [ ] Run `./scripts/release.sh <version>`
- [ ] Verify DMG installs correctly
- [ ] Create GitHub release (if applicable)
- [ ] Update website (if applicable)
- [ ] Submit to App Store (if applicable)

---

## Security Notes

**What gets notarized:**
- The .app bundle (stapled)
- The .dmg file (stapled)

**Gatekeeper verification:**
```bash
# Verify app
spctl --assess --verbose=4 --type execute "build/export/dotViewer.app"
# Expected: "accepted source=Notarized Developer ID"

# Verify DMG
spctl --assess --verbose=4 --type install "build/export/dotViewer-1.0.dmg"
# Expected: "accepted source=Notarized Developer ID"
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ./scripts/release.sh                      │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   xcodebuild  │    │   dropdmg     │    │  notarytool   │
│   archive     │    │   (DropDMG)   │    │   (Apple)     │
│   export      │    │               │    │               │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ dotViewer.app │───▶│ .dmg file     │───▶│ Notarized &   │
│ (signed)      │    │ (signed)      │    │ Stapled       │
└───────────────┘    └───────────────┘    └───────────────┘
```

---

*Last updated: 2026-01-14*
