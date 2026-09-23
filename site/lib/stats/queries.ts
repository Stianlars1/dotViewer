import { sql } from "drizzle-orm";
import { isInternalHost } from "../analytics/classify.ts";
import { getDb } from "../db/client";
import { getGitHubReleases } from "../github-release";
import { getSiteConfig } from "../site-config";
import { pageViewSummary, versionTable, type DownloadRow, type PageViewRow, type PageViewSummary, type VersionRow } from "./report.ts";
import { downloadsInLast, weeklyDownloads, type DailyTotal, type WeeklyDownloads } from "./snapshots.ts";

// Everything /stats shows, read in one pass. Each part degrades on its own: before the first daily
// snapshot the totals come live from GitHub, and before db/sql/001 is applied the page says so.

export type StatsReport = {
  downloads: {
    allTime: number | null;
    from: "live" | "none" | "snapshots";
    last30: number | null;
    last7: number | null;
    weekly: WeeklyDownloads[];
  };
  freshness: { lastDownloadLog: Date | null; lastPageView: Date | null; lastSnapshot: string | null };
  homebrew: { date: string; installs: number; periodDays: number }[];
  pageViews: PageViewSummary;
  versions: VersionRow[];
  warnings: string[];
};

const EMPTY_PAGE_VIEWS: PageViewSummary = { countries: [], paths: [], referrers: [], weekly: [] };

// Raw `db.execute` rows come back through Drizzle's pg driver, which leaves timestamps as strings.
function toDate(value: Date | string | null | undefined): Date | null {
  if (value === null || value === undefined) return null;
  return value instanceof Date ? value : new Date(value);
}

// A missing table means db/sql/001 has not been applied; anything else is a bug worth logging.
function explain(error: unknown, what: string): string {
  const message = error instanceof Error ? error.message : String(error);
  return /does not exist/i.test(message)
    ? `${what}: a table is missing — apply site/db/sql/001 to the database.`
    : `${what} could not be read (${message}).`;
}

function hostOf(url: string | null): string | null {
  if (!url) return null;
  try {
    return new URL(url).host;
  } catch {
    return null;
  }
}

export async function loadStats(now = new Date()): Promise<StatsReport> {
  const report: StatsReport = {
    downloads: { allTime: null, from: "none", last30: null, last7: null, weekly: [] },
    freshness: { lastDownloadLog: null, lastPageView: null, lastSnapshot: null },
    homebrew: [],
    pageViews: EMPTY_PAGE_VIEWS,
    versions: [],
    warnings: [],
  };

  const db = getDb();
  const { githubRepo, homebrewTap, siteUrl } = getSiteConfig();
  if (!db) {
    report.warnings.push("DATABASE_URL is not set, so only GitHub's live totals are shown.");
  }

  let githubDmg = new Map<string, number>();
  if (db) {
    try {
      const daily = await db.execute<DailyTotal>(sql`
        SELECT snapshot_date::text AS date, sum(download_count)::int AS total
          FROM github_asset_snapshots
         WHERE lower(asset) LIKE '%.dmg'
         GROUP BY snapshot_date
         ORDER BY snapshot_date`);
      const latest = await db.execute<{ count: number; tag: string }>(sql`
        SELECT tag, sum(download_count)::int AS count
          FROM github_asset_snapshots
         WHERE lower(asset) LIKE '%.dmg'
           AND snapshot_date = (SELECT max(snapshot_date) FROM github_asset_snapshots)
         GROUP BY tag`);
      const homebrew = await db.execute<{ date: string; installs: number; periodDays: number }>(sql`
        SELECT DISTINCT ON (period_days) period_days AS "periodDays", installs, snapshot_date::text AS date
          FROM homebrew_install_snapshots
         WHERE cask = ${homebrewTap}
         ORDER BY period_days, snapshot_date DESC`);

      if (daily.rows.length > 0) {
        report.downloads = {
          allTime: daily.rows[daily.rows.length - 1].total,
          from: "snapshots",
          last30: downloadsInLast(daily.rows, 30),
          last7: downloadsInLast(daily.rows, 7),
          weekly: weeklyDownloads(daily.rows),
        };
        report.freshness.lastSnapshot = daily.rows[daily.rows.length - 1].date;
        githubDmg = new Map(latest.rows.map((row) => [row.tag, row.count]));
      }
      report.homebrew = homebrew.rows;
    } catch (error) {
      console.error("[stats] snapshot tables unreadable", error);
      report.warnings.push(explain(error, "Download snapshots"));
    }
  }

  if (report.downloads.from === "none" && githubRepo) {
    const releases = await getGitHubReleases(githubRepo, 100);
    githubDmg = new Map(
      releases.flatMap((release) =>
        typeof release.dmgAsset?.download_count === "number" ? [[release.tagName, release.dmgAsset.download_count] as const] : [],
      ),
    );
    if (githubDmg.size > 0) {
      report.downloads.allTime = [...githubDmg.values()].reduce((sum, count) => sum + count, 0);
      report.downloads.from = "live";
    }
  }

  let downloadRows: DownloadRow[] = [];
  if (db) {
    try {
      const downloads = await db.execute<Omit<DownloadRow, "createdAt"> & { createdAt: Date | string }>(sql`
        SELECT channel, created_at AS "createdAt", device, is_bot AS "isBot", is_internal AS "isInternal",
               os, release_tag AS "releaseTag", user_agent AS "userAgent"
          FROM analytics_downloads`);
      downloadRows = downloads.rows.map((row) => ({ ...row, createdAt: toDate(row.createdAt) ?? new Date(0) }));

      const views = await db.execute<Omit<PageViewRow, "createdAt"> & { createdAt: Date | string; url: string | null }>(sql`
        SELECT country, created_at AS "createdAt", device, is_bot AS "isBot", is_internal AS "isInternal",
               path, referrer_host AS "referrerHost", url, user_agent AS "userAgent"
          FROM analytics_page_views
         WHERE created_at > now() - interval '120 days'`);
      const siteHost = hostOf(siteUrl) ?? "dotviewer.app";
      report.pageViews = pageViewSummary(
        views.rows.map((row) => ({
          ...row,
          createdAt: toDate(row.createdAt) ?? new Date(0),
          isInternal: row.isInternal ?? isInternalHost(hostOf(row.url)),
        })),
        now,
        siteHost,
      );

      const fresh = await db.execute<{ lastDownloadLog: Date | string | null; lastPageView: Date | string | null }>(sql`
        SELECT (SELECT max(created_at) FROM analytics_page_views) AS "lastPageView",
               (SELECT max(created_at) FROM analytics_downloads) AS "lastDownloadLog"`);
      report.freshness.lastPageView = toDate(fresh.rows[0]?.lastPageView);
      report.freshness.lastDownloadLog = toDate(fresh.rows[0]?.lastDownloadLog);
    } catch (error) {
      console.error("[stats] analytics tables unreadable", error);
      report.warnings.push(explain(error, "The site's log"));
    }
  }

  report.versions = versionTable(githubDmg, downloadRows);
  return report;
}
