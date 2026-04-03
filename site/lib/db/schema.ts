import { bigserial, index, pgTable, text, timestamp, varchar } from "drizzle-orm/pg-core";

export const analyticsPageViews = pgTable(
  "analytics_page_views",
  {
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
    assetKind: varchar("asset_kind", { length: 32 }).notNull(),
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

export const analyticsSchema = {
  analyticsDownloads,
  analyticsPageViews,
};
