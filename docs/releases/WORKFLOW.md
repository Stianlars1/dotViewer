# dotViewer release checks

Run `xcodegen generate` in `dotViewer/` before any Xcode build. Use `scripts/publish.sh VERSION` for the normal release flow.

The installer must use DropDMG configuration `dotviewer` and its saved `dropViewer_dmg_design_layout`. The expected Finder window has the purple background, dotted arrow, app on the left and Applications on the right. `scripts/package-dmg.sh` refuses failed DropDMG runs, missing output and stale destination files. There is no automatic unstyled fallback. Mount and visually check the final installer before considering the release verified.

Keep third-party notices inside the app bundle; extra visible installer files must not displace the layout.

Before publishing, verify cold launch, both status refresh buttons, Finder Space and the relevant preview formats. A failed status command must produce an error, not an endless spinner or a false green result. Run the unit and packaging tests, verify signing, notarization, stapling, version/build and the public download checksum.

## Explicit recovery for the observed Xcode 26.6 pipe hang

Capture a process sample first; the observed compiler and export stalls were blocked writes to child-process pipes, not compiler errors or denied keychain access.

`DOTVIEWER_USE_COMPILER_WRAPPERS=1` opts into wrappers that forward compilation unchanged to the active Apple clang/clang++ through `xcrun`. This avoids the hanging compiler-discovery route; it changes no application source. Both architectures and tests must still pass.

If Xcode's export stage hangs after a successful archive, `scripts/sign-developer-id-app.py SOURCE DESTINATION --identity CERTIFICATE_SHA1` can explicitly re-sign the freshly built bundle using the exact Developer ID certificate. It preserves declared entitlements, removes the development debugging entitlement and embedded development profiles, signs inner bundles first, and verifies the complete result. It refuses to overwrite an existing destination. This does not notarize or publish anything.

Resume the ordinary notarization/DropDMG/publication steps with:

```sh
./scripts/publish.sh VERSION --reuse-exported-app --build-number=BUILD
```

The export must be at `dotViewer/build/export/dotViewer.app`, with the matching version/build and valid signature. Use a clean DMG destination; preserve earlier candidate installers separately. The reuse option is explicit, never an automatic response to a failed build, and does not skip notarization. Verify that application source has not changed since the candidate was built.
