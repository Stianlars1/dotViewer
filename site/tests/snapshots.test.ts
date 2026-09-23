import assert from "node:assert/strict";
import { test } from "node:test";
import { basicCredentialsMatch, bearerMatches } from "../lib/stats/auth.ts";
import {
  assetCountsFromReleases,
  downloadsInLast,
  homebrewInstallCount,
  isoWeekStart,
  weeklyDownloads,
} from "../lib/stats/snapshots.ts";

test("asset counts come from published releases only", () => {
  const rows = assetCountsFromReleases([
    {
      assets: [
        { download_count: 3, name: "dotViewer-1.5.7.dmg" },
        { download_count: 1, name: "dotViewer-1.5.7.dmg.sha256" },
      ],
      draft: false,
      tag_name: "v1.5.7",
    },
    { assets: [{ download_count: 9, name: "dotViewer-1.6.0.dmg" }], draft: true, tag_name: "v1.6.0" },
    { assets: [{ name: "broken" }], tag_name: "v1.0.0" },
  ]);
  assert.deepEqual(rows, [
    { asset: "dotViewer-1.5.7.dmg", downloadCount: 3, tag: "v1.5.7" },
    { asset: "dotViewer-1.5.7.dmg.sha256", downloadCount: 1, tag: "v1.5.7" },
  ]);
  assert.deepEqual(assetCountsFromReleases({ message: "API rate limit exceeded" }), []);
});

test("Homebrew counts are read from their comma-separated strings", () => {
  const analytics = {
    items: [
      { cask: "codex", count: "79,981", number: 1, percent: "7.20" },
      { cask: "stianlars1/tap/dotviewer", count: "1,018", number: 2330, percent: "0" },
    ],
  };
  assert.equal(homebrewInstallCount(analytics, "stianlars1/tap/dotviewer"), 1018);
  assert.equal(homebrewInstallCount(analytics, "missing/tap/cask"), null);
  assert.equal(homebrewInstallCount({ items: [{ cask: "x", count: "n/a" }] }, "x"), null);
  assert.equal(homebrewInstallCount("<html>", "x"), null);
});

test("ISO weeks start on Monday", () => {
  assert.equal(isoWeekStart("2026-09-23"), "2026-09-21"); // Wednesday
  assert.equal(isoWeekStart("2026-09-21"), "2026-09-21"); // Monday
  assert.equal(isoWeekStart("2026-09-27"), "2026-09-21"); // Sunday
});

test("weekly downloads are the growth of the running total", () => {
  const daily = [
    { date: "2026-09-14", total: 400 },
    { date: "2026-09-20", total: 410 },
    { date: "2026-09-21", total: 412 },
    { date: "2026-09-27", total: 440 },
    { date: "2026-09-29", total: 445 },
  ];
  assert.deepEqual(weeklyDownloads(daily), [
    { downloads: null, week: "2026-09-14" },
    { downloads: 30, week: "2026-09-21" },
    { downloads: 5, week: "2026-09-28" },
  ]);
});

test("recent downloads need a baseline snapshot old enough", () => {
  const daily = [
    { date: "2026-09-01", total: 300 },
    { date: "2026-09-16", total: 400 },
    { date: "2026-09-23", total: 431 },
  ];
  assert.equal(downloadsInLast(daily, 7), 31);
  assert.equal(downloadsInLast(daily, 30), null);
  assert.equal(downloadsInLast([], 7), null);
});

test("stats secrets compare exactly", () => {
  assert.equal(bearerMatches("Bearer s3cret", "s3cret"), true);
  assert.equal(bearerMatches("Bearer s3cre", "s3cret"), false);
  assert.equal(bearerMatches(null, "s3cret"), false);
  assert.equal(bearerMatches("Bearer ", ""), false);

  const header = `Basic ${Buffer.from("stian:pa:ss").toString("base64")}`;
  assert.equal(basicCredentialsMatch(header, "stian", "pa:ss"), true);
  assert.equal(basicCredentialsMatch(header, "stian", "pa"), false);
  assert.equal(basicCredentialsMatch(header, "other", "pa:ss"), false);
  assert.equal(basicCredentialsMatch("Basic !!!", "stian", "pa:ss"), false);
  assert.equal(basicCredentialsMatch(header, "", ""), false);
});
