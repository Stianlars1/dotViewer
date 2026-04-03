"use client";

import { track } from "@vercel/analytics";

declare global {
  interface Window {
    dataLayer: unknown[];
    gtag?: (...args: unknown[]) => void;
  }
}

export type DownloadAnalyticsPayload = {
  assetKind: "dmg" | "checksum";
  releaseTag?: string | null;
  source: string;
  targetUrl: string;
};

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
}
