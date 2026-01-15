# Context Backup: App Store Provisioning Profile Export Fix

**Date:** 2026-01-14
**Issue:** App Store build failing with "No profiles found" error

---

## The Problem

Running `./scripts/release.sh 1.0 --app-store` failed at Step 4 (export) with:

```
error: exportArchive No profiles for 'com.stianlars1.dotViewer' were found
error: exportArchive No profiles for 'com.stianlars1.dotViewer.QuickLookPreview' were found
** EXPORT FAILED **
```

This was confusing because:
- App Store profiles existed in Apple Developer portal
- Profiles were downloaded and visible in Xcode
- Certificates were valid in keychain

---

## What Was Tried (by user before this session)

1. Downloaded App Store provisioning profiles from Apple Developer
2. Tried to install profiles via System Settings (Norwegian message said production profiles must be imported via Xcode)
3. Configured Xcode targets with manual signing pointing to App Store profiles
4. Created multiple certificates (Distribution, Mac Installer Distribution)

---

## Investigation & Discoveries

### 1. Profile Location Check
```bash
# Profiles were correctly in Xcode's directory (not ~/Library/MobileDevice/)
ls ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/
# Found: a3e4f6fa-0234-428e-9496-480ef4dda5d6.provisionprofile (dotViewer App Store)
# Found: 6c0b269f-c583-42ba-b8b8-7877a0ab3882.provisionprofile (QuickLookPreview App Store)
```

### 2. Profile Contents Verified
```bash
security cms -D -i ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/a3e4f6fa-*.provisionprofile | plutil -p -
# Confirmed: Name = "dotViewer App Store"
# Confirmed: Bundle ID = "7F5ZSQFCQ4.com.stianlars1.dotViewer"
# Confirmed: Certificate = "Apple Distribution: Stian Larsen (7F5ZSQFCQ4)"
```

### 3. Project Build Settings Check
```bash
xcodebuild -project dotViewer.xcodeproj -showBuildSettings -target dotViewer -configuration Release
```
Found in project.pbxproj (Release config):
- `CODE_SIGN_STYLE = Manual`
- `CODE_SIGN_IDENTITY[sdk=macosx*]` = `3rd Party Mac Developer Application`
- `PROVISIONING_PROFILE_SPECIFIER[sdk=macosx*]` = `dotViewer App Store`

### 4. Root Cause Identified
The `ExportOptions-AppStore.plist` had:
```xml
<key>signingStyle</key>
<string>automatic</string>
```

**Conflict:** Project uses **manual** signing, but export options said **automatic**.
When xcodebuild sees this mismatch, it can't find profiles because it's looking in the wrong way.

### 5. Second Error After First Fix
After changing to manual signing, got:
```
error: exportArchive Provisioning profile "dotViewer App Store" doesn't include signing certificate "3rd Party Mac Developer Installer: Stian Larsen (7F5ZSQFCQ4)"
```

**Discovery:** App Store exports create a `.pkg` file (not `.app`), which requires:
- **Application cert** for signing the app inside
- **Installer cert** for signing the .pkg wrapper

### 6. Script Bug
The release script expected `.app` output:
```bash
APP_PATH="$EXPORT_PATH/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then  # <-- Looking for directory
```
But App Store exports produce `.pkg` files.

---

## The Solution

### Fix 1: ExportOptions-AppStore.plist

Changed from:
```xml
<key>signingStyle</key>
<string>automatic</string>
```

To:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>teamID</key>
    <string>7F5ZSQFCQ4</string>
    <key>uploadSymbols</key>
    <true/>
    <key>generateAppStoreInformation</key>
    <false/>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.stianlars1.dotViewer</key>
        <string>dotViewer App Store</string>
        <key>com.stianlars1.dotViewer.QuickLookPreview</key>
        <string>QuickLookPreview App Store</string>
    </dict>
    <key>installerSigningCertificate</key>
    <string>3rd Party Mac Developer Installer</string>
</dict>
</plist>
```

Key additions:
- `signingStyle` = `manual` (matches project settings)
- `provisioningProfiles` dict mapping bundle IDs to profile names
- `installerSigningCertificate` for .pkg signing

### Fix 2: release.sh Script

Changed path logic to handle .pkg for App Store:
```bash
if [ "$APP_STORE" = true ]; then
    # App Store exports create a .pkg file
    APP_PATH="$EXPORT_PATH/$APP_NAME.pkg"
else
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
fi
```

Added App Store-specific export handling that:
- Checks for `.pkg` file (not `.app` directory)
- Uses `pkgutil --check-signature` for verification
- Shows correct next steps for Transporter upload

---

## Key Learnings

1. **Signing style must match**: If project uses manual signing, export options must also use manual
2. **App Store exports = .pkg**: Not .app files
3. **Two certificates needed for App Store .pkg**:
   - "Apple Distribution" or "3rd Party Mac Developer Application" - signs the app
   - "3rd Party Mac Developer Installer" - signs the .pkg wrapper
4. **Provisioning profiles location**:
   - Development profiles: `~/Library/MobileDevice/Provisioning Profiles/`
   - Production/App Store profiles: `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`
5. **Profile names in ExportOptions must match exactly** what's shown in Apple Developer portal

---

## Verification Commands

```bash
# Check what profiles Xcode knows about
for profile in ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*.provisionprofile; do
  echo "=== $(basename "$profile") ==="
  security cms -D -i "$profile" 2>/dev/null | plutil -extract Name raw -
done

# Check certificates in keychain
security find-identity -v -p codesigning

# Verify a .pkg signature
pkgutil --check-signature /path/to/app.pkg

# Check what cert is in a profile
security cms -D -i /path/to/profile.provisionprofile | plutil -extract 'DeveloperCertificates.0' raw -o - - | base64 -d | openssl x509 -noout -subject -inform DER
```

---

## Final Working Build Command

```bash
./scripts/release.sh 1.0 --app-store
```

Output: `/Users/stian/Developer/macOS Apps/dotViewer/build/appstore/dotViewer.pkg`

Upload via Transporter app or:
```bash
xcrun altool --upload-package -f "build/appstore/dotViewer.pkg" -t macos -u APPLE_ID -p @keychain:AC_PASSWORD
```
