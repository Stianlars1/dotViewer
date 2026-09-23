import assert from "node:assert/strict";
import { test } from "node:test";
import { classifyDownload, pageViewSummary, versionTable, type DownloadRow, type PageViewRow } from "../lib/stats/report.ts";

const safariMac =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15";
const iphone =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1";

function download(overrides: Partial<DownloadRow>): DownloadRow {
  return {
    channel: "website",
    createdAt: new Date("2026-09-20T12:00:00Z"),
    device: null,
    isBot: null,
    isInternal: null,
    os: null,
    releaseTag: "v1.5.5",
    userAgent: null,
    ...overrides,
  };
}

test("legacy rows are classified from their user agent, new rows from their columns", () => {
  assert.equal(classifyDownload(download({ userAgent: safariMac })), "mac");
  assert.equal(classifyDownload(download({ userAgent: iphone })), "phone");
  assert.equal(classifyDownload(download({ userAgent: "curl/8.7.1" })), "bot");
  assert.equal(classifyDownload(download({ device: "desktop", isBot: false, os: "macOS" })), "mac");
  assert.equal(classifyDownload(download({ device: "desktop", isBot: false, os: "Windows" })), "other");
  assert.equal(classifyDownload(download({ isInternal: true, userAgent: safariMac })), "internal");
  assert.equal(classifyDownload(download({ channel: "sparkle", isBot: false })), "sparkle");
});

test("the version table puts GitHub's count beside the site's log, newest first", () => {
  const rows = versionTable(
    new Map([
      ["v1.5.5", 46],
      ["v1.5.10", 2],
    ]),
    [
      download({ userAgent: safariMac }),
      download({ userAgent: iphone }),
      download({ isInternal: true, userAgent: safariMac }),
      download({ channel: "homebrew", isBot: false, releaseTag: "v1.5.10" }),
      download({ releaseTag: null, userAgent: safariMac }),
    ],
  );
  assert.deepEqual(
    rows.map((row) => [row.tag, row.github, row.mac, row.phone, row.homebrew]),
    [
      ["v1.5.10", 2, 0, 0, 1],
      ["v1.5.5", 46, 1, 1, 0],
    ],
  );
});

test("page views split people from bots per week and rank the last 30 days", () => {
  const now = new Date("2026-09-23T12:00:00Z");
  const view = (overrides: Partial<PageViewRow>): PageViewRow => ({
    country: "NO",
    createdAt: new Date("2026-09-22T12:00:00Z"),
    device: "desktop",
    isBot: false,
    isInternal: false,
    path: "/",
    referrerHost: null,
    userAgent: null,
    ...overrides,
  });
  const summary = pageViewSummary(
    [
      view({ path: "/download?utm_source=hn", referrerHost: "news.ycombinator.com" }),
      view({ referrerHost: "dotviewer.app" }),
      view({ isBot: true }),
      view({ isInternal: true }),
      view({ createdAt: new Date("2026-07-01T12:00:00Z"), path: "/old" }),
    ],
    now,
    "dotviewer.app",
  );

  assert.deepEqual(summary.weekly, [
    { bots: 0, people: 1, week: "2026-06-29" },
    { bots: 1, people: 2, week: "2026-09-21" },
  ]);
  assert.deepEqual(summary.paths, [
    { count: 1, key: "/" },
    { count: 1, key: "/download" },
  ]);
  assert.deepEqual(summary.referrers, [{ count: 1, key: "news.ycombinator.com" }]);
  assert.deepEqual(summary.countries, [{ count: 2, key: "NO" }]);
});
