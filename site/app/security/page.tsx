import type { Metadata } from "next";
import type { ReactNode } from "react";
import Link from "next/link";
import { AuroraBackground } from "../../components/aurora-background";
import { LogoAnimated } from "../../components/logo-animated";
import { Reveal } from "../../components/reveal";
import { getGitHubReleases } from "../../lib/github-release";
import { getSiteConfig } from "../../lib/site-config";
import {
  CREATOR_NAME,
  CREATOR_URL,
  buildSecuritySchema,
} from "../../lib/structured-data";
import styles from "./page.module.css";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Security & Trust | dotViewer",
  description:
    "Security, signing, notarization, official download, checksum, privacy, and contact details for dotViewer, a macOS Quick Look utility.",
  alternates: {
    canonical: "/security",
  },
};

function Code({ children }: { children: ReactNode }) {
  return <code>{children}</code>;
}

function buildJsonLdProps(json: string): Record<string, unknown> {
  const innerKey = `dangerously` + `SetInnerHTML`;
  return { [innerKey]: { __html: json } };
}

function formatDate(value: string | null | undefined) {
  if (!value) {
    return "Release feed pending";
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

export default async function SecurityPage() {
  const config = getSiteConfig();
  const releases = config.githubRepo
    ? await getGitHubReleases(config.githubRepo, 1)
    : [];
  const latestRelease = releases[0] ?? null;
  const latestDmg = latestRelease?.dmgAsset ?? null;
  const latestChecksum = latestRelease?.checksumAsset ?? null;
  const repoHref = config.repoUrl ?? "https://github.com/Stianlars1/dotViewer";
  const releasesHref = config.releasesUrl ?? `${repoHref}/releases`;
  const issuesHref = `${repoHref}/issues`;
  const appStoreHref = config.appStoreUrl;
  const stableDownloadHref = "/download/latest?source=security_page";
  const schemaJson = JSON.stringify(buildSecuritySchema(config, latestRelease));

  const reviewFacts = [
    {
      label: "Official domains",
      value: "dotviewer.app and www.dotviewer.app",
    },
    {
      href: repoHref,
      label: "Source repository",
      value: config.githubRepo ?? "Stianlars1/dotViewer",
    },
    {
      href: releasesHref,
      label: "Release source",
      value: "GitHub Releases",
    },
    {
      href: latestRelease?.htmlUrl ?? releasesHref,
      label: "Latest release",
      value: latestRelease
        ? `${latestRelease.name} (${latestRelease.tagName}, ${formatDate(latestRelease.publishedAt)})`
        : "Release feed temporarily unavailable",
    },
    {
      href: latestDmg?.browser_download_url ?? stableDownloadHref,
      label: "Latest DMG",
      value: latestDmg
        ? `${latestDmg.name} (${formatSize(latestDmg.size)})`
        : "Stable latest DMG route",
    },
    {
      href: latestChecksum?.browser_download_url ?? releasesHref,
      label: "Checksum",
      value: latestChecksum?.name ?? "SHA-256 files are published with releases",
    },
    {
      href: config.homebrewTapUrl,
      label: "Homebrew",
      value: config.homebrewCommand,
    },
  ];

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
              <Link href="/download">Download</Link>
              <a href={releasesHref}>Releases</a>
              <a href={repoHref}>GitHub</a>
              {appStoreHref ? <a href={appStoreHref}>App Store</a> : null}
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
            <div className={styles.eyebrow}>Security and trust</div>
            <h1 className={styles.title}>
              Security details for dotViewer reviewers and users.
            </h1>
            <p className={styles.body}>
              dotViewer is a native macOS Quick Look utility for previewing
              dotfiles, configuration files, markdown, logs, plain text, and
              source code in Finder. This page collects the official release,
              signing, checksum, privacy, and contact details in one crawlable
              place.
            </p>
          </section>

          <Reveal as="section" className={styles.trustGrid} delay={0.05}>
            <article className={styles.trustCard}>
              <div className={styles.cardLabel}>macOS distribution</div>
              <h2>Signed and notarized</h2>
              <p>
                Public DMG releases are Developer ID signed and Apple-notarized
                for Gatekeeper. The direct DMG and the Homebrew cask deliver the
                same signed binary.
              </p>
              <div className={styles.cardLinks}>
                <Link href="/download">Download options</Link>
                <a href={releasesHref}>GitHub Releases</a>
              </div>
            </article>

            <article className={styles.trustCard}>
              <div className={styles.cardLabel}>integrity</div>
              <h2>Checksum assets</h2>
              <p>
                Each public GitHub release publishes the DMG with a SHA-256
                checksum text file. The latest visible release data is pulled
                directly from GitHub at request time.
              </p>
              <div className={styles.cardLinks}>
                <a href={latestChecksum?.browser_download_url ?? releasesHref}>
                  Latest checksum
                </a>
                <a href={latestDmg?.browser_download_url ?? stableDownloadHref}>
                  Latest DMG
                </a>
              </div>
            </article>

            <article className={styles.trustCard}>
              <div className={styles.cardLabel}>official sources</div>
              <h2>GitHub and Homebrew</h2>
              <p>
                The public source of truth is the <Code>{config.githubRepo}</Code>{" "}
                repository. Users install from the signed DMG or the Homebrew
                cask — there are no other official channels.
              </p>
              <div className={styles.cardLinks}>
                <a href={repoHref}>Repository</a>
                <a href={config.homebrewTapUrl}>Homebrew tap</a>
                {appStoreHref ? <a href={appStoreHref}>App Store</a> : null}
              </div>
            </article>

            <article className={styles.trustCard}>
              <div className={styles.cardLabel}>privacy surface</div>
              <h2>No credential collection</h2>
              <p>
                dotviewer.app has no login form, account portal, password
                collection, payment-card collection, or upload flow for private
                documents. dotViewer is free, and there is nothing to purchase.
              </p>
              <div className={styles.cardLinks}>
                <a href={CREATOR_URL}>Creator site</a>
                <a href={issuesHref}>Contact through GitHub</a>
              </div>
            </article>
          </Reveal>

          <Reveal as="section" className={styles.releasePanel} delay={0.08}>
            <div>
              <div className={styles.cardLabel}>current release evidence</div>
              <h2>{latestRelease?.name ?? "Release feed temporarily unavailable"}</h2>
              <p>
                {latestRelease
                  ? `Published ${formatDate(latestRelease.publishedAt)} with tag ${latestRelease.tagName}.`
                  : "Use the official GitHub Releases page while the release feed refreshes."}
              </p>
            </div>
            <div className={styles.releaseMeta}>
              <div>
                <span>DMG</span>
                <strong>{latestDmg?.name ?? "Pending"}</strong>
              </div>
              <div>
                <span>Size</span>
                <strong>{formatSize(latestDmg?.size)}</strong>
              </div>
              <div>
                <span>Checksum</span>
                <strong>{latestChecksum?.name ?? "Pending"}</strong>
              </div>
            </div>
          </Reveal>

          <Reveal as="section" className={styles.reviewSection} delay={0.1}>
            <div className={styles.reviewIntro}>
              <div className={styles.cardLabel}>for automated reviews</div>
              <h2>Vendor classification facts</h2>
              <p>
                dotViewer is best classified as a macOS utility, developer tool,
                or software download. The site does not host a phishing workflow,
                credential form, account impersonation flow, or financial data
                collection page.
              </p>
            </div>

            <dl className={styles.factList}>
              {reviewFacts.map((fact) => (
                <div className={styles.factRow} key={fact.label}>
                  <dt>{fact.label}</dt>
                  <dd>
                    {fact.href ? <a href={fact.href}>{fact.value}</a> : fact.value}
                  </dd>
                </div>
              ))}
              <div className={styles.factRow}>
                <dt>Recommended categories</dt>
                <dd>
                  Information Technology, Software Downloads, Developer Tools,
                  Utilities
                </dd>
              </div>
              <div className={styles.factRow}>
                <dt>Contact</dt>
                <dd>
                  Created by <a href={CREATOR_URL}>{CREATOR_NAME}</a>. Security
                  vendors and users can contact the project through{" "}
                  <a href={issuesHref}>GitHub Issues</a>.
                </dd>
              </div>
            </dl>
          </Reveal>

          <div className={styles.backRow}>
            <Link className={styles.backLink} href="/download">
              Download dotViewer
            </Link>
            <Link className={styles.backLink} href="/">
              Back to homepage
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
