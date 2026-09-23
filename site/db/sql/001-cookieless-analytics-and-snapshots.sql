-- Cookieless analytics columns and daily download snapshots.
--
-- Hand-written, because the schema was created with `drizzle-kit push` and has no migration history:
-- `drizzle-kit generate` would try to create the existing tables again. Additive only — no column is
-- dropped or rewritten — and idempotent, so running it twice is harmless.
--
-- Apply after review, before deploying the code that writes these columns:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f site/db/sql/001-cookieless-analytics-and-snapshots.sql

BEGIN;

-- Coarse facts derived at insert time; the identifying columns are no longer written.
ALTER TABLE analytics_page_views
  ADD COLUMN IF NOT EXISTS browser varchar(32),
  ADD COLUMN IF NOT EXISTS device varchar(16),
  ADD COLUMN IF NOT EXISTS is_bot boolean,
  ADD COLUMN IF NOT EXISTS is_internal boolean,
  ADD COLUMN IF NOT EXISTS os varchar(32),
  ADD COLUMN IF NOT EXISTS referrer_host varchar(255);

ALTER TABLE analytics_downloads
  ADD COLUMN IF NOT EXISTS browser varchar(32),
  ADD COLUMN IF NOT EXISTS channel varchar(16),
  ADD COLUMN IF NOT EXISTS device varchar(16),
  ADD COLUMN IF NOT EXISTS is_bot boolean,
  ADD COLUMN IF NOT EXISTS is_internal boolean,
  ADD COLUMN IF NOT EXISTS os varchar(32),
  ADD COLUMN IF NOT EXISTS referrer_host varchar(255);

-- GitHub keeps one running total per release asset and no history; one row per asset per day.
CREATE TABLE IF NOT EXISTS github_asset_snapshots (
  snapshot_date date NOT NULL,
  tag varchar(64) NOT NULL,
  asset varchar(255) NOT NULL,
  download_count integer NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (snapshot_date, tag, asset)
);

-- Homebrew's public install analytics for the cask, per 30/90/365-day window, one row per day.
CREATE TABLE IF NOT EXISTS homebrew_install_snapshots (
  snapshot_date date NOT NULL,
  cask varchar(128) NOT NULL,
  period_days integer NOT NULL,
  installs integer NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (snapshot_date, cask, period_days)
);

COMMIT;
