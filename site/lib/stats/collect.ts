import { sql } from "drizzle-orm";
import { getDb } from "../db/client";
import { githubAssetSnapshots, homebrewInstallSnapshots } from "../db/schema";
import { githubHeaders } from "../github-release";
import { getSiteConfig } from "../site-config";
import { assetCountsFromReleases, homebrewInstallCount, isDmg, type AssetCount } from "./snapshots.ts";

// The daily snapshot (/api/cron/snapshots): GitHub's running download totals for every release
// asset and Homebrew's public install counts for the cask, one row each per day. Re-running on the
// same day overwrites that day's rows.

const HOMEBREW_PERIODS = [30, 90, 365] as const;

async function fetchAssetCounts(githubRepo: string): Promise<AssetCount[] | null> {
  const rows: AssetCount[] = [];
  for (let page = 1; page <= 10; page++) {
    const response = await fetch(`https://api.github.com/repos/${githubRepo}/releases?per_page=100&page=${page}`, {
      cache: "no-store",
      headers: githubHeaders(),
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) return null;

    const releases: unknown = await response.json();
    rows.push(...assetCountsFromReleases(releases));
    if (!Array.isArray(releases) || releases.length < 100) break;
  }
  return rows;
}

async function fetchHomebrewInstalls(cask: string): Promise<Partial<Record<number, number>>> {
  const installs: Partial<Record<number, number>> = {};
  for (const days of HOMEBREW_PERIODS) {
    try {
      const response = await fetch(`https://formulae.brew.sh/api/analytics/cask-install/${days}d.json`, {
        cache: "no-store",
        signal: AbortSignal.timeout(15_000),
      });
      if (!response.ok) continue;
      const count = homebrewInstallCount(await response.json(), cask);
      if (count !== null) installs[days] = count;
    } catch {
      // A missing Homebrew window is not worth failing the GitHub snapshot for.
    }
  }
  return installs;
}

export type SnapshotResult =
  | { error: string; ok: false }
  | { assets: number; date: string; dmgDownloads: number; homebrew: Partial<Record<number, number>>; ok: true };

export async function collectSnapshots(now = new Date()): Promise<SnapshotResult> {
  const db = getDb();
  if (!db) return { error: "DATABASE_URL is not set", ok: false };

  const { githubRepo, homebrewTap } = getSiteConfig();
  if (!githubRepo) return { error: "No GitHub repository configured", ok: false };

  const date = now.toISOString().slice(0, 10);
  const assets = await fetchAssetCounts(githubRepo);
  if (!assets || assets.length === 0) return { error: "GitHub releases could not be read", ok: false };

  await db
    .insert(githubAssetSnapshots)
    .values(assets.map((row) => ({ ...row, snapshotDate: date })))
    .onConflictDoUpdate({
      set: { capturedAt: sql`now()`, downloadCount: sql`excluded.download_count` },
      target: [githubAssetSnapshots.snapshotDate, githubAssetSnapshots.tag, githubAssetSnapshots.asset],
    });

  const homebrew = await fetchHomebrewInstalls(homebrewTap);
  const homebrewRows = Object.entries(homebrew).map(([days, installs]) => ({
    cask: homebrewTap,
    installs: installs ?? 0,
    periodDays: Number(days),
    snapshotDate: date,
  }));
  if (homebrewRows.length > 0) {
    await db
      .insert(homebrewInstallSnapshots)
      .values(homebrewRows)
      .onConflictDoUpdate({
        set: { capturedAt: sql`now()`, installs: sql`excluded.installs` },
        target: [homebrewInstallSnapshots.snapshotDate, homebrewInstallSnapshots.cask, homebrewInstallSnapshots.periodDays],
      });
  }

  const dmgDownloads = assets.filter((row) => isDmg(row.asset)).reduce((sum, row) => sum + row.downloadCount, 0);
  return { assets: assets.length, date, dmgDownloads, homebrew, ok: true };
}
