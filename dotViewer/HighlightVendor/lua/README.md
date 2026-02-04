# Lua Sources (Required by highlight)

The highlight library depends on Lua. Place Lua sources here so the build can
compile them into the HighlightXPC target.

## Expected Layout
Place Lua sources under:

- `HighlightVendor/lua/src/` (containing `lua.h`, `lauxlib.h`, `lualib.h` and `*.c` sources)

## Recommended Steps
1. Download Lua 5.4.x source from https://www.lua.org/ftp/
2. Extract and copy the `src/` directory into `HighlightVendor/lua/src`
3. Re-run `xcodegen generate`

If you want me to wire this automatically after you drop it in, tell me and I’ll update the build settings.
