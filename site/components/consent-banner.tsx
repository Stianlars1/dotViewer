"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useId, useRef, useState } from "react";
import { shouldShowBanner, type ConsentChoice, type ConsentSource } from "../lib/consent/consent";
import { hasGlobalPrivacyControl, OPEN_CONSENT_EVENT, readStoredConsent, saveConsent } from "../lib/consent/client";
import styles from "./consent-banner.module.css";

// The consent card (docs/plans/2026-09-23-consent-banner-design.md). Shown until a choice is made,
// except to browsers sending Global Privacy Control, which count as Reject. Reject and Accept are the
// same size and style; Choose… offers the two purposes separately. Cookie settings reopens it there.

type View = "choose" | "summary";

const NOTHING: ConsentChoice = { google: false, statistics: false };

export function ConsentBanner({ googleAnalyticsId }: { googleAnalyticsId: string | null }) {
  const pathname = usePathname();
  const hasGoogle = Boolean(googleAnalyticsId);
  const panelRef = useRef<HTMLElement>(null);
  const statisticsId = useId();
  const googleId = useId();
  const [open, setOpen] = useState(false);
  const [view, setView] = useState<View>("summary");
  const [source, setSource] = useState<ConsentSource>("banner");
  const [choice, setChoice] = useState<ConsentChoice>(NOTHING);
  const [saving, setSaving] = useState(false);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (shouldShowBanner(readStoredConsent(), hasGlobalPrivacyControl())) {
      setOpen(true);
    }

    const reopen = () => {
      const stored = readStoredConsent();
      setChoice(stored ? { google: stored.google, statistics: stored.statistics } : NOTHING);
      setSource("settings");
      setView("choose");
      setFailed(false);
      setOpen(true);
      // Asked for by the visitor, so the choices take focus; the first-visit card never does.
      requestAnimationFrame(() => panelRef.current?.focus());
    };
    window.addEventListener(OPEN_CONSENT_EVENT, reopen);
    return () => window.removeEventListener(OPEN_CONSENT_EVENT, reopen);
  }, []);

  // The owner's stats page is not part of the public site.
  if (!open || pathname === "/stats" || pathname.startsWith("/stats/")) return null;

  const save = async (next: ConsentChoice) => {
    setSaving(true);
    setFailed(false);
    const saved = await saveConsent({ google: hasGoogle && next.google, statistics: next.statistics }, source);
    setSaving(false);
    if (saved) setOpen(false);
    else setFailed(true);
  };

  const cookieUse = hasGoogle ? "to see if you come back, and Google Analytics" : "to see if you come back";

  return (
    <section aria-label="Cookie choices" className={styles.banner} ref={panelRef} tabIndex={-1}>
      {view === "summary" ? (
        <>
          <p className={styles.text}>
            dotViewer counts visits without cookies. With your OK it also uses cookies {cookieUse}.{" "}
            <Link href="/privacy#cookies">Details</Link>
          </p>
          <div className={styles.actions}>
            <button className={styles.button} disabled={saving} onClick={() => save(NOTHING)} type="button">
              Reject
            </button>
            <button
              className={styles.button}
              disabled={saving}
              onClick={() => save({ google: true, statistics: true })}
              type="button"
            >
              Accept
            </button>
          </div>
          <button className={styles.textButton} disabled={saving} onClick={() => setView("choose")} type="button">
            Choose…
          </button>
        </>
      ) : (
        <>
          <h2 className={styles.title}>Cookie choices</h2>
          <label className={styles.option}>
            <span>
              <strong id={`${statisticsId}-name`}>dotViewer statistics</strong>
              <small id={`${statisticsId}-about`}>
                A random ID in a cookie for 13 months, used only on dotViewer&apos;s own server to see if you come back.
              </small>
            </span>
            <input
              aria-describedby={`${statisticsId}-about`}
              aria-labelledby={`${statisticsId}-name`}
              checked={choice.statistics}
              className={styles.switch}
              onChange={(event) => setChoice({ ...choice, statistics: event.target.checked })}
              role="switch"
              type="checkbox"
            />
          </label>
          {hasGoogle ? (
            <label className={styles.option}>
              <span>
                <strong id={`${googleId}-name`}>Google Analytics</strong>
                <small id={`${googleId}-about`}>Google&apos;s cookies for 13 months. Google receives your visits to this site.</small>
              </span>
              <input
                aria-describedby={`${googleId}-about`}
                aria-labelledby={`${googleId}-name`}
                checked={choice.google}
                className={styles.switch}
                onChange={(event) => setChoice({ ...choice, google: event.target.checked })}
                role="switch"
                type="checkbox"
              />
            </label>
          ) : null}
          <div className={styles.actions}>
            <button className={styles.button} disabled={saving} onClick={() => save(choice)} type="button">
              Save
            </button>
            {source === "settings" ? (
              <button className={styles.secondary} disabled={saving} onClick={() => setOpen(false)} type="button">
                Cancel
              </button>
            ) : null}
          </div>
          <p className={styles.details}>
            <Link href="/privacy#cookies">What each cookie does</Link>
          </p>
        </>
      )}
      {failed ? (
        <p className={styles.error} role="status">
          Your choice couldn&apos;t be saved. Please try again.
        </p>
      ) : null}
    </section>
  );
}
