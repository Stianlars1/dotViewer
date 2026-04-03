"use client";

import { Analytics } from "@vercel/analytics/next";
import Script from "next/script";
import { usePathname, useSearchParams } from "next/navigation";
import { useEffect } from "react";
import { trackGooglePageView } from "../lib/analytics/client";

type SiteAnalyticsProps = {
  googleAnalyticsId: string | null;
};

export function SiteAnalytics({ googleAnalyticsId }: SiteAnalyticsProps) {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  useEffect(() => {
    if (!googleAnalyticsId) {
      return;
    }

    const query = searchParams.toString();
    const pagePath = query ? `${pathname}?${query}` : pathname;
    trackGooglePageView(pagePath);
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
