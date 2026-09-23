"use client";

import { Analytics, type BeforeSendEvent } from "@vercel/analytics/next";
import { usePathname, useSearchParams } from "next/navigation";
import { useEffect, useRef } from "react";
import { forgetLegacyCookies, trackCustomPageView, trackGooglePageView } from "../lib/analytics/client";
import { applyGoogleAnalytics, CONSENT_CHANGED_EVENT, readStoredConsent } from "../lib/consent/client";

// The owner's own stats page is not site traffic.
const isPrivatePath = (path: string) => path === "/stats" || path.startsWith("/stats/");

function dropPrivatePages(event: BeforeSendEvent) {
  return isPrivatePath(new URL(event.url).pathname) ? null : event;
}

type SiteAnalyticsProps = {
  googleAnalyticsId: string | null;
};

export function SiteAnalytics({ googleAnalyticsId }: SiteAnalyticsProps) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const previousUrlRef = useRef<string | null>(null);

  useEffect(() => {
    forgetLegacyCookies();
  }, []);

  // Google Analytics only with the visitor's consent: applied from the stored choice (before the page
  // view below, so the first view is queued for it) and again whenever the choice changes.
  useEffect(() => {
    const apply = () => {
      const allowed = readStoredConsent()?.google === true;
      applyGoogleAnalytics(googleAnalyticsId, allowed);
      return allowed;
    };
    apply();

    const onChange = () => {
      if (apply()) trackGooglePageView(`${window.location.pathname}${window.location.search}`);
    };
    window.addEventListener(CONSENT_CHANGED_EVENT, onChange);
    return () => window.removeEventListener(CONSENT_CHANGED_EVENT, onChange);
  }, [googleAnalyticsId]);

  useEffect(() => {
    if (isPrivatePath(pathname)) {
      return;
    }

    const query = searchParams.toString();
    const pagePath = query ? `${pathname}?${query}` : pathname;
    const currentUrl = window.location.href;
    const referrer = previousUrlRef.current ?? (document.referrer || null);

    trackCustomPageView(pagePath, referrer);
    previousUrlRef.current = currentUrl;

    // A no-op unless Google Analytics was loaded with consent.
    trackGooglePageView(pagePath);
  }, [pathname, searchParams]);

  return <Analytics beforeSend={dropPrivatePages} />;
}
