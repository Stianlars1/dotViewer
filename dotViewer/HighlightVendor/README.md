# Highlight C++ Library Vendor Drop

This folder is reserved for the native `highlight` C++ library sources.

## Expected Layout
Place the highlight repository here so we end up with:

- `HighlightVendor/highlight/src/`
- `HighlightVendor/highlight/include/`
- `HighlightVendor/highlight/share/`

## Recommended Steps
1. Download the highlight source archive or clone the repository.
2. Move the `highlight` folder into `HighlightVendor/`.
3. Re-run `xcodegen generate` in `dotViewer/`.
4. Build the `HighlightXPC` target.

## Notes
- The Swift bridge is already in place (`HighlightXPC/HighlightBridge.mm`).
- Once the library is present, we will replace the placeholder implementation with real highlighting calls.
- If you want me to wire the exact include paths after you drop in the library, just tell me and I’ll update `project.yml`.
