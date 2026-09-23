-- One-off cleanup of rows logged before 23 September 2026. Not a schema change: it brings the old rows
-- in line with what /privacy says the log keeps, which the live code already does for new rows.
--
-- 1. The linking site's name (referrer_host) is derived from the old full address, by the live rule in
--    lib/analytics/classify.ts referrerHost(): http(s) only, lower-case, without "www.", 255 at most.
-- 2. The full linking address is deleted.
-- 3. Page addresses and paths lose everything from the first "?" or "#", which can carry per-click IDs
--    (fbclid, gclid); campaign tags already sit in the utm_* columns.
--
-- Idempotent, but IRREVERSIBLE for what it deletes. Applied to production on 2026-09-23:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f site/db/sql/003-drop-full-referrers-and-queries.sql

BEGIN;

WITH changed AS (
  UPDATE analytics_page_views
     SET referrer_host = NULLIF(left(regexp_replace(
           substring(lower(referrer) from '^https?://(?:[^/?#@]*@)?([^/:?#]+)'), '^www\.', ''), 255), '')
   WHERE referrer_host IS NULL AND referrer ~* '^https?://'
  RETURNING 1)
SELECT 'page views: linking site derived' AS step, count(*)::int AS rows FROM changed;

WITH changed AS (
  UPDATE analytics_downloads
     SET referrer_host = NULLIF(left(regexp_replace(
           substring(lower(referrer) from '^https?://(?:[^/?#@]*@)?([^/:?#]+)'), '^www\.', ''), 255), '')
   WHERE referrer_host IS NULL AND referrer ~* '^https?://'
  RETURNING 1)
SELECT 'downloads: linking site derived' AS step, count(*)::int AS rows FROM changed;

WITH changed AS (UPDATE analytics_page_views SET referrer = NULL WHERE referrer IS NOT NULL RETURNING 1)
SELECT 'page views: full linking address deleted' AS step, count(*)::int AS rows FROM changed;

WITH changed AS (UPDATE analytics_downloads SET referrer = NULL WHERE referrer IS NOT NULL RETURNING 1)
SELECT 'downloads: full linking address deleted' AS step, count(*)::int AS rows FROM changed;

WITH changed AS (
  UPDATE analytics_page_views
     SET url = substring(url from '^[^?#]*'), path = substring(path from '^[^?#]*')
   WHERE url ~ '[?#]' OR path ~ '[?#]'
  RETURNING 1)
SELECT 'page views: address after ? or # deleted' AS step, count(*)::int AS rows FROM changed;

WITH changed AS (
  UPDATE analytics_downloads SET path = substring(path from '^[^?#]*') WHERE path ~ '[?#]' RETURNING 1)
SELECT 'downloads: path after ? or # deleted' AS step, count(*)::int AS rows FROM changed;

COMMIT;
