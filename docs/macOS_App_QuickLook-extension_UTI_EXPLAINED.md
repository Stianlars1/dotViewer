# macOS Quick Look Extension — UTI System Explained

## The Analogy: A Post Office

Think of macOS as a **post office** that delivers files to apps.

```
  YOU (a file on disk)          THE POST OFFICE (macOS)         YOUR APP (dotViewer)
  ┌──────────────────┐         ┌──────────────────────┐        ┌──────────────────┐
  │ .env.local       │         │                      │        │                  │
  │                  │──[1]──▶ │  What's the ZIP code │──[3]──▶│ QuickLookExt     │
  │ (just bytes on   │         │  for this file?      │        │ "I handle these  │
  │  disk, no label) │         │                      │        │  ZIP codes!"     │
  └──────────────────┘         │  [2] Look up UTI     │        └──────────────────┘
                               └──────────────────────┘
```

- **The file** = a letter with no ZIP code
- **The extension** (`.local`) = the street address on the envelope
- **The UTI** = the ZIP code the post office assigns based on that street address
- **QLSupportedContentTypes** = the list of ZIP codes your app says "deliver those to me"
- **UTExportedTypeDeclarations** = you going to the post office and saying "I'm inventing a new ZIP code for this neighborhood"

**The core problem**: The post office (macOS) **only delivers by ZIP code (UTI)**. It never looks at the street address (extension) directly. If a letter has no ZIP code, it goes to the dead letter office (`dyn.*`).

---

## The Three Distinct Concepts

### 1. File Extensions — What humans see
```
.py  .json  .env.local  .gitignore  .cursorrules
```
This is just the filename suffix. macOS doesn't use it directly for routing — it's an **input** to a lookup table.

### 2. UTIs (Uniform Type Identifiers) — What macOS uses internally
```
public.python-script          ← Apple defined this
com.netscape.javascript-source ← Netscape defined this (decades ago!)
com.stianlars1.dotviewer.env  ← WE defined this
dyn.ah62d4rv4ge80k4pwp7v...   ← macOS generated this (no one claimed it)
```

A UTI is a **reverse-DNS identifier** that macOS uses as the "type" of a file. Think of it as a passport that every file needs. There are three scenarios:

| Scenario | Example | Who defines the UTI |
|----------|---------|---------------------|
| Apple already defined it | `.py` → `public.python-script` | Apple (built into macOS) |
| A vendor defined it | `.ts` → `com.microsoft.typescript` | Microsoft (via their app) |
| **Nobody** defined it | `.env.local` → `dyn.ah62d4...` | macOS auto-generates a "fake" one |

The `dyn.*` UTIs are the problem. They're like a post office generating a random ZIP code and then **nobody** checking their mailbox for that ZIP.

### 3. QLSupportedContentTypes — Your mailbox label

This is a list in your Quick Look extension's Info.plist that says:
> "Deliver any file with **these specific UTIs** to me."

```yaml
QLSupportedContentTypes:
  - public.python-script        # I'll handle .py files
  - public.json                 # I'll handle .json files
  - com.stianlars1.dotviewer.env # I'll handle .env files
```

**Critical gotcha**: Quick Look does **EXACT matching** on UTI strings. Not conformance, not inheritance, not patterns. If the file's UTI is `dyn.ah62d4rv4ge80k4pwp` and your list doesn't contain that exact string, you never see the file. Period.

---

## The Full Flow Diagram

Here's what happens when you press Space on a file in Finder:

```
 USER PRESSES SPACE ON: .env.local
 ═══════════════════════════════════════════════════════════════════

 STEP 1: macOS extracts the pathExtension
 ┌─────────────────────────────────────────────────────────────────┐
 │  ".env.local"  →  pathExtension = "local"                      │
 │                                                                 │
 │  NOTE: macOS ONLY looks at the LAST dot segment.               │
 │  It does NOT see "env.local". It sees "local".                 │
 │  .claude.json.backup.123  →  pathExtension = "123"             │
 └─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
 STEP 2: macOS looks up the UTI for extension "local"
 ┌─────────────────────────────────────────────────────────────────┐
 │  LaunchServices database lookup:                                │
 │                                                                 │
 │  Is "local" claimed by any installed app?                       │
 │    → Check UTExportedTypeDeclarations from ALL installed apps   │
 │    → Check UTImportedTypeDeclarations from ALL installed apps   │
 │    → Check Apple's built-in UTI table                           │
 │                                                                 │
 │  If YES: return that UTI   (e.g. com.stianlars1.dotviewer.local│
 │  If NO:  generate dyn.*    (file is effectively unroutable)     │
 └─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
 STEP 3: macOS finds the Quick Look extension that handles this UTI
 ┌─────────────────────────────────────────────────────────────────┐
 │  For EACH installed Quick Look extension:                       │
 │    Read its Info.plist → NSExtensionAttributes →                │
 │      QLSupportedContentTypes                                    │
 │                                                                 │
 │  Does the file's UTI appear in ANY extension's list?            │
 │    → YES: route to that extension                               │
 │    → NO:  show generic Quick Look (or nothing)                  │
 │                                                                 │
 │  ⚠️  EXACT STRING MATCH. Not "conforms to". Not "is a subtype  │
 │     of". The UTI string must be LITERALLY in the array.         │
 └─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
 STEP 4: Our Quick Look extension receives the file
 ┌─────────────────────────────────────────────────────────────────┐
 │  PreviewProvider.swift receives:                                │
 │    - The file URL                                               │
 │    - The file's UTType                                          │
 │                                                                 │
 │  NOW our Swift code takes over:                                 │
 │    FileTypeResolution.bestKey() → looks at full filename        │
 │    FileTypeRegistry → maps to highlight language                │
 │    XPC → tree-sitter highlighting                               │
 │    PreviewHTMLBuilder → HTML output                             │
 └─────────────────────────────────────────────────────────────────┘
```

---

## Why Three Separate Things?

Here's the part that's genuinely confusing and kind of Apple's fault:

```
 ┌──────────────────────────────────────────────────────────────────────┐
 │  YOUR APP'S Info.plist (the host app: dotViewer.app)                │
 │                                                                      │
 │  UTExportedTypeDeclarations:          ← "I INVENT these file types" │
 │    - identifier: com.stianlars1.dotviewer.local                      │
 │      extension: "local"                                              │
 │      conforms to: public.plain-text                                  │
 │                                                                      │
 │  This tells macOS:                                                   │
 │  "When you see a file ending in .local, its UTI should be           │
 │   com.stianlars1.dotviewer.local, not dyn.*"                        │
 └──────────────────────────────────────┬───────────────────────────────┘
                                        │
         ┌──────────────────────────────┘
         │  These are in DIFFERENT plists!
         │  The host app DECLARES types.
         │  The extension SUBSCRIBES to types.
         ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │  YOUR EXTENSION'S Info.plist (QuickLookExtension.appex)             │
 │                                                                      │
 │  QLSupportedContentTypes:             ← "I HANDLE these file types" │
 │    - com.stianlars1.dotviewer.local   ← our custom one              │
 │    - public.python-script             ← Apple's built-in            │
 │    - com.microsoft.typescript         ← Microsoft's                 │
 │    - public.json                      ← Apple's built-in            │
 │    ...680 total UTIs                                                 │
 │                                                                      │
 │  This tells macOS:                                                   │
 │  "Route files with ANY of these UTIs to my extension"               │
 └──────────────────────────────────────────────────────────────────────┘
```

**Why can't they be one thing?** Because Apple separated *defining* a type from *handling* a type:

| Concept | Who | Where | Purpose |
|---------|-----|-------|---------|
| `UTExportedTypeDeclarations` | Host app's Info.plist | dotViewer.app | "Extension `.local` = UTI `com.stianlars1.dotviewer.local`" |
| `QLSupportedContentTypes` | Extension's Info.plist | QuickLookExtension.appex | "Send me files with UTI `com.stianlars1.dotviewer.local`" |
| `DefaultFileTypes.json` | **Our invention** | Shared framework | "When I receive `.env.local`, highlight as bash" |

The JSON registry is **our own thing** — Apple doesn't know or care about it. It's what our Swift code uses *after* the file reaches us.

---

## The Build Pipeline

Here's where `project.yml` fits in:

```
 ┌─────────────────────┐
 │  project.yml        │  ← Source of truth (what you edit)
 │  (XcodeGen input)   │
 └─────────┬───────────┘
           │  xcodegen generate
           ▼
 ┌─────────────────────┐
 │  dotViewer.xcodeproj│  ← Generated (never edit directly)
 │  + Info.plist files  │
 │                      │
 │  App/Info.plist:     │
 │    UTExportedType... │  ← Baked into the HOST APP binary
 │                      │
 │  QL.../Info.plist:   │
 │    QLSupportedCont...│  ← Baked into the EXTENSION binary
 └─────────┬───────────┘
           │  xcodebuild
           ▼
 ┌─────────────────────┐
 │  dotViewer.app      │  ← Installed in /Applications
 │  └── Contents/      │
 │      ├── Info.plist  │  ← Contains UTExportedTypeDeclarations
 │      └── PlugIns/    │
 │          ├── QuickLookExtension.appex
 │          │   └── Info.plist  ← Contains QLSupportedContentTypes
 │          └── QuickLookThumbnailExtension.appex
 │              └── Info.plist  ← Contains QLSupportedContentTypes
 └─────────┬───────────┘
           │  lsregister / pluginkit
           ▼
 ┌─────────────────────┐
 │  LaunchServices DB  │  ← macOS system-wide database
 │                      │
 │  "com.stianlars1.    │
 │   dotviewer.local"   │
 │   → extension: local │
 │   → conforms to:     │
 │     public.plain-text│
 │                      │
 │  QuickLookExt handles│
 │  680 UTIs            │
 └─────────────────────┘
```

---

## The Exact Steps to Add a New File Type

Say you want to add support for `.foobar` files:

```
 STEP 1: DefaultFileTypes.json
 ─────────────────────────────
 Add to the JSON registry so our SWIFT CODE knows about it:

   {
     "id": "foobar",
     "displayName": "Foobar Config",
     "extensions": ["foobar"],
     "filenames": [".foobarrc"],
     "highlightLanguage": "json"
   }

 This does NOT affect macOS routing at all.
 This ONLY tells our code: "when we receive a .foobar file, highlight as JSON"


 STEP 2: python3 scripts/dotviewer-gen-utis.py --apply
 ─────────────────────────────────────────────────────
 The script reads DefaultFileTypes.json and:

   a) Asks macOS: "Does .foobar have a system UTI?"
      → Swift: UTType(filenameExtension: "foobar")
      → Result: dyn.* (no system UTI exists)

   b) Since it's dyn.*, generates a CUSTOM UTI declaration:
      UTTypeIdentifier: com.stianlars1.dotviewer.foobar
      UTTypeTagSpecification:
        public.filename-extension: foobar

   c) Also adds com.stianlars1.dotviewer.foobar to QLSupportedContentTypes


 STEP 3: Paste YAML into project.yml
 ────────────────────────────────────
 The generated YAML goes into TWO places in project.yml:

   dotViewer target → info → properties → UTExportedTypeDeclarations
     (tells macOS: "ext X = UTI Y")

   QuickLookExtension → QLSupportedContentTypes
     (tells macOS: "route UTI Y to me")

   QuickLookThumbnailExtension → QLSupportedContentTypes
     (tells macOS: "route UTI Y to me for thumbnails too")


 STEP 4: ./scripts/dotviewer-refresh.sh
 ───────────────────────────────────────
   xcodegen    → regenerates .xcodeproj + Info.plists from project.yml
   xcodebuild  → compiles everything, embeds plists in binaries
   ditto       → copies to /Applications
   lsregister  → registers with LaunchServices (updates the system DB)
   pluginkit   → enables the Quick Look plugins
   qlmanage -r → resets the Quick Look cache


 STEP 5: Press Space on a .foobar file
 ──────────────────────────────────────
   macOS: pathExtension = "foobar"
   macOS: LaunchServices lookup → com.stianlars1.dotviewer.foobar ✓
   macOS: Who handles this UTI? → QuickLookExtension ✓
   macOS: → sends file to PreviewProvider.swift
   Our code: FileTypeResolution.bestKey() → "foobar"
   Our code: FileTypeRegistry → highlightLanguage = "json"
   Our code: XPC → tree-sitter JSON highlighting
   Our code: → rendered HTML preview ✓
```

---

## The Gotcha That Bit Us

The biggest trap — and what this whole session fixed:

```
 DefaultFileTypes.json:
   "env" type → filenames: [".env", ".env.local", ".env.production"]
                extensions: ["env"]

 OLD gen script:
   ✅ Read extensions: ["env"]           → declared UTI for "env"
   ❌ Ignored filenames completely!       → NO UTI for "local" or "production"

 What happened:
   .env        → pathExtension "env"        → UTI exists     → ✅ routed to us
   .env.local  → pathExtension "local"      → UTI missing    → dyn.* → ❌ white doc
   .env.prod   → pathExtension "production" → UTI missing    → dyn.* → ❌ white doc

 FIX: Gen script now extracts TAIL EXTENSIONS from filenames:
   ".env.local"      → implied extension "local"      → declare UTI
   ".env.production" → implied extension "production"  → declare UTI
   ".gitignore"      → implied extension "gitignore"   → declare UTI
```

**The fundamental lesson**: macOS only sees `pathExtension` (the last dot segment). Our JSON registry knows about full filenames, but macOS doesn't. We need UTIs for every possible **tail extension** that macOS might encounter.

---

## Quick Reference Card

```
 LAYER                        WHERE                    WHAT IT DOES
 ─────────────────────────────────────────────────────────────────────
 DefaultFileTypes.json        Shared framework         Maps ext → language
                                                       (OUR code only)

 UTExportedTypeDeclarations   Host app Info.plist      Tells macOS:
                                                       "ext X = UTI Y"

 QLSupportedContentTypes      Extension Info.plist     Tells macOS:
                                                       "route UTI Y to me"

 project.yml                  XcodeGen input           Source of truth for
                                                       both plists above

 LaunchServices DB            macOS system             Runtime lookup table
                                                       (populated by lsregister)

 dotviewer-gen-utis.py        Dev script               Generates the YAML
                                                       from JSON registry
```

The reason it feels like so many layers is because it **is** too many layers. Apple designed UTIs in 2004 as a replacement for file type/creator codes from Classic Mac OS. The system assumes apps will only claim a handful of types. We're claiming 680 — which is... not what they envisioned.
