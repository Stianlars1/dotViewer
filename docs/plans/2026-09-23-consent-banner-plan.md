# Consent banner and visitor statistics — implementation plan

> Compact by the owner's preference (CLAUDE.md: planning under ~20% of the session): each task lists
> files, exact interfaces and the tests that define it; code is written in the task, test first.
> Executed inline on branch `feat/consent-banner`.

**Goal:** a self-made consent banner, cookieless daily visitor codes for everyone, consent-gated
visitor IDs and Google Analytics, and a Visitors section on /stats.

**Architecture:** pure modules (`lib/consent/consent.ts`, `lib/analytics/day-visitor.ts`,
`lib/stats/visitors.ts`) hold every rule and are unit-tested; thin routes and components call them.
The server decides what is stored from the request's own cookies; the page only asks.

**Tech stack:** Next.js 16 App Router, React 19, Drizzle + `pg`, `node --test` with native TypeScript,
CSS Modules. No new dependencies.

**Spec:** `docs/plans/2026-09-23-consent-banner-design.md`

## Global constraints

- Nothing beyond the existing anonymous log before a choice; `gtag.js` never requested before the
  Google choice is on.
- Reject exactly as easy as Accept (same size, same style, same layer).
- Cookie names and lifetimes: `dv_consent` 12 months, `dv_visitor` 13 months (`HttpOnly`), GA cookies
  13 months (`cookie_expires: 34128000`). All `Path=/; SameSite=Lax`, `Secure` on https.
- Consent value format `v1.s<0|1>.g<0|1>`; current version 1.
- The site is light-only; the banner uses the site's tokens (`--dv-card`, `--dv-ink`, `--dv-line`, …).
- Tests: `cd site && npm test` (node --test, imports with `.ts` extensions); `npm run typecheck`.

---

### Task 1: Schema for day codes and consent records

**Files:** create `site/db/sql/002-consent-and-day-visitors.sql`; modify `site/lib/db/schema.ts`.

**Produces:** columns `analytics_page_views.day_visitor`, `analytics_downloads.day_visitor`
(`varchar(16)`, indexed with `created_at`); tables `analytics_daily_salts (day date PK, salt text NOT NULL,
created_at timestamptz default now())` and `analytics_consents (id bigserial PK, created_at timestamptz
default now() NOT NULL, version smallint NOT NULL, statistics boolean NOT NULL, google boolean NOT NULL,
source varchar(16) NOT NULL, visitor_id varchar(64))`. Drizzle exports `analyticsDailySalts`,
`analyticsConsents`, `dayVisitor` fields.

- [ ] Write 002 (additive, idempotent, one transaction) and the matching schema.
- [ ] Throwaway Postgres (Docker `postgres:17-alpine`): apply 001 + 002 twice; `drizzle-kit push`
      reports no changes.
- [ ] Commit `feat(site): add day visitor codes and consent records to the schema`.

### Task 2: Consent rules (pure)

**Files:** create `site/lib/consent/consent.ts`, `site/tests/consent.test.ts`.

**Produces:**
```ts
export const CONSENT_VERSION = 1;
export const CONSENT_COOKIE = "dv_consent";
export const VISITOR_COOKIE = "dv_visitor";
export const CONSENT_MAX_AGE = 365 * 24 * 60 * 60;
export const VISITOR_MAX_AGE = 395 * 24 * 60 * 60;
export type ConsentChoice = { google: boolean; statistics: boolean };
export type StoredConsent = ConsentChoice & { version: number };
export type ConsentSource = "banner" | "settings";
export function formatConsent(choice: ConsentChoice, version?: number): string;      // "v1.s1.g0"
export function parseConsent(value: string | null | undefined): StoredConsent | null;
export function isCurrentConsent(consent: StoredConsent | null): consent is StoredConsent;
export function readCookie(cookieHeader: string | null | undefined, name: string): string | null;
export function isVisitorId(value: string | null | undefined): value is string;       // UUID v4
export function consentedVisitorId(cookieHeader: string | null | undefined): string | null;
export function parseConsentRequest(raw: unknown): (ConsentChoice & { source: ConsentSource }) | null;
export function consentCookies(choice: ConsentChoice, visitorId: string | null, secure: boolean): string[];
export function shouldShowBanner(consent: StoredConsent | null, globalPrivacyControl: boolean): boolean;
export function cookieDomains(hostname: string): string[];  // "www.dotviewer.app" → ["", ".dotviewer.app"]
```
Tests: format/parse round trip; malformed values (`v1.s2.g0`, `x`, empty) → null; old version not
current; `readCookie` with spaces, `=` in values, missing names; `consentedVisitorId` only with a
current `s1` consent and a valid UUID; `parseConsentRequest` rejects non-booleans, unknown source,
wrong version; `consentCookies` sets `HttpOnly` only on the visitor cookie, expires it when statistics is
off, omits `Secure` on http; `shouldShowBanner` false for a current consent and for GPC; `cookieDomains`
for `www.dotviewer.app`, `dotviewer.app`, `localhost`, `*.vercel.app`.

- [ ] Tests first, then the module. Commit `feat(site): add consent rules`.

### Task 3: Daily visitor code (pure + store)

**Files:** create `site/lib/analytics/day-visitor.ts`, `site/tests/day-visitor.test.ts`.

**Produces:**
```ts
export function utcDay(date: Date): string;                                   // "2026-09-23"
export function clientIp(headers: Headers): string | null;                    // x-real-ip, else first x-forwarded-for
export function dayVisitorCode(salt: string, ip: string | null, userAgent: string | null): string; // 16 hex
export type SaltStore = { deleteBefore(day: string): Promise<void>; get(day: string): Promise<string | null>; insert(day: string, salt: string): Promise<void> };
export async function saltFor(store: SaltStore, day: string, randomSalt?: () => string): Promise<string>;
export function dbSaltStore(db: NonNullable<ReturnType<typeof getDb>>): SaltStore;
```
`saltFor` keeps one `{ day, salt }` per function instance; on a miss it deletes earlier days, inserts
with `ON CONFLICT DO NOTHING` and re-reads, so racing instances converge on one salt.
Tests: same salt/IP/UA → same code; different IP, UA or salt → different; 16 lowercase hex; `clientIp`
header precedence; fake store: first call inserts and deletes earlier days, second call hits cache, a
conflicting insert returns the stored salt.

- [ ] Tests first, then the module. Commit `feat(site): count visitors per day without cookies`.

### Task 4: Logging with day codes and consented IDs

**Files:** modify `site/lib/analytics/server.ts`, `site/app/api/analytics/route.ts`,
`site/app/download/latest/route.ts`; test `site/tests/server-context.test.ts`.

**Interfaces:** `RequestContext` gains `ip: string | null` (memory only) and
`visitorId: string | null` (= `consentedVisitorId(cookie header)`). `recordPageView` and
`recordDownload` add `dayVisitor` (page views, and downloads with `channel === "website"`; null for
`/updates` channels) and `visitorId`. `getRequestContext(request)` stays synchronous.
Tests: `getRequestContext` on a `Request` with/without consent cookies → `visitorId` set only with
`v1.s1.*` and a UUID; a forged `visitorId` in the JSON body never reaches the context.

- [ ] Tests first, then the change. Commit `feat(site): log day codes and consented visitor IDs`.

### Task 5: Consent endpoint

**Files:** create `site/app/api/consent/route.ts`; test via Task 2's pure functions plus Task 11.

`POST /api/consent`: body ≤ 512 bytes → 413; bad JSON or `parseConsentRequest` null → 400; else
`204` with `Set-Cookie` from `consentCookies(choice, visitorId, secure)` where `visitorId` reuses a
valid `dv_visitor` from the request or `crypto.randomUUID()`, and `after()` inserts into
`analytics_consents` (`visitor_id` only when statistics is on). `runtime = "nodejs"`, no caching.

- [ ] Implement. Commit `feat(site): record consent choices`.

### Task 6: Browser side and Google Analytics

**Files:** create `site/lib/consent/client.ts`; modify `site/components/site-analytics.tsx`,
`site/lib/analytics/client.ts`.

**Produces (client):** `readStoredConsent(): StoredConsent | null`, `hasGlobalPrivacyControl(): boolean`,
`saveConsent(choice: ConsentChoice, source: ConsentSource): Promise<void>` (POST, then dispatch
`CONSENT_CHANGED_EVENT`), `openConsentSettings(): void` (dispatch `OPEN_CONSENT_EVENT`),
`applyGoogleAnalytics(id: string | null, allowed: boolean): void` (load once with `send_page_view:false`
and `cookie_expires: 34128000`; when not allowed: `window["ga-disable-<id>"] = true`, delete `_ga` and
`_ga_<suffix>` on every `cookieDomains()` entry, remove the script). Event names:
`"dv:consent-changed"`, `"dv:open-consent"`.
`SiteAnalytics` drops the unconditional GA `<Script>`; it applies GA from the stored consent on mount and
on `CONSENT_CHANGED_EVENT`; page views go to GA only while it is loaded. The analytics `fetch` fallback
sends `credentials: "same-origin"` (the beacon already does).

- [ ] Implement. Commit `feat(site): load Google Analytics only after consent`.

### Task 7: Banner and Cookie settings

**Files:** create `site/components/consent-banner.tsx`, `site/components/consent-banner.module.css`,
`site/components/cookie-settings-button.tsx`; modify `site/app/layout.tsx` (mount the banner with
`googleAnalyticsId`), `site/app/page.tsx` (footer link), `site/app/page.module.css` if needed.

Behaviour per the spec's "Visitor experience": hidden when `!shouldShowBanner(...)`; opens in the
Choose view on `OPEN_CONSENT_EVENT` with the current choice; Accept/Reject/Save call `saveConsent` and
close. Region `aria-label="Cookie choices"`, switches as `<input type="checkbox" role="switch">` with
labels, no focus stealing, no motion under `prefers-reduced-motion`, bottom-left card (max 420 px) and
full width minus 16 px gutters under 640 px.

- [ ] Implement. Commit `feat(site): add the consent banner and cookie settings`.

### Task 8: Privacy page and README

**Files:** modify `site/app/privacy/page.tsx` (+ CSS module if needed), `README.md`, `site/README.md`.

Cookies section `id="cookies"` with the table, Google's role and the EU–US Data Privacy Framework,
legal bases, retention, a Cookie settings button; the "no cookies" bullets and the description rewritten;
`UPDATED` moved to the deploy date.

- [ ] Implement. Commit `docs(site): describe the cookies and the consent choices`.

### Task 9: Visitors on /stats

**Files:** create `site/lib/stats/visitors.ts`, `site/tests/visitors.test.ts`; modify
`site/lib/stats/queries.ts`, `site/app/stats/page.tsx`, `site/app/stats/page.module.css`.

**Produces:**
```ts
export type VisitorEvent = { createdAt: Date; dayVisitor: string | null; isBot: boolean | null; isInternal: boolean | null; kind: "download" | "view"; referrerHost: string | null; visitorId: string | null };
export type ConsentRow = { createdAt: Date; google: boolean; statistics: boolean };
export function dailyVisitors(events: VisitorEvent[], now: Date, days?: number): { day: string; visitors: number }[];
export function sameDayConversion(events: VisitorEvent[], now: Date, siteHost: string, days?: number): { downloaders: number; rate: number | null; sources: { downloaders: number; key: string; visitors: number }[]; visitors: number };
export function returningVisitors(events: VisitorEvent[], now: Date, weeks?: number): { newVisitors: number; returning: number; week: string }[];
export function downloadsByVisit(events: VisitorEvent[], gapMinutes?: number): { firstVisit: number; laterVisit: number };
export function consentRate(rows: ConsentRow[], now: Date, days?: number): { choices: number; google: number | null; statistics: number | null };
```
`StatsReport` gains `visitors: { consent, conversion, daily, firstVisitDownloads, returning }`.
Tests on synthetic events: bots/internal excluded; a visitor counted once per day; conversion joins
views and downloads by day code; returning = seen in an earlier week; visits split at 30-minute gaps;
empty inputs give zeros or null rates.

- [ ] Tests first, then module, query and page. Commit `feat(site): show visitors on /stats`.

### Task 10: Retention in the daily cron

**Files:** create `site/lib/stats/retention.ts`; modify `site/app/api/cron/snapshots/route.ts`.

`applyRetention(now: Date): Promise<{ consentsDeleted: number; saltsDeleted: number; visitorIdsCleared: number }>`:
delete salts before `utcDay(now)`, null `visitor_id` on rows older than 13 months in both tables, delete
consent rows older than 2 years. The cron runs it after the snapshot and returns its counts; a retention
failure is logged and reported without failing the snapshot.

- [ ] Implement; covered in Task 11. Commit `feat(site): expire visitor IDs, consents and salts`.

### Task 11: End-to-end check (local)

Throwaway Postgres + `next dev` with `DATABASE_URL`, `NEXT_PUBLIC_GA_MEASUREMENT_ID=G-F0Q1EGB3EM`,
`STATS_USER/PASSWORD`, `CRON_SECRET` (local values). In the built-in browser, desktop and 375 px:
banner shown and keyboard-usable; no cookies and no `googletagmanager.com` request before a choice;
Reject → `dv_consent=v1.s0.g0`, no visitor cookie, no GA; Choose statistics only → `dv_visitor` set
(`Set-Cookie`, `HttpOnly`), no GA; Accept → GA requested with `cookie_expires`; Cookie settings → off →
`_ga*` and `dv_visitor` gone. DB: page views carry `day_visitor`, `visitor_id` only after statistics
consent; consent rows as chosen; cron returns retention counts; /stats renders Visitors.

- [ ] Run and fix; `npm test`, `npm run typecheck`, `npm run build`.

### Task 12: Preview, production, docs

- [ ] Push the branch; confirm Vercel's preview build; send the owner the preview link.
- [ ] After the owner's OK: apply 002 to production (node + `pg`), add `NEXT_PUBLIC_GA_MEASUREMENT_ID`
      to Production, fast-forward `main`, push; verify live as in the spec's Rollout step 4.
- [ ] Update the spec's status, `HANDOFF.md`, `AGENTS.md`, memory.
