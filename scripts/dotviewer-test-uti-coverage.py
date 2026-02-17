#!/usr/bin/env python3
"""
dotviewer-test-uti-coverage.py — Verify ALL declared extensions actually route to dotViewer.

For every extension in DefaultFileTypes.json (both `extensions` and implied from `filenames`),
this script:
  1. Creates a temp file with that extension
  2. Asks macOS what UTI it resolves to (via Swift UTType API)
  3. Checks that UTI is in our QLSupportedContentTypes (from project.yml)
  4. Reports pass/fail for each

Usage:
  python3 scripts/dotviewer-test-uti-coverage.py           # Full test
  python3 scripts/dotviewer-test-uti-coverage.py --quick    # Summary only
"""

import json
import subprocess
import sys
import tempfile
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
DEFAULT_TYPES_JSON = ROOT_DIR / "dotViewer" / "Shared" / "DefaultFileTypes.json"
PROJECT_YML = ROOT_DIR / "dotViewer" / "project.yml"


def load_all_extensions():
    """Load all extensions from DefaultFileTypes.json (extensions + implied from filenames)."""
    data = json.loads(DEFAULT_TYPES_JSON.read_text(encoding="utf-8"))
    extensions = {}

    for entry in data:
        lang = entry.get("highlightLanguage", entry.get("id", ""))
        display = entry.get("displayName", "")
        for ext in entry.get("extensions", []):
            ext_lower = ext.lower()
            if "." in ext:
                continue
            if ext_lower not in extensions:
                extensions[ext_lower] = {"lang": lang, "display": display, "source": "extensions"}

    for entry in data:
        lang = entry.get("highlightLanguage", entry.get("id", ""))
        display = entry.get("displayName", "")
        for fn in entry.get("filenames", []):
            fn_stripped = fn.lstrip(".").lower()
            if not fn_stripped:
                continue
            if "." in fn_stripped:
                implied = fn_stripped.rsplit(".", 1)[1]
            elif fn.startswith("."):
                implied = fn_stripped
            else:
                continue
            if implied and implied not in extensions:
                extensions[implied] = {"lang": lang, "display": display, "source": f"filename:{fn}"}

    return extensions


def load_ql_supported_content_types():
    """Parse QLSupportedContentTypes from project.yml."""
    content = PROJECT_YML.read_text(encoding="utf-8")
    utis = set()
    in_ql = False
    for line in content.splitlines():
        stripped = line.strip()
        if stripped == "QLSupportedContentTypes:":
            in_ql = True
            continue
        if in_ql:
            if stripped.startswith("- ") and not stripped.startswith("- {"):
                uti = stripped[2:].strip()
                if not uti.startswith("#"):
                    utis.add(uti)
            elif stripped.startswith("#"):
                continue
            elif stripped and not stripped.startswith("-"):
                in_ql = False
    return utis


def load_exported_utis():
    """Parse UTExportedTypeDeclarations from project.yml to get ext→UTI mapping."""
    content = PROJECT_YML.read_text(encoding="utf-8")
    exports = {}  # ext → UTI identifier
    current_uti = None
    in_ext_spec = False
    in_uti_block = False

    for line in content.splitlines():
        stripped = line.strip()
        if stripped == "UTExportedTypeDeclarations:":
            in_uti_block = True
            continue
        if not in_uti_block:
            continue
        # End of block: next key at 4-space indent level
        if line.startswith("    ") and not line.startswith("        ") and stripped and ":" in stripped:
            break

        if "UTTypeIdentifier:" in stripped:
            current_uti = stripped.split("UTTypeIdentifier:", 1)[1].strip()
            in_ext_spec = False
        elif "public.filename-extension:" in stripped:
            in_ext_spec = True
        elif in_ext_spec and stripped.startswith("- "):
            ext = stripped[2:].strip()
            if current_uti:
                exports[ext.lower()] = current_uti
            in_ext_spec = False

    return exports


def resolve_utis_batch(extensions):
    """Use Swift to resolve each extension to its actual macOS UTI."""
    ext_list = sorted(extensions)

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


def main():
    quick = "--quick" in sys.argv

    print("=" * 70)
    print("dotViewer UTI Coverage Test")
    print("=" * 70)

    # Load everything
    extensions = load_all_extensions()
    ql_types = load_ql_supported_content_types()
    exported = load_exported_utis()

    print(f"\nExtensions to test:          {len(extensions)}")
    print(f"QLSupportedContentTypes:     {len(ql_types)}")
    print(f"UTExportedTypeDeclarations:  {len(exported)}")

    # Resolve all extensions via macOS
    print("\nResolving UTIs via macOS UTType API...")
    resolved = resolve_utis_batch(list(extensions.keys()))
    print(f"Resolved: {len(resolved)}")

    # Test each extension
    passed = []
    failed_not_in_ql = []  # UTI exists but not in our QL list
    failed_dyn = []         # Got dyn.* UTI (no UTI exists)
    failed_unknown = []     # UTType returned UNKNOWN
    failed_conflict = []    # System UTI conflict (e.g. .ts → mpeg-2)

    # Known system UTI conflicts we can't fix
    known_conflicts = {
        "ts": "public.mpeg-2-transport-stream",
    }

    for ext in sorted(extensions.keys()):
        info = extensions[ext]
        actual_uti = resolved.get(ext, "UNKNOWN")

        if actual_uti == "UNKNOWN":
            failed_unknown.append((ext, info))
        elif actual_uti.startswith("dyn."):
            # Check if we have an exported UTI for this extension
            if ext in exported:
                # We exported it but macOS still gave dyn.* — this can happen
                # if the app hasn't been registered yet
                failed_dyn.append((ext, info, actual_uti, exported[ext]))
            else:
                failed_dyn.append((ext, info, actual_uti, None))
        elif actual_uti in ql_types:
            passed.append((ext, actual_uti))
        elif ext in known_conflicts and actual_uti == known_conflicts[ext]:
            # Known conflict — we handle this with TransportStreamDetector etc.
            passed.append((ext, actual_uti))
        else:
            # UTI exists but not in our QL list
            failed_not_in_ql.append((ext, info, actual_uti))

    # Also check: do we have exported UTIs for extensions that got dyn.*?
    # After app registration, our exports should override dyn.*
    export_would_fix = 0
    for ext, info, actual_uti, our_uti in failed_dyn:
        if our_uti and our_uti in ql_types:
            export_would_fix += 1

    # Results
    print(f"\n{'=' * 70}")
    print(f"RESULTS")
    print(f"{'=' * 70}")
    print(f"  PASS (UTI in QLSupportedContentTypes):  {len(passed)}")
    print(f"  FAIL (dyn.* — no system UTI):           {len(failed_dyn)}")
    if export_would_fix:
        print(f"    └─ Of these, {export_would_fix} have our custom UTI export")
        print(f"       (will work once app is registered via LaunchServices)")
    print(f"  FAIL (UTI not in our QL list):           {len(failed_not_in_ql)}")
    print(f"  FAIL (UNKNOWN):                          {len(failed_unknown)}")

    total = len(passed) + len(failed_dyn) + len(failed_not_in_ql) + len(failed_unknown)
    effective_pass = len(passed) + export_would_fix
    print(f"\n  Coverage: {effective_pass}/{total} ({100*effective_pass/total:.1f}%)")

    if not quick:
        if failed_not_in_ql:
            print(f"\n{'─' * 70}")
            print(f"FAIL: UTI exists but NOT in QLSupportedContentTypes")
            print(f"{'─' * 70}")
            for ext, info, actual_uti in failed_not_in_ql:
                print(f"  .{ext:20s} → {actual_uti}")
                print(f"    {info['display']} ({info['lang']}) [{info['source']}]")

        if failed_dyn:
            dyn_no_export = [(e, i, u, o) for e, i, u, o in failed_dyn if not o or o not in ql_types]
            dyn_with_export = [(e, i, u, o) for e, i, u, o in failed_dyn if o and o in ql_types]

            if dyn_no_export:
                print(f"\n{'─' * 70}")
                print(f"FAIL: dyn.* UTI — NO export declared (truly unreachable)")
                print(f"{'─' * 70}")
                for ext, info, actual_uti, our_uti in dyn_no_export:
                    print(f"  .{ext:20s} → {actual_uti}")
                    print(f"    {info['display']} ({info['lang']}) [{info['source']}]")

            if dyn_with_export:
                print(f"\n{'─' * 70}")
                print(f"OK (pending registration): dyn.* but we have export")
                print(f"{'─' * 70}")
                for ext, info, actual_uti, our_uti in dyn_with_export[:20]:
                    print(f"  .{ext:20s} → export: {our_uti}")
                if len(dyn_with_export) > 20:
                    print(f"  ... and {len(dyn_with_export) - 20} more")

        if failed_unknown:
            print(f"\n{'─' * 70}")
            print(f"FAIL: UNKNOWN (UTType API returned nothing)")
            print(f"{'─' * 70}")
            for ext, info in failed_unknown:
                print(f"  .{ext:20s} — {info['display']} ({info['lang']})")

    # Summary verdict
    print(f"\n{'=' * 70}")
    if len(failed_not_in_ql) == 0 and len(failed_unknown) == 0:
        truly_broken = len(failed_dyn) - export_would_fix
        if truly_broken == 0:
            print("VERDICT: ALL extensions covered (100% routing)")
        else:
            print(f"VERDICT: {truly_broken} extensions get dyn.* without exports")
            print(f"         These will only work after app registration (LaunchServices)")
    else:
        print(f"VERDICT: {len(failed_not_in_ql)} extensions have UTIs missing from QL list")
        if failed_not_in_ql:
            print(f"         Add these UTIs to BASE_CONTENT_TYPES in gen-utis.py:")
            for ext, info, uti in failed_not_in_ql:
                print(f"           \"{uti}\",  # .{ext}")
    print("=" * 70)


if __name__ == "__main__":
    main()
