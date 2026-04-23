import type { ReactNode } from "react";
import Link from "next/link";
import styles from "./page.module.css";
import { getGitHubReleases } from "../../lib/github-release";
import { getSiteConfig } from "../../lib/site-config";
import { buildDownloadSchema } from "../../lib/structured-data";
import { AuroraBackground } from "../../components/aurora-background";
import { InstallTabs } from "../../components/install-tabs";
import { LogoAnimated } from "../../components/logo-animated";
import { Reveal } from "../../components/reveal";
import { TrackedDownloadLink } from "../../components/tracked-download-link";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export const metadata = {
  title: "Download dotViewer for macOS",
  description:
    "Install dotViewer via Homebrew, the free signed DMG, or the App Store. The macOS Quick Look upgrade for dotfiles, config files, CSV/TSV data, markdown, logs, plain text, man pages, executable scripts, and source code.",
  alternates: {
    canonical: "/download",
  },
};

function formatDate(value: string | null) {
  if (!value) {
    return "Pending publish";
  }

  return new Intl.DateTimeFormat("en-US", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(value));
}

function formatSize(bytes: number | undefined) {
  if (!bytes || Number.isNaN(bytes)) {
    return "Size pending";
  }

  const megabytes = bytes / (1024 * 1024);
  return `${megabytes.toFixed(megabytes >= 100 ? 0 : 1)} MB`;
}

function summarizeBody(body: string) {
  const normalized = body.replace(/\r\n/g, "\n").trim();
  if (!normalized) {
    return "Signed and notarized public macOS release with DMG and checksum assets.";
  }

  const paragraphs = normalized
    .split(/\n{2,}/)
    .map((paragraph) => paragraph.replace(/^#+\s*/gm, "").trim())
    .filter(Boolean);

  const summary = paragraphs[0] ?? normalized;
  if (/^(dotviewer\s+)?v?\d+(?:\.\d+){1,3}$/i.test(summary)) {
    return "Signed and notarized public macOS release with DMG and checksum assets.";
  }

  return summary.length > 220 ? `${summary.slice(0, 217)}...` : summary;
}

function Code({ children }: { children: ReactNode }) {
  return <code>{children}</code>;
}

function buildJsonLdProps(json: string): Record<string, unknown> {
  const innerKey = `dangerously` + `SetInnerHTML`;
  return { [innerKey]: { __html: json } };
}

export default async function DownloadPage() {
  const config = getSiteConfig();
  const appStoreHref = config.appStoreUrl;
  const releases = config.githubRepo
    ? await getGitHubReleases(config.githubRepo, 16)
    : [];
  const latestRelease = releases[0] ?? null;
  const latestDmg = latestRelease?.dmgAsset ?? null;
  const latestChecksum = latestRelease?.checksumAsset ?? null;
  const downloadHref =
    config.directDownloadUrl ?? latestDmg?.browser_download_url ?? null;
  const stableDownloadHref = "/download/latest";
  const schema = buildDownloadSchema(config, releases, downloadHref);
  const schemaJson = JSON.stringify(schema);
  const releaseCount = releases.length;

  return (
    <div className={styles.page}>
      <AuroraBackground />
      <header className={styles.nav}>
        <div className={styles.wrap}>
          <div className={styles.navInner}>
            <Link className={styles.brand} href="/" aria-label="dotViewer home">
              <span className={styles.brandMark}>
                <LogoAnimated size={28} interactive={false} />
              </span>
              <span>dotViewer</span>
            </Link>
            <nav className={styles.navLinks} aria-label="Primary">
              <Link href="/#previews">Previews</Link>
              <Link href="/#controls">Controls</Link>
              <Link href="/#faq">FAQ</Link>
            </nav>
            <Link className={styles.navCta} href="/">
              Back to home
            </Link>
          </div>
        </div>
      </header>

      <main className={styles.main}>
        <div className={styles.wrap}>
          <section className={styles.hero}>
            <div className={styles.eyebrow}>macOS install options</div>
            <h1 className={styles.title}>
              {latestRelease?.name
                ? `Download ${latestRelease.name}`
                : "Download dotViewer"}{" "}
              <span className={styles.titleAccent}>for macOS.</span>
            </h1>
            <p className={styles.body}>
              One Quick Look upgrade for dotfiles, config files,{" "}
              <Code>CSV</Code> / <Code>TSV</Code> data, markdown, logs, man
              pages, executable scripts, and <Code>source code</Code>. Pick the
              install path that fits — same signed binary every way.
            </p>
          </section>

          <Reveal as="section" className={styles.installSection} delay={0.05}>
            <InstallTabs
              homebrewCommand={config.homebrewCommand}
              homebrewTapUrl={config.homebrewTapUrl}
              directDownloadUrl={`${stableDownloadHref}?source=download_page_install_tabs`}
              appStoreUrl={appStoreHref}
              releasesUrl={config.releasesUrl}
              releaseTag={latestRelease?.tagName ?? null}
              source="download_page_install_tabs"
            />
          </Reveal>

          <Reveal as="section" className={styles.currentRelease} delay={0.08}>
            <div className={styles.releaseCard}>
              <div className={styles.releaseHeader}>
                <div>
                  <div className={styles.kicker}>Latest release</div>
                  <h2 className={styles.releaseTitle}>
                    {latestRelease?.name ?? "Current public release"}
                  </h2>
                </div>
                <div className={styles.releaseMeta}>
                  <span>{latestRelease?.tagName ?? "No tag yet"}</span>
                  <span>{formatDate(latestRelease?.publishedAt ?? null)}</span>
                  <span>{formatSize(latestDmg?.size)}</span>
                </div>
              </div>

              <p className={styles.releaseSummary}>
                {latestRelease
                  ? summarizeBody(latestRelease.body)
                  : "Release details are temporarily unavailable. Use the install options above or the GitHub releases link while the release feed refreshes."}
              </p>

              <div className={styles.releaseActions}>
                <TrackedDownloadLink
                  assetKind="dmg"
                  className={styles.primary}
                  persistCustomEvent={false}
                  releaseTag={latestRelease?.tagName ?? null}
                  source="download_page_latest_release"
                  targetUrl={`${stableDownloadHref}?source=download_page_latest_release`}
                >
                  Download DMG
                </TrackedDownloadLink>
                {latestChecksum ? (
                  <TrackedDownloadLink
                    assetKind="checksum"
                    className={styles.ghost}
                    releaseTag={latestRelease?.tagName ?? null}
                    source="download_page_latest_checksum"
                    targetUrl={latestChecksum.browser_download_url}
                  >
                    Checksum
                  </TrackedDownloadLink>
                ) : null}
                {latestRelease ? (
                  <a className={styles.ghost} href={latestRelease.htmlUrl}>
                    Release notes
                  </a>
                ) : null}
              </div>
            </div>

            <aside className={styles.sidePanel}>
              <div className={styles.sideItem}>
                <div className={styles.sideLabel}>Best for previewing</div>
                <p>
                  Dotfiles, config files, markdown, <Code>log files</Code>,
                  plain text, <Code>CSV</Code> / <Code>TSV</Code> data, man
                  pages, executable scripts, and <Code>source code</Code> in
                  Finder Quick Look.
                </p>
              </div>
              <div className={styles.sideItem}>
                <div className={styles.sideLabel}>Homebrew cask</div>
                <code className={styles.codeBlock}>{config.homebrewCommand}</code>
                <p>
                  Source in the tap:{" "}
                  <a href={config.homebrewTapUrl}>
                    {config.homebrewTapUrl.replace(/^https:\/\//, "")}
                  </a>
                  .
                </p>
              </div>
              <div className={styles.sideItem}>
                <div className={styles.sideLabel}>Stable DMG URL</div>
                <code className={styles.codeBlock}>{stableDownloadHref}</code>
              </div>
              <div className={styles.sideItem}>
                <div className={styles.sideLabel}>Source of truth</div>
                <p>
                  {config.githubRepo
                    ? `${config.githubRepo} GitHub Releases`
                    : "Official dotViewer GitHub Releases"}
                </p>
              </div>
              <div className={styles.sideItem}>
                <div className={styles.sideLabel}>Installer format</div>
                <p>
                  Developer ID signed, Apple-notarized macOS DMG with a
                  checksum asset published alongside the release.
                </p>
              </div>
            </aside>
          </Reveal>

          <Reveal as="section" className={styles.historySection} delay={0.1}>
            <div className={styles.historyIntro}>
              <div className={styles.kicker}>Version history</div>
              <h2 className={styles.historyTitle}>
                Fetched directly from GitHub Releases.
              </h2>
              <p className={styles.historyBody}>
                Published versions appear here automatically so the download
                page stays in sync with the official release source.
              </p>
              <p className={styles.historyBody}>
                {releaseCount > 0
                  ? `Current published versions listed on this page: ${releaseCount}.`
                  : "Release history is temporarily unavailable, but the stable download route above still points to the official installer path."}
              </p>
            </div>

            <div className={styles.historyList}>
              {releases.length > 0 ? (
                releases.map((release) => (
                  <article
                    className={styles.historyCard}
                    key={release.tagName}
                  >
                    <div className={styles.historyTop}>
                      <div>
                        <h3 className={styles.historyVersion}>{release.name}</h3>
                        <div className={styles.historyTag}>{release.tagName}</div>
                      </div>
                      <div className={styles.historyDate}>
                        {formatDate(release.publishedAt)}
                      </div>
                    </div>

                    <p className={styles.historySummary}>
                      {summarizeBody(release.body)}
                    </p>

                    <div className={styles.historyLinks}>
                      {release.dmgAsset ? (
                        <TrackedDownloadLink
                          assetKind="dmg"
                          releaseTag={release.tagName}
                          source="download_page_release_history"
                          targetUrl={release.dmgAsset.browser_download_url}
                        >
                          DMG
                        </TrackedDownloadLink>
                      ) : null}
                      {release.checksumAsset ? (
                        <TrackedDownloadLink
                          assetKind="checksum"
                          releaseTag={release.tagName}
                          source="download_page_release_history_checksum"
                          targetUrl={release.checksumAsset.browser_download_url}
                        >
                          Checksum
                        </TrackedDownloadLink>
                      ) : null}
                      <a href={release.htmlUrl}>GitHub</a>
                    </div>
                  </article>
                ))
              ) : (
                <article className={styles.historyEmpty}>
                  <h3>Release history is temporarily unavailable</h3>
                  <p>
                    The GitHub release feed did not return data just now. Use
                    the install options above and try again shortly.
                  </p>
                </article>
              )}
            </div>
          </Reveal>

          <div className={styles.backRow}>
            <Link className={styles.backLink} href="/">
              ← Back to dotViewer.app
            </Link>
          </div>
        </div>
      </main>
      <script
        type="application/ld+json"
        suppressHydrationWarning
        {...buildJsonLdProps(schemaJson)}
      />
    </div>
  );
}
