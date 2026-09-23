"use client";

import type { ReactNode } from "react";
import { openConsentSettings } from "../lib/consent/client";

/** Reopens the consent choices from anywhere on the site (home footer, /privacy). */
export function CookieSettingsButton({ children, className }: { children?: ReactNode; className?: string }) {
  return (
    <button className={className} onClick={openConsentSettings} type="button">
      {children ?? "Cookie settings"}
    </button>
  );
}
