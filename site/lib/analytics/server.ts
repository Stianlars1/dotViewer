import { analyticsDownloads, analyticsPageViews } from "../db/schema";
import { getDb } from "../db/client";
import { summarizeUserAgent, type DownloadChannel } from "./classify.ts";
import type { RequestContext } from "./context.ts";
import { dayVisitorCode, dbSaltStore, saltFor, utcDay, type SaltStore } from "./day-visitor.ts";
import type { DownloadEvent, PageViewEvent } from "./payload.ts";

// The first-party log stores coarse facts: time, path, referrer host, UTM tags, country, browser
// and OS family, device class, bot/internal flags and a code for the visitor that is valid for one
// UTC day. No cookies are read except the consent ones, and a visitor ID is stored only with consent
// to dotViewer statistics (see /privacy). IP addresses and user agents are never stored.

export { getRequestContext, type RequestContext } from "./context.ts";

let saltStore: SaltStore | null = null;

/** The visitor's code for today, or null when the salt can't be had (the log row is kept anyway). */
async function dayVisitor(context: RequestContext, now = new Date()): Promise<string | null> {
  const db = getDb();
  if (!db) return null;
  saltStore ??= dbSaltStore(db);
  try {
    return dayVisitorCode(await saltFor(saltStore, utcDay(now)), context.ip, context.userAgent);
  } catch (error) {
    console.error("[analytics] no visitor salt", error);
    return null;
  }
}

function classification(context: RequestContext, referrerHost: string | null, dayCode: string | null) {
  const summary = summarizeUserAgent(context.userAgent);
  return {
    browser: summary.browser,
    country: context.country,
    dayVisitor: dayCode,
    device: summary.device,
    isBot: summary.isBot,
    isInternal: context.internal,
    os: summary.os,
    referrerHost,
    visitorId: context.visitorId,
  };
}

export async function recordPageView(event: PageViewEvent, context: RequestContext) {
  const db = getDb();
  if (!db) {
    return false;
  }

  try {
    await db.insert(analyticsPageViews).values({
      ...classification(context, event.referrerHost, await dayVisitor(context)),
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
    // Day codes count website visitors; app updates and Homebrew fetches through /updates are not visits.
    const code = event.channel === "website" ? await dayVisitor(context) : null;
    await db.insert(analyticsDownloads).values({
      ...classification(context, event.referrerHost, code),
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
