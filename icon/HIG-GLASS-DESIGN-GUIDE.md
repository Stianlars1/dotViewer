# HIG Glass Design Guide for dotViewer Icon Lab

> **Purpose:** This document is a complete reference for generating Apple HIG-informed glass assets and presets in the dotViewer Icon Lab (`dotViewer-icon-lab.html`). Feed this to Claude in a fresh session to produce more HIG-quality content.

---

## Critical Rules

1. **NEVER delete, edit, or overwrite existing assets or presets.** Only append new ones.
2. Every new asset goes into the `ASSETS` array (before the closing `];`).
3. Every new preset goes into the `PRESETS` array (before the closing `];`).
4. Update the filter tab counts and badge rendering if you add a new group.
5. All asset IDs must be unique across the entire `ASSETS` array.
6. All preset names must be unique across the entire `PRESETS` array.

---

## File Structure

```
dotViewer-icon-lab.html (single-file web app)
├── <style>        — CSS including .preset-badge.{group} styles
├── <svg>          — Canvas with squircle clip, defs (gradients, filters)
├── ASSETS[]       — Array of asset objects (draggable SVG elements)
├── PRESETS[]      — Array of preset objects (compositions)
├── Rendering      — renderCanvas(), renderBG(), presetThumbSVG()
├── Left Panel     — Gallery (presets) / Studio (assets)
├── Right Panel    — Properties inspector + layer list
├── Interactions   — Click, drag, keyboard shortcuts
└── Export         — PNG 1024px + SVG export
```

---

## The 7-Layer Glass Formula

Every HIG Glass asset uses this exact layering order. **This is what makes them feel alive.**

### Layer 1: Floor Shadow
A colored ellipse below the main shape. Simulates the object casting a shadow onto the "desk" beneath it.
```svg
<ellipse cx="CENTER_X" cy="BOTTOM+4" rx="SHAPE_WIDTH*0.7" ry="3-4" fill="${c}" opacity="0.06"/>
```
- Use the shape's own color (`${c}`), not black — this creates a **chromatic shadow**
- `opacity: 0.06` — barely visible, but adds grounding
- Position it 4-6px below the shape's bottom edge
- rx should be ~70% of the shape's width

### Layer 2: Main Shape Fill
The primary shape body. Uses the color parameter `c`.
```svg
<circle cx="40" cy="40" r="37" fill="${c}"/>
```
- Always the full color, no opacity reduction on the main body
- This is the "glass body" that everything else sits on top of

### Layer 3: Inner Frost Zone
A slightly smaller version of the shape, filled white at very low opacity. Creates the "frosted glass interior" look.
```svg
<circle cx="40" cy="40" r="34" fill="white" fill-opacity="0.06-0.12"/>
```
- 2-4px smaller than the main shape
- `fill-opacity: 0.06–0.12` — subtle, never obvious
- Optional: for complex shapes, use a path that covers the top ~60% of the shape

### Layer 4: Primary Specular Highlight (THE KEY LAYER)
A rotated ellipse in the top-left quadrant. This is the **main light reflection** that makes the glass feel real.
```svg
<ellipse cx="X-15%" cy="Y-25%" rx="16" ry="10" fill="white" opacity="0.38-0.42" transform="rotate(-12 to -20, cx, cy)"/>
```
- **Position:** Top-left quadrant (~30-35% from left, ~25-30% from top)
- **Size:** ~40% of the shape's width, ~25% of its height
- **Opacity:** `0.35–0.45` — this is the brightest element
- **Rotation:** `-12° to -20°` — slight tilt adds natural light behavior
- The rotation angle should follow the gradient direction loosely

### Layer 5: Secondary Specular Highlight
A smaller highlight slightly right and below the primary. Adds depth to the glass curvature.
```svg
<ellipse cx="X+10%" cy="Y-15%" rx="8" ry="5" fill="white" opacity="0.14-0.18"/>
```
- ~50% the size of the primary highlight
- `opacity: 0.14–0.18` — much dimmer than primary
- Positioned slightly right and below the primary highlight
- No rotation needed (or very slight)

### Layer 6: Tertiary Micro Highlight
A tiny bright spot that adds sparkle and perceived detail.
```svg
<ellipse cx="X-20%" cy="Y-30%" rx="4" ry="2.5" fill="white" opacity="0.10-0.12"/>
```
- Very small (4-6px radius)
- `opacity: 0.10–0.12`
- Positioned near the top-left edge of the shape
- Creates a "hot spot" of light

### Layer 7: Ambient Occlusion + Rim Lighting
Two sub-layers that finish the volumetric effect:

**Ambient Occlusion** — dark area at the bottom of the shape:
```svg
<ellipse cx="CENTER" cy="BOTTOM-10%" rx="WIDTH*0.6" ry="HEIGHT*0.15" fill="black" opacity="0.04"/>
```
- Black fill, very low opacity (0.03–0.06)
- Positioned at the bottom 20% of the shape
- Creates the feeling of shadow on the underside of glass

**Rim Lighting** — thin white stroke around the entire shape:
```svg
<circle cx="40" cy="40" r="37" stroke="white" stroke-width="0.6-0.7" fill="none" opacity="0.12-0.15"/>
```
- Matches the exact outline of the main shape
- `stroke-width: 0.5–0.8` — must be very thin
- `opacity: 0.10–0.15` — subtle edge glow
- This is what separates the icon from its background

---

## Asset Definition Format

```javascript
{ id: 'hig_UNIQUE_ID',          // Prefix with 'hig_' for HIG Glass category
  name: 'HIG Display Name',      // Human-readable, shown in asset panel
  cat: 'HIG Glass',              // Category for grouping in left panel
  w: WIDTH,                       // Viewbox width (typically 60-120)
  h: HEIGHT,                      // Viewbox height (typically 70-90, +4 for floor shadow)
  svg: c => `                     // Arrow function, 'c' = color parameter
    LAYER_1_FLOOR_SHADOW
    LAYER_2_MAIN_SHAPE
    LAYER_3_INNER_FROST
    LAYER_4_PRIMARY_SPECULAR
    LAYER_5_SECONDARY_SPECULAR
    LAYER_6_TERTIARY_MICRO
    LAYER_7A_AMBIENT_OCCLUSION
    LAYER_7B_RIM_LIGHTING
  ` }
```

**Important:** The SVG must be a single template literal string (backtick). It can contain newlines for readability in source, but each SVG element must be properly closed.

### Sizing Convention
- Main shape area: use coordinates within `0–80` range (width) and `0–80` (height)
- Floor shadow: add 4px to height for the shadow ellipse
- So typical `h` values are `78–90` (main shape + floor shadow space)
- Keep viewBox proportions reasonable — not too wide, not too tall

---

## Preset Definition Format

```javascript
{ name: 'HIG Preset Name',       // Unique display name
  group: 'hig',                   // MUST be 'hig' for HIG presets
  bg: {
    c1: '#COLOR_1',               // Gradient start color
    c2: '#COLOR_2',               // Gradient end color
    angle: 145-172                // Gradient angle in degrees
  },
  els: [                           // Array of elements (layer order = render order)
    { type: 'ASSET_ID',           // Must match an existing asset id
      x: X_POS,                   // X position on 512x512 canvas
      y: Y_POS,                   // Y position on 512x512 canvas
      scale: SCALE,               // Multiplier (1.0 = native, 2.5-3.5 = typical)
      opacity: OPACITY,           // 0.0–1.0
      color: '#COLOR',            // Color passed to the asset's svg(c) function
      rot: ROTATION               // Degrees, typically 0
    },
    // ... more elements
  ]
}
```

---

## Composition Rules (Apple Icon Composer Philosophy)

### Single Metaphor
Every icon should communicate ONE idea. For dotViewer, the core metaphors are:
- **Magnifier/Loupe** = inspection, viewing, analysis
- **Dot** = the "dot" in dotViewer, also represents data points
- **Code lines** = code inspection context (supporting detail only)

### Layer Hierarchy
Apple's Icon Composer uses 3 conceptual layers:
1. **Background** — gradient fill, optional subtle texture (code lines at 0.05–0.08 opacity)
2. **Midground** — the main symbol (loupe), largest and most prominent
3. **Foreground** — accent detail (dot, highlight line), smaller and complementary

### Positioning Guidelines
On the 512x512 canvas:
- **Center the main element** around `x:116-156, y:106-136` with `scale: 2.5-3.2`
- **Accent elements** at `x:200-260, y:200-260` with `scale: 0.8-1.5`
- **Background textures** at `x:80-120, y:100-140` with `scale: 2.5-3.5, opacity: 0.04-0.08`
- Keep content within the safe zone (roughly 80px margin from edges)

### Gradient Angles
- `145-155°` — classic Apple diagonal (top-left to bottom-right)
- `158-165°` — slightly steeper, more dynamic
- `170-175°` — near-vertical, calmer feel

---

## Color Palettes

### dotViewer Brand Colors
```
Indigo:    c1: '#3730a3'  c2: '#6366f1'   — The signature dotViewer palette
Purple:    c1: '#4a3fb8'  c2: '#7c5ce7'   — Rich variant
Deep:      c1: '#1e1b4b'  c2: '#312e81'   — Dark mode variant
```

### Background Archetypes
```
White/Light:    c1: '#f8f9fa'  c2: '#ebedf2'   — Clean Apple white
Warm White:     c1: '#f5f5f7'  c2: '#e0e3ea'   — Settings-style gray
Dark:           c1: '#1a1a2e'  c2: '#0f0f1a'   — Dark mode
Near-Black:     c1: '#0d1b2a'  c2: '#1b2838'   — Midnight
Blue:           c1: '#42a5f5'  c2: '#1e88e5'   — iCloud blue
Green:          c1: '#3bd16f'  c2: '#28a745'   — Messages green
Red:            c1: '#e53935'  c2: '#f44336'   — Health red
Warm:           c1: '#e65100'  c2: '#ff9800'   — Sunset
Purple:         c1: '#7c3aed'  c2: '#5b21b6'   — Rich purple
Teal:           c1: '#00897b'  c2: '#26a69a'   — Mint
```

### Element Colors
- **White foreground on colored bg:** `color: '#ffffff'` (most common)
- **Colored foreground on white bg:** use the same hue as a hypothetical bg
- **Accent dots/highlights:** use a lighter tint of the bg (e.g., `'#e9d5ff'` on purple bg)
- **Gold accents:** `'#ffd54f'` for premium/royal feel

---

## Existing Assets to Use in Presets

### Best Assets for dotViewer Icon Compositions

**Primary (magnifier/inspection):**
- `liq_mag` — Liquid Glass magnifier (THE go-to for dotViewer)
- `glass_mag` — Apple Glass magnifier (simpler variant)
- `hig_camera` — Aperture lens (alternative inspection metaphor)

**Secondary (dot/data):**
- `liq_dot` — Liquid Glass sphere (THE accent dot)
- `dot_large` — Apple Glass big dot
- `dot_glow` — Glowing dot with filter

**Supporting (code context):**
- `lines3`, `lines5` — Code lines (background texture, very low opacity)
- `highlight_line` — Glowing code highlight
- `code_block` — Full code block structure
- `liq_terminal` — Glass terminal window

**Decorative (add polish):**
- `sparkle` — Star sparkle
- `hig_star` — Glass star
- `hig_wand` — AI/magic wand
- `concentric` — Signal rings

---

## dotViewer Icon Recipe

The "perfect" dotViewer icon follows this template:

```javascript
{ name: 'HIG dotViewer [VARIANT]', group: 'hig',
  bg: { c1: '#BRAND_COLOR_1', c2: '#BRAND_COLOR_2', angle: 148-155 },
  els: [
    // Optional: background texture (code lines, very faint)
    { type:'lines5', x:80, y:130, scale:3.0, opacity:0.05, color:'#ffffff', rot:0 },
    // Main element: glass magnifier, centered-left
    { type:'liq_mag', x:116, y:106, scale:2.8, opacity:1, color:'#ffffff', rot:0 },
    // Accent: glass dot, positioned at the loupe's focal point
    { type:'liq_dot', x:200, y:200, scale:1.3-1.5, opacity:0.85-0.92, color:'#TINT', rot:0 },
    // Optional: subtle highlight line below loupe
    { type:'highlight_line', x:176, y:218, scale:0.5, opacity:0.6, color:'#ACCENT', rot:0 },
  ]
}
```

### Variations to Explore
- **Dot size:** smaller dot (scale 0.8-1.0) = more minimalist, larger (1.5-2.0) = bolder
- **Dot color:** match the bg tint for harmony, or use white for contrast
- **Code lines:** include for "code inspector" feel, omit for "clean viewer" feel
- **Extra elements:** add `sparkle` or `hig_star` for premium feel
- **Color schemes:** try every palette above with the same composition

---

## Badge & Filter Integration

When adding a new group (if needed), update these three locations:

### 1. CSS Badge Style
```css
.preset-badge.GROUPNAME { background: linear-gradient(...); color: #HEX; border: 1px solid rgba(...); }
```

### 2. Filter Tab (in `renderLeftPanel()`)
```javascript
const GROUPNAMECount = PRESETS.filter(p => p.group === 'GROUPNAME').length;
// ... add button in filter-tabs div:
html += `<button class="filter-tab ${S.galleryFilter==='GROUPNAME'?'active':''}" onclick="setGalleryFilter('GROUPNAME')">LABEL<span class="filter-count"> ${GROUPNAMECount}</span></button>`;
```

### 3. Badge Rendering (in preset card generation)
```javascript
const badge = p.group === 'apple' ? '...' : p.group === 'liquid' ? '...' : p.group === 'hig' ? '<span class="preset-badge hig">HIG</span>' : p.group === 'NEWGROUP' ? '<span class="preset-badge NEWGROUP">LABEL</span>' : '';
```

---

## Quality Checklist

Before finalizing any new asset or preset:

- [ ] Asset ID is unique (check with `ASSETS.find(a => a.id === 'YOUR_ID')`)
- [ ] Preset name is unique
- [ ] Floor shadow present (Layer 1)
- [ ] Primary specular highlight present and positioned top-left (Layer 4)
- [ ] At least one secondary highlight (Layer 5)
- [ ] Rim lighting stroke present (Layer 7b)
- [ ] Ambient occlusion at bottom (Layer 7a)
- [ ] Asset uses `${c}` parameter for main color (not hardcoded colors except white/black)
- [ ] Preset elements reference valid asset IDs
- [ ] Canvas positioning within safe zone (80px margin)
- [ ] Gradient angle between 145-175°
- [ ] Main element scale between 2.5-3.5 for proper icon sizing

---

## Example: Creating a New HIG Asset from Scratch

Let's say you want to create a "HIG Compass":

```javascript
{ id: 'hig_compass', name: 'HIG Compass', cat: 'HIG Glass', w: 80, h: 84,
  svg: c => `
    <ellipse cx="40" cy="78" rx="28" ry="4" fill="${c}" opacity="0.06"/>
    <circle cx="40" cy="40" r="37" fill="${c}"/>
    <circle cx="40" cy="40" r="33" fill="white" fill-opacity="0.08"/>
    <line x1="40" y1="10" x2="40" y2="70" stroke="white" stroke-width="0.8" opacity="0.08"/>
    <line x1="10" y1="40" x2="70" y2="40" stroke="white" stroke-width="0.8" opacity="0.08"/>
    <polygon points="40,12 44,38 40,42 36,38" fill="white" opacity="0.9"/>
    <polygon points="40,68 44,42 40,38 36,42" fill="${c}" opacity="0.3"/>
    <circle cx="40" cy="40" r="4" fill="white" opacity="0.6"/>
    <ellipse cx="30" cy="24" rx="14" ry="9" fill="white" opacity="0.4" transform="rotate(-16,30,24)"/>
    <ellipse cx="46" cy="30" rx="7" ry="4" fill="white" opacity="0.16"/>
    <ellipse cx="24" cy="20" rx="4" ry="2.5" fill="white" opacity="0.1"/>
    <ellipse cx="40" cy="58" rx="20" ry="6" fill="black" opacity="0.04"/>
    <circle cx="40" cy="40" r="37" stroke="white" stroke-width="0.7" fill="none" opacity="0.12"/>
  ` }
```

Notice how every layer follows the formula: floor shadow → main body → inner frost → shape details → primary specular → secondary specular → micro highlight → ambient occlusion → rim lighting.

---

## Summary Prompt for Fresh Sessions

> **Copy this prompt to start a new session:**
>
> "I'm working on `dotViewer-icon-lab.html` — an interactive SVG icon playground for designing macOS app icons. Read the file `HIG-GLASS-DESIGN-GUIDE.md` in the same folder for the complete design system. Then read the HTML file itself. Add [N] new HIG-style presets focused on [DESCRIPTION]. Use the 7-Layer Glass Formula. Group them as `group: 'hig'`. Do NOT delete or modify any existing content — only append. Verify with asset/preset counts when done."
