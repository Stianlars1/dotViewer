import { sql } from "drizzle-orm";
import { utcDay } from "../analytics/day-visitor.ts";
import { getDb } from "../db/client";

// Keeps what /privacy promises, run by the daily cron: no day-code salt outlives its UTC day, visitor
// IDs leave the log after 13 months, and consent records are kept for 2 years.

export type RetentionResult = { consentsDeleted: number; saltsDeleted: number; visitorIdsCleared: number };

export async function applyRetention(now = new Date()): Promise<RetentionResult | null> {
  const db = getDb();
  if (!db) return null;

  const at = now.toISOString();
  const salts = await db.execute(sql`DELETE FROM analytics_daily_salts WHERE day < ${utcDay(now)}::date`);
  const views = await db.execute(sql`
    UPDATE analytics_page_views SET visitor_id = NULL
     WHERE visitor_id IS NOT NULL AND created_at < ${at}::timestamptz - interval '13 months'`);
  const downloads = await db.execute(sql`
    UPDATE analytics_downloads SET visitor_id = NULL
     WHERE visitor_id IS NOT NULL AND created_at < ${at}::timestamptz - interval '13 months'`);
  const consents = await db.execute(sql`
    DELETE FROM analytics_consents WHERE created_at < ${at}::timestamptz - interval '2 years'`);

  return {
    consentsDeleted: consents.rowCount ?? 0,
    saltsDeleted: salts.rowCount ?? 0,
    visitorIdsCleared: (views.rowCount ?? 0) + (downloads.rowCount ?? 0),
  };
}
