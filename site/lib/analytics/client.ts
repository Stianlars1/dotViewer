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
const SESSION_COOKIE = "dv_sid";
const VISITOR_COOKIE = "dv_vid";
const VISITOR_COOKIE_MAX_AGE = 60 * 60 * 24 * 365 * 2;

type AnalyticsEnvelope =
  | {
      path: string;
      referrer: string | null;
      sessionId: string;
      title: string;
      type: "page_view";
      url: string;
      utmCampaign: string | null;
      utmContent: string | null;
      utmMedium: string | null;
      utmSource: string | null;
      utmTerm: string | null;
      visitorId: string;
    }
  | {
      assetKind: "app_store" | "checksum" | "dmg";
      path: string;
      referrer: string | null;
      releaseTag: string | null;
      sessionId: string;
      source: string;
      targetUrl: string;
      type: "download";
      visitorId: string;
    };

function readCookie(name: string) {
  if (typeof document === "undefined") {
    return null;
  }

  const prefix = `${name}=`;
  const parts = document.cookie.split(";").map((part) => part.trim());
  for (const part of parts) {
    if (part.startsWith(prefix)) {
      return decodeURIComponent(part.slice(prefix.length));
    }
  }

  return null;
}

function writeCookie(name: string, value: string, maxAge?: number) {
  if (typeof document === "undefined") {
    return;
  }

  const parts = [`${name}=${encodeURIComponent(value)}`, "Path=/", "SameSite=Lax"];
  if (maxAge) {
    parts.push(`Max-Age=${maxAge}`);
  }

  document.cookie = parts.join("; ");
}

function ensureCookie(name: string, options?: { maxAge?: number }) {
  const existing = readCookie(name);
  if (existing) {
    return existing;
  }

  const value = crypto.randomUUID();
  writeCookie(name, value, options?.maxAge);
  return value;
}

function getVisitorSessionIds() {
  return {
    sessionId: ensureCookie(SESSION_COOKIE),
    visitorId: ensureCookie(VISITOR_COOKIE, { maxAge: VISITOR_COOKIE_MAX_AGE }),
  };
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
    credentials: "same-origin",
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
  const { sessionId, visitorId } = getVisitorSessionIds();

  sendAnalyticsEvent({
    path: pagePath,
    referrer,
    sessionId,
    title: document.title,
    type: "page_view",
    url: window.location.href,
    utmCampaign: query.get("utm_campaign"),
    utmContent: query.get("utm_content"),
    utmMedium: query.get("utm_medium"),
    utmSource: query.get("utm_source"),
    utmTerm: query.get("utm_term"),
    visitorId,
  });
}

export function trackDownloadClick(payload: DownloadAnalyticsPayload) {
  track("download_clicked", {
    assetKind: payload.assetKind,
    releaseTag: payload.releaseTag ?? undefined,
    source: payload.source,
    targetUrl: payload.targetUrl,
  });

  if (typeof window.gtag !== "function") {
    return;
  }

  window.gtag("event", "download_click", {
    asset_kind: payload.assetKind,
    download_source: payload.source,
    link_url: payload.targetUrl,
    release_tag: payload.releaseTag ?? undefined,
  });

  if (payload.persistCustomEvent === false) {
    return;
  }

  const { sessionId, visitorId } = getVisitorSessionIds();
  sendAnalyticsEvent({
    assetKind: payload.assetKind,
    path: `${window.location.pathname}${window.location.search}`,
    referrer: document.referrer || null,
    releaseTag: payload.releaseTag ?? null,
    sessionId,
    source: payload.source,
    targetUrl: payload.targetUrl,
    type: "download",
    visitorId,
  });
}
