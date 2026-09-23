// Pure parsing and arithmetic for the download snapshots: no network, no database, so the numbers
// on /stats can be tested (tests/snapshots.test.ts).

export type AssetCount = {
  asset: string;
  downloadCount: number;
  tag: string;
};

type GitHubReleaseJson = {
  assets?: { download_count?: unknown; name?: unknown }[];
  draft?: unknown;
  tag_name?: unknown;
};

/** One row per asset of every published release, from GitHub's releases API. */
export function assetCountsFromReleases(releases: unknown): AssetCount[] {
  if (!Array.isArray(releases)) return [];

  const rows: AssetCount[] = [];
  for (const release of releases as GitHubReleaseJson[]) {
    if (release.draft === true || typeof release.tag_name !== "string") continue;
    for (const asset of release.assets ?? []) {
      if (typeof asset.name !== "string" || typeof asset.download_count !== "number") continue;
      rows.push({ asset: asset.name.slice(0, 255), downloadCount: asset.download_count, tag: release.tag_name.slice(0, 64) });
    }
  }
  return rows;
}

/**
 * The cask's install count from one of formulae.brew.sh's analytics files
 * (`/api/analytics/cask-install/{30,90,365}d.json`), whose counts are strings such as "1,234".
 * Null when the file is malformed or does not list the cask.
 */
export function homebrewInstallCount(analytics: unknown, cask: string): number | null {
  if (analytics === null || typeof analytics !== "object") return null;
  const items = (analytics as { items?: unknown }).items;
  if (!Array.isArray(items)) return null;

  const item = items.find((entry) => (entry as { cask?: unknown })?.cask === cask) as { count?: unknown } | undefined;
  if (typeof item?.count !== "string" && typeof item?.count !== "number") return null;

  const count = Number(String(item.count).replace(/,/g, ""));
  return Number.isInteger(count) && count >= 0 ? count : null;
}

export const isDmg = (asset: string) => asset.toLowerCase().endsWith(".dmg");

export type DailyTotal = { date: string; total: number };

/** Monday of the ISO week containing `date` (YYYY-MM-DD, UTC). */
export function isoWeekStart(date: string): string {
  const day = new Date(`${date}T00:00:00Z`);
  const offset = (day.getUTCDay() + 6) % 7;
  day.setUTCDate(day.getUTCDate() - offset);
  return day.toISOString().slice(0, 10);
}

export type WeeklyDownloads = { downloads: number | null; week: string };

/**
 * Downloads per ISO week from daily running totals: the last total of each week minus the last
 * total of the week before. The first week has no baseline, so its count is null.
 */
export function weeklyDownloads(daily: DailyTotal[]): WeeklyDownloads[] {
  const lastOfWeek = new Map<string, DailyTotal>();
  for (const day of [...daily].sort((a, b) => a.date.localeCompare(b.date))) {
    lastOfWeek.set(isoWeekStart(day.date), day);
  }

  const weeks = [...lastOfWeek.entries()].sort(([a], [b]) => a.localeCompare(b));
  return weeks.map(([week, day], index) => ({
    downloads: index === 0 ? null : Math.max(0, day.total - weeks[index - 1][1].total),
    week,
  }));
}

/** Downloads in the `days` before the latest snapshot, or null without a snapshot that old. */
export function downloadsInLast(daily: DailyTotal[], days: number): number | null {
  if (daily.length === 0) return null;
  const sorted = [...daily].sort((a, b) => a.date.localeCompare(b.date));
  const latest = sorted[sorted.length - 1];

  const cutoff = new Date(`${latest.date}T00:00:00Z`);
  cutoff.setUTCDate(cutoff.getUTCDate() - days);
  const baseline = [...sorted].reverse().find((day) => new Date(`${day.date}T00:00:00Z`) <= cutoff);
  return baseline ? Math.max(0, latest.total - baseline.total) : null;
}
