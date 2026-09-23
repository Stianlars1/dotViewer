import {
  CONSENT_COOKIE,
  CONSENT_VERSION,
  VISITOR_MAX_AGE,
  cookieDomains,
  isCurrentConsent,
  parseConsent,
  readCookie,
  type ConsentChoice,
  type ConsentSource,
  type StoredConsent,
} from "./consent.ts";

// The browser half of the consent system: reads the choice, sends a new one to /api/consent (which
// sets the cookies) and turns Google Analytics on or off to match. Google's script is not requested
// until the Google choice is on.

/** Fired on `window` after a choice is saved. */
export const CONSENT_CHANGED_EVENT = "dv:consent-changed";
/** Fired on `window` to reopen the choices (Cookie settings). */
export const OPEN_CONSENT_EVENT = "dv:open-consent";

const GA_SCRIPT_ID = "dv-google-analytics";

/** The visitor's current choice, or null when there is none under the current banner version. */
export function readStoredConsent(): StoredConsent | null {
  if (typeof document === "undefined") return null;
  const consent = parseConsent(readCookie(document.cookie, CONSENT_COOKIE));
  return isCurrentConsent(consent) ? consent : null;
}

export function hasGlobalPrivacyControl(): boolean {
  if (typeof navigator === "undefined") return false;
  return (navigator as Navigator & { globalPrivacyControl?: boolean }).globalPrivacyControl === true;
}

/** Sends a choice to /api/consent. True once the cookies are set; false leaves everything as it was. */
export async function saveConsent(choice: ConsentChoice, source: ConsentSource): Promise<boolean> {
  try {
    const response = await fetch("/api/consent", {
      body: JSON.stringify({ google: choice.google, source, statistics: choice.statistics, version: CONSENT_VERSION }),
      credentials: "same-origin",
      headers: { "Content-Type": "application/json" },
      method: "POST",
    });
    if (!response.ok) return false;
  } catch {
    return false;
  }
  window.dispatchEvent(new CustomEvent(CONSENT_CHANGED_EVENT));
  return true;
}

export function openConsentSettings() {
  window.dispatchEvent(new CustomEvent(OPEN_CONSENT_EVENT));
}

/**
 * Loads Google Analytics when allowed. When not, stops it (`ga-disable-<id>`), removes its script and
 * `window.gtag`, and deletes the `_ga` cookies it set.
 */
export function applyGoogleAnalytics(measurementId: string | null, allowed: boolean) {
  if (!measurementId || typeof window === "undefined") return;
  (window as unknown as Record<string, unknown>)[`ga-disable-${measurementId}`] = !allowed;

  if (allowed) {
    if (document.getElementById(GA_SCRIPT_ID)) return;
    window.dataLayer = window.dataLayer || [];
    window.gtag = function gtag() {
      // gtag.js reads the arguments object itself, not an array.
      window.dataLayer.push(arguments);
    };
    window.gtag("js", new Date());
    window.gtag("config", measurementId, { cookie_expires: VISITOR_MAX_AGE, send_page_view: false });

    const script = document.createElement("script");
    script.id = GA_SCRIPT_ID;
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(measurementId)}`;
    document.head.appendChild(script);
    return;
  }

  document.getElementById(GA_SCRIPT_ID)?.remove();
  delete window.gtag;
  const names = document.cookie
    .split(";")
    .map((part) => part.split("=")[0].trim())
    .filter((name) => name === "_ga" || name.startsWith("_ga_"));
  for (const name of names) {
    for (const domain of cookieDomains(window.location.hostname)) {
      document.cookie = `${name}=; Path=/; Max-Age=0${domain ? `; Domain=${domain}` : ""}`;
    }
  }
}
