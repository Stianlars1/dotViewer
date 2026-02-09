# Quick Look Reference Library

Curated deep-dive knowledge base for building and maintaining Quick Look extensions on macOS. Compiled during dotViewer v2 research phase — includes full repo scans, architectural patterns, performance guidance, and feature-to-reference mappings.

## Contents

| Document | Description |
|----------|-------------|
| [00-Source-Index.md](00-Source-Index.md) | Every source repo with links to deep-dives |
| [01-Architecture-Patterns.md](01-Architecture-Patterns.md) | Common architecture patterns across 37 repos |
| [02-Performance-Sandboxing-Compatibility.md](02-Performance-Sandboxing-Compatibility.md) | Performance techniques, sandbox constraints, macOS compatibility |
| [03-Feature-Recipes.md](03-Feature-Recipes.md) | Feature → reference implementation mapping |
| [Repos/](Repos/) | Per-repo deep-dives (directory trees, key paths, architecture notes) |

## How to Use

1. **Start with the Source Index** — find repos relevant to your feature
2. **Check Feature Recipes** — look up the feature you need, jump to reference implementations
3. **Read Architecture & Performance docs** — understand common patterns and constraints
4. **Open a Repo Deep-Dive** — `Repos/<owner>-<repo>.md` has directory trees, key paths, and architecture notes

## Scope

- Focus: **text/code/markup/config/dotfiles** and **unknown-extension** text handling
- Media-only plugins excluded unless they contain transferable Quick Look architecture patterns

## Licensing

Many Quick Look plugins are GPL-licensed. Before copying code, always check the license. Prefer reusing ideas and patterns over direct code.
