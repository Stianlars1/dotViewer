#!/usr/bin/env python3
"""
dotviewer-gen-utis.py — Generate exhaustive UTI declarations for dotViewer.

Reads DefaultFileTypes.json and classifies each extension:
  1. System UTI (macOS built-in) → add to QLSupportedContentTypes
  2. Vendor UTI (third-party known) → add to QLSupportedContentTypes
  3. No UTI → export custom UTI (com.stianlars1.dotviewer.<ext>)

For category 3, we export a custom UTI that macOS registers via LaunchServices.
Once registered, files with that extension resolve to our UTI instead of dyn.*.

Usage:
  python3 scripts/dotviewer-gen-utis.py              # Summary (default)
  python3 scripts/dotviewer-gen-utis.py --apply       # Print YAML for project.yml
  python3 scripts/dotviewer-gen-utis.py --dry-run     # Detailed classification
"""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
DEFAULT_TYPES_JSON = ROOT_DIR / "dotViewer" / "Shared" / "DefaultFileTypes.json"

# ──────────────────────────────────────────────────────────────────────────────
# Known UTI map: extension → system/vendor UTI identifier
# ──────────────────────────────────────────────────────────────────────────────
KNOWN_UTIS = {
    # ── Apple system UTIs ────────────────────────────────────────────────────
    "c":        "public.c-source",
    "h":        "public.c-header",
    "cc":       "public.c-plus-plus-source",
    "cpp":      "public.c-plus-plus-source",
    "c++":      "public.c-plus-plus-source",
    "cxx":      "public.c-plus-plus-source",
    "hh":       "public.c-plus-plus-header",
    "hpp":      "public.c-plus-plus-header",
    "hxx":      "public.c-plus-plus-header",
    "m":        "public.objective-c-source",
    "mm":       "public.objective-c-plus-plus-source",
    "swift":    "public.swift-source",
    "java":     "com.sun.java-source",
    "py":       "public.python-script",
    "rb":       "public.ruby-script",
    "pl":       "public.perl-script",
    "pm":       "public.perl-script",
    "php":      "public.php-script",
    "php3":     "public.php-script",
    "php4":     "public.php-script",
    "js":       "com.netscape.javascript-source",
    "mjs":      "com.netscape.javascript-source",
    "sh":       "public.shell-script",
    "bash":     "public.bash-script",
    "zsh":      "public.zsh-script",
    "ksh":      "public.ksh-script",
    "csh":      "public.csh-script",
    "tcsh":     "public.tcsh-script",
    "s":        "public.assembly-source",
    "pas":      "public.pascal-source",
    "f":        "public.fortran-source",
    "for":      "public.fortran-source",
    "f90":      "public.fortran-90-source",
    "f95":      "public.fortran-95-source",
    "mak":      "public.make-source",
    "mk":       "public.make-source",
    "y":        "public.yacc-source",
    "txt":      "public.plain-text",
    "text":     "public.plain-text",
    "html":     "public.html",
    "htm":      "public.html",
    "xhtml":    "public.xhtml",
    "css":      "public.css",
    "csv":      "public.comma-separated-values-text",
    "json":     "public.json",
    "xml":      "public.xml",
    "yaml":     "public.yaml",
    "yml":      "public.yaml",
    "svg":      "public.svg-image",
    "log":      "com.apple.log",
    "md":       "net.daringfireball.markdown",
    "markdown": "net.daringfireball.markdown",
    "plist":    "com.apple.property-list",
    "toml":     "public.toml",
    "patch":    "public.patch-file",
    "diff":     "public.patch-file",
    "scpt":     "com.apple.applescript.script",
    "adb":      "public.ada-source",
    "ads":      "public.ada-source",
    "i":        "public.c-source.preprocessed",
    "inl":      "public.c-plus-plus-inline-header",
    "ipp":      "public.c-plus-plus-header",

    # ── Vendor UTIs ──────────────────────────────────────────────────────────
    "ts":       "com.microsoft.typescript",
    "go":       "org.golang.go-script",
    "rs":       "org.rust-lang.rust-script",
    "cs":       "com.microsoft.c-sharp",
    "kt":       "org.kotlinlang.source",
    "kts":      "org.kotlinlang.source",
    "scala":    "org.scala-lang.scala-source",
    "d":        "org.dlang.d-source",
    "hs":       "org.haskell.haskell-script",
    "lua":      "org.lua.lua-source",
    "jl":       "org.julialang.julia",
    "sql":      "org.iso.sql",
    "dart":     "org.dartlang.dart",
    "clj":      "org.clojure",
    "cljc":     "org.clojure",
    "cljs":     "org.clojure",
    "tex":      "org.tug",
    "org":      "org.orgmode",
    "adoc":     "org.asciidoc",
    "asciidoc": "org.asciidoc",
    "rst":      "org.python.restructuredtext",
    "r":        "org.r-project.r",
    "conf":     "com.coteditor.conf",
    "v":        "com.coteditor.verilog",
    "svelte":   "dev.svelte",
    "fish":     "com.fishshell.script",
    "ini":      "com.microsoft.ini",
    "ps":       "com.adobe.postscript",
    "lsp":      "com.coteditor.lisp",
    "scm":      "com.coteditor.scheme",
    "ss":       "com.coteditor.scheme",
    "vhd":      "com.coteditor.vhdl",
    "awk":      "com.coteditor.awk",
    "bib":      "org.bibtex",
    "rss":      "public.rss",
    "mojo":     "com.coteditor.mojo",
    "textile":  "com.textpattern.textile",

    # ── Third-party UTIs that claim extensions we also want ─────────────────
    # These must be in QLSupportedContentTypes even though we also export our own
    # (macOS may resolve to the third-party UTI if the app is installed)

    # ── Our existing custom UTIs ─────────────────────────────────────────────
    "cts":      "com.stianlars1.dotviewer.typescript",
    "env":      "com.stianlars1.dotviewer.env",
    "bat":      "com.stianlars1.dotviewer.batch",
    "jsx":      "com.stianlars1.dotviewer.jsx",
    "fs":       "com.stianlars1.dotviewer.fsharp",
    "vb":       "com.stianlars1.dotviewer.vb",
}

# Extensions whose system UTI is for a DIFFERENT file type
UTI_CONFLICTS = {
    "abc",       # public.alembic (3D), we want ABC notation
    "as",        # com.apple.applesingle-archive, we want ActionScript
    "class",     # com.sun.java-class (binary), we want Gambas
    "dot",       # com.microsoft.word.dot, we want Graphviz
    "edn",       # com.adobe.edn, we want Clojure EDN
    "exp",       # com.apple.symbol-export, we want Express
    "hdr",       # public.radiance (image), we want XML header
    "mts",       # public.avchd-mpeg-2-transport-stream, we want TypeScript
    "cl",        # public.opencl-source, we want Lisp
    "clp",       # com.apple.clips-source, we want Clips
    "eml",       # com.apple.mail.email, we want email-as-text
    "applescript", # com.apple.applescript.text, we want text
    "jnlp",     # com.sun.java-web-start, we want XML
}

# Base QLSupportedContentTypes — always included
BASE_CONTENT_TYPES = {
    "public.data",
    "public.mpeg-2-transport-stream",
    "public.plain-text",
    "public.text",
    "public.source-code",
    "public.script",
    "public.shell-script",
    "public.bash-script",
    "public.zsh-script",
    "public.ksh-script",
    "public.csh-script",
    "public.tcsh-script",
    "public.python-script",
    "public.ruby-script",
    "public.perl-script",
    "public.php-script",
    "public.swift-source",
    "com.netscape.javascript-source",
    "com.microsoft.typescript",
    "com.sun.java-source",
    "com.microsoft.c-sharp",
    "org.golang.go-script",
    "org.rust-lang.rust-script",
    "org.kotlinlang.source",
    "org.scala-lang.scala-source",
    "org.dlang.d-source",
    "org.haskell.haskell-script",
    "org.lua.lua-source",
    "org.julialang.julia",
    "org.iso.sql",
    "public.c-source",
    "public.c-header",
    "public.c-plus-plus-source",
    "public.c-plus-plus-header",
    "public.objective-c-source",
    "public.objective-c-plus-plus-source",
    "public.assembly-source",
    "public.make-source",
    "public.protobuf-source",
    "net.daringfireball.markdown",
    "net.ia.markdown",
    "org.asciidoc",
    "org.python.restructuredtext",
    "org.tug.tex",
    "org.orgmode",
    "com.textpattern.textile",
    "org.clojure",
    "public.json",
    "public.xml",
    "public.yaml",
    "public.toml",
    "com.apple.property-list",
    "com.microsoft.ini",
    "com.coteditor.conf",
    "com.coteditor.verilog",
    "com.apple.log",
    "com.apple.rez-source",
    "public.html",
    "public.xhtml",
    "public.css",
    "public.svg-image",
    "public.comma-separated-values-text",
    "public.tab-separated-values-text",
    "dev.svelte",
    "public.handlebars",
    "public.mustache",
    "com.fishshell.script",
    "org.dartlang.dart",
    "public.patch-file",
    "org.lua",
    "public.pascal-source",
    "com.apple.applescript.script",
    "org.r-project.r",
    # Third-party UTIs that may claim our extensions
    "org.khronos.glsl.fragment-shader",
    "com.coteditor.mojo",
    # UTI_CONFLICTS: system UTIs for extensions we override with custom exports
    # We still need these in QL list so macOS routes the system UTI to us too
    "public.alembic",                          # .abc (we want ABC notation)
    "com.apple.applescript.text",              # .applescript
    "com.apple.applesingle-archive",           # .as (we want ActionScript)
    "public.opencl-source",                    # .cl (we want Lisp)
    "com.sun.java-class",                      # .class (we want Gambas)
    "com.apple.clips-source",                  # .clp (we want Clips)
    "com.microsoft.word.dot",                  # .dot (we want Graphviz)
    "com.adobe.edn",                           # .edn (we want Clojure EDN)
    "com.apple.mail.email",                    # .eml (we want email-as-text)
    "com.apple.symbol-export",                 # .exp (we want Express)
    "public.radiance",                         # .hdr (we want XML header)
    "com.sun.java-web-start",                  # .jnlp (we want XML)
    "public.avchd-mpeg-2-transport-stream",    # .mts (we want TypeScript)
    "cz.wz.zuggy.subrip",                     # .srt (subtitle)
    "org.tug",                                 # .tex (resolves to org.tug, not org.tug.tex)
    # Our existing custom exports
    "com.stianlars1.dotviewer.typescript",
    "com.stianlars1.dotviewer.env",
    "com.stianlars1.dotviewer.batch",
    "com.stianlars1.dotviewer.jsx",
    "com.stianlars1.dotviewer.fsharp",
    "com.stianlars1.dotviewer.vb",
}


def get_conformance(lang):
    """Return UTTypeConformsTo list for a highlight language."""
    source = {
        "c", "cmake", "csharp", "d", "dart", "elixir", "erlang", "fsharp",
        "go", "haskell", "java", "javascript", "julia", "kotlin", "lua",
        "nim", "nix", "objc", "ocaml", "pascal", "perl", "php", "python",
        "r", "ruby", "rust", "scala", "swift", "typescript", "tsx", "jsx",
        "vb", "zig", "crystal", "coffeescript", "clojure", "hcl", "graphviz",
        "solidity", "gdscript", "gleam", "vue", "wat", "qml", "purs",
        "fortran77", "fortran90", "delphi", "ada", "verilog", "vhd",
        "smalltalk", "eiffel", "pro", "lisp",
    }
    script = {"sh", "bash", "bat", "powershell", "fish", "awk", "tcl"}

    if lang in source:
        return ["public.source-code", "public.plain-text"]
    elif lang in script:
        return ["public.script", "public.plain-text"]
    else:
        return ["public.plain-text"]


def load_extensions():
    """Load all unique extensions from DefaultFileTypes.json.

    Pass 1: Read `extensions` arrays (skip compound like 'config.ru').
    Pass 2: Read `filenames` arrays and extract implied tail extensions
            (e.g. .env.local → 'local', .gitignore → 'gitignore').
    """
    data = json.loads(DEFAULT_TYPES_JSON.read_text(encoding="utf-8"))
    extensions = {}

    # Pass 1: explicit extensions arrays
    for entry in data:
        lang = entry.get("highlightLanguage", entry.get("id", ""))
        display = entry.get("displayName", "")
        for ext in entry.get("extensions", []):
            ext_lower = ext.lower()
            if "." in ext:
                continue  # Skip compound extensions like config.ru
            if ext_lower not in extensions:
                extensions[ext_lower] = {"lang": lang, "display": display}

    # Pass 2: filenames arrays → implied tail extensions
    for entry in data:
        lang = entry.get("highlightLanguage", entry.get("id", ""))
        display = entry.get("displayName", "")
        for fn in entry.get("filenames", []):
            fn_stripped = fn.lstrip(".").lower()
            if not fn_stripped:
                continue
            if "." in fn_stripped:
                # Compound: .env.local → tail ext 'local'
                implied = fn_stripped.rsplit(".", 1)[1]
            elif fn.startswith("."):
                # Single-segment dotfile: .gitignore → ext 'gitignore'
                implied = fn_stripped
            else:
                # Extensionless: Makefile, LICENSE → skip (pathExtension is "")
                continue
            if implied and implied not in extensions:
                extensions[implied] = {"lang": lang, "display": display}

    return extensions


def resolve_utis_via_swift(extensions):
    """Use Swift to resolve each extension to its macOS UTI."""
    ext_list = sorted(extensions.keys())

    swift_code = """\
import Foundation
import UniformTypeIdentifiers

let exts = CommandLine.arguments.dropFirst()
for ext in exts {
    if let type = UTType(filenameExtension: String(ext)) {
        print("\\(ext)\\t\\(type.identifier)")
    } else {
        print("\\(ext)\\tUNKNOWN")
    }
}
"""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".swift", delete=False) as f:
        f.write(swift_code)
        swift_path = f.name

    try:
        result = subprocess.run(
            ["swift", swift_path] + ext_list,
            capture_output=True, text=True, timeout=120
        )
        if result.returncode != 0:
            print(f"Swift resolution failed: {result.stderr}", file=sys.stderr)
            return {}

        resolved = {}
        for line in result.stdout.strip().split("\n"):
            if "\t" in line:
                ext, uti = line.split("\t", 1)
                resolved[ext] = uti
        return resolved
    finally:
        Path(swift_path).unlink(missing_ok=True)


def classify_extensions(extensions, resolved_utis):
    """Classify extensions into categories."""
    system = {}
    vendor = {}
    already_custom = {}
    needs_export = {}  # ext → {lang, display}

    for ext, info in sorted(extensions.items()):
        if ext in UTI_CONFLICTS:
            needs_export[ext] = info
            continue

        if ext in KNOWN_UTIS:
            uti = KNOWN_UTIS[ext]
            if uti.startswith("com.stianlars1."):
                already_custom[ext] = uti
            elif uti.startswith("public.") or uti.startswith("com.apple."):
                system[ext] = uti
            else:
                vendor[ext] = uti
            continue

        resolved = resolved_utis.get(ext, "UNKNOWN")
        if resolved.startswith("dyn.") or resolved == "UNKNOWN":
            needs_export[ext] = info
        elif resolved.startswith("com.stianlars1.dotviewer."):
            # Our own previously-exported UTI — still needs export declaration
            needs_export[ext] = info
        elif resolved.startswith("public.") or resolved.startswith("com.apple."):
            system[ext] = resolved
        else:
            vendor[ext] = resolved

    return system, vendor, already_custom, needs_export


def make_uti_name(ext):
    """Convert extension to safe UTI component name."""
    return ext.replace("+", "plus").replace("#", "sharp").replace("-", "_")


def main():
    mode = "summary"
    if "--apply" in sys.argv:
        mode = "apply"
    elif "--dry-run" in sys.argv:
        mode = "dry-run"

    print("=" * 70)
    print("dotViewer UTI Coverage Generator")
    print("=" * 70)

    extensions = load_extensions()
    print(f"\nLoaded {len(extensions)} unique extensions from DefaultFileTypes.json")

    print("Resolving UTIs via macOS UTType API...")
    resolved_utis = resolve_utis_via_swift(extensions)
    print(f"Resolved {len(resolved_utis)} extensions")

    system, vendor, already_custom, needs_export = classify_extensions(
        extensions, resolved_utis
    )

    print(f"\n── Classification ──────────────────────────────────────")
    print(f"  System UTIs (macOS built-in):    {len(system)}")
    print(f"  Vendor UTIs (third-party):       {len(vendor)}")
    print(f"  Already exported (our custom):   {len(already_custom)}")
    print(f"  Needs new export:                {len(needs_export)}")
    total = len(system) + len(vendor) + len(already_custom) + len(needs_export)
    print(f"  Total:                           {total}")

    # Build exports for ALL extensions needing them (including "already custom"
    # entries that are in KNOWN_UTIS with our prefix but may be missing from
    # UTExportedTypeDeclarations in project.yml)
    new_exports = []
    for ext, info in sorted(needs_export.items()):
        uti_name = make_uti_name(ext)
        new_exports.append({
            "ext": ext,
            "identifier": f"com.stianlars1.dotviewer.{uti_name}",
            "description": info["display"],
            "conforms_to": get_conformance(info["lang"]),
        })
    for ext, uti in sorted(already_custom.items()):
        info = extensions.get(ext, {"lang": "", "display": ext})
        new_exports.append({
            "ext": ext,
            "identifier": uti,
            "description": info["display"],
            "conforms_to": get_conformance(info["lang"]),
        })
    new_exports.sort(key=lambda e: e["ext"])

    # Build complete QLSupportedContentTypes
    all_utis = set(BASE_CONTENT_TYPES)
    for uti in system.values():
        all_utis.add(uti)
    for uti in vendor.values():
        all_utis.add(uti)
    for exp in new_exports:
        all_utis.add(exp["identifier"])

    print(f"\n── Output ──────────────────────────────────────────────")
    print(f"  New UTExportedTypeDeclarations:   {len(new_exports)}")
    print(f"  Total QLSupportedContentTypes:    {len(all_utis)}")
    print(f"  (was ~78, sbarex has ~383)")

    if mode == "dry-run":
        print(f"\n── New exports ────────────────────────────────────────")
        for exp in new_exports:
            print(f"  .{exp['ext']:15s} → {exp['identifier']}")

        print(f"\n── Vendor UTIs (newly discovered) ─────────────────────")
        for ext, uti in sorted(vendor.items()):
            if uti not in BASE_CONTENT_TYPES:
                print(f"  .{ext:15s} → {uti}")

    elif mode == "apply":
        # ── UTExportedTypeDeclarations ───────────────────────────────────
        print(f"\n{'=' * 70}")
        print("# UTExportedTypeDeclarations — paste into dotViewer target")
        print(f"{'=' * 70}")
        for exp in new_exports:
            print(f"          - UTTypeIdentifier: {exp['identifier']}")
            print(f"            UTTypeDescription: {exp['description']}")
            print(f"            UTTypeConformsTo:")
            for c in exp["conforms_to"]:
                print(f"              - {c}")
            print(f"            UTTypeTagSpecification:")
            print(f"              public.filename-extension:")
            print(f"                - {exp['ext']}")

        # ── QLSupportedContentTypes ──────────────────────────────────────
        print(f"\n{'=' * 70}")
        print("# QLSupportedContentTypes — use for BOTH extensions")
        print(f"{'=' * 70}")

        known_prefixes = {"public.", "com.", "org.", "net.", "dev."}
        public_utis = sorted(u for u in all_utis if u.startswith("public."))
        com_utis = sorted(u for u in all_utis if u.startswith("com."))
        org_utis = sorted(u for u in all_utis if u.startswith("org."))
        net_utis = sorted(u for u in all_utis if u.startswith("net."))
        dev_utis = sorted(u for u in all_utis if u.startswith("dev."))
        other_utis = sorted(u for u in all_utis if not any(u.startswith(p) for p in known_prefixes))

        print("            QLSupportedContentTypes:")
        print("              # System UTIs")
        for u in public_utis:
            print(f"              - {u}")
        print("              # Vendor UTIs (com.*)")
        for u in com_utis:
            print(f"              - {u}")
        print("              # Vendor UTIs (org.*)")
        for u in org_utis:
            print(f"              - {u}")
        if net_utis:
            print("              # Vendor UTIs (net.*)")
            for u in net_utis:
                print(f"              - {u}")
        if dev_utis:
            print("              # Vendor UTIs (dev.*)")
            for u in dev_utis:
                print(f"              - {u}")
        if other_utis:
            print("              # Other vendor UTIs")
            for u in other_utis:
                print(f"              - {u}")

    print(f"\n{'=' * 70}")
    print("Done.")


if __name__ == "__main__":
    main()
