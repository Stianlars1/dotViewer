// The consent rules shared by the banner, the consent endpoint and the analytics log
// (docs/plans/2026-09-23-consent-banner-design.md). Pure: no DOM and no database, so every rule is
// unit-tested (tests/consent.test.ts).
//
// The choice lives in `dv_consent` as `v<version>.s<0|1>.g<0|1>` — dotViewer statistics and Google
// Analytics. `dv_visitor` holds a random ID and exists only while statistics is allowed. Both are set
// by /api/consent, so what the server logs never depends on what a page claims.

export const CONSENT_VERSION = 1;
export const CONSENT_COOKIE = "dv_consent";
export const VISITOR_COOKIE = "dv_visitor";
/** 12 months: how long a choice is remembered before the banner asks again. */
export const CONSENT_MAX_AGE = 365 * 24 * 60 * 60;
/** 13 months: the longest a statistics cookie lives, dotViewer's and Google's alike. */
export const VISITOR_MAX_AGE = 395 * 24 * 60 * 60;

export type ConsentChoice = { google: boolean; statistics: boolean };
export type StoredConsent = ConsentChoice & { version: number };
export type ConsentSource = "banner" | "settings";

const CONSENT_VALUE = /^v(\d{1,3})\.s([01])\.g([01])$/;
const VISITOR_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const SOURCES: readonly ConsentSource[] = ["banner", "settings"];

export function formatConsent(choice: ConsentChoice, version = CONSENT_VERSION): string {
  return `v${version}.s${choice.statistics ? 1 : 0}.g${choice.google ? 1 : 0}`;
}

export function parseConsent(value: string | null | undefined): StoredConsent | null {
  const match = value ? CONSENT_VALUE.exec(value) : null;
  if (!match) return null;
  return { google: match[3] === "1", statistics: match[2] === "1", version: Number(match[1]) };
}

/** A choice made under the current banner. An older version means the banner asks again. */
export function isCurrentConsent(consent: StoredConsent | null): consent is StoredConsent {
  return consent !== null && consent.version === CONSENT_VERSION;
}

/** One cookie's value from a `Cookie` header or `document.cookie`, matched by its exact name. */
export function readCookie(cookieHeader: string | null | undefined, name: string): string | null {
  if (!cookieHeader) return null;
  for (const part of cookieHeader.split(";")) {
    const separator = part.indexOf("=");
    if (separator < 0 || part.slice(0, separator).trim() !== name) continue;
    const value = part.slice(separator + 1).trim();
    try {
      return decodeURIComponent(value);
    } catch {
      return value;
    }
  }
  return null;
}

/** A visitor ID as `crypto.randomUUID()` makes them. Anything else is ignored, not trusted. */
export function isVisitorId(value: string | null | undefined): value is string {
  return typeof value === "string" && VISITOR_ID.test(value);
}

/** The visitor ID to log for a request: only with a current consent to dotViewer statistics. */
export function consentedVisitorId(cookieHeader: string | null | undefined): string | null {
  const consent = parseConsent(readCookie(cookieHeader, CONSENT_COOKIE));
  if (!isCurrentConsent(consent) || !consent.statistics) return null;
  const visitorId = readCookie(cookieHeader, VISITOR_COOKIE);
  return isVisitorId(visitorId) ? visitorId : null;
}

/** The body of a POST to /api/consent: the current version, both choices and where it was made. */
export function parseConsentRequest(raw: unknown): (ConsentChoice & { source: ConsentSource }) | null {
  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) return null;
  const { google, source, statistics, version } = raw as Record<string, unknown>;
  if (version !== CONSENT_VERSION || typeof google !== "boolean" || typeof statistics !== "boolean") return null;
  if (!SOURCES.includes(source as ConsentSource)) return null;
  return { google, source: source as ConsentSource, statistics };
}

/** `Set-Cookie` values for a choice: the choice itself, and the visitor ID set or expired. */
export function consentCookies(choice: ConsentChoice, visitorId: string | null, secure: boolean): string[] {
  const attributes = `Path=/; SameSite=Lax${secure ? "; Secure" : ""}`;
  const consent = `${CONSENT_COOKIE}=${formatConsent(choice)}; ${attributes}; Max-Age=${CONSENT_MAX_AGE}`;
  const visitor =
    choice.statistics && visitorId
      ? `${VISITOR_COOKIE}=${visitorId}; ${attributes}; Max-Age=${VISITOR_MAX_AGE}; HttpOnly`
      : `${VISITOR_COOKIE}=; ${attributes}; Max-Age=0; HttpOnly`;
  return [consent, visitor];
}

/** The banner shows until there is a current choice. Global Privacy Control counts as Reject. */
export function shouldShowBanner(consent: StoredConsent | null, globalPrivacyControl: boolean): boolean {
  return !isCurrentConsent(consent) && !globalPrivacyControl;
}

/**
 * Where a cookie set by this page may live: host-only (`""`) and every parent domain. Deleting a
 * cookie needs the domain it was set with, and Google Analytics picks the widest one it can.
 */
export function cookieDomains(hostname: string): string[] {
  const labels = hostname.split(".");
  if (labels.length < 2 || hostname.includes(":") || /^[\d.]+$/.test(hostname)) return [""];
  return ["", ...labels.slice(0, -1).map((_, index) => `.${labels.slice(index).join(".")}`)];
}

/**
 * Whether a request to /api/consent comes from the site's own pages. Another site must not be able
 * to make a choice for a visitor, so browsers' `Sec-Fetch-Site` has to say same-origin, and without it
 * `Origin`, when sent, has to match the host. Requests from outside a browser send neither.
 */
export function isSameOriginRequest(headers: Headers, requestUrl: string): boolean {
  const site = headers.get("sec-fetch-site");
  if (site) return site === "same-origin";

  const origin = headers.get("origin");
  if (!origin) return true;
  const host = headers.get("x-forwarded-host") ?? headers.get("host") ?? new URL(requestUrl).host;
  try {
    return new URL(origin).host === host;
  } catch {
    return false;
  }
}
