import { consentedVisitorId } from "../consent/consent.ts";
import { isInternalHost } from "./classify.ts";
import { clientIp } from "./day-visitor.ts";

// What the log takes from a request besides the event itself (tests/context.test.ts). The IP and user
// agent are only used to classify the request and make the day code; neither is stored. The visitor
// ID comes from the request's own cookies and only with consent to dotViewer statistics — a page
// cannot supply one.

export type RequestContext = {
  country: string | null;
  internal: boolean;
  ip: string | null;
  userAgent: string | null;
  visitorId: string | null;
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
    ip: clientIp(request.headers),
    userAgent: request.headers.get("user-agent"),
    visitorId: consentedVisitorId(request.headers.get("cookie")),
  };
}
