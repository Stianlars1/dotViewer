import {
  bigserial,
  boolean,
  date,
  index,
  integer,
  pgTable,
  primaryKey,
  text,
  timestamp,
  varchar,
} from "drizzle-orm/pg-core";

// Columns written since the cookieless change (2026-09): coarse facts derived at insert time.
// The older identifying columns (visitor_id, session_id, city, region, user_agent, request_id) are
// no longer written; they stay in the schema until the owner decides about the existing rows.
const classification = () => ({
  browser: varchar("browser", { length: 32 }),
  device: varchar("device", { length: 16 }),
  isBot: boolean("is_bot"),
  isInternal: boolean("is_internal"),
  os: varchar("os", { length: 32 }),
  referrerHost: varchar("referrer_host", { length: 255 }),
});

export const analyticsPageViews = pgTable(
  "analytics_page_views",
  {
    ...classification(),
    city: varchar("city", { length: 128 }),
    country: varchar("country", { length: 8 }),
    createdAt: timestamp("created_at", { mode: "date", withTimezone: true })
      .defaultNow()
      .notNull(),
    id: bigserial("id", { mode: "number" }).primaryKey(),
    path: text("path").notNull(),
    referrer: text("referrer"),
    region: varchar("region", { length: 128 }),
    requestId: varchar("request_id", { length: 128 }),
    sessionId: varchar("session_id", { length: 64 }),
    title: text("title").notNull(),
    url: text("url").notNull(),
    userAgent: text("user_agent"),
    utmCampaign: varchar("utm_campaign", { length: 128 }),
    utmContent: varchar("utm_content", { length: 128 }),
    utmMedium: varchar("utm_medium", { length: 128 }),
    utmSource: varchar("utm_source", { length: 128 }),
    utmTerm: varchar("utm_term", { length: 128 }),
    visitorId: varchar("visitor_id", { length: 64 }),
  },
  (table) => ({
    createdAtIdx: index("analytics_page_views_created_at_idx").on(table.createdAt),
    pathIdx: index("analytics_page_views_path_idx").on(table.path),
    visitorIdx: index("analytics_page_views_visitor_id_idx").on(table.visitorId),
  }),
);

export const analyticsDownloads = pgTable(
  "analytics_downloads",
  {
    ...classification(),
    assetKind: varchar("asset_kind", { length: 32 }).notNull(),
    // website (/download/latest and on-page links), sparkle, homebrew or direct (/updates/<file>).
    channel: varchar("channel", { length: 16 }),
    city: varchar("city", { length: 128 }),
    country: varchar("country", { length: 8 }),
    createdAt: timestamp("created_at", { mode: "date", withTimezone: true })
      .defaultNow()
      .notNull(),
    id: bigserial("id", { mode: "number" }).primaryKey(),
    path: text("path").notNull(),
    referrer: text("referrer"),
    region: varchar("region", { length: 128 }),
    releaseTag: varchar("release_tag", { length: 64 }),
    requestId: varchar("request_id", { length: 128 }),
    sessionId: varchar("session_id", { length: 64 }),
    source: varchar("source", { length: 128 }).notNull(),
    targetUrl: text("target_url").notNull(),
    userAgent: text("user_agent"),
    visitorId: varchar("visitor_id", { length: 64 }),
  },
  (table) => ({
    createdAtIdx: index("analytics_downloads_created_at_idx").on(table.createdAt),
    sourceIdx: index("analytics_downloads_source_idx").on(table.source),
    visitorIdx: index("analytics_downloads_visitor_id_idx").on(table.visitorId),
  }),
);

// GitHub keeps one running total per release asset, with no history. A daily snapshot turns it into
// downloads per day, week and version.
export const githubAssetSnapshots = pgTable(
  "github_asset_snapshots",
  {
    asset: varchar("asset", { length: 255 }).notNull(),
    capturedAt: timestamp("captured_at", { mode: "date", withTimezone: true }).defaultNow().notNull(),
    downloadCount: integer("download_count").notNull(),
    snapshotDate: date("snapshot_date", { mode: "string" }).notNull(),
    tag: varchar("tag", { length: 64 }).notNull(),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.snapshotDate, table.tag, table.asset], name: "github_asset_snapshots_pkey" }),
  }),
);

// Homebrew's public install analytics for the cask (30, 90 and 365-day windows), once a day.
export const homebrewInstallSnapshots = pgTable(
  "homebrew_install_snapshots",
  {
    capturedAt: timestamp("captured_at", { mode: "date", withTimezone: true }).defaultNow().notNull(),
    cask: varchar("cask", { length: 128 }).notNull(),
    installs: integer("installs").notNull(),
    periodDays: integer("period_days").notNull(),
    snapshotDate: date("snapshot_date", { mode: "string" }).notNull(),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.snapshotDate, table.cask, table.periodDays], name: "homebrew_install_snapshots_pkey" }),
  }),
);

export const analyticsSchema = {
  analyticsDownloads,
  analyticsPageViews,
  githubAssetSnapshots,
  homebrewInstallSnapshots,
};
