import { analyticsDownloads, analyticsPageViews } from "../db/schema";
import { getDb } from "../db/client";
import { isInternalHost, summarizeUserAgent, type DownloadChannel } from "./classify.ts";
import type { DownloadEvent, PageViewEvent } from "./payload.ts";

// The first-party log stores coarse facts only: time, path, referrer host, UTM tags, country,
// browser and OS family, device class and bot/internal flags. No cookies, IP addresses, visitor or
// session IDs, cities or full user agents (see /privacy). The user agent is read to classify the
// request and then dropped.

export type RequestContext = {
  country: string | null;
  internal: boolean;
  userAgent: string | null;
};

function hostOf(url: string): string | null {
  try {
    return new URL(url).host;
  } catch {
    return null;
  }
}

export function getRequestContext(request: Request): RequestContext {
  const host = request.headers.get("x-forwarded-host") ?? request.headers.get("host") ?? hostOf(request.url);
  const country = request.headers.get("x-vercel-ip-country");

  return {
    country: country && /^[A-Z]{2}$/.test(country) ? country : null,
    internal: isInternalHost(host),
    userAgent: request.headers.get("user-agent"),
  };
}

function classification(context: RequestContext, referrerHost: string | null) {
  const summary = summarizeUserAgent(context.userAgent);
  return {
    browser: summary.browser,
    country: context.country,
    device: summary.device,
    isBot: summary.isBot,
    isInternal: context.internal,
    os: summary.os,
    referrerHost,
  };
}

export async function recordPageView(event: PageViewEvent, context: RequestContext) {
  const db = getDb();
  if (!db) {
    return false;
  }

  try {
    await db.insert(analyticsPageViews).values({
      ...classification(context, event.referrerHost),
      path: event.path,
      title: event.title,
      url: event.url,
      utmCampaign: event.utmCampaign,
      utmContent: event.utmContent,
      utmMedium: event.utmMedium,
      utmSource: event.utmSource,
      utmTerm: event.utmTerm,
    });
    return true;
  } catch (error) {
    console.error("[analytics] failed to record page view", error);
    return false;
  }
}

export type DownloadRecord = DownloadEvent & { channel: DownloadChannel };

export async function recordDownload(event: DownloadRecord, context: RequestContext) {
  const db = getDb();
  if (!db) {
    return false;
  }

  try {
    await db.insert(analyticsDownloads).values({
      ...classification(context, event.referrerHost),
      assetKind: event.assetKind,
      channel: event.channel,
      path: event.path,
      releaseTag: event.releaseTag,
      source: event.source,
      targetUrl: event.targetUrl,
    });
    return true;
  } catch (error) {
    console.error("[analytics] failed to record download", error);
    return false;
  }
}
