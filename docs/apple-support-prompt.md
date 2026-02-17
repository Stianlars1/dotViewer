# Prompt for Apple Developer Support

---

## Context

I'm building a macOS Quick Look extension (QLPreviewProvider subclass, data-based preview with `QLIsDataBasedPreview: true`) that syntax-highlights source code, config files, and dotfiles — essentially any text-based file a developer might encounter.

The extension works perfectly for files whose UTIs we explicitly list in `QLSupportedContentTypes`. We currently declare 563 custom UTIs via `UTExportedTypeDeclarations` and list 680 UTIs in `QLSupportedContentTypes` across both our preview and thumbnail extensions.

## The Problem

Files with extensions that no app has claimed — like `.env.local`, `.fooconfig`, or any novel text file — get assigned dynamic UTIs (`dyn.*`) by macOS. Our Quick Look extension never receives these files because:

1. `public.data` in `QLSupportedContentTypes` does NOT match `dyn.*` UTIs (confirmed — dynamic UTIs conform to `public.data` in the type hierarchy, but Quick Look appears to use exact matching, not conformance-based matching)
2. We cannot pre-declare UTIs for extensions we don't know about in advance
3. Pre-computing `dyn.*` identifiers doesn't work — the encoding algorithm is undocumented and our computed values didn't match what macOS actually generates

Meanwhile, apps like TextEdit can open ANY text file via "Open With" regardless of UTI — but that uses a different routing mechanism (user-initiated, not system-routed).

## What We've Tried

- Adding `public.data` to `QLSupportedContentTypes` — no effect on `dyn.*` files
- Adding `public.item` and `public.content` — no effect
- Pre-computing `dyn.*` codes from extensions — 0% match rate with actual macOS-generated codes
- Declaring custom UTIs for every extension we know about (currently 563 exports) — works, but can't cover truly unknown extensions

## Questions

1. **Is there any mechanism for a Quick Look extension to receive files with `dyn.*` UTIs?** A wildcard, a catch-all content type, or a conformance-based matching mode?

2. **Does `QLSupportedContentTypes` use exact UTI matching or conformance-based matching?** The documentation says Quick Look checks "whether the UTI of the file conforms to one of the UTIs" in the array, but in practice `public.data` does not catch `dyn.*` files even though `dyn.*` UTIs conform to `public.data`. Is this a documentation/behavior mismatch, or are we doing something wrong?

3. **Is there a way to register a Quick Look extension as a fallback handler** — one that receives files only when no other Quick Look extension has claimed them?

4. **Would the older QLGeneratorRequest API (CFPlugin-based Quick Look generators) handle `dyn.*` UTIs differently** than the modern QLPreviewProvider API? We're aware generators are deprecated but wondering if they had broader matching.

5. **Is there an entitlement, Info.plist key, or private API** that allows a Quick Look extension to opt into receiving all text-like files regardless of specific UTI?

6. **If none of the above is possible**, is the recommended approach to simply declare custom UTIs for every conceivable text-file extension? Is there a practical upper limit to how many `UTExportedTypeDeclarations` an app can have? (We're at 563 currently.)

## Environment

- macOS 15.0+ (Sequoia)
- Xcode 16, Swift 6
- App is sandboxed
- Using `QLPreviewProvider` (not the deprecated `QLPreviewingController`)
- Data-based previews (`QLIsDataBasedPreview: true`)
- Both preview and thumbnail extensions

## What We Want

Ideally: a way for our Quick Look extension to be invoked for ANY file that is textual, even if its extension has no declared UTI. We'd do our own binary detection and gracefully reject non-text files.

Minimum viable: confirmation that this is impossible so we can stop searching, along with any recommendations for maximizing coverage within the current system.
