import assert from "node:assert/strict";
import { test } from "node:test";
import { parseAnalyticsPayload } from "../lib/analytics/payload.ts";

const pageView = {
  path: "/download?utm_source=hn",
  referrer: "https://news.ycombinator.com/item?id=42",
  title: "Download dotViewer",
  type: "page_view",
  url: "https://dotviewer.app/download?utm_source=hn",
  utmCampaign: null,
  utmContent: null,
  utmMedium: null,
  utmSource: "hn",
  utmTerm: null,
};

test("a page view keeps the referrer host only", () => {
  const parsed = parseAnalyticsPayload(pageView);
  assert.equal(parsed?.type, "page_view");
  assert.equal(parsed?.type === "page_view" && parsed.event.referrerHost, "news.ycombinator.com");
  assert.equal(parsed?.type === "page_view" && parsed.event.utmSource, "hn");
});

test("identifiers sent by old cached pages are ignored, not stored", () => {
  const parsed = parseAnalyticsPayload({ ...pageView, sessionId: "s", visitorId: "v" });
  assert.ok(parsed);
  assert.equal("visitorId" in parsed.event, false);
  assert.equal("sessionId" in parsed.event, false);
});

test("page and download addresses are stored without query strings or fragments", () => {
  const parsed = parseAnalyticsPayload({
    ...pageView,
    path: "/download?utm_source=hn&fbclid=IwAR0abc#top",
    url: "https://dotviewer.app/download?utm_source=hn&fbclid=IwAR0abc#top",
  });
  assert.equal(parsed?.type === "page_view" && parsed.event.path, "/download");
  assert.equal(parsed?.type === "page_view" && parsed.event.url, "https://dotviewer.app/download");
  // Campaign tags arrive in their own fields, so they survive.
  assert.equal(parsed?.type === "page_view" && parsed.event.utmSource, "hn");

  const click = parseAnalyticsPayload({ ...download, path: "/download?gclid=abc" });
  assert.equal(click?.type === "download" && click.event.path, "/download");
});

test("page views need a site path and a web URL", () => {
  assert.equal(parseAnalyticsPayload({ ...pageView, path: "download" }), null);
  assert.equal(parseAnalyticsPayload({ ...pageView, url: "javascript:alert(1)" }), null);
});

const download = {
  assetKind: "checksum",
  path: "/download",
  referrer: null,
  releaseTag: "v1.5.7",
  source: "download_page_latest_checksum",
  targetUrl: "https://github.com/Stianlars1/dotViewer/releases/download/v1.5.7/dotViewer-1.5.7.dmg.sha256",
  type: "download",
};

test("a download event is validated and its source sanitised", () => {
  const parsed = parseAnalyticsPayload({ ...download, source: "x'; DROP TABLE t;--" });
  assert.equal(parsed?.type, "download");
  assert.equal(parsed?.type === "download" && parsed.event.source, "other");
  assert.equal(parsed?.type === "download" && parsed.event.releaseTag, "v1.5.7");
});

test("unknown asset kinds and malformed tags are refused or dropped", () => {
  assert.equal(parseAnalyticsPayload({ ...download, assetKind: "exe" }), null);
  const parsed = parseAnalyticsPayload({ ...download, releaseTag: "latest" });
  assert.equal(parsed?.type === "download" && parsed.event.releaseTag, null);
});

test("anything that is not an event is refused", () => {
  for (const raw of [null, "page_view", [], { type: "other" }, 42]) {
    assert.equal(parseAnalyticsPayload(raw), null);
  }
});
