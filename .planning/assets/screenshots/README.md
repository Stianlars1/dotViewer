# App Store Screenshots

Marketing screenshots for Mac App Store submission.

## Requirements

### App Store Connect Specifications

- **Minimum:** 1 screenshot
- **Maximum:** 10 screenshots
- **Supported sizes:**
  - 2880x1800 pixels (Retina - recommended)
  - 2560x1600 pixels
  - 1440x900 pixels
  - 1280x800 pixels
- **Format:** PNG or JPEG
- **Color space:** sRGB or P3

### Recommended: 2880x1800 (Retina)

This provides the crispest display on high-resolution Macs and scales well across all display sizes.

## Screenshot Suggestions for dotViewer

### Screenshot 1: Hero Shot (Required)
**QuickLook preview showing Swift code with syntax highlighting**
- Select a visually appealing Swift file (e.g., ContentView.swift)
- Press Space to trigger QuickLook
- Capture the preview window with clear syntax colors

### Screenshot 2: Sensitive Data Warning
**QuickLook preview showing a .env file with warning banner**
- Create or use an existing .env file
- QuickLook should display the sensitive data warning banner
- Shows the security-conscious design

### Screenshot 3: Theme Selection
**Main app settings showing theme picker**
- Open dotViewer preferences
- Show the theme dropdown/picker
- Demonstrates customization options

### Screenshot 4: Custom File Types
**Custom file type registration UI**
- Show the file type extension management
- Demonstrates extensibility

### Screenshot 5: Variety (Optional)
**Side-by-side or another file type**
- Show a different file type being previewed (JSON, YAML, etc.)
- Demonstrates range of supported languages

## Capture Instructions

### Method 1: Window Capture (Recommended)
```bash
# Press Cmd+Shift+4, then Space
# Click on the QuickLook window to capture
```

### Method 2: Screenshot.app
1. Open Screenshot.app (Cmd+Shift+5)
2. Select "Capture Selected Window"
3. Click on the target window

### Resizing to Exact Dimensions

Using `sips` (macOS built-in):

```bash
# Resize to exact dimensions (may distort if aspect ratio differs)
sips -z 1800 2880 screenshot.png --out resized.png

# Crop to exact size (from center)
sips -c 1800 2880 screenshot.png --out cropped.png

# Check dimensions
sips -g pixelHeight -g pixelWidth screenshot.png
```

Using Preview.app:
1. Open image in Preview
2. Tools > Adjust Size
3. Uncheck "Scale proportionally" if needed
4. Enter 2880 x 1800

## File Naming Convention

Save screenshots with descriptive names:
- `screenshot-01-hero.png`
- `screenshot-02-warning.png`
- `screenshot-03-themes.png`
- `screenshot-04-custom-types.png`
- `screenshot-05-variety.png`

## Checklist

- [ ] At least 1 screenshot captured
- [ ] All screenshots are 2880x1800 (or valid alternative size)
- [ ] PNG format
- [ ] Clear, readable content
- [ ] No sensitive personal data visible
- [ ] App name/branding visible if applicable
