# Product Marketing Context

*Last updated: 2026-03-27*

This draft was inferred from the product codebase, launch site, app UI, release flow, and internal research notes. Update it as customer language and positioning become sharper.

## Product Overview
**One-liner:**
dotViewer is a native macOS Quick Look app that lets people preview dotfiles, config files, markdown, plain text documents, logs, and source code directly in Finder.

**What it does:**
dotViewer upgrades Finder Quick Look for technical text files that macOS handles poorly by default. It adds syntax-highlighted previews, rendered markdown, markdown RAW mode, copy controls, theme controls, file type management, and matching Finder thumbnails from one installable macOS app.

**Product category:**
macOS Quick Look extension, Finder preview app, markdown/code/config previewer.

**Product type:**
Native macOS app plus Quick Look extension suite.

**Business model:**
Dual-channel distribution. The direct website DMG is the free adoption path, distributed outside the App Store as a signed and notarized installer. A paid App Store listing is also live and should be treated as the convenience and support purchase path rather than hidden or contradicted by the site.

## Target Audience
**Target companies:**
Small teams, individual developers, consultants, indie makers, DevOps/SRE practitioners, security-minded power users, and technical Mac users who browse repositories and config-heavy folders in Finder.

**Decision-makers:**
Individual users first. In team settings, engineering leads, developer experience owners, and technical founders.

**Primary use case:**
Quickly inspect technical files in Finder without opening VS Code, Xcode, Typora, Terminal, or another editor.

**Jobs to be done:**
- Preview code and config files in Finder with syntax-aware formatting.
- Read markdown in either source or rendered form without leaving Quick Look.
- Inspect dotfiles, logs, and plain text documents with better defaults and less friction.

**Use cases:**
- Checking `.gitignore`, `.env`, `.editorconfig`, `.zshrc`, and other dotfiles.
- Inspecting `README.md`, `CHANGELOG.md`, and other markdown docs.
- Reading `package.json`, `docker-compose.yml`, XML, plist, JSON, INI, and log files.
- Verifying source files quickly during code review, repository cleanup, or search workflows.

## Personas
| Persona | Cares about | Challenge | Value we promise |
|---------|-------------|-----------|------------------|
| Developer | Speed, clarity, fewer app switches | Finder previews are weak or inconsistent for code and config | Instant, readable Quick Look for the files they open constantly |
| Power user | Better defaults and less friction | macOS can preview many files poorly or not at all | One install that improves daily file inspection |
| DevOps / SRE | Logs, configs, dotfiles, reliability | Needs to inspect text-heavy operational files fast | Broad file support, plain-text friendliness, and pragmatic controls |
| Technical founder | Shipping fast without workflow drag | Opening an editor for every tiny check wastes attention | A lightweight macOS-native utility that fits into existing Finder behavior |

## Problems & Pain Points
**Core problem:**
Finder Quick Look is not good enough for many technical files, especially code, config, markdown, logs, dotfiles, and odd but still text-based documents.

**Why alternatives fall short:**
- Some tools only handle markdown.
- Some only handle plain text.
- Some show code, but without strong customization or markdown rendering.
- Many workflows still push users back into editors just to inspect small files.
- Installing multiple Quick Look tools creates overlap, inconsistency, and maintenance friction.

**What it costs them:**
Lost time, broken flow, extra app switching, less trust in Finder previews, and more cognitive overhead for simple file inspection.

**Emotional tension:**
“Why do I need to open a full editor just to check this file?” The frustration is less about missing features in absolute terms and more about daily interruption.

## Competitive Landscape
**Direct:** QLMarkdown, QLStephen, SourceCodeSyntaxHighlight, and other Quick Look plugins that cover only one slice of the problem.

**Secondary:** VS Code, Xcode, Typora, BBEdit, Nova, Sublime Text, and Terminal tools like `cat`, `less`, and `bat`. These solve the job by opening a separate environment.

**Indirect:** Finder default previews, Quick Look for system-owned UTIs, and manual “open file and close it again” workflows.

**How competitors and alternatives fall short:**
- Separate plugins often mean separate tradeoffs for markdown, code, plain text, and configs.
- Editors are powerful but too heavy for quick inspection.
- Native Finder previews remain inconsistent across technical file types.

## Differentiation
**Key differentiators:**
- One install covers markdown, config files, logs, dotfiles, plain text, and source code.
- Real markdown RAW and rendered modes in the same Quick Look flow.
- Built-in themes, copy behavior, width, typography, markdown defaults, and file type controls.
- Broad out-of-the-box file type coverage plus custom mappings.
- Honest communication about macOS-owned preview paths and platform limits.

**How we do it differently:**
dotViewer combines a Quick Look extension, thumbnail extension, XPC highlighting pipeline, and companion settings app into one coherent product instead of a pile of unrelated utilities.

**Why that's better:**
Users get consistent previews, settings, and file-type behavior across more of the files they actually touch. It feels like a single product, not a workaround stack.

**Why customers choose us:**
Because dotViewer is the “all-in-one Quick Look upgrade” for technical files on macOS, not just a markdown viewer or a plain-text extension.

## Objections
| Objection | Response |
|-----------|----------|
| “Finder already has Quick Look.” | It does, but not with consistent previews for dotfiles, config files, markdown, logs, and many code formats. dotViewer improves the cases where Finder is weakest. |
| “I can just open VS Code.” | You can, but dotViewer is for the smaller checks that should stay small. It saves the editor launch for when you actually need to edit. |
| “Will it override every file type?” | No, and we say that clearly. Some macOS system-owned preview paths stay with Apple. dotViewer focuses on the large set of technical file cases where third-party extensions can help. |

**Anti-persona:**
People who only want a full editor workflow and do not care about Finder or Quick Look are not the primary fit.

## Switching Dynamics
**Push:**
Poor Finder previews, plugin sprawl, and opening editors too often for simple inspection.

**Pull:**
One polished app that previews the technical files they care about, with settings and better markdown handling built in.

**Habit:**
People are used to falling back to editors or Terminal because Quick Look has trained them not to trust it.

**Anxiety:**
Worry that it may be limited, brittle, or blocked by macOS routing for important file types.

## Customer Language
**How they describe the problem:**
- “I just want to preview this without opening an editor.”
- “Finder is terrible for config files.”
- “I want Quick Look for `.gitignore`, `.env`, and README files.”
- “I need markdown rendering and code preview in one place.”

**How they describe us:**
- “A better Quick Look for technical files.”
- “An all-in-one Finder previewer for code, config, and markdown.”
- “The Quick Look extension I wanted macOS to ship with.”

**Words to use:**
Quick Look, Finder preview, dotfiles, config files, markdown, source code, logs, plain text documents, one install, all-in-one, notarized DMG, macOS-native.

**Words to avoid:**
Magic, revolutionary, perfect replacement, overrides everything, no limitations.

**Glossary:**
| Term | Meaning |
|------|---------|
| Quick Look | Finder's spacebar preview system on macOS |
| Dotfiles | Hidden technical files such as `.gitignore`, `.env`, `.zshrc`, `.editorconfig` |
| RAW markdown | Markdown source view |
| Rendered markdown | Styled reading mode for markdown documents |
| Companion app | The installed dotViewer app used for settings, status, and file-type controls |

## Brand Voice
**Tone:**
Calm, technically credible, precise, polished.

**Style:**
Direct, confident, product-focused, with restrained marketing language.

**Personality:**
Native, useful, trustworthy, pragmatic, thoughtful.

## Proof Points
**Metrics:**
- 400 built-in file type definitions
- 582 registered extensions
- 295 filename mappings
- 53 tree-sitter query files
- Developer ID signed and notarized DMG distribution
- Public App Store listing live as an additional paid channel

**Customers:**
No public customer logos captured yet.

**Testimonials:**
No published testimonial library captured yet.

**Value themes:**
| Theme | Proof |
|-------|-------|
| Broad coverage | Hundreds of file types, extensions, and filename mappings |
| Better markdown | RAW + rendered markdown with optional TOC |
| Better daily workflow | Quick inspection without opening editors |
| All-in-one setup | One app instead of separate markdown, code, and text preview tools |
| Native credibility | Signed, notarized macOS install flow |

## Goals
**Business goal:**
Make `dotviewer.app` a credible public launch site that converts search and direct visitors into either direct DMG installs or App Store purchase intent.

**Conversion action:**
Choose an install path from `/download`: free direct DMG for low-friction adoption or paid App Store purchase for convenience and support.

**Current metrics:**
- GitHub DMG downloads: 17 total across public releases as of 2026-04-04 (`v1.1.0`: 5, `v1.0.0`: 12)
- GitHub repo baseline: 0 stars, 0 watchers, 0 forks as of 2026-04-04
- App Store listing is live, but no ratings or review overview are displayed yet
- Website analytics stack exists, but no formal Search Console baseline or published funnel report is captured yet
