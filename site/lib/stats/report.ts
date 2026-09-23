// Pure aggregation for /stats: log rows in, table rows out (tests/report.test.ts).
//
// Rows written before the cookieless change carry a full user agent instead of the derived
// columns; they are classified here with the same code, so old and new rows count alike.

import { summarizeUserAgent } from "../analytics/classify.ts";
import { isoWeekStart } from "./snapshots.ts";

export type DownloadRow = {
  channel: string | null;
  createdAt: Date;
  device: string | null;
  isBot: boolean | null;
  isInternal: boolean | null;
  os: string | null;
  releaseTag: string | null;
  userAgent: string | null;
};

export type PageViewRow = {
  country: string | null;
  createdAt: Date;
  device: string | null;
  isBot: boolean | null;
  isInternal: boolean | null;
  path: string;
  referrerHost: string | null;
  userAgent: string | null;
};

export type DownloadClass = "bot" | "direct" | "homebrew" | "internal" | "mac" | "other" | "phone" | "sparkle";

function traits(row: { device: string | null; isBot: boolean | null; os: string | null; userAgent: string | null }) {
  if (row.isBot !== null) return { device: row.device, isBot: row.isBot, os: row.os };
  const summary = summarizeUserAgent(row.userAgent);
  return { device: summary.device, isBot: summary.isBot, os: summary.os };
}

export function classifyDownload(row: DownloadRow): DownloadClass {
  if (row.isInternal) return "internal";
  if (row.channel === "sparkle" || row.channel === "homebrew" || row.channel === "direct") return row.channel;

  const { device, isBot, os } = traits(row);
  if (isBot) return "bot";
  if (device === "mobile" || device === "tablet") return "phone";
  if (os === "macOS" && device === "desktop") return "mac";
  return "other";
}

export type VersionRow = { github: number | null; tag: string } & Record<Exclude<DownloadClass, "internal">, number>;

function compareTags(a: string, b: string) {
  const parts = (tag: string) => tag.replace(/^v/, "").split(".").map(Number);
  const [x, y] = [parts(a), parts(b)];
  for (let i = 0; i < 3; i++) {
    if ((x[i] ?? 0) !== (y[i] ?? 0)) return (y[i] ?? 0) - (x[i] ?? 0);
  }
  return 0;
}

/** Newest version first: GitHub's DMG count next to the site's own log, split by who asked. */
export function versionTable(githubDmg: Map<string, number>, downloads: DownloadRow[]): VersionRow[] {
  const rows = new Map<string, VersionRow>();
  const row = (tag: string) => {
    let existing = rows.get(tag);
    if (!existing) {
      existing = { bot: 0, direct: 0, github: githubDmg.get(tag) ?? null, homebrew: 0, mac: 0, other: 0, phone: 0, sparkle: 0, tag };
      rows.set(tag, existing);
    }
    return existing;
  };

  for (const tag of githubDmg.keys()) row(tag);
  for (const download of downloads) {
    if (!download.releaseTag) continue;
    const kind = classifyDownload(download);
    if (kind !== "internal") row(download.releaseTag)[kind] += 1;
  }

  return [...rows.values()].sort((a, b) => compareTags(a.tag, b.tag));
}

export type Ranked = { count: number; key: string };

function top(counts: Map<string, number>, limit: number): Ranked[] {
  return [...counts.entries()]
    .map(([key, count]) => ({ count, key }))
    .sort((a, b) => b.count - a.count || a.key.localeCompare(b.key))
    .slice(0, limit);
}

export type PageViewSummary = {
  countries: Ranked[];
  paths: Ranked[];
  referrers: Ranked[];
  weekly: { bots: number; people: number; week: string }[];
};

/** People vs bots per ISO week, and the last 30 days' top pages, referrers and countries. */
export function pageViewSummary(rows: PageViewRow[], now: Date, siteHost: string): PageViewSummary {
  const weekly = new Map<string, { bots: number; people: number; week: string }>();
  const paths = new Map<string, number>();
  const referrers = new Map<string, number>();
  const countries = new Map<string, number>();
  const monthAgo = now.getTime() - 30 * 24 * 60 * 60 * 1000;
  const bump = (map: Map<string, number>, key: string) => map.set(key, (map.get(key) ?? 0) + 1);
  // The site answers on both dotviewer.app and www.dotviewer.app; neither is an outside referrer.
  const bare = (host: string) => host.replace(/^www\./, "");
  const site = bare(siteHost);

  for (const row of rows) {
    if (row.isInternal) continue;
    const { isBot } = traits({ ...row, os: null });
    const week = isoWeekStart(row.createdAt.toISOString().slice(0, 10));
    const bucket = weekly.get(week) ?? { bots: 0, people: 0, week };
    if (isBot) bucket.bots += 1;
    else bucket.people += 1;
    weekly.set(week, bucket);

    if (isBot || row.createdAt.getTime() < monthAgo) continue;
    bump(paths, row.path.split("?")[0] || "/");
    if (row.referrerHost && bare(row.referrerHost) !== site) bump(referrers, row.referrerHost);
    if (row.country) bump(countries, row.country);
  }

  return {
    countries: top(countries, 8),
    paths: top(paths, 8),
    referrers: top(referrers, 8),
    weekly: [...weekly.values()].sort((a, b) => a.week.localeCompare(b.week)),
  };
}
