"use client";

import { Analytics } from "@vercel/analytics/next";
import Script from "next/script";
import { usePathname, useSearchParams } from "next/navigation";
import { useEffect, useRef } from "react";
import { trackCustomPageView, trackGooglePageView } from "../lib/analytics/client";

type SiteAnalyticsProps = {
  googleAnalyticsId: string | null;
};

export function SiteAnalytics({ googleAnalyticsId }: SiteAnalyticsProps) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const previousUrlRef = useRef<string | null>(null);

  useEffect(() => {
    const query = searchParams.toString();
    const pagePath = query ? `${pathname}?${query}` : pathname;
    const currentUrl = window.location.href;
    const referrer = previousUrlRef.current ?? (document.referrer || null);

    trackCustomPageView(pagePath, referrer);
    previousUrlRef.current = currentUrl;

    if (googleAnalyticsId) {
      trackGooglePageView(pagePath);
    }
  }, [googleAnalyticsId, pathname, searchParams]);

  return (
    <>
      <Analytics />
      {googleAnalyticsId ? (
        <>
          <Script
            src={`https://www.googletagmanager.com/gtag/js?id=${googleAnalyticsId}`}
            strategy="afterInteractive"
          />
          <Script id="google-analytics" strategy="afterInteractive">
            {`
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              window.gtag = gtag;
              gtag('js', new Date());
              gtag('config', '${googleAnalyticsId}', { send_page_view: false });
            `}
          </Script>
        </>
      ) : null}
    </>
  );
}
