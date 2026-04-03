"use client";

import type { ReactNode } from "react";
import { trackDownloadClick, type DownloadAnalyticsPayload } from "../lib/analytics/client";

type TrackedDownloadLinkProps = DownloadAnalyticsPayload & {
  children: ReactNode;
  className?: string;
};

export function TrackedDownloadLink({
  assetKind,
  children,
  className,
  persistCustomEvent,
  releaseTag,
  source,
  targetUrl,
}: TrackedDownloadLinkProps) {
  return (
    <a
      className={className}
      href={targetUrl}
      onClick={() =>
        trackDownloadClick({
          assetKind,
          persistCustomEvent,
          releaseTag,
          source,
          targetUrl,
        })
      }
    >
      {children}
    </a>
  );
}
