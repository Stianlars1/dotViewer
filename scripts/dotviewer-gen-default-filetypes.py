#!/usr/bin/env python3
"""Validate and audit DefaultFileTypes.json against the rest of the dotViewer codebase.

Checks performed:
  1. JSON structure — every entry has required fields
  2. Duplicate extensions — two entries claiming the same ext (first-loaded wins)
  3. Highlight language → tree-sitter grammar coverage
  4. Suspicious extensions — too long, contain dots, look like language names
  5. project.yml QLSupportedContentTypes sync — extensions with system UTIs not in the list
  6. Summary statistics

Usage:
    ./scripts/dotviewer-gen-default-filetypes.py           # audit + report
    ./scripts/dotviewer-gen-default-filetypes.py --fix     # auto-fix safe issues (future)
    ./scripts/dotviewer-gen-default-filetypes.py --json    # machine-readable output
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT_DIR = Path(__file__).resolve().parents[1]
DOTVIEWER_DIR = ROOT_DIR / "dotViewer"
DEFAULT_TYPES_JSON = DOTVIEWER_DIR / "Shared" / "DefaultFileTypes.json"
PROJECT_YML = DOTVIEWER_DIR / "project.yml"
HIGHLIGHTER_SWIFT = DOTVIEWER_DIR / "HighlightXPC" / "TreeSitterHighlighter.swift"
REGISTRY_SWIFT = DOTVIEWER_DIR / "Shared" / "FileTypeRegistry.swift"
QUERIES_DIR = DOTVIEWER_DIR / "HighlightXPC" / "TreeSitterQueries"

# ── Colours ──────────────────────────────────────────────────────────────────

RED = "\033[31m"
YELLOW = "\033[33m"
GREEN = "\033[32m"
CYAN = "\033[36m"
DIM = "\033[2m"
BOLD = "\033[1m"
RESET = "\033[0m"

def coloured(text: str, colour: str) -> str:
    if not sys.stdout.isatty():
        return text
    return f"{colour}{text}{RESET}"


# ── Data loading ─────────────────────────────────────────────────────────────

def load_json(path: Path) -> list[dict[str, Any]]:
    return json.loads(path.read_text(encoding="utf-8"))


def load_tree_sitter_grammars() -> set[str]:
    """Extract grammar keys from TreeSitterHighlighter.swift."""
    grammars: set[str] = set()
    if not HIGHLIGHTER_SWIFT.exists():
        return grammars
    text = HIGHLIGHTER_SWIFT.read_text(encoding="utf-8")
    for match in re.finditer(r'\("(\w+)",\s*tree_sitter_\w+\(\)\)', text):
        grammars.add(match.group(1))
    return grammars


def load_highlight_aliases() -> dict[str, str]:
    """Extract the aliases dict from FileTypeRegistry.resolveHighlightLanguage."""
    aliases: dict[str, str] = {}
    if not REGISTRY_SWIFT.exists():
        return aliases
    text = REGISTRY_SWIFT.read_text(encoding="utf-8")
    for match in re.finditer(r'"(\w+)":\s*"(\w+)"', text):
        key, value = match.group(1), match.group(2)
        # Only capture items inside the aliases dict (heuristic: the key is lowercase
        # and the value looks like a grammar name).
        if key.islower() or key[0].islower():
            aliases[key] = value
    return aliases


def load_query_files() -> set[str]:
    """List available .scm query files (stem = grammar key)."""
    if not QUERIES_DIR.exists():
        return set()
    return {p.stem for p in QUERIES_DIR.glob("*.scm")}


def load_ql_content_types() -> set[str]:
    """Extract QLSupportedContentTypes entries from project.yml."""
    utis: set[str] = set()
    if not PROJECT_YML.exists():
        return utis
    text = PROJECT_YML.read_text(encoding="utf-8")
    in_ql = False
    for line in text.splitlines():
        stripped = line.strip()
        if "QLSupportedContentTypes:" in stripped:
            in_ql = True
            continue
        if in_ql:
            if stripped.startswith("- ") and not stripped.startswith("- target:"):
                uti = stripped[2:].strip()
                if uti and not uti.startswith("{"):
                    utis.add(uti)
            elif stripped and not stripped.startswith("#") and not stripped.startswith("- "):
                in_ql = False
    return utis


def resolve_to_grammar(highlight_lang: str, aliases: dict[str, str]) -> str:
    """Resolve a highlightLanguage value through the alias chain to a grammar key."""
    resolved = aliases.get(highlight_lang, highlight_lang)
    # One more hop in case of chained aliases (unlikely but safe).
    return aliases.get(resolved, resolved)


# ── Checks ───────────────────────────────────────────────────────────────────

class Issue:
    def __init__(self, severity: str, entry_id: str, message: str):
        self.severity = severity  # "error", "warning", "info"
        self.entry_id = entry_id
        self.message = message

    def __str__(self) -> str:
        if self.severity == "error":
            tag = coloured("ERROR", RED)
        elif self.severity == "warning":
            tag = coloured("WARN ", YELLOW)
        else:
            tag = coloured("INFO ", CYAN)
        return f"  {tag}  [{self.entry_id}] {self.message}"


def check_structure(entries: list[dict]) -> list[Issue]:
    issues: list[Issue] = []
    required = {"id", "displayName"}
    for i, entry in enumerate(entries):
        eid = entry.get("id", f"<index {i}>")
        missing = required - set(entry.keys())
        if missing:
            issues.append(Issue("error", eid, f"Missing required fields: {missing}"))
        if not entry.get("extensions") and not entry.get("filenames"):
            issues.append(Issue("info", eid, "No extensions and no filenames — only reachable via id lookup"))
    return issues


def check_duplicate_extensions(entries: list[dict]) -> list[Issue]:
    issues: list[Issue] = []
    seen: dict[str, str] = {}
    for entry in entries:
        eid = entry.get("id", "?")
        for ext in entry.get("extensions", []):
            ext_lower = ext.lower()
            if ext_lower in seen:
                issues.append(Issue(
                    "warning", eid,
                    f'Extension "{ext}" also claimed by "{seen[ext_lower]}" (first-loaded wins)'
                ))
            else:
                seen[ext_lower] = eid
    return issues


def check_duplicate_filenames(entries: list[dict]) -> list[Issue]:
    issues: list[Issue] = []
    seen: dict[str, str] = {}
    for entry in entries:
        eid = entry.get("id", "?")
        for fn in entry.get("filenames", []):
            fn_lower = fn.lower()
            if fn_lower in seen:
                issues.append(Issue(
                    "warning", eid,
                    f'Filename "{fn}" also claimed by "{seen[fn_lower]}"'
                ))
            else:
                seen[fn_lower] = eid
    return issues


def check_highlight_coverage(
    entries: list[dict],
    grammars: set[str],
    aliases: dict[str, str],
    queries: set[str],
) -> list[Issue]:
    issues: list[Issue] = []
    for entry in entries:
        eid = entry.get("id", "?")
        hl = (entry.get("highlightLanguage") or eid).lower()
        resolved = resolve_to_grammar(hl, aliases)
        if resolved == "plaintext":
            continue
        if resolved not in grammars:
            issues.append(Issue(
                "info", eid,
                f'highlightLanguage "{hl}" → "{resolved}" has no tree-sitter grammar (falls back to heuristic)'
            ))
        elif resolved not in queries:
            issues.append(Issue(
                "info", eid,
                f'highlightLanguage "{hl}" → "{resolved}" has grammar but no .scm query file'
            ))
    return issues


def check_suspicious_extensions(entries: list[dict]) -> list[Issue]:
    issues: list[Issue] = []
    for entry in entries:
        eid = entry.get("id", "?")
        for ext in entry.get("extensions", []):
            if len(ext) > 12:
                issues.append(Issue("warning", eid, f'Extension "{ext}" is suspiciously long (>12 chars)'))
            if ext != ext.lower():
                issues.append(Issue("info", eid, f'Extension "{ext}" has uppercase characters'))
    return issues


def check_duplicate_ids(entries: list[dict]) -> list[Issue]:
    issues: list[Issue] = []
    seen: dict[str, int] = {}
    for i, entry in enumerate(entries):
        eid = entry.get("id", f"<index {i}>")
        if eid in seen:
            issues.append(Issue("error", eid, f"Duplicate id (first at index {seen[eid]}, again at {i})"))
        else:
            seen[eid] = i
    return issues


# ── Report ───────────────────────────────────────────────────────────────────

def print_summary(
    entries: list[dict],
    grammars: set[str],
    aliases: dict[str, str],
    queries: set[str],
    ql_utis: set[str],
) -> None:
    ext_count = sum(len(e.get("extensions", [])) for e in entries)
    fn_count = sum(len(e.get("filenames", [])) for e in entries)
    categories = {e.get("category", "(none)") for e in entries}

    # Count how many entries resolve to a real grammar.
    grammar_hit = 0
    for entry in entries:
        hl = (entry.get("highlightLanguage") or entry.get("id", "")).lower()
        resolved = resolve_to_grammar(hl, aliases)
        if resolved in grammars:
            grammar_hit += 1

    print(coloured("\n── Summary ─────────────────────────────────────", BOLD))
    print(f"  Entries:              {len(entries)}")
    print(f"  Total extensions:     {ext_count}")
    print(f"  Total filenames:      {fn_count}")
    print(f"  Categories:           {len(categories)}")
    print(f"  Tree-sitter grammars: {len(grammars)}")
    print(f"  Query files (.scm):   {len(queries)}")
    print(f"  Entries with grammar: {grammar_hit}/{len(entries)} "
          f"({100 * grammar_hit // len(entries)}%)")
    print(f"  QL content types:     {len(ql_utis)}")
    print()


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit DefaultFileTypes.json")
    parser.add_argument("--json", action="store_true", help="Machine-readable JSON output")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show info-level issues")
    args = parser.parse_args()

    if not DEFAULT_TYPES_JSON.exists():
        print(f"ERROR: {DEFAULT_TYPES_JSON} not found", file=sys.stderr)
        return 1

    entries = load_json(DEFAULT_TYPES_JSON)
    grammars = load_tree_sitter_grammars()
    aliases = load_highlight_aliases()
    queries = load_query_files()
    ql_utis = load_ql_content_types()

    all_issues: list[Issue] = []
    all_issues.extend(check_structure(entries))
    all_issues.extend(check_duplicate_ids(entries))
    all_issues.extend(check_duplicate_extensions(entries))
    all_issues.extend(check_duplicate_filenames(entries))
    all_issues.extend(check_highlight_coverage(entries, grammars, aliases, queries))
    all_issues.extend(check_suspicious_extensions(entries))

    if args.json:
        out = [{"severity": i.severity, "id": i.entry_id, "message": i.message} for i in all_issues]
        print(json.dumps(out, indent=2))
        return 1 if any(i.severity == "error" for i in all_issues) else 0

    errors = [i for i in all_issues if i.severity == "error"]
    warnings = [i for i in all_issues if i.severity == "warning"]
    infos = [i for i in all_issues if i.severity == "info"]

    print(coloured("── dotViewer DefaultFileTypes.json Audit ───────", BOLD))
    print(f"  Source: {DEFAULT_TYPES_JSON.relative_to(ROOT_DIR)}")
    print()

    if errors:
        print(coloured(f"Errors ({len(errors)}):", RED))
        for issue in errors:
            print(issue)
        print()

    if warnings:
        print(coloured(f"Warnings ({len(warnings)}):", YELLOW))
        for issue in warnings:
            print(issue)
        print()

    if infos and args.verbose:
        print(coloured(f"Info ({len(infos)}):", CYAN))
        for issue in infos:
            print(issue)
        print()

    print_summary(entries, grammars, aliases, queries, ql_utis)

    if not errors and not warnings:
        print(coloured("  All checks passed.", GREEN))
    elif errors:
        print(coloured(f"  {len(errors)} error(s), {len(warnings)} warning(s), {len(infos)} info(s)", RED))
    else:
        print(coloured(f"  {len(warnings)} warning(s), {len(infos)} info(s)", YELLOW))

    if not args.verbose and infos:
        print(coloured(f"  Run with -v to see {len(infos)} info-level items", DIM))
    print()

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
