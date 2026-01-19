---
phase: 03-performance
plan: 02
subsystem: uti
tags: [UTI, QuickLook, plist, FileTypeRegistry, syntax-highlighting]

# Dependency graph
requires:
  - phase: 03-01
    provides: FastSyntaxHighlighter for language-aware previewing
provides:
  - Comprehensive UTI declarations for 100+ file extensions
  - QuickLook extension support for all new UTIs
  - FileTypeRegistry mappings for highlight languages
affects: [app-store, future-uti-additions]

# Tech tracking
tech-stack:
  added: []
  patterns: [UTI grouping by category, highlight language mapping]

key-files:
  modified:
    - dotViewer/Info.plist
    - QuickLookPreview/Info.plist
    - Shared/FileTypeRegistry.swift

key-decisions:
  - "Group related extensions in single UTI declarations for maintainability"
  - "Use appropriate parent UTIs (public.plain-text, public.source-code, public.shell-script)"
  - "Map highlight languages to closest available (e.g., django for Jinja, dos for batch)"

patterns-established:
  - "UTI naming: com.stianlars1.dotviewer.{type-name}"
  - "FileTypeRegistry entries include isSystemUTI: false for custom types"

issues-created: []

# Metrics
duration: 3min
completed: 2026-01-19
---

# Phase 3 Plan 2: Comprehensive UTI Support Summary

**Added 100+ file extension UTI declarations organized by category with QuickLook support and FileTypeRegistry language mappings**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-19T06:46:31Z
- **Completed:** 2026-01-19T06:49:55Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added 45+ new UTI type declarations to main app Info.plist covering backup files, config files, logs, programming languages, templates, DevOps tools, and shell scripts
- Extended QuickLook extension to support all 52 new UTI identifiers
- Added 40+ new FileTypeRegistry entries with appropriate highlight language mappings

## Task Commits

Each task was committed atomically:

1. **Task 1: Add comprehensive UTI declarations to main app** - `92b036e` (feat)
2. **Task 2: Add UTIs to QuickLook extension's supported types** - `8402a18` (feat)
3. **Task 3: Update FileTypeRegistry with new built-in types** - `47b1fc3` (feat)

## Files Created/Modified

- `dotViewer/Info.plist` - Added 45+ new UTExportedTypeDeclarations covering:
  - Backup & temp files (bak, old, tmp, swp, etc.)
  - Config files (conf, cfg, rc, htaccess, etc.)
  - Log & data files (log, csv, tsv, dat)
  - Programming languages (Lua, R, Julia, Nim, Zig, V, D, Elixir, Erlang, Clojure, F#, Haskell, OCaml, Tcl, Assembly, C#, Scala)
  - Template languages (Nunjucks, Jinja, Twig, Handlebars, Pug, HAML, Liquid, EJS)
  - DevOps (Terraform, HashiCorp tools, Kubernetes)
  - Build tools (CMake, Gradle, Maven, Ruby tools, task runners)
  - Shell scripts (Fish, csh, tcsh, ksh, PowerShell, batch)
  - Web components (Astro, Less, Protocol Buffers, LaTeX)

- `QuickLookPreview/Info.plist` - Added 52 new UTI identifiers to QLSupportedContentTypes

- `Shared/FileTypeRegistry.swift` - Added 40+ new SupportedFileType entries with:
  - Appropriate categories (.dataFormats, .shellAndTerminal, .scripting, etc.)
  - Highlight language mappings (plaintext, bash, json, yaml, etc.)
  - isSystemUTI: false for all custom types

## Decisions Made

1. **Group related extensions in single UTI declarations** - Backup files (backup, bak, old, orig, tmp, temp, swp, swo) grouped together for cleaner Info.plist
2. **Use parent UTI inheritance** - Source code files conform to public.source-code + public.plain-text; shell scripts to public.shell-script
3. **Map to closest available highlight language** - Used django for Jinja templates, dos for batch files, x86asm for assembly

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- All 100+ file extensions now have proper UTI declarations
- QuickLook extension will preview all new file types
- FileTypeRegistry provides language mappings for syntax highlighting
- Ready for manual verification testing
- Phase 3 complete after this plan (2/2 plans done)

---
*Phase: 03-performance*
*Completed: 2026-01-19*
