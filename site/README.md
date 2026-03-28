# dotViewer Site

[![Website](https://img.shields.io/badge/site-dotviewer.app-1762ff?style=for-the-badge)](https://dotviewer.app)
[![Download](https://img.shields.io/badge/download-latest%20DMG-0f172a?style=for-the-badge)](https://dotviewer.app/download)
[![GitHub release](https://img.shields.io/github/v/release/Stianlars1/dotViewer?style=for-the-badge)](https://github.com/Stianlars1/dotViewer/releases)
[![GitHub downloads](https://img.shields.io/github/downloads/Stianlars1/dotViewer/total?style=for-the-badge)](https://github.com/Stianlars1/dotViewer/releases)
[![macOS](https://img.shields.io/badge/macOS-15%2B-black?style=for-the-badge&logo=apple)](https://dotviewer.app/download)

Marketing site and public download handoff for [dotViewer](https://dotviewer.app), the macOS Quick Look app for dotfiles, config files, markdown, plain text documents, logs, and source code.

The site is intentionally product-led. It uses real app screenshots, links directly to the public download flow, and keeps the release history in sync with GitHub Releases.

Created by [Stian Larsen](https://stianlarsen.com). Also worth a look: [dbHost](https://dbhost.app), a free PostgreSQL database management app from the same creator.

## What This Site Covers

- The homepage positions dotViewer as the all-in-one Quick Look upgrade for technical files on macOS.
- The `/download` page acts as the stable public install URL while the actual DMG changes release to release.
- The version history is fetched from GitHub Releases, so the website does not need a separate manual release archive.
- Structured data, sitemap, robots, metadata, and internal links are tuned around Finder preview search intent and direct download discovery.

## Why The Positioning Matters

The core product story is not just "preview code."

dotViewer is better positioned as:

- one install instead of separate markdown, code, and plain-text Quick Look plugins
- a Finder-native way to preview `.gitignore`, `.env`, `README.md`, JSON, YAML, XML, plist, logs, shell scripts, and other technical files
- a calmer alternative to opening VS Code, Xcode, Typora, or Terminal for every tiny file check

That is why the site copy repeatedly emphasizes:

- dotfiles
- config files
- markdown
- plain text documents
- logs
- source code

## Site Architecture

### Pages

- `/` - launch homepage with real product screenshots, install flow, feature proof, FAQ, and CTA
- `/download` - live download landing page with the public installer CTA, checksum link, and version history
- `/download/latest` - stable redirect to the newest DMG asset

### Data Sources

- GitHub Releases API for DMG assets, checksums, tags, and release history
- Local repo product stats for file type and grammar counts
- Static screenshot assets from `site/public/product`

### SEO / Search Signals

- descriptive metadata and canonical URLs
- `SoftwareApplication`, `Organization`, `WebSite`, `CollectionPage`, `BreadcrumbList`, and FAQ JSON-LD
- `sitemap.xml` including the homepage and `/download`
- `robots.txt` with sitemap and host
- crawlable internal links that reinforce the `/download` page as the public install destination

## Local Development

```bash
cd site
npm install
npm run dev
```

Other useful commands:

```bash
npm run typecheck
npm run build
```

## Environment Variables

| Variable | Required | Purpose |
| --- | --- | --- |
| `NEXT_PUBLIC_SITE_URL` | Yes in deployment | Public canonical site URL, usually `https://dotviewer.app` |
| `GITHUB_REPO` | Optional override | GitHub repo used for release history and latest DMG resolution. Defaults to `Stianlars1/dotViewer`. |
| `NEXT_PUBLIC_GITHUB_REPO` | Optional override | Public repo slug fallback for client-visible config |
| `GITHUB_TOKEN` | Optional | Raises GitHub API rate limits for release fetches |
| `DIRECT_DOWNLOAD_URL` | Optional override | Forces the download CTA to a specific installer URL |

## Download Resolution Order

The site resolves the latest macOS installer in this order:

1. `DIRECT_DOWNLOAD_URL`
2. `GITHUB_REPO` or the built-in `Stianlars1/dotViewer` default via GitHub Releases
3. Vercel Git environment variables: `VERCEL_GIT_REPO_OWNER` and `VERCEL_GIT_REPO_SLUG`

Public download behavior:

- `/download` is the human-facing landing page with release-aware copy and version history
- `/download/latest` is the stable machine-friendly redirect to the current installer

## Release Flow

The intended release flow is:

1. Build and notarize the macOS DMG
2. Upload the DMG and checksum to GitHub Releases
3. Let `/download` and `/download/latest` pick up the new release automatically

That keeps the website aligned with the release source of truth and avoids hand-editing download links on each release.

## Vercel Deployment

Recommended production target: [dotviewer.app](https://dotviewer.app)

Important details:

- The GitHub repo is `Stianlars1/dotViewer`
- The Vercel **Root Directory** should be `site`
- The Vercel **Production Branch** should be `main`
- The project should use the **Next.js** framework preset

The repo includes [vercel.json](/Users/stian/Developer/macOS%20Apps/v2.5/site/vercel.json) with `"framework": "nextjs"` so Vercel uses the correct framework even if the project was originally created from a CLI deployment.

## Files Worth Knowing

- [site/app/page.tsx](/Users/stian/Developer/macOS%20Apps/v2.5/site/app/page.tsx) - homepage content and CTA structure
- [site/app/download/page.tsx](/Users/stian/Developer/macOS%20Apps/v2.5/site/app/download/page.tsx) - download page and release history
- [site/app/layout.tsx](/Users/stian/Developer/macOS%20Apps/v2.5/site/app/layout.tsx) - site-wide metadata
- [site/lib/structured-data.ts](/Users/stian/Developer/macOS%20Apps/v2.5/site/lib/structured-data.ts) - JSON-LD builders
- [site/lib/github-release.ts](/Users/stian/Developer/macOS%20Apps/v2.5/site/lib/github-release.ts) - GitHub Releases fetch logic
- [site/app/sitemap.ts](/Users/stian/Developer/macOS%20Apps/v2.5/site/app/sitemap.ts) - crawlable page list
- [site/app/robots.ts](/Users/stian/Developer/macOS%20Apps/v2.5/site/app/robots.ts) - robots policy and sitemap reference

## Search Intent The Site Targets

The copy and schema are written to compete for queries around:

- preview dotfiles on macOS
- Quick Look markdown viewer
- preview config files in Finder
- preview `.gitignore`
- preview `.env` files
- Finder code preview
- preview plain text documents on macOS

This improves the odds that search traffic lands on the homepage for discovery and on `/download` for direct install intent.
