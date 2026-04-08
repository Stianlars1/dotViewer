import { analyticsDownloads, analyticsPageViews } from "../db/schema";
import { getDb } from "../db/client";

type RequestContext = {
  city: string | null;
  country: string | null;
  referrer: string | null;
  region: string | null;
  requestId: string | null;
  sessionId: string | null;
  userAgent: string | null;
  visitorId: string | null;
};

type PageViewEvent = {
  path: string;
  title: string;
  url: string;
  utmCampaign: string | null;
  utmContent: string | null;
  utmMedium: string | null;
  utmSource: string | null;
  utmTerm: string | null;
};

type DownloadEvent = {
  assetKind: "app_store" | "checksum" | "dmg";
  path: string;
  releaseTag: string | null;
  source: string;
  targetUrl: string;
};

function readCookieValue(cookieHeader: string | null, name: string) {
  if (!cookieHeader) {
    return null;
  }

  const entries = cookieHeader.split(";").map((part) => part.trim());
  const prefix = `${name}=`;
  for (const entry of entries) {
    if (entry.startsWith(prefix)) {
      return decodeURIComponent(entry.slice(prefix.length));
    }
  }

  return null;
}

export function getRequestContext(request: Request): RequestContext {
  const cookieHeader = request.headers.get("cookie");

  return {
    city: request.headers.get("x-vercel-ip-city"),
    country: request.headers.get("x-vercel-ip-country"),
    referrer: request.headers.get("referer"),
    region: request.headers.get("x-vercel-ip-country-region"),
    requestId: request.headers.get("x-vercel-id"),
    sessionId: readCookieValue(cookieHeader, "dv_sid"),
    userAgent: request.headers.get("user-agent"),
    visitorId: readCookieValue(cookieHeader, "dv_vid"),
  };
}

export async function recordPageView(event: PageViewEvent, context: RequestContext) {
  const db = getDb();
  if (!db) {
    return false;
  }

  try {
    await db.insert(analyticsPageViews).values({
      city: context.city,
      country: context.country,
      path: event.path,
      referrer: context.referrer,
      region: context.region,
      requestId: context.requestId,
      sessionId: context.sessionId,
      title: event.title,
      url: event.url,
      userAgent: context.userAgent,
      utmCampaign: event.utmCampaign,
      utmContent: event.utmContent,
      utmMedium: event.utmMedium,
      utmSource: event.utmSource,
      utmTerm: event.utmTerm,
      visitorId: context.visitorId,
    });
    return true;
  } catch (error) {
    console.error("[analytics] failed to record page view", error);
    return false;
  }
}

export async function recordDownload(event: DownloadEvent, context: RequestContext) {
  const db = getDb();
  if (!db) {
    return false;
  }

  try {
    await db.insert(analyticsDownloads).values({
      assetKind: event.assetKind,
      city: context.city,
      country: context.country,
      path: event.path,
      referrer: context.referrer,
      region: context.region,
      releaseTag: event.releaseTag,
      requestId: context.requestId,
      sessionId: context.sessionId,
      source: event.source,
      targetUrl: event.targetUrl,
      userAgent: context.userAgent,
      visitorId: context.visitorId,
    });
    return true;
  } catch (error) {
    console.error("[analytics] failed to record download", error);
    return false;
  }
}
