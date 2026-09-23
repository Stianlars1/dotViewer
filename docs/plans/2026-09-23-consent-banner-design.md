# Consent banner and visitor statistics — design

Approved in conversation on 2026-09-23 (three parts, each confirmed). Reverses the "no banner"
recommendation of §6.2 in `2026-09-22-usage-stats-telemetry-updates.md` at the owner's request: the
owner wants returning visitors and Google Analytics, and both need consent.

## Goals

The owner wants to see, on the website:
1. Visitors per day and week.
2. Which visits lead to downloads.
3. Returning visitors over weeks.
4. Google Analytics reports (GA4 property `G-F0Q1EGB3EM`).

1 and 2 are answered for every visitor without cookies (same day). 2 across days, 3 and 4 need consent
and cover only visitors who accept.

## Constraints

- Norway's ekomloven § 3-15 with GDPR-level consent: nothing stored on or read from the device
  beyond what is strictly necessary until the visitor chooses; Reject as easy as Accept; no pre-ticked
  choices; withdrawing as easy as giving; the site works the same either way (no cookie wall).
- Self-made: no third-party consent service.
- Google Analytics in basic consent mode: `gtag.js` is not requested at all before consent.
- No new npm dependencies. Next.js 16 conventions as in the rest of `site/`.

## Visitor experience

- **First visit:** a card at the bottom left (full width with a 16 px gutter on phones), not modal and
  not covering the page. Text, roughly: "dotViewer counts visits without cookies. With your OK it also
  uses cookies to see if you come back, and Google Analytics." Buttons **Reject** and **Accept**, same
  size and style; a text button **Choose…** and a link to `/privacy#cookies`. **Accept** turns both
  switches on, **Reject** both off. Without a GA measurement ID the text and the switches leave Google out.
- **Choose…** shows two switches, both off: *dotViewer statistics* (a random ID in a cookie, 13 months,
  only on dotViewer's server) and *Google Analytics* (Google's cookies; data goes to Google). **Save**.
  The Google switch exists only when a GA measurement ID is configured. Reopened from Cookie settings,
  the switches show the current choice.
- **No choice** means no consent. The card stays on every page until a choice.
- **Memory:** the choice is kept 12 months, then asked again. A new banner version (a purpose added or
  changed) asks again too.
- **Change of mind:** "Cookie settings" in the home page footer and on `/privacy` reopens the choices.
  Turning something off deletes its cookies at once and stops it on the page.
- **Global Privacy Control** (`navigator.globalPrivacyControl === true`): treated as Reject, card never
  shown, nothing recorded. Cookie settings still lets such a visitor opt in explicitly.
- Keyboard and screen reader: a labelled region (`aria-label="Cookie choices"`), buttons in reading
  order, visible focus, focus not stolen on load; no animation under reduced motion; light and dark.

## Data

### Daily visitor code (everyone, no cookie)

- For each logged page view and download, the server computes
  `sha256(salt ‖ ip ‖ "\n" ‖ user-agent)` and stores the first 16 hex characters in a new
  `day_visitor` column. IP (`x-real-ip`, else the first `x-forwarded-for` entry) and user agent are used
  in memory only; neither is stored.
- `salt` is 32 random bytes per UTC day in a new table `analytics_daily_salts (day date primary key,
  salt text)`, created on first use with `INSERT … ON CONFLICT DO NOTHING` and re-read, so concurrent
  function instances agree. Salts for earlier days are deleted by the daily cron (and before inserting a
  new day's salt), so codes cannot be recomputed or linked across days afterwards — Plausible's scheme.
- Gives unique visitors per UTC day and "visited and downloaded the same day".

### Cookies

| Name | Set by | Content | Lifetime | Category |
|------|--------|---------|----------|----------|
| `dv_consent` | `/api/consent` | `v1.s1.g0` (version, statistics, Google) | 12 months | strictly necessary |
| `dv_visitor` | `/api/consent` | random UUID, `HttpOnly` | 13 months | dotViewer statistics |
| `_ga`, `_ga_F0Q1EGB3EM` | Google's `gtag.js` | Google client and session IDs | 13 months (`cookie_expires`) | Google Analytics |

All first-party, `Path=/`, `SameSite=Lax`, `Secure` in production. `dv_consent` is readable by the page
so it can decide about the card and Google. The retired `dv_vid` and `dv_sid` stay on the list of
cookies the page expires.

### Server rules

- `/api/analytics` and `/download/latest` store `visitor_id` only when the request itself carries
  `dv_consent` with statistics on and a well-formed `dv_visitor`. Otherwise `visitor_id` is null, whatever
  the page sends. (The existing `visitor_id` column is reused; `session_id` stays unused.)
- Visits are derived at query time: a consented visitor's events less than 30 minutes apart are one visit.
- `POST /api/consent` with `{ version, statistics, google, source: "banner" | "settings" }`: validates,
  sets or expires `dv_consent` and `dv_visitor`, and inserts a row into `analytics_consents (id,
  created_at, version, statistics, google, source, visitor_id)` — `visitor_id` only when statistics is
  accepted. Rejections are recorded without an ID. Recording failures are logged; the visitor's choice is
  applied either way.

### Google Analytics

- The existing dormant GA code in `components/site-analytics.tsx` loads only while the Google choice is
  on, with `cookie_expires: 34128000` (395 days). Turning it off sets `ga-disable-<id>`, deletes `_ga*`
  cookies on the site's registrable domain and path, and removes the loaded script.
- The measurement ID comes from `NEXT_PUBLIC_GA_MEASUREMENT_ID` (already read by `lib/site-config.ts`).

## /stats additions

A "Visitors" section: unique visitors per day (today, 7-day average, 30-day chart) from day codes;
same-day download rate overall and for the top referring sites; returning visitors per week (new vs
returning) and downloads on a first versus a later visit, from consented visitor IDs; consent rate over
30 days (share allowing statistics, share allowing Google). Bots and internal traffic excluded, as now.

## Retention

The daily cron also clears `visitor_id` from log rows older than 13 months and deletes consent records
older than 2 years, besides deleting old salts.

## Privacy page

A "Cookies" section (`id="cookies"`) with the table above, what Google receives and that Google may
process it in the US under the EU–US Data Privacy Framework, the legal bases (consent for the cookies,
legitimate interest for the cookieless log and day codes), retention, and a "Cookie settings" button.
The "no cookies" statements and the page description are rewritten; the last-updated date moves.

## Components

- `lib/consent/consent.ts` — pure: choice type, cookie value format, version, parse and serialize.
- `lib/consent/client.ts` — browser: read the choice, GPC, open and close the card, call
  `/api/consent`, apply and withdraw Google.
- `components/consent-banner.tsx` + `.module.css`, `components/cookie-settings-button.tsx`.
- `lib/analytics/day-visitor.ts` — salt lookup and rotation behind a small store interface, the hash.
- `lib/analytics/server.ts` — day code and consent-gated visitor ID on every logged row.
- `app/api/consent/route.ts`, `db/sql/002-consent-and-day-visitors.sql`, `lib/db/schema.ts`.
- `lib/stats/` — the new queries and report shapes; `app/stats/page.tsx` — the Visitors section.
- `app/api/cron/snapshots/route.ts` — salt cleanup and retention.

## Testing

- Unit (`node --test`): consent value round trips and rejects malformed values; day-code hash stable
  within a day and different across salts; salt rotation with a fake store; the server stores a visitor
  ID only with consent; the new stats functions on synthetic rows.
- End to end against a throwaway local Postgres (Docker), as for phase 1: `002` applied twice; beacons
  with and without consent cookies; consent endpoint; retention.
- In the built-in browser against the local dev server: the card on desktop and phone widths, light and
  dark, keyboard only; Reject and Accept; withdrawing deletes cookies; `googletagmanager.com` is
  requested only after Google is allowed.

## Rollout

1. Branch `feat/consent-banner`; this spec and the implementation plan in `docs/plans/`.
2. Push the branch for a Vercel preview. `NEXT_PUBLIC_GA_MEASUREMENT_ID` is set for **Preview** only
   (done 2026-09-23). The preview has no database, so nothing is logged from it.
3. After the owner's OK: apply `002` to production, add `NEXT_PUBLIC_GA_MEASUREMENT_ID` to
   **Production** — not earlier: the code on `main` today loads GA for everyone whenever the variable is
   set — then merge and deploy.
4. Verify live: no cookies before a choice; `dv_consent`/`dv_visitor`/`_ga*` after Accept and gone after
   withdrawing; GA requested only after consent; consent rows recorded; day codes on new rows; the
   Visitors section on `/stats`.

## Out of scope

Marketing or advertising cookies, other third-party trackers, translations, cross-device identity,
GA consent mode "advanced" (cookieless pings before consent).
