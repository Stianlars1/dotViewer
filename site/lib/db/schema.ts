import {
  bigserial,
  boolean,
  date,
  index,
  integer,
  pgTable,
  primaryKey,
  smallint,
  text,
  timestamp,
  varchar,
} from "drizzle-orm/pg-core";

// Columns written since the cookieless change (2026-09): coarse facts derived at insert time, a
// code for the visitor that is valid for one UTC day (lib/analytics/day-visitor.ts) and, only with
// the visitor's consent, visitor_id. The older identifying columns (session_id, city, region,
// user_agent, request_id) are no longer written; their old values were deleted on 2026-09-23.
const classification = () => ({
  browser: varchar("browser", { length: 32 }),
  dayVisitor: varchar("day_visitor", { length: 16 }),
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
    dayVisitorIdx: index("analytics_page_views_day_visitor_idx").on(table.createdAt, table.dayVisitor),
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
    dayVisitorIdx: index("analytics_downloads_day_visitor_idx").on(table.createdAt, table.dayVisitor),
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

// Today's salt for the day codes. Earlier days are deleted, so their codes cannot be recomputed.
export const analyticsDailySalts = pgTable("analytics_daily_salts", {
  createdAt: timestamp("created_at", { mode: "date", withTimezone: true }).defaultNow().notNull(),
  day: date("day", { mode: "string" }).primaryKey(),
  salt: text("salt").notNull(),
});

// One row per consent choice, as proof of consent; visitor_id only when statistics was accepted.
export const analyticsConsents = pgTable(
  "analytics_consents",
  {
    createdAt: timestamp("created_at", { mode: "date", withTimezone: true }).defaultNow().notNull(),
    google: boolean("google").notNull(),
    id: bigserial("id", { mode: "number" }).primaryKey(),
    source: varchar("source", { length: 16 }).notNull(),
    statistics: boolean("statistics").notNull(),
    version: smallint("version").notNull(),
    visitorId: varchar("visitor_id", { length: 64 }),
  },
  (table) => ({
    createdAtIdx: index("analytics_consents_created_at_idx").on(table.createdAt),
  }),
);

export const analyticsSchema = {
  analyticsConsents,
  analyticsDailySalts,
  analyticsDownloads,
  analyticsPageViews,
  githubAssetSnapshots,
  homebrewInstallSnapshots,
};
