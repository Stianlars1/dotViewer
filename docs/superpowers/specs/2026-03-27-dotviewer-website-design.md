# dotViewer Website Design

Date: 2026-03-27
Status: User-approved design, awaiting final spec review
Owner: Codex

## Summary

Build a polished marketing website for dotViewer at `dotViewer.app`.

The site should feel bright, restrained, premium, and clearly inspired by Apple's product-marketing discipline without becoming a visual copy of `apple.com`.

The launch version should be a balanced single-page marketing site:

- focused on one clear action: `Download for macOS`
- clear enough for developers and advanced Mac users
- framed around the solvable problem, not the identity of the audience
- designed to grow into a richer marketing site later without requiring a rewrite

## Problem

Finder and Quick Look do not handle many technical files well enough for fast inspection. People working with markdown, config files, logs, and source code often need to open an editor just to quickly inspect a file.

dotViewer solves that problem by providing a better Quick Look experience for files Finder handles poorly.

## Goals

- Launch a professional public website for dotViewer
- Drive direct downloads of the latest notarized macOS installer
- Explain the product in a way that works for both developers and advanced Mac users
- Communicate polish, macOS-native quality, and trust
- Leave room for deeper product storytelling later

## Non-Goals

- Do not build a large docs site in v1
- Do not build a blog, changelog browser, or account system in v1
- Do not add heavy marketing automation or complex analytics in v1
- Do not promise `free forever`
- Do not present the site as developer-only

## Audience

Primary audience:

- people who work with markdown, config files, logs, dotfiles, and code on macOS

Secondary audience:

- developers
- advanced Mac users
- technical operators and builders who frequently inspect project files from Finder

The copy should be understandable to non-programmer power users, but it should still feel technically credible to developers.

## Positioning

### Core framing

dotViewer is a better Quick Look experience for markdown, config, and code files that Finder does not handle well.

### Messaging strategy

The site should be:

- problem-first
- workflow-aware
- not scoped only to developers

Avoid leading with:

- "for developers"
- file-extension jargon in the hero
- implementation details such as XPC or tree-sitter in the first fold

Lead with:

- inability to preview these files well in Finder
- instant inspection without opening an editor
- macOS-native fit and polish

### Recommended hero message direction

Headline direction:

`Preview markdown, config, and code files Finder doesn't handle well.`

Supporting subhead direction:

`Inspect technical files instantly in Quick Look instead of opening an editor.`

CTA label:

`Download for macOS`

Secondary CTA:

`View releases` or `View on GitHub`

## Product Decisions Locked In

- Visual direction: `A / Pure Light`
- Site depth: `Balanced`
- Audience framing: both developers and advanced Mac users
- Messaging frame: problem-first plus workflow-first
- Availability language: free download now, without a forever promise
- Download source of truth: GitHub Releases
- Primary install artifact: notarized `.dmg`
- Primary domain: `dotViewer.app`

## Information Architecture

Single-page website with these sections:

1. Hero
2. Product proof
3. Feature grid
4. Coverage and limits
5. Install steps
6. FAQ
7. Footer

This should remain a single scrollable page in v1. It should not become a multi-page marketing site unless later growth justifies it.

## UX and Visual Direction

### Tone

- bright
- calm
- premium
- quiet confidence

### Apple-like traits to borrow

- strong hierarchy
- very clean spacing
- restrained copy
- careful use of gradients and light
- product-first presentation
- minimal chrome

### Traits to avoid

- direct imitation of Apple layouts
- oversized hype language
- purple-on-white generic SaaS look
- noisy cards and dashboard clichés
- dark-first branding as the default

### Visual system

- light background with soft atmospheric gradients
- precise typography with high contrast and strong whitespace
- glass-like or frosted accents used sparingly
- iconography and screenshots treated as premium objects, not decorations
- minimal but meaningful motion: staged reveal, gentle parallax or fade, polished hover states

### Brand expression

The site should use the light icon direction as the primary brand expression.

The icon should appear:

- in the nav
- in the hero or hero visual cluster
- optionally in one supporting product lockup

The site should not lean heavily into the dark violet icon direction for launch.

## Page Anatomy

### 1. Hero

Purpose:

- explain the problem
- explain the workflow benefit
- create trust
- give a direct download action

Contents:

- compact top nav with logo and 2 to 4 anchor links
- headline and subhead
- primary CTA: `Download for macOS`
- secondary CTA: `View releases`
- a single polished visual: either a Finder/Quick Look inspired product frame or a stylized preview mockup
- a short trust bar under the hero

Trust bar candidates:

- notarized macOS app
- Quick Look extension
- supports markdown, config, and code files

### 2. Product Proof

Purpose:

- quickly show what the app does before the user reads deeper

Recommended format:

- one short section directly below the hero
- either a product strip or 3 concise proof tiles

Proof themes:

- syntax-highlighted previews
- rendered markdown support
- better handling for technical files Finder misses

### 3. Feature Grid

Purpose:

- explain the product without overloading the hero

Recommended feature set:

- syntax-highlighted previews for code and config files
- markdown raw and rendered viewing
- Finder thumbnails and Quick Look previews
- settings and customization

Optional fifth feature if needed:

- custom file type coverage or sensitive file awareness

Each feature block should be compact and visual, not text-heavy.

### 4. Coverage and Limits

Purpose:

- show breadth
- build trust
- preempt confusion about macOS-owned file types

This section should be balanced and honest.

Recommended structure:

- a stats row
- a short note on platform limitations

Stats should be sourced from the repo at implementation time, not hardcoded from old notes. Candidate metrics:

- file types supported
- file extensions covered
- filename pattern coverage

Limitations should be framed as system constraints, not product failure. Examples:

- `.html` is handled by macOS's native Quick Look renderer
- `.ts` may be claimed by system video routing in some cases

This section should feel reassuring and transparent, not defensive.

### 5. Install Section

Purpose:

- reduce friction from download to use

Recommended 3-step flow:

1. Download the latest notarized DMG
2. Drag dotViewer into Applications
3. Launch once, then press Space on a supported file in Finder

Supporting notes:

- macOS version requirement
- notarization / Gatekeeper reassurance
- GitHub Releases as the download source

### 6. FAQ

Keep the FAQ short.

Recommended questions:

- What files is dotViewer for?
- Does it replace Finder's built-in Quick Look for every file type?
- Is the app signed and notarized?
- How do I install or update it?
- Why do some file types still open in Apple's preview?

### 7. Footer

Include:

- GitHub repository
- releases link
- changelog link if available
- support/contact link
- copyright / company label if needed

## Copy Direction

### Voice

- calm
- concise
- technical but readable
- premium without sounding inflated

### Do

- emphasize clarity and ease
- describe the file-viewing problem plainly
- keep sentences short
- use macOS/Finder/Quick Look language naturally

### Do not

- oversell with exaggerated superlatives
- write for developers only
- overload the page with implementation details
- use generic startup copy

## Technical Architecture

### Recommendation

Implement the site in the same repository as a dedicated website project.

Recommended structure:

- `site/` as an isolated frontend app

Recommended stack:

- Next.js deployed to Vercel

Reasoning:

- easiest path to a polished marketing site on a custom domain
- straightforward future expansion if docs, changelog pages, or release-aware routes are needed
- allows a small redirect endpoint for the latest release download without introducing a separate service

### Rendering Model

- static marketing page for the main content
- one lightweight dynamic redirect route for download resolution

### Download Architecture

The website should not hardcode a single versioned DMG URL in page copy.

Recommended behavior:

- `Download for macOS` points to a site-owned route such as `/download`
- `/download` resolves the latest GitHub Release asset and redirects to the correct DMG

Benefits:

- the homepage stays stable across releases
- the CTA always points to the latest version
- the direct asset source can change later without changing page copy

Fallback:

- if latest asset resolution fails, redirect to the GitHub Releases page

### Release Assumptions

The installer published on launch should be:

- Developer ID signed
- notarized
- stapled
- packaged as a DMG

This repo already contains release automation for archive, export, notarization, DMG creation, and optional GitHub release creation, so the website should integrate with that workflow rather than invent a second release path.

### Repo Strategy

Reuse the existing `dotViewer` GitHub repository.

Recommended repo transition:

- preserve old v1 state on a `v1-legacy` tag or branch
- make `main` represent the current dotViewer product
- publish releases from the current product state

The website can live in the same repo for launch to reduce overhead.

## Accessibility

Minimum bar for v1:

- strong text contrast
- keyboard-accessible nav and CTA controls
- reduced-motion support
- semantic headings and landmark structure
- readable install instructions without relying on visuals

## Performance

The site should feel fast and lightweight.

Targets:

- minimal client JavaScript for the landing page
- optimized imagery
- no heavy animation libraries unless clearly justified
- smooth scrolling and polished transitions without visual lag

## SEO and Metadata

Minimum v1 requirements:

- clear title and meta description
- Open Graph image
- favicon and app icon alignment
- canonical URL for `dotViewer.app`

Suggested title direction:

`dotViewer — Preview markdown, config, and code files in Quick Look`

## Metrics

Keep analytics minimal in v1.

Only track:

- download CTA clicks
- secondary GitHub/release link clicks

Do not block launch on analytics setup.

## Future Expansion

The chosen design should scale into these later additions without a redesign:

- dedicated features pages
- release notes or changelog pages
- install/help page
- documentation or compatibility matrix
- pricing if the product later changes monetization

## Risks

### 1. Overbuilding before release

Mitigation:

- keep v1 to one page
- avoid docs/blog complexity

### 2. Weak trust if download flow feels improvised

Mitigation:

- use notarized DMG
- clearly state install steps
- link to GitHub Releases and GitHub repo

### 3. Confusion around unsupported or system-owned file types

Mitigation:

- include a tasteful limitations note
- explain that some Quick Look behavior is controlled by macOS

### 4. Inconsistent stats

Mitigation:

- derive coverage metrics from the current repo at implementation time
- avoid manually maintained numbers in the marketing copy

## Implementation Shape

The eventual implementation should produce:

- one refined landing page
- one download redirect route
- one clean deployment target on `dotViewer.app`

No additional pages are required for launch unless a dedicated releases or install page becomes necessary.

## Acceptance Criteria

The design should be considered implemented correctly when:

- the website feels premium, calm, and Apple-adjacent without imitation
- the homepage clearly explains the problem and workflow benefit
- users can download the latest notarized macOS installer in one click
- install instructions are obvious and short
- the site communicates both breadth and honesty about platform limits
- the architecture allows future expansion without rebuilding the site from scratch
