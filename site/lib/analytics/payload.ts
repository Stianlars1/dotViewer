// Validation for the beacons posted to /api/analytics. Everything is re-derived or length-checked
// here; fields the site no longer stores (visitorId and sessionId, still sent by pages cached
// before the cookieless change) are ignored rather than rejected.

import { referrerHost, sanitizeSource } from "./classify.ts";

export type AssetKind = "app_store" | "checksum" | "dmg";

export type PageViewEvent = {
  path: string;
  referrerHost: string | null;
  title: string;
  url: string;
  utmCampaign: string | null;
  utmContent: string | null;
  utmMedium: string | null;
  utmSource: string | null;
  utmTerm: string | null;
};

export type DownloadEvent = {
  assetKind: AssetKind;
  path: string;
  referrerHost: string | null;
  releaseTag: string | null;
  source: string;
  targetUrl: string;
};

export type AnalyticsEvent =
  | { event: DownloadEvent; type: "download" }
  | { event: PageViewEvent; type: "page_view" };

export const MAX_PAYLOAD_BYTES = 8 * 1024;

const ASSET_KINDS: readonly AssetKind[] = ["app_store", "checksum", "dmg"];
const RELEASE_TAG = /^v?\d{1,3}\.\d{1,3}\.\d{1,3}$/;

type Fields = Record<string, unknown>;

function text(fields: Fields, key: string, max: number): string | null {
  const value = fields[key];
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed ? trimmed.slice(0, max) : null;
}

/**
 * An address without its query string and fragment. Those can carry per-click IDs such as fbclid or
 * gclid; campaign tags arrive in their own fields, so nothing the log keeps is lost.
 */
function withoutQuery(value: string): string {
  const end = value.search(/[?#]/);
  return end === -1 ? value : value.slice(0, end);
}

function isWebUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}

function parsePageView(fields: Fields): PageViewEvent | null {
  const path = text(fields, "path", 2048);
  const url = text(fields, "url", 2048);
  if (!path?.startsWith("/") || !url || !isWebUrl(url)) return null;

  return {
    path: withoutQuery(path),
    referrerHost: referrerHost(text(fields, "referrer", 2048)),
    title: text(fields, "title", 512) ?? "",
    url: withoutQuery(url),
    utmCampaign: text(fields, "utmCampaign", 128),
    utmContent: text(fields, "utmContent", 128),
    utmMedium: text(fields, "utmMedium", 128),
    utmSource: text(fields, "utmSource", 128),
    utmTerm: text(fields, "utmTerm", 128),
  };
}

function parseDownload(fields: Fields): DownloadEvent | null {
  const assetKind = fields.assetKind;
  const path = text(fields, "path", 2048);
  const targetUrl = text(fields, "targetUrl", 2048);
  if (!ASSET_KINDS.includes(assetKind as AssetKind) || !path?.startsWith("/") || !targetUrl) return null;
  if (!targetUrl.startsWith("/") && !isWebUrl(targetUrl)) return null;

  const releaseTag = text(fields, "releaseTag", 64);
  return {
    assetKind: assetKind as AssetKind,
    path: withoutQuery(path),
    referrerHost: referrerHost(text(fields, "referrer", 2048)),
    releaseTag: releaseTag && RELEASE_TAG.test(releaseTag) ? releaseTag : null,
    source: sanitizeSource(text(fields, "source", 128)),
    targetUrl,
  };
}

/** A valid page-view or download event, or null for anything else. */
export function parseAnalyticsPayload(raw: unknown): AnalyticsEvent | null {
  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) return null;
  const fields = raw as Fields;

  if (fields.type === "page_view") {
    const event = parsePageView(fields);
    return event ? { event, type: "page_view" } : null;
  }
  if (fields.type === "download") {
    const event = parseDownload(fields);
    return event ? { event, type: "download" } : null;
  }
  return null;
}
