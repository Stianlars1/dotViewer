# Apple App Icon Design Guide — Liquid Glass & HIG

> **Purpose:** Paste this document as context into any AI chat session to generate Apple-style macOS/iOS app icons that match the quality, style, tone, and feel of first-party Apple icons (Finder, Photos, Shazam, Notes, Weather, etc.) following Human Interface Guidelines and the Liquid Glass design system introduced at WWDC 2025.

---

## 1. The Output

You are generating a **1024 x 1024 pixel PNG image** of an app icon. This image must look indistinguishable from a real Apple first-party app icon when placed in a macOS Dock or iOS Home Screen. The system will apply the squircle mask automatically — your image should be a full-bleed square with no baked-in rounded corners.

---

## 2. The Shape — Apple's Squircle

Apple icons use a **continuous-curvature rounded rectangle** (commonly called a "squircle"), not a standard rounded rectangle. The difference is that curvature transitions smoothly from flat edges to rounded corners rather than jumping abruptly.

**Key measurements (at 1024px):**

- Visible icon area: **824 x 824 px** centered within the 1024px canvas
- Corner radius: **185.4 px** (continuous curvature, not circular arc)
- Gutter/padding: **100 px** on all sides from canvas edge to visible shape edge
- The system applies this mask — your artwork should fill the full 1024px square

**For image generation:** Render your icon as a full 1024x1024 square. The content should be designed knowing that corners will be clipped by the squircle mask, so keep critical elements within the **central 70%** of the canvas (approximately a 716px centered safe zone).

---

## 3. Core Design Principles

These are non-negotiable rules that every Apple-quality icon follows:

### 3.1 — Single Focal Object
Every icon communicates **one idea** through **one dominant shape**. Not a collage, not a scene — a single, immediately recognizable silhouette.

- Finder = a face
- Photos = a flower
- Shazam = an S-curve
- Notes = a notepad
- Weather = a cloud + sun
- Safari = a compass

**Rule:** If you squint at the icon from across the room, you should still recognize what it is.

### 3.2 — No Text
Never include text, letters, app names, or labels inside the icon. The Dock/Home Screen label handles naming. The only exception is when a letter IS the brand identity (like the "S" in Sublime Text), and even then it must be treated as a graphic symbol, not as readable text.

### 3.3 — Works at Every Size
The icon must be recognizable and beautiful at all sizes:

| Size | Context | What must survive |
|------|---------|-------------------|
| 1024px | App Store, marketing | Full detail, all subtlety visible |
| 512px | Finder, large grid | All elements clear |
| 256px | Launchpad | Main shape + color story clear |
| 128px | Dock (large) | Silhouette + dominant color |
| 64px | Dock (default) | Shape instantly recognizable |
| 32px | Sidebar, small UI | Basic form + color |
| 16px | Menu bar, tiny UI | Colored blob with recognizable outline |

### 3.4 — Depth, Not Flat
Apple icons have rich, dimensional quality. They are not flat vector illustrations. They use subtle 3D depth cues: gradients, highlights, shadows, and material simulation. This creates the "rich, crafted object" feel Apple is known for.

### 3.5 — 1-2 Color Story
Use a **dominant hue** plus at most **one accent color**. Not a rainbow. The background gradient should be a refined range within one color family. The foreground symbol typically contrasts against it (usually white or a very light tint on a colored background, or a colored symbol on a white/light background).

### 3.6 — Metaphor Over Literal
The best icons use visual metaphors rather than literal depictions. Xcode uses a hammer (building/construction), not a screenshot of code. Music uses a note, not a speaker. Choose a symbol that *suggests* your app's purpose rather than literally showing it.

---

## 4. The Liquid Glass Material System (2025+)

Liquid Glass is Apple's new design material introduced at WWDC 2025. It combines optical properties of glass with a sense of fluidity — translucent surfaces that reflect and refract their surroundings.

### 4.1 — Layered Construction

Liquid Glass icons are built from **separate layers** that the system composites with material effects:

| Layer | Purpose | Content |
|-------|---------|---------|
| **Background** | Base fill, always visible | Gradient, solid color, or subtle pattern |
| **Foreground Group 1** | Primary symbol | The main icon element |
| **Foreground Group 2** | Secondary detail (optional) | Accent element, overlay |
| **Foreground Group 3** | Tertiary detail (optional) | Small decorative element |
| **Foreground Group 4** | Fine accent (optional) | Sparkle, dot, micro-detail |

**Maximum foreground groups:** 4 (Apple found this provides the right visual complexity bounds).

**Minimum:** 1 background + 1 foreground layer.

### 4.2 — Material Properties

Each layer can have these Liquid Glass properties applied:

| Property | Description | Guidance |
|----------|-------------|----------|
| **Liquid Glass Toggle** | Enables/disables the glass material | Enable on primary layers for the characteristic look |
| **Fill** | Base color of the layer | Use brand/thematic colors |
| **Opacity** | Layer transparency | Background: fully opaque; foreground: typically 85-100% |
| **Blend Mode** | How the layer composites | Normal for most cases |
| **Specular Highlights** | Bright glass-like light reflections | Keep enabled — this is what makes it "glass" |
| **Blur** | Frosted glass texture | Slight blur on backgrounds; avoid on foreground for clarity |
| **Translucency** | See-through quality | Apply to background layers only; foreground must stay readable |
| **Shadow** | Drop shadow beneath elements | Choose "neutral" (black) or "chromatic" (colored) |

### 4.3 — Appearance Modes

Liquid Glass icons automatically adapt to 6 appearance contexts:

1. **Default Light** — Standard appearance on light backgrounds
2. **Default Dark** — Standard appearance on dark backgrounds
3. **Clear Light** — Transparent glass on light wallpapers (wallpaper shows through)
4. **Clear Dark** — Transparent glass on dark wallpapers
5. **Tinted Light** — User-chosen color tint infused into glass
6. **Tinted Dark** — Color tint on dark background

**Critical rule:** The **silhouette must be identical** across all modes. Only background hues and material intensity change — the foreground symbol never changes shape.

### 4.4 — What NOT to Bake In

When preparing artwork for Liquid Glass / Icon Composer:

- Do NOT add shadows (the system applies them dynamically)
- Do NOT add specular highlights (the system adds real-time reflections)
- Do NOT add gradients that simulate lighting (system handles this)
- Do NOT add the squircle mask shape
- DO keep artwork flat, opaque, and cleanly separated by layer
- DO use bold, simple shapes that read clearly through glass effects

---

## 5. The 7-Layer Glass Formula (For Image Generation)

When generating a static icon image (PNG) that *simulates* the Liquid Glass look — as opposed to building layers in Icon Composer — use this layering approach to achieve the authentic Apple glass feel:

### Layer 1: Floor Shadow
A soft, colored shadow beneath the entire icon shape that grounds it visually.

- Shape: Ellipse, positioned just below the icon's bottom edge
- Color: Use the icon's own dominant color (chromatic shadow), NOT black
- Opacity: 4-8% — barely visible, but adds grounding
- Size: ~70% of icon width, very short vertically (3-6px at 80px scale)

### Layer 2: Main Shape / Background Fill
The primary body of the icon. This fills the entire visible area.

- A rich gradient within one color family (e.g., deep blue to medium blue)
- Gradient angle: **145-165 degrees** (top-left to bottom-right) — this is Apple's classic light direction
- The gradient should be subtle — a refined shift, not a dramatic rainbow

### Layer 3: Inner Frost Zone
A frosted glass interior effect that adds dimensionality.

- A slightly inset version of the background shape
- White fill at **6-12% opacity**
- Creates the characteristic "frosted glass interior" look
- Can cover the top ~60% of the icon for a natural light-from-above feel

### Layer 4: Primary Specular Highlight (THE KEY LAYER)
The main light reflection that makes the glass feel real. This is what separates an Apple-quality icon from a flat one.

- Shape: Rotated ellipse in the **upper-left quadrant**
- Position: ~30-35% from left, ~25-30% from top
- Size: ~40% of the icon's width, ~25% of its height
- Color: Pure white
- Opacity: **35-45%** — the brightest element in the composition
- Rotation: **-12 to -20 degrees** — slight tilt following the light direction

### Layer 5: Secondary Specular Highlight
A softer, smaller highlight that reinforces the glass curvature.

- ~50% the size of the primary highlight
- Positioned slightly right and below the primary
- Opacity: **14-18%** — much dimmer
- Little to no rotation

### Layer 6: Tertiary Micro Highlight
A tiny bright spot that adds sparkle and perceived detail/craftsmanship.

- Very small (4-6px at 80px scale)
- Near the top-left edge of the icon
- Opacity: **10-12%**
- Creates a concentrated "hot spot" of light

### Layer 7: Ambient Occlusion + Rim Lighting

**7a — Ambient Occlusion** (shadow on the underside):
- Dark area at the bottom ~20% of the icon
- Black fill at **3-6% opacity**
- Creates the sense of shadow on the underside of a glass object

**7b — Rim Lighting** (edge glow):
- Very thin white stroke around the entire icon outline
- Stroke width: **0.5-0.8px** (at 80px scale)
- Opacity: **10-15%**
- Separates the icon from its background and adds polish

---

## 6. Color System

### 6.1 — Background Gradients

Apple uses refined, deep gradients. Study these reference palettes:

| App | Gradient Start | Gradient End | Angle |
|-----|---------------|-------------|-------|
| Finder | `#1E90FF` (blue) | `#4FC3F7` (light blue) | ~150° |
| Photos | Multi-color (unique) | Flower petal colors | Radial |
| Notes | `#FDD835` (yellow) | `#FFF176` (light yellow) | ~170° |
| Battery | `#43A047` (green) | `#66BB6A` (light green) | ~155° |
| Weather | `#1976D2` (blue) | `#42A5F5` (medium blue) | ~160° |
| Shazam | `#1565C0` (deep blue) | `#42A5F5` (bright blue) | ~150° |
| GitHub (3rd party) | `#6A1B9A` (purple) | `#7B1FA2` (medium purple) | ~150° |
| Shortcuts | `#4A148C` (deep purple) | `#7B1FA2` (medium purple) | ~155° |
| iCloud | `#E3F2FD` (white-blue) | `#90CAF9` (light blue) | ~165° |

**Key pattern:** Gradients stay within one hue family. The shift is from a darker/more saturated version to a lighter/less saturated version. The angle is almost always between 145-170 degrees.

### 6.2 — Foreground Colors

- **White foreground on colored background** — The most common pattern (Finder face, Shazam S, Notes lines, Battery shape)
- **Colored foreground on white/light background** — Used for multi-color symbols (Photos flower, Game Center hexagons)
- **Color-on-color** — Rare, used when the symbol is a different hue from the background

### 6.3 — Color Temperature

- **Cool tones** (blue, teal, purple): Professional, technical, utility apps
- **Warm tones** (orange, yellow, red): Creative, social, action-oriented apps
- **Neutral/white**: Clean, document-focused, productivity apps
- **Green**: Success, health, completion, nature
- **Multiple colors**: Photos, creativity, fun (use sparingly — harder to pull off)

---

## 7. Composition & Layout

### 7.1 — Safe Zone

All essential content must stay within the **central 70%** of the canvas to survive squircle clipping.

At 1024px, that means:
- Safe area: **716 x 716 px**, centered
- Margin from edge: **154 px** on all sides
- Critical elements (the main symbol) should be even more centered — within the central **60%**

### 7.2 — Visual Weight & Centering

The main symbol should feel **optically centered**, which is not always geometrically centered. Organic shapes may need to be nudged slightly to feel balanced. Heavier elements (thick bases) should be centered lower; lighter elements (points, antennae) can extend upward.

### 7.3 — Scale of the Main Element

The primary symbol should occupy approximately **55-70%** of the visible icon area. Too small and it gets lost at small sizes. Too large and it feels cramped with no breathing room.

### 7.4 — Depth Layering

Create a sense of front-to-back depth:

1. **Background** — The gradient fill (deepest layer)
2. **Subtle texture** (optional) — Very faint pattern at 4-8% opacity (like the code lines behind a loupe)
3. **Main symbol** — The dominant foreground element, fully opaque
4. **Accent detail** (optional) — A small complementary element (a dot, a sparkle, a highlight line)

---

## 8. Rendering Style

### 8.1 — The "Apple Material" Look

Apple icons simulate **real physical materials**:

- **Glass**: Translucent, with specular highlights, internal frosting, and rim lighting
- **Metal**: Brushed or polished surfaces with directional highlights
- **Paper**: Soft, matte, with subtle fiber texture and soft shadows
- **Plastic**: Smooth, glossy, with a single strong highlight and saturated color

Most modern Apple icons lean toward the **glass** aesthetic, especially with Liquid Glass.

### 8.2 — Light Direction

Apple's canonical light source comes from the **upper-left**. This affects:

- Gradient direction: light upper-left to dark lower-right (145-165°)
- Specular highlights: positioned in the upper-left quadrant
- Shadows: cast toward the lower-right
- Ambient occlusion: darker at the bottom

**Never** light an icon from below or from the right — it will feel "wrong" even if viewers can't articulate why.

### 8.3 — Shadow Specifications (at 1024px)

For the icon's drop shadow:
- Blur radius: **28 px**
- Y-axis offset: **12 px** downward
- X-axis offset: **0 px**
- Spread: **0 px**
- Color: Pure black at **30-50% opacity**

For internal element shadows (symbols sitting on the background):
- Blur: **8-20 px**
- Y offset: **4-8 px**
- Opacity: **15-30%**

### 8.4 — Highlights & Reflections

The top surface of the icon should have a **subtle top highlight** — an elliptical white gradient at 8-15% opacity, positioned at the top and fading downward. This simulates overhead ambient light catching the top surface of a glass or plastic object.

---

## 9. What NOT To Do

These are the most common mistakes. Avoid all of them:

| Mistake | Why it's wrong |
|---------|---------------|
| Text in the icon | Apple explicitly forbids this; the app name label handles identification |
| Baked-in squircle corners | The system applies the mask; baking it in creates a double-border artifact |
| Too many elements | At 64px Dock size, it becomes visual noise; stick to one focal object |
| Flat design with no depth | Apple icons always have dimensionality — gradients, highlights, shadows |
| Sharp corners on internal elements | Liquid Glass prefers rounded forms; light travels better on curves |
| Literal screenshots or UI | Use metaphorical symbols, not literal depictions of your app's UI |
| Rainbow/too many colors | Stick to 1-2 hue families; multi-color is very hard to pull off |
| Dark foreground on dark background | The main symbol must have strong contrast against the background |
| Thin lines or fine detail | At small sizes, thin elements disappear; use bold, chunky shapes |
| Competing visual elements | One hero element, not a committee of equal-weight objects |
| Pure black or pure white backgrounds | Use gradients with subtle color shifts for richness |
| Transparency/see-through PNG backgrounds | The background must be fully opaque (the system handles masking) |

---

## 10. Step-by-Step Process for AI Image Generation

When prompting an AI image generator, follow this exact workflow:

### Step 1: Define the Concept
Decide on your single focal metaphor. Express it in 3 words or fewer:
- "Music note" / "Code magnifier" / "Cloud sync" / "Shield lock"

### Step 2: Choose Your Color Story
Pick a background gradient (2 colors in the same family) and a foreground color (usually white).

### Step 3: Construct the Prompt

Use this template, filling in the bracketed sections:

```
A macOS app icon, 1024x1024 pixels, square with no rounded corners
(the OS applies the squircle mask).

Background: A refined [COLOR FAMILY] gradient from [DARKER HEX] (upper-left)
to [LIGHTER HEX] (lower-right), at approximately 150 degree angle.

Foreground: A single [DESCRIPTION OF SYMBOL] rendered in [COLOR, usually white]
with a subtle 3D glass-like quality — soft specular highlights in the upper-left,
gentle shadows toward the lower-right, and a thin rim light along the edges.

Style: Apple Human Interface Guidelines aesthetic. Rich, dimensional, premium feel.
Liquid Glass material — the symbol should appear to be made of frosted glass with
internal depth, subtle translucency, and realistic light behavior.

The icon should have a soft ambient glow at the top suggesting overhead lighting.
The main symbol occupies roughly 60% of the visible area and is centered.

No text. No letters. No app name. Clean, minimal, one focal object.
The icon should look like it belongs in a macOS Dock next to Finder, Safari,
and Photos. Professional, polished, Apple-quality.
```

### Step 4: Post-Generation Checklist

After generating, verify:

- [ ] Full 1024x1024 square, no baked-in rounded corners
- [ ] One dominant focal element, instantly recognizable
- [ ] No text or letters (unless the letter IS the brand mark)
- [ ] Background is a subtle gradient, not flat or jarring
- [ ] Specular highlights present in upper-left area
- [ ] Shadows present in lower-right area
- [ ] Light direction is consistently from upper-left
- [ ] Main symbol has depth/dimensionality (not flat)
- [ ] Content within central 70% safe zone
- [ ] Looks recognizable when mentally shrunk to 64px
- [ ] Color palette is 1-2 hue families maximum
- [ ] Premium, polished quality — no "stock art" or "clip art" feel
- [ ] Would look at home next to Finder, Notes, and Weather in a Dock

### Step 5: Refinement Prompts

If the result needs adjustment, use these targeted follow-ups:

- **Too flat:** "Add more depth — richer specular highlights in the upper-left, stronger ambient occlusion at the bottom, and a more pronounced rim light along the edges."
- **Too busy:** "Simplify — remove secondary elements and keep only the single main symbol. Reduce detail to just the essential silhouette."
- **Wrong shape:** "The background should fill the entire square — no rounded corners, no circular mask. The OS applies the squircle mask automatically."
- **Looks AI-generated:** "Make it more refined and Apple-like — smoother gradients, cleaner geometry, more precise highlights. It should look hand-crafted by an Apple designer, not AI-generated."
- **Too much contrast:** "Soften the gradients and reduce contrast. Apple icons use subtle, refined color shifts — not dramatic high-contrast transitions."

---

## 11. Reference: Anatomy of Real Apple Icons

### Finder Icon
- Background: Blue gradient (medium to bright cyan-blue)
- Foreground: White/light face silhouette with two eyes and a smile
- Style: The face has subtle 3D depth with glass-like translucency
- Lesson: One simple, iconic shape; universally recognizable

### Photos Icon
- Background: White/light
- Foreground: Multi-colored flower with 8 overlapping translucent petals
- Style: Each petal is a different color with glass-like overlapping
- Lesson: Color can BE the identity when handled with restraint

### Notes Icon
- Background: Yellow gradient (warm, notepad yellow)
- Foreground: Notepad with ruled lines, spiral binding at top
- Style: Realistic paper material simulation
- Lesson: Skeuomorphic details can work when tasteful and minimal

### Weather Icon
- Background: Blue gradient (sky blue)
- Foreground: White cloud partially covering a yellow sun
- Style: Soft, rounded shapes with glass-like translucency on the cloud
- Lesson: Two elements can work when one clearly dominates (cloud) and the other supports (sun)

### Shazam Icon
- Background: Deep blue gradient
- Foreground: White S-curve symbol centered on a raised circular platform
- Style: Clean geometry with strong specular highlight on the platform
- Lesson: Abstract shapes work when they're distinctive and bold

---

## 12. Quick Reference Card

```
CANVAS:         1024 x 1024 px, full-bleed square, no rounded corners
SAFE ZONE:      Central 70% (716px) for critical content
SHAPE:          System applies squircle mask (continuous curvature)
GRADIENT ANGLE: 145-165° (upper-left light to lower-right dark)
COLOR STORY:    1-2 hue families, dominant + accent
FOREGROUND:     Usually white on colored background
SYMBOL SCALE:   ~55-70% of visible area
TEXT:           NEVER (zero text in the icon)
ELEMENTS:       ONE focal object (single metaphor)
DEPTH:          Always — highlights, shadows, gradients, glass effects
LIGHT SOURCE:   Upper-left, always
HIGHLIGHTS:     35-45% white in upper-left quadrant
SHADOWS:        3-6% ambient occlusion at bottom
RIM LIGHT:      10-15% white stroke on edges
MATERIAL:       Liquid Glass — frosted, translucent, refractive
TEST:           Must be recognizable at 64px (Dock size)
```

---

## 13. Icon Composer Workflow (For Native Development)

If you are building a real app icon for Xcode:

1. **Design** your artwork in Figma/Sketch/Illustrator at 1024x1024
2. **Separate** into clean layers: background (opaque) + foreground(s) (transparent)
3. **Export** each layer as SVG (preferred) or PNG — flat, opaque, no baked-in effects
4. **Open Icon Composer** (requires macOS Sequoia 15.3+, ships with Xcode 26)
5. **Import** background into the Back layer slot
6. **Import** foreground(s) into Group layers (up to 4 groups)
7. **Toggle** Liquid Glass on per layer
8. **Adjust** specular, blur, translucency, shadow (neutral or chromatic)
9. **Preview** across all 6 appearance modes (Default, Dark, Clear Light/Dark, Tinted Light/Dark)
10. **Export** as .icon file → drag into Xcode project
11. **Keep legacy .icns** for backward compatibility with older macOS versions

---

*This guide synthesizes Apple's Human Interface Guidelines, WWDC 2025 Liquid Glass design sessions, Icon Composer specifications, and analysis of Apple's first-party icon designs.*
