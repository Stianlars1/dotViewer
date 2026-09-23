// Classifies analytics rows written before the cookieless change, and — only when asked — removes
// the identifying values they still hold. Run after db/sql/001 has been applied.
//
//   node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --env-file=.env.local \
//     scripts/backfill-analytics.ts [--apply [--scrub]]
//
//   (no flags)       dry run: counts only
//   --apply          fill browser, os, device, is_bot and is_internal
//   --apply --scrub  ALSO null visitor_id, session_id, city, region, user_agent and request_id —
//                    IRREVERSIBLE
//
// The classification uses the same code as the live site (lib/analytics/classify.ts), so old and
// new rows are counted alike on /stats.

import pg from "pg";
import { isInternalHost, summarizeUserAgent } from "../lib/analytics/classify.ts";

const apply = process.argv.includes("--apply");
const scrub = process.argv.includes("--scrub");

if (scrub && !apply) {
  console.error("--scrub only runs together with --apply.");
  process.exit(2);
}

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error("DATABASE_URL is not set.");
  process.exit(2);
}

const pool = new pg.Pool({
  connectionString,
  ssl: /sslmode=/i.test(connectionString) ? { rejectUnauthorized: true } : undefined,
});

type Row = { id: string; url?: string | null; user_agent: string | null };

function hostOf(url: string | null | undefined): string | null {
  if (!url) return null;
  try {
    return new URL(url).host;
  } catch {
    return null;
  }
}

async function classify(table: "analytics_downloads" | "analytics_page_views") {
  const columns = table === "analytics_page_views" ? "id, url, user_agent" : "id, user_agent";
  const { rows } = await pool.query<Row>(`SELECT ${columns} FROM ${table} WHERE is_bot IS NULL`);
  const bots = rows.filter((row) => summarizeUserAgent(row.user_agent).isBot).length;
  console.log(`${table}: ${rows.length} unclassified rows (${bots} bots)`);
  if (!apply || rows.length === 0) return;

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    for (const row of rows) {
      const summary = summarizeUserAgent(row.user_agent);
      const internal = isInternalHost(hostOf(row.url));
      if (table === "analytics_page_views") {
        await client.query(
          "UPDATE analytics_page_views SET browser = $2, os = $3, device = $4, is_bot = $5, is_internal = $6 WHERE id = $1",
          [row.id, summary.browser, summary.os, summary.device, summary.isBot, internal],
        );
      } else {
        await client.query(
          "UPDATE analytics_downloads SET browser = $2, os = $3, device = $4, is_bot = $5, is_internal = false, channel = COALESCE(channel, 'website') WHERE id = $1",
          [row.id, summary.browser, summary.os, summary.device, summary.isBot],
        );
      }
    }
    await client.query("COMMIT");
    console.log(`${table}: classified ${rows.length} rows`);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function scrubIdentifiers() {
  for (const table of ["analytics_page_views", "analytics_downloads"]) {
    const { rowCount } = await pool.query(
      `UPDATE ${table}
          SET visitor_id = NULL, session_id = NULL, city = NULL, region = NULL,
              user_agent = NULL, request_id = NULL
        WHERE visitor_id IS NOT NULL OR session_id IS NOT NULL OR city IS NOT NULL
           OR region IS NOT NULL OR user_agent IS NOT NULL OR request_id IS NOT NULL`,
    );
    console.log(`${table}: removed identifying values from ${rowCount ?? 0} rows`);
  }
}

try {
  await classify("analytics_page_views");
  await classify("analytics_downloads");
  if (scrub) {
    await scrubIdentifiers();
  } else {
    console.log(apply ? "Identifying values kept (no --scrub)." : "Dry run: nothing changed. Add --apply to write.");
  }
} finally {
  await pool.end();
}
