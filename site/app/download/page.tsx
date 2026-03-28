import Link from "next/link";
import styles from "./page.module.css";
import { getGitHubReleases } from "../../lib/github-release";
import { getSiteConfig } from "../../lib/site-config";
import { buildDownloadSchema } from "../../lib/structured-data";

export const runtime = "nodejs";

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
    return "Release notes will appear on GitHub once published.";
  }

  const paragraphs = normalized
    .split(/\n{2,}/)
    .map((paragraph) => paragraph.replace(/^#+\s*/gm, "").trim())
    .filter(Boolean);

  const summary = paragraphs[0] ?? normalized;
  return summary.length > 220 ? `${summary.slice(0, 217)}...` : summary;
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
  const schema = buildDownloadSchema(config, releases, downloadHref);
  const releaseCount = releases.length;

  return (
    <div className={styles.page}>
      <Link href={"/"} className={styles.backLink + ` ${styles.goBack}`}>
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
            {downloadHref
              ? latestRelease?.name
                ? `Download ${latestRelease.name} for macOS.`
                : "Download dotViewer for macOS."
              : "dotViewer download will appear here once the release is published."}
          </h1>
          <p className={styles.body}>
            {downloadHref
              ? "Get the notarized DMG for the Quick Look app that previews `.gitignore`, `.env`, markdown, config files, plain text documents, logs, and source code in Finder. Use the button below to download the current release."
              : "The website is already wired for GitHub Releases. As soon as the notarized DMG is attached to the latest release, this page becomes the public download handoff and version history."}
          </p>
          <p className={styles.body}>
            This page exists so the public download link can stay stable while
            the actual DMG asset and version change release to release.
          </p>

          <div className={styles.actions}>
            <a
              className={styles.primaryAction}
              href={downloadHref ?? "/download/latest"}
            >
              {latestRelease?.name
                ? `Download ${latestRelease.name}`
                : "Download latest DMG"}
            </a>
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
                  {latestRelease?.name ?? "Awaiting first GitHub release"}
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
                : "Once the latest notarized DMG is attached on GitHub, this card will show the live version, file size, checksum, and release notes summary."}
            </p>

            <div className={styles.releaseActions}>
              <a
                className={styles.primaryAction}
                href={downloadHref ?? "/download/latest"}
              >
                Download DMG
              </a>
              {latestChecksum ? (
                <a
                  className={styles.secondaryAction}
                  href={latestChecksum.browser_download_url}
                >
                  Checksum
                </a>
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
                Dotfiles, config files, markdown, logs, plain text documents,
                and source code in Finder Quick Look.
              </p>
            </div>
            <div className={styles.sideItem}>
              <div className={styles.sideLabel}>Direct download URL</div>
              <code>{downloadHref ?? "/download/latest"}</code>
            </div>
            <div className={styles.sideItem}>
              <div className={styles.sideLabel}>Source of truth</div>
              <p>
                {config.githubRepo
                  ? `${config.githubRepo} GitHub Releases`
                  : "GitHub repo not configured yet"}
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
              Every published version can appear here automatically. That keeps
              the download page in sync with the release source instead of
              maintaining a second manual changelog just for installers.
            </p>
            <p className={styles.historyBody}>
              Current published versions available on this page: {releaseCount}.
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
                      <a href={release.dmgAsset.browser_download_url}>DMG</a>
                    ) : null}
                    {release.checksumAsset ? (
                      <a href={release.checksumAsset.browser_download_url}>
                        Checksum
                      </a>
                    ) : null}
                    <a href={release.htmlUrl}>GitHub</a>
                  </div>
                </article>
              ))
            ) : (
              <article className={styles.historyEmpty}>
                <h3>No GitHub releases yet</h3>
                <p>
                  Publish the first notarized DMG and this page will start
                  listing versions automatically.
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
