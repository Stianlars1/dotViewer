#!/usr/bin/env python3
"""Generate DefaultFileTypes.json from SourceCodeSyntaxHighlight mappings.

This intentionally reuses the same language coverage as SourceCodeSyntaxHighlight
(GPLv3, compatible with dotViewer's GPLv3 license) while allowing us to append
our own dotfile mappings.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple

DEFAULT_SOURCE = Path("/Users/stian/Developer/macOS Apps/v2.5/research_extenisons/quicklook-research/SourceCodeSyntaxHighlight")

EXTRA_DOTFILES = [
    {
        "id": "gitignore",
        "displayName": "Git Ignore",
        "highlightLanguage": "bash",
        "category": "dotfiles",
        "filenames": [
            ".gitignore",
            ".gitexclude",
        ],
    },
    {
        "id": "gitconfig",
        "displayName": "Git Config",
        "highlightLanguage": "ini",
        "category": "dotfiles",
        "filenames": [
            ".gitconfig",
            ".gitattributes",
            ".gitmodules",
            ".mailmap",
            ".gitkeep",
            ".gitmessage",
        ],
    },
    {
        "id": "env",
        "displayName": "Environment",
        "highlightLanguage": "bash",
        "category": "dotfiles",
        "filenames": [
            ".env",
            ".env.local",
            ".env.development",
            ".env.production",
            ".env.staging",
            ".env.test",
            ".env.example",
        ],
    },
    {
        "id": "editorconfig",
        "displayName": "EditorConfig",
        "highlightLanguage": "ini",
        "category": "dotfiles",
        "filenames": [".editorconfig"],
    },
    {
        "id": "npmrc",
        "displayName": "Node Config",
        "highlightLanguage": "ini",
        "category": "dotfiles",
        "filenames": [
            ".npmrc",
            ".nvmrc",
            ".yarnrc",
            ".yarnrc.yml",
            ".pnpmfile.cjs",
        ],
    },
    {
        "id": "rcfile",
        "displayName": "Project RC Files",
        "highlightLanguage": "json",
        "category": "dotfiles",
        "filenames": [
            ".prettierrc",
            ".eslintrc",
            ".babelrc",
            ".stylelintrc",
            ".lintstagedrc",
            ".commitlintrc",
            ".npmignore",
        ],
    },
    {
        "id": "shellrc",
        "displayName": "Shell Config",
        "highlightLanguage": "bash",
        "category": "dotfiles",
        "filenames": [
            ".zshrc",
            ".zshenv",
            ".zprofile",
            ".bashrc",
            ".bash_profile",
            ".bash_logout",
            ".profile",
            ".zsh_history",
            ".zsh-theme",
            ".zsh-update",
            ".shellcheckrc",
            ".python_history",
            ".psql_history",
        ],
    },
    {
        "id": "vimrc",
        "displayName": "Vim Config",
        "highlightLanguage": "plaintext",
        "category": "dotfiles",
        "filenames": [
            ".vimrc",
            ".viminfo",
        ],
    },
    {
        "id": "dockerignore",
        "displayName": "Docker Ignore",
        "highlightLanguage": "plaintext",
        "category": "dotfiles",
        "filenames": [".dockerignore"],
    },
]

EXTRA_EXTENSION_MERGE = {
    "markdown": ["mdx", "mdtxt", "rmd", "qmd", "mkd", "mkdn", "mdown"],
    "json": ["jsonl", "ndjson", "jsonc"],
    "yaml": ["yml"],
    "ini": ["cfg", "conf", "properties", "prefs", "editorconfig"],
}


class ParseError(RuntimeError):
    pass


def find_filetypes_conf(root: Path) -> Path:
    candidates = [
        root / "XPCService" / "highlight" / "share2" / "filetypes.conf",
        root / "XPCService" / "highlight" / "share" / "filetypes.conf",
        root / "XPCService" / "share" / "filetypes.conf",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    for found in root.rglob("filetypes.conf"):
        return found
    raise ParseError("filetypes.conf not found under SourceCodeSyntaxHighlight")


def find_languages_json(root: Path) -> Path:
    candidates = [
        root / "SyntaxHighlightRenderXPC" / "languages.json",
        root / "SyntaxHighlightRenderXPC" / "Resources" / "languages.json",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise ParseError("languages.json not found under SourceCodeSyntaxHighlight")


def parse_filetypes_conf(path: Path) -> Dict[str, Dict[str, Set[str]]]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    match = re.search(r"^\s*FileMapping\s*=\s*\{", text, re.M)
    if not match:
        raise ParseError("FileMapping assignment not found in filetypes.conf")
    start = text.find("{", match.start())
    if start < 0:
        raise ParseError("Opening brace not found in filetypes.conf")

    entries: List[str] = []
    depth = 0
    entry_start = None

    for idx in range(start, len(text)):
        char = text[idx]
        if char == "{":
            depth += 1
            if depth == 2:
                entry_start = idx
        elif char == "}":
            if depth == 2 and entry_start is not None:
                entries.append(text[entry_start : idx + 1])
                entry_start = None
            depth -= 1
            if depth <= 0:
                break

    mapping: Dict[str, Dict[str, Set[str]]] = {}
    for entry in entries:
        lang_match = re.search(r"Lang\s*=\s*\"([^\"]+)\"", entry)
        if not lang_match:
            continue
        lang = lang_match.group(1)
        exts_match = re.search(r"Extensions\s*=\s*\{([^}]*)\}", entry, re.S)
        filenames_match = re.search(r"Filenames\s*=\s*\{([^}]*)\}", entry, re.S)

        exts = re.findall(r"\"([^\"]+)\"", exts_match.group(1)) if exts_match else []
        filenames = re.findall(r"\"([^\"]+)\"", filenames_match.group(1)) if filenames_match else []

        entry_data = mapping.setdefault(lang, {"extensions": set(), "filenames": set()})
        entry_data["extensions"].update(exts)
        entry_data["filenames"].update(filenames)

    return mapping


def parse_languages_json(path: Path) -> Tuple[Dict[str, str], Dict[str, Set[str]]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    display_by_lang: Dict[str, str] = {}
    extensions_by_lang: Dict[str, Set[str]] = {}
    for display_name, values in data.items():
        if not values:
            continue
        lang_id = values[0]
        extensions_by_lang.setdefault(lang_id, set()).update(values[1:])
        for index, value in enumerate(values):
            if value not in display_by_lang or index == 0:
                display_by_lang[value] = display_name
    return display_by_lang, extensions_by_lang


def normalize_values(values: Set[str]) -> List[str]:
    return sorted({value.strip().lower() for value in values if value.strip()})


def title_case_fallback(lang: str) -> str:
    return lang.replace("_", " ").replace("-", " ").title()


def build_default_types(
    mapping: Dict[str, Dict[str, Set[str]]],
    display_map: Dict[str, str],
    extension_map: Dict[str, Set[str]],
) -> List[dict]:
    items: List[dict] = []

    for lang, data in mapping.items():
        merged_extensions = set(data["extensions"])
        merged_extensions.update(extension_map.get(lang, set()))
        extensions = normalize_values(merged_extensions)
        if not extensions and lang.strip():
            extensions = [lang.lower()]
        filenames = normalize_values(data["filenames"])

        for extra in EXTRA_EXTENSION_MERGE.get(lang, []):
            if extra not in extensions:
                extensions.append(extra)

        display_name = display_map.get(lang, title_case_fallback(lang))

        items.append(
            {
                "id": lang,
                "displayName": display_name,
                "extensions": extensions,
                "filenames": filenames,
                "highlightLanguage": lang,
            }
        )

    # Add any languages that exist only in languages.json (no explicit mapping in filetypes.conf).
    for lang, extra_extensions in extension_map.items():
        if lang in mapping:
            continue
        extensions = normalize_values(extra_extensions)
        if not extensions and lang.strip():
            extensions = [lang.lower()]
        display_name = display_map.get(lang, title_case_fallback(lang))
        items.append(
            {
                "id": lang,
                "displayName": display_name,
                "extensions": extensions,
                "filenames": [],
                "highlightLanguage": lang,
            }
        )

    items.extend(EXTRA_DOTFILES)

    return items


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate DefaultFileTypes.json")
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help="Path to SourceCodeSyntaxHighlight repo",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "dotViewer" / "Shared" / "DefaultFileTypes.json",
        help="Output JSON path",
    )
    args = parser.parse_args()

    source = args.source
    filetypes_conf = find_filetypes_conf(source)
    languages_json = find_languages_json(source)

    mapping = parse_filetypes_conf(filetypes_conf)
    display_map, extension_map = parse_languages_json(languages_json)

    items = build_default_types(mapping, display_map, extension_map)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(items, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"Wrote {len(items)} entries to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
