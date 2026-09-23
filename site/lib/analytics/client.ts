"use client";

import { track } from "@vercel/analytics";

declare global {
  interface Window {
    dataLayer: unknown[];
    gtag?: (...args: unknown[]) => void;
  }
}

export type DownloadAnalyticsPayload = {
  assetKind: "app_store" | "checksum" | "dmg";
  persistCustomEvent?: boolean;
  releaseTag?: string | null;
  source: string;
  targetUrl: string;
};

const ANALYTICS_ENDPOINT = "/api/analytics";

// Cookies the site set before it went cookieless. Expired on every visit so returning browsers
// drop them; nothing reads them any more.
const LEGACY_COOKIES = ["dv_vid", "dv_sid"];

type AnalyticsEnvelope =
  | {
      path: string;
      referrer: string | null;
      title: string;
      type: "page_view";
      url: string;
      utmCampaign: string | null;
      utmContent: string | null;
      utmMedium: string | null;
      utmSource: string | null;
      utmTerm: string | null;
    }
  | {
      assetKind: "app_store" | "checksum" | "dmg";
      path: string;
      referrer: string | null;
      releaseTag: string | null;
      source: string;
      targetUrl: string;
      type: "download";
    };

export function forgetLegacyCookies() {
  if (typeof document === "undefined") {
    return;
  }

  for (const name of LEGACY_COOKIES) {
    document.cookie = `${name}=; Path=/; Max-Age=0; SameSite=Lax`;
  }
}

function sendAnalyticsEvent(event: AnalyticsEnvelope) {
  if (typeof window === "undefined") {
    return;
  }

  const body = JSON.stringify(event);
  if (typeof navigator.sendBeacon === "function") {
    const payload = new Blob([body], { type: "application/json" });
    if (navigator.sendBeacon(ANALYTICS_ENDPOINT, payload)) {
      return;
    }
  }

  void fetch(ANALYTICS_ENDPOINT, {
    body,
    credentials: "omit",
    headers: {
      "Content-Type": "application/json",
    },
    keepalive: true,
    method: "POST",
  });
}

export function trackGooglePageView(pagePath: string) {
  if (typeof window === "undefined" || typeof window.gtag !== "function") {
    return;
  }

  window.gtag("event", "page_view", {
    page_location: window.location.href,
    page_path: pagePath,
    page_title: document.title,
  });
}

export function trackCustomPageView(pagePath: string, referrer: string | null) {
  const query = new URLSearchParams(window.location.search);

  sendAnalyticsEvent({
    path: pagePath,
    referrer,
    title: document.title,
    type: "page_view",
    url: window.location.href,
    utmCampaign: query.get("utm_campaign"),
    utmContent: query.get("utm_content"),
    utmMedium: query.get("utm_medium"),
    utmSource: query.get("utm_source"),
    utmTerm: query.get("utm_term"),
  });
}

export function trackDownloadClick(payload: DownloadAnalyticsPayload) {
  track("download_clicked", {
    assetKind: payload.assetKind,
    releaseTag: payload.releaseTag ?? undefined,
    source: payload.source,
    targetUrl: payload.targetUrl,
  });

  if (typeof window.gtag === "function") {
    window.gtag("event", "download_click", {
      asset_kind: payload.assetKind,
      download_source: payload.source,
      link_url: payload.targetUrl,
      release_tag: payload.releaseTag ?? undefined,
    });
  }

  // Links through /download/latest are logged by that route; logging the click too would count
  // them twice.
  if (payload.persistCustomEvent === false) {
    return;
  }

  sendAnalyticsEvent({
    assetKind: payload.assetKind,
    path: `${window.location.pathname}${window.location.search}`,
    referrer: document.referrer || null,
    releaseTag: payload.releaseTag ?? null,
    source: payload.source,
    targetUrl: payload.targetUrl,
    type: "download",
  });
}
