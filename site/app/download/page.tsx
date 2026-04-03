import type { ReactNode } from "react";
import Link from "next/link";
import styles from "./page.module.css";
import { getGitHubReleases } from "../../lib/github-release";
import { getSiteConfig } from "../../lib/site-config";
import { buildDownloadSchema } from "../../lib/structured-data";
import { TrackedDownloadLink } from "../../components/tracked-download-link";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export const metadata = {
  title: "Download dotViewer for macOS",
  description:
    "Download the notarized dotViewer DMG for macOS and browse version history for the Quick Look app that previews dotfiles, config files, markdown, logs, plain text, and code.",
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

export default async function DownloadPage() {
  const config = getSiteConfig();
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
  const releaseCount = releases.length;

  return (
    <div className={styles.page}>
      <Link href="/" className={styles.backLink + ` ${styles.goBack}`}>
        Go back
      </Link>

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
      />

      <main className={styles.main}>
        <video
          src={"/test.mov"}
          autoPlay={true}
          muted={true}
          controls={false}
          loop={true}
          className={styles.testVideo}
        />
        <section className={styles.hero}>
          <div className={styles.eyebrow}>Direct macOS download</div>
          <h1 className={styles.title}>
            {latestRelease?.name
              ? `Download ${latestRelease.name} for macOS.`
              : "Download dotViewer for macOS."}
          </h1>
          <p className={styles.body}>
            Get the notarized DMG for the Quick Look app that previews{" "}
            <Code>.gitignore</Code>, <Code>.env</Code>, markdown, config files,
            plain text documents, <Code>log files</Code>, and{" "}
            <Code>source code</Code> in Finder. Use the button below to
            download the current release.
          </p>
          <p className={styles.body}>
            This page exists so the public download link can stay stable while
            the actual DMG asset and version change release to release. If the
            GitHub release feed is temporarily slow, the stable installer route
            still stays the same.
          </p>

          <div className={styles.actions}>
            <TrackedDownloadLink
              assetKind="dmg"
              className={styles.primaryAction}
              persistCustomEvent={false}
              releaseTag={latestRelease?.tagName ?? null}
              source="download_page_hero"
              targetUrl={`${stableDownloadHref}?source=download_page_hero`}
            >
              {latestRelease?.name
                ? `Download ${latestRelease.name}`
                : "Download latest DMG"}
            </TrackedDownloadLink>
            <a
              className={styles.secondaryAction}
              href={config.releasesUrl ?? "/#install"}
            >
              View GitHub releases
            </a>
          </div>
        </section>

        <section className={styles.currentRelease}>
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
                : "Release details are temporarily unavailable. Use the stable download button above or the GitHub releases link while the release feed refreshes."}
            </p>

            <div className={styles.releaseActions}>
              <TrackedDownloadLink
                assetKind="dmg"
                className={styles.primaryAction}
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
                  className={styles.secondaryAction}
                  releaseTag={latestRelease?.tagName ?? null}
                  source="download_page_latest_checksum"
                  targetUrl={latestChecksum.browser_download_url}
                >
                  Checksum
                </TrackedDownloadLink>
              ) : null}
              {latestRelease ? (
                <a
                  className={styles.secondaryAction}
                  href={latestRelease.htmlUrl}
                >
                  Release notes
                </a>
              ) : null}
            </div>
          </div>

          <aside className={styles.sidePanel}>
            <div className={styles.sideItem}>
              <div className={styles.sideLabel}>Best for previewing</div>
              <p>
                Dotfiles, config files, markdown, <Code>log files</Code>, plain
                text documents, and <Code>source code</Code> in Finder Quick
                Look.
              </p>
            </div>
            <div className={styles.sideItem}>
              <div className={styles.sideLabel}>Direct download URL</div>
              <code>{stableDownloadHref}</code>
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
                Developer ID signed and notarized macOS DMG with checksum asset
                published alongside the release.
              </p>
            </div>
          </aside>
        </section>

        <section className={styles.historySection}>
          <div className={styles.historyIntro}>
            <div className={styles.kicker}>Version history</div>
            <h2 className={styles.historyTitle}>
              Fetched directly from GitHub Releases.
            </h2>
            <p className={styles.historyBody}>
              Published versions appear here automatically. That keeps the
              download page in sync with the official release source instead of
              maintaining a second manual changelog just for installers.
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
                <article className={styles.historyCard} key={release.tagName}>
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
                  The GitHub release feed did not return data just now. Use the
                  main download button or the GitHub releases link above and
                  try again shortly.
                </p>
              </article>
            )}
          </div>
        </section>

        <section className={styles.backLinkRow}>
          <Link className={styles.backLink} href="/">
            Back to dotViewer.app
          </Link>
        </section>
      </main>
    </div>
  );
}
