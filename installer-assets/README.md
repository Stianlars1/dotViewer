# DMG Installer Assets

This folder contains assets for creating the DMG installer for dotViewer.

## Background Image

**File**: `dmg-background.png` (660x400 pixels)

### Design Specifications

Create a background image with these characteristics:
- **Size**: 660×400 pixels
- **Style**: Light, modern, matches macOS Big Sur+ design language
- **Color scheme**: Light gray gradient (#f5f5f7 to #e8e8ed) or subtle pattern
- **Elements**:
  - "dotViewer" title at top
  - Subtle instruction text (e.g., "Drag to Applications folder to install")
  - Optional: Faint code/syntax pattern in background (on-brand)

### Design Tools

- Sketch
- Figma
- Photoshop
- Affinity Designer
- Or any image editor

### Template Guide

1. Create 660×400px canvas
2. Add light gradient background
3. Add "dotViewer" text at top (SF Pro font, ~48pt)
4. Add instruction text near bottom (SF Pro font, ~14pt, secondary color)
5. Optional: Add subtle curved arrow from left (app position: 150,200) to right (Applications position: 500,200)
6. Export as PNG

### Example Layout

```
┌────────────────────────────────────────────────┐
│                                                │
│              dotViewer                         │
│                                                │
│                                                │
│                                                │
│     [App Icon]    ─→    [Applications]        │
│                                                │
│                                                │
│    Drag to Applications to install             │
│                                                │
└────────────────────────────────────────────────┘
```

## Using the Installer Script

Once you have the background image:

```bash
# 1. Build your app in Xcode (Product → Archive → Distribute → Copy App)
# 2. Save to build/Release/dotViewer.app
# 3. Run the installer script
./scripts/create-installer.sh
```

The DMG will be created in `dist/dotViewer-1.0-Installer.dmg`

## Without Background Image

If you don't have a background image yet, the script will create a basic DMG without custom styling. You can still use it for testing!
