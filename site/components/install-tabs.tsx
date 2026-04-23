"use client";

import { useCallback, useEffect, useId, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { TrackedDownloadLink } from "./tracked-download-link";
import { easeOutExpo } from "../lib/motion";
import styles from "./install-tabs.module.css";

type InstallTabsProps = {
  homebrewCommand: string;
  homebrewTapUrl: string;
  directDownloadUrl: string;
  appStoreUrl: string | null;
  releasesUrl: string | null;
  releaseTag: string | null;
  source: string;
};

type TabKey = "homebrew" | "dmg" | "app-store";

export function InstallTabs({
  homebrewCommand,
  homebrewTapUrl,
  directDownloadUrl,
  appStoreUrl,
  releasesUrl,
  releaseTag,
  source,
}: InstallTabsProps) {
  const [active, setActive] = useState<TabKey>("homebrew");
  const [copied, setCopied] = useState(false);
  const baseId = useId();

  const handleCopy = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(homebrewCommand);
      setCopied(true);
    } catch {
      // Silent fallback: selection fallback could be added if needed.
    }
  }, [homebrewCommand]);

  useEffect(() => {
    if (!copied) return;
    const timer = window.setTimeout(() => setCopied(false), 1800);
    return () => window.clearTimeout(timer);
  }, [copied]);

  const tabs: { key: TabKey; label: string; meta: string }[] = [
    { key: "homebrew", label: "Homebrew", meta: "brew" },
    { key: "dmg", label: "Direct DMG", meta: "free" },
    ...(appStoreUrl ? [{ key: "app-store" as TabKey, label: "App Store", meta: "paid" }] : []),
  ];

  return (
    <div className={styles.root}>
      <div
        role="tablist"
        aria-label="dotViewer install options"
        className={styles.tablist}
      >
        {tabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            role="tab"
            id={`${baseId}-tab-${tab.key}`}
            aria-selected={active === tab.key}
            aria-controls={`${baseId}-panel-${tab.key}`}
            tabIndex={active === tab.key ? 0 : -1}
            className={styles.tab}
            onClick={() => setActive(tab.key)}
          >
            <span>{tab.label}</span>
            <span className={styles.tabMeta}>{tab.meta}</span>
          </button>
        ))}
      </div>

      <AnimatePresence mode="wait" initial={false}>
        {active === "homebrew" ? (
          <motion.div
            key="homebrew"
            role="tabpanel"
            id={`${baseId}-panel-homebrew`}
            aria-labelledby={`${baseId}-tab-homebrew`}
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.22, ease: easeOutExpo }}
            className={styles.panel}
          >
            <h3 className={styles.panelTitle}>Install with Homebrew</h3>
            <p className={styles.panelBody}>
              Paste this into Terminal. Homebrew downloads the notarized DMG,
              copies dotViewer into <code>/Applications</code>, and registers the
              Quick Look extensions automatically.
            </p>

            <div className={styles.commandRow}>
              <div className={styles.commandText}>
                <span className={styles.commandSigil}>$</span>
                <span>{homebrewCommand}</span>
              </div>
              <button
                type="button"
                className={styles.copyButton}
                onClick={handleCopy}
                data-copied={copied}
                aria-live="polite"
              >
                <AnimatePresence mode="wait" initial={false}>
                  {copied ? (
                    <motion.span
                      key="copied"
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.8 }}
                      transition={{ duration: 0.2, ease: easeOutExpo }}
                      style={{ display: "inline-flex", alignItems: "center", gap: 6 }}
                    >
                      <CheckIcon className={styles.copyIcon} />
                      Copied
                    </motion.span>
                  ) : (
                    <motion.span
                      key="copy"
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.8 }}
                      transition={{ duration: 0.2, ease: easeOutExpo }}
                      style={{ display: "inline-flex", alignItems: "center", gap: 6 }}
                    >
                      <CopyIcon className={styles.copyIcon} />
                      Copy
                    </motion.span>
                  )}
                </AnimatePresence>
              </button>
            </div>

            <p className={styles.note}>
              New to Homebrew?{" "}
              <a href="https://brew.sh" target="_blank" rel="noopener noreferrer">
                brew.sh
              </a>{" "}
              has the one-line installer. Cask source lives at{" "}
              <a href={homebrewTapUrl} target="_blank" rel="noopener noreferrer">
                {homebrewTapUrl.replace(/^https:\/\//, "")}
              </a>
              .
            </p>
          </motion.div>
        ) : null}

        {active === "dmg" ? (
          <motion.div
            key="dmg"
            role="tabpanel"
            id={`${baseId}-panel-dmg`}
            aria-labelledby={`${baseId}-tab-dmg`}
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.22, ease: easeOutExpo }}
            className={styles.panel}
          >
            <h3 className={styles.panelTitle}>Download the notarized DMG</h3>
            <p className={styles.panelBody}>
              Signed with a Developer ID certificate and Apple-notarized. Drag
              dotViewer into <code>Applications</code> and launch it once —
              Quick Look registers the extension automatically.
            </p>
            <div className={styles.actions}>
              <TrackedDownloadLink
                assetKind="dmg"
                className={styles.primary}
                persistCustomEvent={false}
                releaseTag={releaseTag}
                source={source}
                targetUrl={directDownloadUrl}
              >
                Get the free DMG
              </TrackedDownloadLink>
              {releasesUrl ? (
                <a className={styles.ghost} href={releasesUrl}>
                  View GitHub releases
                </a>
              ) : null}
            </div>
            <p className={styles.note}>
              Gatekeeper-friendly on a normal Mac. macOS 13+, universal binary.
            </p>
          </motion.div>
        ) : null}

        {active === "app-store" && appStoreUrl ? (
          <motion.div
            key="app-store"
            role="tabpanel"
            id={`${baseId}-panel-app-store`}
            aria-labelledby={`${baseId}-tab-app-store`}
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.22, ease: easeOutExpo }}
            className={styles.panel}
          >
            <h3 className={styles.panelTitle}>Buy on the App Store</h3>
            <p className={styles.panelBody}>
              Prefer store-managed installation, Apple billing, and automatic
              updates? The paid App Store route is how you support ongoing
              development.
            </p>
            <div className={styles.actions}>
              <TrackedDownloadLink
                assetKind="app_store"
                className={styles.primary}
                releaseTag={null}
                source={`${source}_app_store`}
                targetUrl={appStoreUrl}
              >
                Open the App Store
              </TrackedDownloadLink>
            </div>
            <p className={styles.note}>
              Same app, same extensions, store-managed updates.
            </p>
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  );
}

function CopyIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
      <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
    </svg>
  );
}

function CheckIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.4"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M20 6L9 17l-5-5" />
    </svg>
  );
}
