-- Daily visitor codes and consent records (docs/plans/2026-09-23-consent-banner-design.md).
--
-- Hand-written like 001: additive only and idempotent, so running it twice is harmless.
-- Apply before deploying the code that writes these columns and tables:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f site/db/sql/002-consent-and-day-visitors.sql

BEGIN;

-- A code per visitor per UTC day, hashed with that day's salt (lib/analytics/day-visitor.ts).
ALTER TABLE analytics_page_views ADD COLUMN IF NOT EXISTS day_visitor varchar(16);
ALTER TABLE analytics_downloads ADD COLUMN IF NOT EXISTS day_visitor varchar(16);

CREATE INDEX IF NOT EXISTS analytics_page_views_day_visitor_idx ON analytics_page_views (created_at, day_visitor);
CREATE INDEX IF NOT EXISTS analytics_downloads_day_visitor_idx ON analytics_downloads (created_at, day_visitor);

-- Only today's salt is kept: earlier days are deleted, so their codes cannot be recomputed.
CREATE TABLE IF NOT EXISTS analytics_daily_salts (
  day date PRIMARY KEY,
  salt text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- One row per consent choice, as proof of consent. visitor_id only when dotViewer statistics was
-- accepted; rejections carry no ID.
CREATE TABLE IF NOT EXISTS analytics_consents (
  id bigserial PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  version smallint NOT NULL,
  statistics boolean NOT NULL,
  google boolean NOT NULL,
  source varchar(16) NOT NULL,
  visitor_id varchar(64)
);

CREATE INDEX IF NOT EXISTS analytics_consents_created_at_idx ON analytics_consents (created_at);

COMMIT;
