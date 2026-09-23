# dotViewer Site

[![Website](https://img.shields.io/badge/site-dotviewer.app-1762ff?style=for-the-badge)](https://dotviewer.app)
[![Download](https://img.shields.io/badge/download-latest%20DMG-0f172a?style=for-the-badge)](https://dotviewer.app/download)
[![GitHub release](https://img.shields.io/github/v/release/Stianlars1/dotViewer?style=for-the-badge)](https://github.com/Stianlars1/dotViewer/releases)
[![GitHub downloads](https://img.shields.io/github/downloads/Stianlars1/dotViewer/total?style=for-the-badge)](https://github.com/Stianlars1/dotViewer/releases)
[![macOS](https://img.shields.io/badge/macOS-15%2B-black?style=for-the-badge&logo=apple)](https://dotviewer.app/download)

Marketing site and install chooser for [dotViewer](https://dotviewer.app), the macOS Quick Look app for dotfiles, config files, markdown, CSV/TSV data, man pages, plain text documents, logs, executable scripts, source code, and user-selected preview fonts.

The site is intentionally product-led. It uses real app screenshots, links directly to the public install flow, and keeps the release history in sync with GitHub Releases.

Created by [Stian Larsen](https://stianlarsen.com). Also worth a look: [dbHost](https://dbhost.app), a free PostgreSQL database management app from the same creator.

## What This Site Covers

- The homepage positions dotViewer as the all-in-one Quick Look upgrade for technical files on macOS.
- The `/download` page acts as the stable public install chooser for the free direct DMG and the paid App Store route while the actual DMG changes release to release.
- The version history is fetched from GitHub Releases, so the website does not need a separate manual release archive.
- Structured data, sitemap, robots, metadata, and internal links are tuned around Finder preview search intent and install discovery.

## Why The Positioning Matters

The core product story is not just "preview code."

dotViewer is better positioned as:

- one install instead of separate markdown, code, and plain-text Quick Look plugins
- a Finder-native way to preview `.gitignore`, `.env`, `README.md`, JSON, YAML, XML, TSV, man pages, executable scripts, plist, logs, shell scripts, and other technical files
- a single settings surface for themes, font families, sizing, width, copy behavior, and file-type management
- a calmer alternative to opening VS Code, Xcode, Typora, or Terminal for every tiny file check

That is why the site copy repeatedly emphasizes:

- dotfiles
- config files
- markdown
- TSV and CSV data
- man pages
- executable scripts
- plain text documents
- logs
- source code

## Site Architecture

### Pages

- `/` - launch homepage with real product screenshots, install flow, feature proof, FAQ, and CTA
- `/download` - live download landing page with the public installer CTA, checksum link, and version history
- `/download/latest` - stable redirect to the newest DMG asset
- `/security` - crawlable trust page with signing, notarization, checksum, privacy, contact, and official-source details
- `/privacy` - what the app and the site collect (the app: nothing; the site: a cookieless log, cookies only with consent)
- `/stats` - owner-only download and visitor numbers behind HTTP Basic Auth (`proxy.ts`), `noindex`
- `/updates/<file>` - stable URL for update archives (`dotViewer-X.Y.Z.dmg`); logs Sparkle / Homebrew / direct and redirects to the GitHub asset
- `/api/cron/snapshots` - daily Vercel Cron job that snapshots GitHub's per-asset download counts and Homebrew's install counts

### Data Sources

- GitHub Releases API for DMG assets, checksums, tags, and release history
- Vercel Analytics for aggregated traffic and custom event reporting
- `dbHost` PostgreSQL storage for raw page-view and download events via Drizzle
- Local repo product stats for file type and grammar counts
- Static screenshot assets from `site/public/product`

### SEO / Search Signals

- descriptive metadata and canonical URLs
- `SoftwareApplication`, `Organization`, `WebSite`, `CollectionPage`, `AboutPage`, `BreadcrumbList`, and FAQ JSON-LD
- `sitemap.xml` including the homepage, `/download`, `/security`, and `/privacy`
- `robots.txt` with sitemap and host; `/api/` and `/stats` disallowed
- crawlable internal links that reinforce the `/download` page as the public install destination

## Analytics Stack

The site counts traffic and downloads without cookies, in three layers, and asks before using any
(design: `docs/plans/2026-09-23-consent-banner-design.md`):

- Vercel Web Analytics, mounted once in the root layout through `@vercel/analytics/next` (cookieless)
- A first-party PostgreSQL log written by `/api/analytics`, `/download/latest` and `/updates/<file>`
- Daily snapshots of GitHub's per-asset download totals and Homebrew's public install counts (`/api/cron/snapshots`)

The consent banner (`components/consent-banner.tsx`) offers two purposes. *dotViewer statistics* sets `dv_visitor`, a random ID the log stores as `visitor_id`; *Google Analytics* loads Google's script, which is never requested before consent. `/api/consent` sets `dv_consent` (the choice) and `dv_visitor`, and records each choice in `analytics_consents`. The server stores a visitor ID only when the request's own `dv_consent` allows it. Browsers sending Global Privacy Control are treated as a no.

What the first-party log stores per row: time, path, referrer host, UTM fields, country, browser and OS family, device class, `is_bot`, `is_internal` (deployment URLs and localhost), `day_visitor` (a hash of the IP address and user agent with a salt that is deleted after its UTC day; page views and website downloads only), `visitor_id` only with consent, and for downloads `source` (plain identifiers only, otherwise `other`), `channel`, `release_tag`, `asset_kind` and target URL. It stores no IP address, city or full user agent. The daily cron clears visitor IDs older than 13 months, consent records older than 2 years and old salts. Identifying values in rows from before 23 September 2026 were deleted with `scripts/backfill-analytics.ts --apply --scrub`.

Writes happen in `after()`, so neither a beacon nor a download redirect waits for the database.

Relevant implementation files:

- [site/components/site-analytics.tsx](components/site-analytics.tsx)
- [site/lib/analytics/client.ts](lib/analytics/client.ts)
- [site/lib/analytics/server.ts](lib/analytics/server.ts)
- [site/app/api/analytics/route.ts](app/api/analytics/route.ts)
- [site/app/download/latest/route.ts](app/download/latest/route.ts)
- [site/app/updates/[file]/route.ts](app/updates/[file]/route.ts)
- [site/lib/analytics/classify.ts](lib/analytics/classify.ts) and [payload.ts](lib/analytics/payload.ts) - what is kept, and validation
- [site/lib/stats/](lib/stats/) - snapshots, `/stats` queries and aggregation, secret checks
- [site/proxy.ts](proxy.ts) - Basic Auth for `/stats`
- [site/lib/db/schema.ts](lib/db/schema.ts)

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
npm test            # node --test on tests/*.test.ts, no extra dependencies
```

## Environment Variables

| Variable | Required | Purpose |
| --- | --- | --- |
| `NEXT_PUBLIC_SITE_URL` | Yes in deployment | Public canonical site URL, usually `https://dotviewer.app` |
| `GITHUB_REPO` | Optional override | GitHub repo used for release history and latest DMG resolution. Defaults to `Stianlars1/dotViewer`. |
| `NEXT_PUBLIC_GITHUB_REPO` | Optional override | Public repo slug fallback for client-visible config |
| `GITHUB_TOKEN` | Optional | Raises GitHub API rate limits for release fetches |
| `DIRECT_DOWNLOAD_URL` | Optional override | Forces the download CTA to a specific installer URL |
| `APP_STORE_URL` | Optional override | App Store URL used for the paid channel CTA |
| `NEXT_PUBLIC_APP_STORE_URL` | Optional public override | Client-visible fallback for the same App Store URL |
| `DATABASE_URL` | Required for first-party analytics persistence | PostgreSQL connection string used by Drizzle and the runtime analytics route |
| `NEXT_PUBLIC_GOOGLE_TAG_ID` | Optional | Google tag / GA measurement ID (`G-...` or `GT-...`) for client-side Google tracking |
| `NEXT_PUBLIC_GA_MEASUREMENT_ID` | Optional | GA4 measurement ID (`G-F0Q1EGB3EM` for dotviewer.app); inlined at build time, so a change needs a redeploy |
| `STATS_USER`, `STATS_PASSWORD` | Required for `/stats` | Basic Auth credentials; without both the page answers 503 |
| `CRON_SECRET` | Required for the snapshot cron | Vercel Cron sends it as `Authorization: Bearer …`; without it the route answers 503 |

Google Analytics needs one of the Google ID variables and then still loads only for visitors who allow it. Without an ID the banner leaves Google out.

## Database Bootstrap

A new, empty database can be created from the schema:

```bash
cd site
DATABASE_URL=postgresql://... npm run db:push
```

The live database was created that way and has no migration history, so changes to it are hand-written, reviewed SQL files in `db/sql/`, applied in order:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/sql/001-cookieless-analytics-and-snapshots.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/sql/002-consent-and-day-visitors.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/sql/003-drop-full-referrers-and-queries.sql
```

`003` is a one-off cleanup of rows logged before 23 September 2026 (full linking addresses, and the parts of page addresses after `?`); on a new database it changes nothing.

Never run `db:push --force` against production. The schema has:

- `analytics_page_views`, `analytics_downloads` - the first-party log
- `github_asset_snapshots` - GitHub's running download total per release asset, one row per day
- `homebrew_install_snapshots` - Homebrew's 30/90/365-day install counts for the cask, one row per day
- `analytics_daily_salts` - today's salt for the day codes (earlier days are deleted)
- `analytics_consents` - one row per consent choice, as proof of consent

Rows logged before the cookieless change are classified (and, only on request, stripped of identifiers) by:

```bash
node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --env-file=.env.local scripts/backfill-analytics.ts                    # dry run
node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --env-file=.env.local scripts/backfill-analytics.ts --apply            # classify
node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --env-file=.env.local scripts/backfill-analytics.ts --apply --scrub    # also remove identifiers (irreversible)
```

## Querying The Custom Analytics Data

`/stats` shows the usual numbers. For anything else:

Weekly DMG downloads from the snapshots:

```sql
with daily as (
  select snapshot_date, sum(download_count) as total
  from github_asset_snapshots
  where asset ilike '%.dmg'
  group by 1
), weekly as (
  select date_trunc('week', snapshot_date)::date as week, max(total) as total
  from daily
  group by 1
)
select week, total - lag(total) over (order by week) as downloads
from weekly
order by week desc;
```

Example page-view query:

```sql
select
  date_trunc('day', created_at) as day,
  path,
  count(*) filter (where not coalesce(is_bot, false)) as people,
  count(*) filter (where is_bot) as bots
from analytics_page_views
where not coalesce(is_internal, false)
group by 1, 2
order by 1 desc, 3 desc;
```

Example download query:

```sql
select
  date_trunc('day', created_at) as day,
  source,
  asset_kind,
  release_tag,
  count(*) as downloads
from analytics_downloads
group by 1, 2, 3, 4
order by 1 desc, 5 desc;
```

## Download Resolution Order

The site resolves the latest macOS installer in this order:

1. `DIRECT_DOWNLOAD_URL`
2. `GITHUB_REPO` or the built-in `Stianlars1/dotViewer` default via GitHub Releases
3. Vercel Git environment variables: `VERCEL_GIT_REPO_OWNER` and `VERCEL_GIT_REPO_SLUG`

Public install behavior:

- `/download` is the human-facing landing page with release-aware copy, the free direct DMG CTA, the paid App Store CTA, and version history
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
- Add `DATABASE_URL` to the production environment before relying on the first-party analytics tables at runtime
- Add `NEXT_PUBLIC_GOOGLE_TAG_ID` or `NEXT_PUBLIC_GA_MEASUREMENT_ID` if you want the Google tracking layer enabled in production

The repo includes [vercel.json](vercel.json) with `"framework": "nextjs"` so Vercel uses the correct framework even if the project was originally created from a CLI deployment.

## Files Worth Knowing

- [site/app/page.tsx](app/page.tsx) - homepage content and CTA structure
- [site/app/download/page.tsx](app/download/page.tsx) - download page and release history
- [site/app/security/page.tsx](app/security/page.tsx) - signing, notarization, checksum, privacy, and contact trust page
- [site/app/layout.tsx](app/layout.tsx) - site-wide metadata
- [site/lib/structured-data.ts](lib/structured-data.ts) - JSON-LD builders
- [site/lib/github-release.ts](lib/github-release.ts) - GitHub Releases fetch logic
- [site/app/sitemap.ts](app/sitemap.ts) - crawlable page list
- [site/app/robots.ts](app/robots.ts) - robots policy and sitemap reference

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
