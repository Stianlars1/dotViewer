# dotViewer Icon — Step-by-Step Icon Composer Guide

## What You're Building

A magnifying glass inspecting code lines on an indigo gradient background. One line inside the lens glows purple as the "active/highlighted" line. Faint code lines sit behind in the background. This communicates "code viewer" instantly — one metaphor, zero clutter.

---

## What You Need Before Starting

1. **Icon Composer** (already open)
2. **A design tool** to create the source image — use one of these:
   - **Figma** (free, recommended) — best for vector precision
   - **Pixelmator Pro** — great if you already own it
   - **Sketch** — if you have it
   - **AI image generator** — ChatGPT/DALL-E, Midjourney, or similar for a photorealistic render
3. The SVG reference file I created: `dotViewer-icon-1024.svg` (in your folder)

---

## Phase 1: Create Your Source Image (in Figma or your design tool)

### Step 1 — Set Up the Canvas

- Create a new file at **1024 × 1024 px**
- This is Apple's required maximum resolution

### Step 2 — The Background Gradient

- Draw a rectangle filling the entire 1024 × 1024 canvas
- Apply a **linear gradient** at 145° angle:
  - Top-left stop: `#3730a3` (deep indigo)
  - Bottom-right stop: `#6366f1` (bright indigo)
- Round the corners to **~225px** (Icon Composer will apply the squircle mask, but this helps you visualize)

### Step 3 — Subtle Top Highlight (Depth)

- Draw an ellipse near the top, roughly 1200 × 520 px, centered horizontally
- Fill: white at **12% opacity**
- Blur: Gaussian blur ~40px
- This creates the subtle Apple-style "light catching the top surface" effect

### Step 4 — Background Code Lines

- Draw 12-16 horizontal rounded rectangles scattered across the background
- Height: ~18px each, widths varying between 200–420px
- Start them from x=120, stagger the widths naturally (like real code indentation)
- Fill: white at **7-8% opacity**
- These should be barely visible — they whisper "code" without shouting

### Step 5 — The Magnifying Glass Ring

- Draw a **circle** centered around position (460, 460) — slightly above-center and to the left
  - Outer radius: ~225px
  - Stroke: white at 92% opacity, **32px thick**, no fill
- Add a subtle **drop shadow**: 0px offset, 8px Y, 20px blur, black at 30%

### Step 6 — Lens Glass Effect

- Draw a filled circle inside the ring (radius ~209px, same center)
- Apply a **radial gradient**:
  - Center point at 35%, 35% (upper-left)
  - Inner stop: white at 12% opacity
  - Outer stop: black at 12% opacity
- This creates the subtle glass/lens feel

### Step 7 — Lens Specular Highlight

- Draw a small **ellipse** near the upper-left of the lens (~60 × 32px)
- Rotate it -25°
- Fill: white at **15% opacity**
- This is the classic "light reflection on glass" detail

### Step 8 — Code Lines Inside the Lens

Inside the magnifying glass circle, draw 4-5 horizontal lines:

| Line | Position | Width | Color | Opacity |
|------|----------|-------|-------|---------|
| 1 | y ≈ 388 | 120px | White | 50% |
| 2 | y ≈ 418 | 170px | `#a78bfa` (purple) | 85% |
| 3 | y ≈ 448 | 140px | White | 50% |
| 4 | y ≈ 478 | 100px | White | 50% |
| 5 | y ≈ 508 | 130px | White | 35% |

- Height: ~14px each, corner radius: 7px
- Indent them slightly differently to suggest real code structure
- **Line 2 is the star** — it's the highlighted/active line in purple (`#a78bfa`). Add a subtle glow (Gaussian blur layer behind it, ~6px)

### Step 9 — The Handle

- Draw a **rounded rectangle** (170 × 48px, corner radius 24px)
- Position it extending from the bottom-right of the lens ring
- Rotate 45° so it points to the bottom-right corner
- Fill: white linear gradient from 90% to 65% opacity (left to right)
- Add a slight shadow to ground it

### Step 10 — Export

- Export the entire canvas as **PNG at 1024 × 1024px**
- Make sure the background extends fully to all edges (no transparency!)
- Save as `dotViewer-foreground.png`

---

## Phase 2: Icon Composer Setup

### Step 11 — Open Icon Composer

You should see a blank canvas with the squircle shape outlined.

### Step 12 — Understanding Layers

Icon Composer in 2025 supports **layered icons** for macOS 26 Tahoe's Liquid Glass effect. The layers are:

- **Background** — The solid color/gradient behind everything
- **Foreground** — Your main icon imagery (the magnifying glass, code lines)

For maximum compatibility, you can also create a single **flat** icon.

### Step 13 — Import Your Image

**Option A — Single layer (simpler):**
1. Drag your exported `dotViewer-foreground.png` onto Icon Composer
2. It will place it as the main icon layer
3. The squircle mask is applied automatically

**Option B — Two layers (better for Liquid Glass):**
1. Create two separate PNGs:
   - `background.png` — just the gradient + subtle code lines
   - `foreground.png` — just the magnifying glass on transparent background
2. Import the background layer first
3. Import the foreground layer on top
4. This allows macOS to apply Liquid Glass depth effects between the layers

### Step 14 — Adjust Positioning

- Make sure your content has **~12% padding** from the edges (the squircle mask will clip corners)
- The magnifying glass should be comfortably within the safe area
- Use Icon Composer's preview to check all sizes

### Step 15 — Preview All Sizes

Icon Composer shows your icon at multiple sizes. Check:
- **1024px** — Full detail, every element visible
- **512px** — Should still look great
- **256px** — Code lines inside lens should still be distinguishable
- **128px** — The magnifying glass silhouette should be clear
- **64px** (Dock size) — The icon should be instantly recognizable as a magnifier
- **32px** — Only the basic shape should remain
- **16px** — A simple magnifier silhouette is all you need

### Step 16 — Dark/Light Mode Variants (Optional)

If you want different appearances:
- **Light mode**: Use the indigo gradient as described
- **Dark mode**: Slightly brighter gradient or keep the same (indigo reads well on dark backgrounds)
- **Tinted**: A monochrome version

### Step 17 — Export from Icon Composer

1. Go to File → Export
2. Icon Composer generates the `.icns` file containing all required sizes
3. Add this to your Xcode project's Assets catalog

---

## Phase 3: Add to Your Xcode Project

### Step 18 — Import to Xcode

1. Open your dotViewer Xcode project
2. Navigate to **Assets.xcassets**
3. Select **AppIcon**
4. Drag your exported icon set from Icon Composer into the AppIcon slot
5. Build and run — your new icon should appear in the Dock

---

## Quick Reference: Color Palette

| Role | Hex | Usage |
|------|-----|-------|
| Background dark | `#3730a3` | Gradient start (top-left) |
| Background light | `#6366f1` | Gradient end (bottom-right) |
| Icon elements | `#FFFFFF` @ 90% | Magnifier ring, handle |
| Accent highlight | `#a78bfa` | Active code line inside lens |
| Subtle elements | `#FFFFFF` @ 7-8% | Background code lines |
| Deep variant | `#1e1b4b` | If you want a darker mood |

---

## Tips

- **Less is more** — resist adding brackets, eyes, or other symbols. The magnifier + code lines tells the whole story.
- **Test in the Dock** — put your icon next to Finder, Safari, and Xcode. Does it hold its own? Does it look like it belongs?
- **The purple highlight line** is your signature detail — it's what makes people remember this icon.
- **Don't put text in the icon** — "dotViewer" should NOT appear in the icon itself. The app name shows below the icon in the Dock and Launchpad.
