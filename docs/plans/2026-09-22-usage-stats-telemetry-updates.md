# Download stats, usage telemetry and in-app updates — research and plan

- **Date:** 2026-09-22 · **Branch:** `feat/usage-stats-and-updates`
- **Status:** approved 2026-09-22. Phase 1 (site) implemented and tested locally on this branch, 2026-09-23 —
  **not applied to the database, not deployed** (see §10). Phases 2–3 not started.
- **Scope:** (1) one trustworthy download number per version/week, (2) privacy-respecting active-user
  telemetry, (3) update prompts and automatic updates.

## TL;DR

- **Today:** 418 DMG downloads on GitHub — ~31/week since August, more than 3× the May–July rate.
  Homebrew's public analytics: 55 fresh installs in a year, 18 in the last 30 days. Website log:
  218 download clicks, ~43 of them a person on a Mac. How many people *use* dotViewer is unknown:
  nothing in the app reports, and Homebrew users never need to open it.
- **Downloads:** GitHub counts are the only all-channel total. Snapshot them and Homebrew's counts
  daily into Postgres, attribute channels from the site log, show it all on a password-protected
  `/stats` page. Fix the logging on the way: client download events are lost without Google
  Analytics, referrers are useless, a 34-day outage went unnoticed, `source` is unvalidated.
- **Active users:** opt-in telemetry — Norwegian law (ekomloven § 3-15) requires consent for a
  stored install ID. The sandboxed extensions only count preview days into the App Group and stay
  offline; the host app sends them to a new route on your Vercel + Postgres. Anonymous per-version
  counts of Sparkle update checks cover everyone else.
- **Updates:** Sparkle 2.10. Feed on `dotviewer.app/appcast.xml`, serving a signed appcast attached
  to each GitHub release; the existing notarized DMG is the update; the EdDSA key lives only in your
  Keychain plus an offline backup; the app re-registers its Quick Look extensions after each update;
  the cask becomes `auto_updates true`. Sparkle beats a GitHub-API check because it installs updates
  itself.
- **Website privacy:** the `dv_vid`/`dv_sid` cookies need consent today. Drop them (no banner needed)
  and add a `/privacy` page.
- **Order:** Phase 1 site (no app release) → Phase 2 Sparkle in 1.6.0 → Phase 3 telemetry in 1.6.1,
  delivered by Sparkle.

## 1. Current numbers (checked 2026-09-22, read-only)

### 1.1 GitHub Releases — the authoritative total

418 DMG downloads across 13 releases (+20 `.sha256` downloads). "Days latest" = time until the next
release; the per-day rate is only meaningful for versions that were latest for days.

| Version | Published | Days latest | DMG downloads | Per day | Site redirects logged | …human Mac browsers |
|---|---|---:|---:|---:|---:|---:|
| 1.0.0 | 03-27 | 7.1 | 15 | 2.1 | 1 | 0 |
| 1.1.0 | 04-03 | 4.8 | 12 | 2.5 | 8 | 1 |
| 1.2.0 | 04-08 | 7.8 | 18 | 2.3 | 0 — logging down | – |
| 1.3.0 | 04-16 | 12.7 | 34 | 2.7 | 0 — logging down | – |
| 1.4.0 | 04-29 | 100.6 | 132 | 1.3 | 117 (from 05-08) | 18 |
| 1.5.0 | 08-07 | 2.5 | 13 | 5.1 | 4 | 2 |
| 1.5.1 | 08-10 | ~1 h | 2 | – | 1 | 0 |
| 1.5.2 | 08-10 | 29.5 | 97 | 3.3 | 60 | 14 |
| 1.5.3 | 09-08 | ~1.5 h | 8 | – | 3 | 0 |
| 1.5.4 | 09-08 | 5.3 | 39 | 7.3 | 13 | 5 |
| 1.5.5 | 09-14 | 8.5 | 46 | 5.4 | 8 | 3 |
| 1.5.6 | 09-22 | ~2 h | 2 | – | 2 | 0 |
| 1.5.7 | 09-22 | live | 0 | – | 1 (our curl) | 0 |
| **Total** | | | **418** | | **218** | **43** |

- **Trend:** ~31 downloads/week since 1.5.0 (207 in 46 days), up from ~9/week during 1.4.0 (May–Aug).
- **What a GitHub count is:** every hit on the asset's github.com URL, GET or HEAD (an independent
  experiment suggests repeats from one IP within ~10 minutes count once) — people, Homebrew installs
  *and upgrades*, bots and link previews that follow `/download/latest`, phones, and our own
  verification downloads. GitHub keeps only a running total per asset: no dates, no user agents.
  Weekly trends therefore need daily snapshots (§3).

### 1.2 Website first-party log (Postgres on dbhost.app)

Queried read-only (`BEGIN READ ONLY`, aggregates only, no IDs printed).

- `analytics_downloads`: 218 rows, 2026-04-03 → 2026-09-22 19:54 UTC. 217 are `/download/latest`
  redirects, 1 is a checksum click. **Logging works today** — the last row is the 1.5.7 verification curl.
- `analytics_page_views`: 794 rows, 606 distinct `dv_vid` cookies; ~40 views/week lately; `/` 666,
  `/download` 112, `/security` 14.
- Who clicks the download redirect: 43 Mac desktop browsers, 56 phones (49 iOS, 7 Android),
  67 bots/tools (Amazonbot, ClaudeBot, GPTBot, Googlebot, SEO crawlers, and 15 of our own curls),
  33 Windows/Linux, the rest generic. **Only ~20 % look like a person on a Mac.**
- Logged site redirects ÷ GitHub downloads: 1.4.0 ≈ 89 %, 1.5.2 ≈ 62 %, 1.5.4 ≈ 33 %, 1.5.5 ≈ 17 %
  (an upper bound — bots are logged even when they never fetch the DMG). Since September most
  downloads bypass the site: Homebrew upgrades, the GitHub release page, links in issue threads.
- Top countries of redirect clicks: US 79, CN 21, SG 19, DE 17, NO 15, FR 12.

### 1.3 Homebrew

- **Homebrew publishes analytics for public third-party taps**, dotViewer included
  ([formulae.brew.sh](https://formulae.brew.sh/api/analytics/cask-install/30d.json), verified today):
  `stianlars1/tap/dotviewer` — **18 installs in 30 days, 35 in 90, 55 in 365** (#2,330 of 9,183 casks
  over 30 days). A lower bound: users with analytics off are missing, and upgrades emit no event.
- Every Homebrew install and upgrade also lands in the GitHub count: brew sends a HEAD to the cask URL
  (GitHub counts it) and then fetches the CDN URL directly. Its user agent carries macOS version and
  architecture: `Homebrew/7.0.6 (Macintosh; arm64 Mac OS X 15.7) curl/…`.
- Tap repo traffic (47 clones / 33 unique in 14 days) is noise: only `brew tap` makes a full clone,
  `brew update` fetches are not counted, and scanners clone every public repo.
- Cask today: `auto_updates false`, livecheck `url :url` + `:github_latest`, and a `postflight` that
  registers both extensions (`pluginkit -e use`, `qlmanage -r`) — so a Homebrew user never has to open
  the app. Current Homebrew is 7.0.6; `verified:` is deprecated.

### 1.4 Vercel

- Project `stians-applications/dotviewer` (`prj_rjHe…`), Pro plan, root directory `site`.
- **Web Analytics: enabled** since 2026-03-29, has data (the numbers live in the dashboard; no query
  API was used). Speed Insights: created, no data. Crons: enabled, none defined. Functions: `iad1`, Fluid.
- Production env vars: `DATABASE_URL`, `GITHUB_REPO`, `NEXT_PUBLIC_SITE_URL`. GA variables unset
  (Google layer inactive, as expected). No `GITHUB_TOKEN`: the site calls the GitHub API
  unauthenticated from shared Vercel IPs (60 requests/hour/IP) with `cache: "no-store"`.

### 1.5 GitHub repository

10 stars. Last 14 days: 224 views / 31 unique visitors, 113 clones / 79 unique (mostly mirrors/bots).

## 2. Problems in the existing logging

1. **Client-side download events never reach Postgres** unless Google Analytics is loaded:
   `trackDownloadClick` returns at the `window.gtag` check before `sendAnalyticsEvent`
   ([client.ts:163](../../site/lib/analytics/client.ts)). Checksum and release-history clicks: 1 row, ever.
2. **Page-view referrers are always dotviewer.app.** The server stores the beacon's own `Referer`
   header ([server.ts:56](../../site/lib/analytics/server.ts)); the client sends `document.referrer`,
   but the route drops it. There is no traffic-source data in the DB.
3. **34-day silent hole** (2026-04-04 → 2026-05-08, both tables): failed inserts only `console.error`.
   1.2.0 and 1.3.0 have no site data. Nothing alerts.
4. **`source` is stored unvalidated.** A sqlmap scan on 2026-06-17 left 13 SQL-injection strings in
   `source` — harmless (Drizzle parameterises, `varchar(128)` caps it), but it pollutes reports.
5. **`/download/latest` awaits the insert before redirecting**, from `iad1` to the DB host — every
   download click waits for a database round trip. `after()` (Next 16) removes that.
6. **Own traffic is mixed in:** ~40 page views from production deployment URLs
   (`dotviewer-*-stians-applications.vercel.app`, behind Vercel Authentication — i.e. you) and
   verification curls.
7. **Consent:** `dv_vid` (2-year) and `dv_sid` are set by JavaScript for analytics without consent — see §6.

## 3. Part 1 — Downloads

### 3.1 Definitions

- **Downloads (headline)** = the daily change in GitHub's DMG `download_count`, summed per version and
  per ISO week. Every channel ends at GitHub — site redirect, Homebrew, release page, and (after
  Part 3) Sparkle — so this is the only complete number. It counts downloads, not people.
- **Channel split** attributes that total:
  - *Website:* `analytics_downloads` rows, split into human Mac / phone / bot by user agent.
  - *Sparkle updates* (Part 3): enclosure URLs go through the site's `/updates/<file>` redirect;
    Sparkle's user agent identifies them.
  - *Homebrew* (optional, §9): the cask `url` goes through the same redirect; Homebrew's user agent
    then yields installs + upgrades per version, and macOS version and architecture.
  - *Unattributed* = GitHub delta − attributed: release page, issue links, bots hitting GitHub directly.
- **People** come from Part 2 (active installs). A Homebrew or Sparkle update is a new download of an
  existing install, so downloads overstate users as soon as updates flow.

### 3.2 Collection changes (site only — no app release)

1. **Daily snapshot cron** (`/api/cron/snapshots`, Vercel Cron + `CRON_SECRET`) → upsert
   `github_asset_counts(snapshot_date, tag, asset, download_count)` and Homebrew's public 30/90/365-day
   install counts for the cask. Weekly and per-version trends are SQL deltas. History before the first
   snapshot stays as the per-release totals above.
2. **File redirect** `/updates/[file]` (e.g. `/updates/dotViewer-1.6.0.dmg`): maps the file name to
   its GitHub release asset, logs `{channel, version}` with `after()` — channel from the user agent:
   `Sparkle/…`, `Homebrew/…`, else direct — and 302s. Used by Sparkle enclosures (§5.2) and,
   optionally, the cask.
3. **Fix §2:** move the `gtag` guard; take the referrer from the payload (host only); whitelist
   `source` (`^[a-z0-9_]{1,64}$`, else `other`); log with `after()`; add `is_bot` / `is_internal` flags
   at insert; the cron also does a write-check so a broken pipeline shows up within a day.
4. **Go cookieless** (§6.2).

### 3.3 Where you look at it — recommendation: a protected `/stats` page

- `site/app/stats/page.tsx`, server-rendered on each request, `noindex`, not in the sitemap.
- HTTP Basic Auth in `site/proxy.ts` (Next 16's renamed middleware) for `/stats`, credentials in
  `STATS_USER` / `STATS_PASSWORD`, constant-time compare. Works from a phone; no new service.
- Shows: downloads 7 d / 30 d / all-time; weekly downloads by channel (inline SVG, no chart library);
  per-version table (GitHub, site human/phone/bot, Sparkle, Homebrew, unattributed); after Part 2,
  WAU/MAU, version adoption, macOS and architecture; a freshness line (last site row, last snapshot,
  last heartbeat).
- Rejected: Grafana/Metabase/Hex (another service and credential for five queries); Vercel Password
  Protection (protects whole deployments, paid add-on). A `scripts/dotviewer-stats.sh` on the same SQL
  is cheap to add later if a terminal view is wanted.

## 4. Part 2 — Active users

### 4.1 Constraints found

- **Extensions and HighlightXPC are sandboxed with no `network.client`** (`project.yml`). Keep it that
  way: the processes that read `.env` files and keys never touch the network. That is also the
  simplest privacy statement to make publicly.
- **Sandboxed extensions can already write to the App Group** in shipped builds —
  `PreviewProvider.swift:167` stores `previewWindowLastWidth/Height` for the host app to read.
- **The host app runs only when opened.** No login item; the SwiftUI `WindowGroup` keeps it alive
  until Quit or logout. Homebrew's `postflight` registers the extensions, so a Homebrew user never
  has to open the app. ⌥Space and ⌘F also only work while it runs, and the UI never says so.
  Consequence: heartbeats **and** Sparkle update checks only reach people who open the app now and then.

### 4.2 Design: extensions record, the host app reports

- **`Shared/UsageLedger.swift`** — per UTC day: `previews` (Finder Space), `panel` (⌥Space) and a
  `thumbnails` flag. Written to the App Group only while telemetry is on. Counts are batched in memory
  and flushed at most every ~10 s (a Finder thumbnail storm must not hit `cfprefsd` per file); each
  process kind writes its own keys, so preview and thumbnail processes cannot lose each other's
  updates. Keeps 35 days.
- **`App/TelemetryReporter.swift`** — on launch (+60 s) and every 24 h while running
  (`NSBackgroundActivityScheduler`). If on and ≥ 20 h since the last success, it sends the
  unreported days plus the current environment; days are marked reported only after a 2xx.
  Offline → next time. Days used while the app was closed are still reported the next time it opens.
- **The complete payload** (nothing else is sent):

  ```json
  {
    "schema": 1,
    "installId": "8b0c4a5e-…",
    "app": { "version": "1.6.1", "build": 16, "channel": "homebrew" },
    "os": { "version": "15.7", "arch": "arm64" },
    "days": [{ "date": "2026-10-02", "previews": "10-49", "panel": "1-9", "thumbnails": true }]
  }
  ```

  `installId` is a random UUIDv4 created on opt-in and deleted on opt-out. `arch` is the machine's
  (`hw.optional.arm64`), not the process's, so Rosetta cannot skew it. `channel` is `homebrew`
  when a `Caskroom/dotviewer` directory exists, else `dmg`. Counts are buckets (`0`, `1-9`, `10-49`,
  `50+` — §9). No file names, paths, types or contents; no Mac model, locale, time zone, host or user
  name; the server stores no IP address and no geolocation.
- **Endpoint** `POST /api/telemetry/v1/heartbeat` (Node runtime): strict validation, body ≤ 4 KB,
  dates within the last 35 days, version must be a published tag. Upserts
  `telemetry_installs(install_id, first_seen, last_seen, app_version, build, os_version, arch, channel)`
  and `telemetry_days(install_id, day, previews, panel, thumbnails)`. `DELETE
  /api/telemetry/v1/installs/:id` erases an install when the user opts out.
- **Abuse:** anyone can post fake heartbeats (no attestation on macOS). Validation, idempotent
  upserts per `(install, day)` and a Vercel Firewall rate limit on the path keep that cheap; accepted
  risk for a free app.
- **Metrics:** DAU/WAU/MAU = distinct installs with a day row in the window; installs seen in the last
  30 days; version adoption; macOS and architecture; Homebrew vs DMG. Days arrive late, so the page
  marks the last 7 days as incomplete.
- **Consent UX:** the first launch of 1.6.1 shows one sheet: what is sent (the payload above), why,
  retention, a link to `/privacy`, and two equally prominent buttons — "Share anonymous statistics" /
  "Don't share". Nothing is recorded or sent before a yes; the answer, consent version and time are
  stored. Settings gets a **Privacy** tab: the toggle, "Show what is sent" (the exact next JSON),
  "Delete my data". Turning it off deletes the local ID and ledger and calls `DELETE`. (Update checks
  get their own choice through Sparkle's prompt, §5.4.)

### 4.3 Backend: own endpoint vs services

| | Free tier (2026) | Company / data | ID on device | Sends by default | Fit |
|---|---|---|---|---|---|
| **Own route + Postgres** | within current Vercel Pro + DB | Vercel (US, EU region possible) + your DB host | UUID, only after opt-in | exactly §4.2 | exact WAU/MAU; joins with downloads; `/stats` exists anyway |
| TelemetryDeck | 50K signals/mo, 3-month history (€9: 750K, 24 months) | Germany, EU hosting | UUID, double-hashed | + model, screen, time zone, language, region, locale, session signals | best ready-made fallback; free history too short for trends |
| Aptabase | 20K events/mo | Romania, EU or US | none (daily IP+UA hash) | OS, language, version, model — no architecture | no WAU/MAU by design |
| PostHog EU | 1M events/mo | US company, Frankfurt | UUID, not hashed | + locale, time zone, screen, Wi-Fi… | heavy SDK (bundles a crash reporter); overkill |
| Plausible / Umami | website tools | EU / US | none | — | no concept of an install |

The vendors' "no consent banner needed" claims are about GDPR anonymisation, not § 3-15's rule on
storing and reading device data (§6) — the opt-in is needed with any of them, so a vendor saves
the dashboard, not the consent work. **Recommendation: own endpoint.** Five fields, no new processor,
one database with the download data, no cost, and the `/stats` page is being built for Part 1
anyway. TelemetryDeck if you would rather not own the dashboard.

## 5. Part 3 — Updates

### 5.1 Recommendation: Sparkle 2 (2.10.0)

| | Sparkle 2 | GitHub API check + own dialog |
|---|---|---|
| Popup when a version is out | standard alert with release notes: Install / Remind Me Later / Skip | custom alert |
| Background updates | download + install, verified | none — user downloads, mounts, drags, replaces |
| Integrity | EdDSA signature + new app must satisfy the installed app's designated requirement; downgrades refused | Gatekeeper at manual install |
| Work | SPM, key, `publish.sh` step, signer fix, post-update hook | ~150 lines |
| Ongoing | guard one private key forever | nothing |

The host app is unsandboxed, which is Sparkle's simplest setup: no installer XPC services, no
installer launcher. Sparkle 2.10.0 (2026-09-13) needs macOS 12; never use < 2.9.6 (it fixes a local
privilege escalation). The lighter option loses the part you asked for — updates that happen without
the user — and a half-finished DMG install leaves the extensions unregistered.

### 5.2 Feed, archive, hosting

- **`SUFeedURL = https://dotviewer.app/appcast.xml`.** The URL is baked into every binary forever, so
  it lives on your domain. The route serves the appcast attached to the latest GitHub release
  (`releases/latest/download/appcast.xml`) with a short CDN cache, and counts requests per day by app
  version from the User-Agent (`dotViewer/1.6.0 Sparkle/2.10.0`) — no IP, no ID. No site deploy per
  release. Rejected: pointing binaries at GitHub directly (no counting, tied to repo layout — the
  competitor Syntax Highlight's feed broke on a repo rename,
  [sbarex/SourceCodeSyntaxHighlight#358](https://github.com/sbarex/SourceCodeSyntaxHighlight/issues/358));
  a static file in `site/public` (a deploy per release). If the site is down, checks fail quietly and
  retry next interval.
- **Archive: the existing notarized DMG.** Sparkle mounts it without showing it, ignores the
  `.background` folder and the `/Applications` link, and handles licence prompts; its docs recommend
  exactly this. No second artifact.
- **Enclosure URLs under one fixed prefix**, `https://dotviewer.app/updates/<file>`. `generate_appcast`
  applies a single `--download-url-prefix` to every archive in its folder and rewrites older items,
  so per-tag GitHub URLs break history. The route maps `dotViewer-1.6.0.dmg` (and later `.delta`
  files) to the GitHub release asset, logs it as a Sparkle download and 302s. Sparkle verifies the
  EdDSA signature, so the redirect cannot swap content.
- **Signed feed** (Sparkle ≥ 2.9: `SURequireSignedFeed` + `SUVerifyUpdateBeforeExtraction`):
  `generate_appcast` signs the appcast and release notes. Worth it because the feed passes through
  the proxy. Cost: losing the key blocks updates for 20 days, then they show without notes.
- **`publish.sh`** gets a step between "DMG notarized" and "GitHub release": copy the DMG and a
  release-notes file (`dotViewer-X.md`, cut from the CHANGELOG as today) into a clean folder, run
  `generate_appcast` (key from the Keychain), attach `appcast.xml` to the release together with the
  DMG. Python tests for the step, like the existing packaging tests.

### 5.3 The signing key

- You run Sparkle's `generate_keys` once (it ships in `SourcePackages/artifacts/sparkle/Sparkle/bin/`):
  the Ed25519 private key goes into your login Keychain, the printed public key into `project.yml`
  as `SUPublicEDKey`. I never see the private key.
- `generate_keys -x <file>` → store the export in your password manager or offline, delete the file.
  Recovery if the key is lost: ship an update signed with the same Developer ID certificate and a new
  public key (you can rotate the certificate or the key, never both at once).
- Never in the repo, CI or Vercel.

### 5.4 App changes (1.6.0)

- `project.yml`: package `Sparkle` (`from: 2.10.0`) on the `dotViewer` target only; Info.plist keys
  `SUFeedURL`, `SUPublicEDKey`, `SURequireSignedFeed`, `SUVerifyUpdateBeforeExtraction`, and
  `SUAutomaticallyUpdate` per §9 Q6. `SUEnableAutomaticChecks` stays **unset**, so Sparkle asks on the
  second launch — "Check Automatically" / "Don't Check", with an "automatically download and install"
  checkbox. That gives update checks an explicit user choice (§6.3) at no cost. No
  `SUEnableSystemProfiling` (its checkbox is pre-ticked — not valid consent). Optionally strip
  Sparkle's unused `XPCServices` in an install-only build phase.
- `SPUStandardUpdaterController` in `dotViewerApp`; **"Check for Updates…"** after "About dotViewer"
  (`CommandGroup(after: .appInfo)`); Settings gets an **Updates** tab: check automatically, download
  and install automatically, last check, Check Now.
- **Post-update hook:** on the first launch of a new build, `pluginkit -a` both extensions, re-enable
  them, `qlmanage -r`, and end stale extension processes. Sparkle never touches PlugInKit, and others
  saw stale Quick Look registrations after Sparkle updates this month. This replaces what the cask's
  `postflight` does today.
- **Automatic installs:** Sparkle's default installs a downloaded update silently at quit, without
  relaunch — so the hook would not run until the next launch, possibly days later. Instead, use
  `updater(_:willInstallUpdateOnQuit:immediateInstallationBlock:)`: when an update is ready and no
  window or ⌥Space panel is open, install now and relaunch without a window (SwiftUI's
  `defaultLaunchBehavior(.suppressed)` on macOS 15). With automatic installs off, the user gets the
  standard alert — the popup you asked for.
- Recovery signer (`sign-developer-id-app.py`): also sign `Autoupdate` and `Updater.app`, inside-out,
  `-o runtime --timestamp`, never `--deep`. Today it only collects `.framework/.appex/.xpc`, so the
  helpers would stay ad-hoc signed and fail notarization. The normal Xcode export already handles
  them; `developer_id_profiles.py` correctly skips Sparkle's bundles.

### 5.5 Homebrew

- Cask: **`auto_updates true`** plus a `livecheck` block on the appcast URL with
  `strategy :sparkle, &:short_version`, flipped **with 1.6.0**. Current Homebrew upgrades an `auto_updates` cask
  only when the installed bundle's version is older than the cask's
  ([FAQ](https://docs.brew.sh/FAQ); since [brew#21985](https://github.com/Homebrew/brew/pull/21985)):
  1.5.x users still reach 1.6.0 via `brew upgrade`; installs Sparkle already updated are left alone —
  no redundant 70 MB reinstall, no forced quit through the cask's `uninstall quit:`, no downgrade
  when Sparkle is ahead of the tap. (With today's `auto_updates false`, brew compares against its own
  stale record and does all three.) Homebrew older than 5.2 skips such casks entirely — a small tail.
- A Homebrew copy is owned by whoever ran `brew`; another account on the same Mac would get
  Sparkle's admin prompt (inferred). Same for a DMG installed by another admin.

### 5.6 Accessibility (TCC)

Sparkle swaps the bundle atomically at the same path and rejects any update that does not satisfy
the installed app's designated requirement (Team ID `7F5ZSQFCQ4` + bundle ID). TCC keys the grant on
that requirement, so the grant should survive — as it did for the manual same-signature upgrades
1.5.0 → 1.5.2 and 1.5.5 → 1.5.6 → 1.5.7. An unresolved 2020 report
([Sparkle#1625](https://github.com/sparkle-project/Sparkle/issues/1625)) blamed resets on identity
changes. App Management (macOS 13+) lets same-team code modify the app, so no prompt is expected.
**Both are verified in Phase 2 with a real N → N+1 Sparkle update before 1.6.0 ships.**

### 5.7 Update size (Phase 4)

The app is 518 MB unpacked — HighlightXPC is embedded twice (host and preview extension, 165 MB each)
— so every update is a 70 MB DMG. `generate_appcast` can build up to 5 binary deltas from older
archives in its folder (kept when ≥ 12.5 % smaller), uploaded next to the DMG. An APFS/lzfse DMG
also decompresses faster.

## 6. Privacy and GDPR (engineering reading — not legal advice)

### 6.1 App telemetry must be opt-in

- Norway's **ekomloven § 3-15** (new act, in force 2025-01-01) requires GDPR-standard consent before
  storing or reading *any* information on a user's device, whether or not it is personal data
  ([Lovdata](https://lovdata.no/dokument/NL/lov/2024-12-13-76/KAPITTEL_3#%C2%A73-15),
  [Datatilsynet](https://www.datatilsynet.no/aktuelt/aktuelle-nyheter-2024/nye-cookie-regler-fra-1.-januar/)).
  Only two exemptions: pure transmission, and what is strictly necessary for a service the user
  explicitly asked for. Both regulators call the rule technology-neutral; the EDPB's final Guidelines
  2/2023 (Oct 2024) say installed software calling an API counts as "gaining access" (¶33) and
  identifiers stored through any software count (¶36)
  ([EDPB](https://www.edpb.europa.eu/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en_0.pdf)).
- A stored install ID and a heartbeat are neither exemption → **opt-in, unticked, withdrawable,
  with the consent version and time recorded**. An on-by-default opt-out is not defensible in Norway.
- The install ID plus versions is **pseudonymous personal data** (Recitals 26/30), so:
  an Art. 13 notice; fixed retention (raw rows ≤ 13 months, then anonymous aggregates only); a
  one-page record of processing (Art. 30's under-250 exemption does not cover continuous processing);
  DPAs with Vercel (its DPA covers Pro — this team is Pro) and the database host; erasure by ID
  (Art. 11) through "Delete my data", which also rotates the ID.
- US transfer: Vercel Inc. is EU-US Data Privacy Framework certified and its DPA has SCCs; the
  framework was upheld by the General Court (2025-09-03), appeal pending. Pinning the analytics and
  telemetry routes to an EU region (`preferredRegion`) keeps processing in the EU where possible.

### 6.2 Website: go cookieless instead of adding a banner

- `dv_vid` (2 years) and `dv_sid` are analytics cookies → **they need consent under § 3-15 today**;
  the site also has no privacy notice. Two ways out: a consent banner (reject as easy as accept), or
  remove them. **Recommendation: remove them.**
- First-party rows then hold: time, path, referrer host, UTM, country, browser and OS family, a bot
  flag. No visitor/session ID, no IP, no full user agent, no city/region. Unique visitors come from
  Vercel Web Analytics, which is cookieless and uses a request hash valid for one day
  ([Vercel](https://vercel.com/docs/analytics/privacy-policy)) — the same model Datatilsynet uses on
  its own site ([notice](https://datatilsynet.no/om-datatilsynet/datatilsynets-personvernerklaring/?id=11916)).
  Residual risk: the EDPB reads headers and IP-based tracking broadly (¶43, ¶54) and Norway has no
  audience-measurement exemption like France's CNIL; low in practice, and disclosed.
- Historical rows (1,012) keep `visitor_id`, `session_id`, `city`, `region` and full user agents.
  Proposal: null those values once (classify bots first) and add a retention job. That is an
  irreversible data change, so it needs your go-ahead; no columns are dropped.
- New `/privacy` page, linked from the footer, the security page's "privacy surface" card and the
  README. It covers the website, download logging, update checks and app telemetry.

### 6.3 Update checks

Sparkle's User-Agent carries the app name and version plus Sparkle's version; system profiling is off
unless enabled. The check itself, once the user has turned checks on or pressed "Check for Updates…",
is plausibly the "strictly necessary" exemption. Counting feed requests per version per day with no
IP or ID stored is low-risk; disclose it. Keep system profiling off.

## 7. Phases (each ends with a checkpoint)

| Phase | What | Ships as | Needs from you |
|---|---|---|---|
| **1 — Site** | §2 fixes, cookieless logging, `/privacy`, GitHub snapshot cron, `/stats` | site deploy only | env vars `STATS_USER`, `STATS_PASSWORD`, `CRON_SECRET`; approve reviewed migration SQL; approve deploy; OK to scrub old IDs |
| **2 — Updates** | Sparkle, `/appcast.xml`, `/updates/[file]`, `publish.sh` appcast step, signer support, post-update re-registration, cask `auto_updates true` | app **1.6.0** | create the EdDSA key on your Mac (I never see it); approve release and tap change |
| **3 — Telemetry** | `UsageLedger`, `TelemetryReporter`, consent sheet, Privacy tab, endpoint, stats section | app **1.6.1**, delivered by Sparkle | approve fields/buckets; approve release |
| 4 — optional | "Open at login", delta updates, Homebrew URL via site | later | decide |

Why this order: every release without an updater strands more people on old versions, and telemetry
reaches people only through updates — so Sparkle goes first and delivers telemetry as its first real
update, which is also the first real-world Sparkle test. Phase 1 needs no app release and starts
counting at once. Everyone on 1.5.x has to install 1.6.0 by hand once (Homebrew users via
`brew upgrade`); 1.5.x has no way to be told.

Testing stays on Developer ID builds (`./scripts/release.sh <ver> --skip-notarize --skip-dmg`), never a
development build over `/Applications`. Sparkle's TCC check: install build N from its DMG, grant
Accessibility, update to N+1 from a test feed, confirm "⌘F search is active".

## 8. Dead ends — do not try

- **Network access from the Quick Look extensions or HighlightXPC.** Whether Quick Look even allows it
  is unverified, and it breaks the "the processes that read your files are offline" guarantee.
- **Launching the host app from an extension to send a heartbeat** — a Dock icon appearing because
  you pressed Space is a trust-killer.
- **On-by-default or pre-ticked telemetry** — not valid consent under § 3-15.
- **Reconstructing weekly history from GitHub counts** — GitHub stores no history; start snapshots.
- **Treating downloads as users** — Homebrew and Sparkle updates re-download the DMG.
- **Sparkle system profiling as telemetry** — weekly, no install ID, and it sends Mac model, RAM and
  language: more than needed, less than wanted.
- **The EdDSA private key anywhere but the Keychain and an offline backup** — not the repo, CI or Vercel.
- **Keeping the cask on `auto_updates false` once Sparkle ships** — brew would reinstall over every
  Sparkle update, quit the running app, and could downgrade when Sparkle is ahead of the tap. (The
  opposite worry — that `auto_updates true` strands 1.5.x — no longer holds: current Homebrew compares
  the installed bundle's version.)
- **Silent install-at-quit without a relaunch** — leaves stale extension registrations until the
  next launch (§5.4).
- **`drizzle-kit push --force` against production** — generate SQL, review it, then apply.
- **Tap clone counts as an install metric** — scanners and `brew tap` only; use Homebrew's public
  analytics instead.

## 9. Open questions

Blocking Phase 1:

1. **Where does the dbHost database run** (provider, region)? Needed for the privacy notice and to
   pin the new routes near it (`arn1`/`fra1` instead of today's `iad1`).
2. **Scrub the old rows?** Null `visitor_id`, `session_id`, `city`, `region` and reduce user agents to
   browser/OS family in the 1,012 existing rows — irreversible.
3. **A non-production database** for migrations and endpoint tests — can dbHost provide one?
   Preview deployments have no `DATABASE_URL` today.
4. **Stats access:** Basic Auth enough, or "Sign in with Vercel"?
5. **Google Analytics hooks:** remove the dormant code? Turning it on would need a consent banner.

Blocking Phase 2:

6. **Pre-tick "automatically download and install" in Sparkle's prompt** (`SUAutomaticallyUpdate`)?
   Recommendation: yes — installed while idle with a quiet relaunch; the user can untick it and then
   gets the update popup instead.
7. **Homebrew attribution:** point the cask `url` at `dotviewer.app/updates/…` for per-version
   installs + upgrades with macOS/architecture, at the cost of `brew install` depending on the site?
   Recommendation: yes, once the route has run through one release.

Blocking Phase 3:

8. **Fields:** as in §4.2, or also country (derived server-side, IP not stored) or feature flags
   (⌥Space / ⌘F enabled)? Default: neither.
9. **Buckets** for preview counts: `0 / 1-9 / 10-49 / 50+`?

Later:

10. **"Open at login"** so ⌥Space, ⌘F, update checks and telemetry work without opening the app?

## 10. Phase 1 — status and deploy runbook (2026-09-23)

Built on this branch in five commits (`8057cde` … `55da8e7`): cookieless first-party log with the §2
fixes, `db/sql/001`, a backfill/scrub script, the daily snapshot cron, `/updates/<file>`, `/stats` behind
Basic Auth, `/privacy`, README updates. 26 unit tests (`npm test`), typecheck and `next build` pass.

**Tested end to end** against a throwaway local Postgres (Docker `postgres:17-alpine`) created with the
production schema from `main` and seeded with old-format rows: the migration applies twice without
error and matches `schema.ts` exactly (`drizzle-kit push` finds no changes); the backfill classifies
old rows and scrubs only with `--apply --scrub`; every route answered as designed (beacons 202/400/413,
redirects to the right GitHub asset, cron 401 without the secret and a real snapshot with it — 26
assets, 421 DMG downloads, Homebrew 18/35/55 — `/stats` 401/200); stored rows hold no IP, cookie,
visitor/session ID, city or user agent even when an old page sends a `visitorId`; `/stats` visits are
not logged; no `Set-Cookie` anywhere.

**Decisions taken on the §9 questions** (defaults, change freely):
- Q4 stats access: Basic Auth (`proxy.ts`).
- Q5 Google Analytics: code kept dormant, unchanged; `/privacy` says it is not used.
- Q2 scrub: script ready (`--apply --scrub`), **not run** — irreversible, your call. `/privacy` is accurate
  either way: it says what the site did until 23 September, not that old rows were cleaned.
- Q3 test database: a local Docker container instead; none is needed in production.
- Q1 database region: still open. `/privacy` names dbHost without a region; add it once known.

**Runbook — in this order** (nothing below has been done):
1. Review the branch; `cd site && npm test && npm run typecheck`.
2. Apply the schema change *before* deploying (the new code writes the new columns):
   `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f site/db/sql/001-cookieless-analytics-and-snapshots.sql`
3. Old rows: `node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --env-file=.env.local scripts/backfill-analytics.ts`
   (dry run), then `--apply`; add `--scrub` only if you decide to remove the old identifiers.
4. Environment variables on the Vercel project **`dotviewer`** (production): `STATS_USER`,
   `STATS_PASSWORD`, `CRON_SECRET` — e.g. `vercel env add CRON_SECRET production` from `site/`.
5. Merge and deploy. Vercel picks up the cron from `vercel.json`.
6. Verify: `curl -I https://dotviewer.app/stats` → 401; open it with the credentials; run the snapshot
   once by hand — `curl -H "Authorization: Bearer $CRON_SECRET" https://dotviewer.app/api/cron/snapshots`
   → `"ok":true`; confirm the job in the project's Cron tab; the next day `/stats` shows a fresh snapshot.

Phase 2 (Sparkle) needs the EdDSA key from you first (§5.3); `/updates/<file>` is already in place for
its enclosure URLs.

