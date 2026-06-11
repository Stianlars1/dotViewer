import type { ReleaseRecord } from "./github-release";
import type { ProductStats } from "./product-stats";
import type { SiteConfig } from "./site-config";

export const CREATOR_NAME = "Stian Larsen";
export const CREATOR_URL = "https://stianlarsen.com";
export const DBHOST_URL = "https://dbhost.app";

const APP_NAME = "dotViewer";
const APP_DESCRIPTION =
  "dotViewer lets macOS preview dotfiles, config files, markdown, CSV and TSV data, man pages, plain text documents, logs, executable scripts, and source code in Finder Quick Look.";
const FEATURE_LIST = [
  "Preview dotfiles, config files, CSV and TSV data, man pages, logs, executable scripts, plain text documents, and source code in Finder Quick Look.",
  "Read markdown in RAW mode or rendered mode with an optional table of contents.",
  "Use system-following theme choices, installed font family pickers, initial preview window sizing, font sizing, width controls, word wrap, and line number options.",
  "Configure copy behavior for Quick Look selection workflows.",
  "Manage supported extension and exact filename mappings from the companion macOS app.",
];

const SCREENSHOT_PATHS = [
  "/product/code-c.jpeg",
  "/product/markdown-rendered-toc.jpeg",
  "/product/settings-appearance.jpeg",
  "/product/file-types.jpeg",
];

function absoluteUrl(siteUrl: string, pathname: string) {
  return new URL(pathname, siteUrl).toString();
}

function normalizeVersion(tagName: string | null | undefined) {
  if (!tagName) {
    return undefined;
  }

  return tagName.replace(/^v/i, "");
}

function buildBaseGraph(config: SiteConfig) {
  const homeUrl = absoluteUrl(config.siteUrl, "/");
  const downloadPageUrl = absoluteUrl(config.siteUrl, "/download");
  const securityPageUrl = absoluteUrl(config.siteUrl, "/security");
  const latestDownloadUrl = absoluteUrl(config.siteUrl, "/download/latest");
  const logoUrl = absoluteUrl(config.siteUrl, "/brand/dotviewer-icon-light.png");

  const organizationId = `${homeUrl}#organization`;
  const creatorId = `${homeUrl}#creator`;
  const websiteId = `${homeUrl}#website`;
  const appId = `${homeUrl}#software`;

  const organization = {
    "@id": organizationId,
    "@type": "Organization",
    name: APP_NAME,
    url: homeUrl,
    logo: logoUrl,
    founder: { "@id": creatorId },
    sameAs: [CREATOR_URL, DBHOST_URL, config.repoUrl, config.appStoreUrl].filter(Boolean),
  };

  const creator = {
    "@id": creatorId,
    "@type": "Person",
    name: CREATOR_NAME,
    url: CREATOR_URL,
  };

  const website = {
    "@id": websiteId,
    "@type": "WebSite",
    name: APP_NAME,
    url: homeUrl,
    publisher: { "@id": organizationId },
  };

  const software = {
    "@id": appId,
    "@type": "SoftwareApplication",
    name: APP_NAME,
    description: APP_DESCRIPTION,
    applicationCategory: "DeveloperApplication",
    applicationSubCategory: "macOS Quick Look extension",
    operatingSystem: "macOS",
    requirements: "macOS 15.0 or later",
    url: homeUrl,
    downloadUrl: latestDownloadUrl,
    image: logoUrl,
    screenshot: SCREENSHOT_PATHS.map((pathname) => absoluteUrl(config.siteUrl, pathname)),
    featureList: FEATURE_LIST,
    creator: { "@id": creatorId },
    publisher: { "@id": organizationId },
    isAccessibleForFree: true,
    sameAs: [config.appStoreUrl].filter(Boolean),
    keywords:
      "Quick Look extension, Finder preview, dotfiles, config files, markdown preview, TSV preview, man page preview, code preview, plain text preview, macOS",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
      availability: "https://schema.org/InStock",
      category: "Free",
      url: downloadPageUrl,
    },
  };

  return {
    appId,
    creator,
    creatorId,
    downloadPageUrl,
    homeUrl,
    latestDownloadUrl,
    organization,
    organizationId,
    securityPageUrl,
    software,
    website,
    websiteId,
  };
}

export function buildHomeSchema(config: SiteConfig, stats: ProductStats, faqs: { answer: string; question: string }[]) {
  const base = buildBaseGraph(config);
  const pageId = `${base.homeUrl}#webpage`;
  const faqId = `${base.homeUrl}#faq`;

  const webpage = {
    "@id": pageId,
    "@type": "WebPage",
    name: "dotViewer for macOS",
    url: base.homeUrl,
    description:
      "Preview dotfiles, config files, markdown, CSV and TSV data, man pages, executable scripts, plain text documents, logs, and source code in Finder Quick Look.",
    isPartOf: { "@id": base.websiteId },
    about: { "@id": base.appId },
    primaryImageOfPage: absoluteUrl(config.siteUrl, "/product/markdown-rendered-toc.jpeg"),
  };

  const appWithStats = {
    ...base.software,
    featureList: [
      ...FEATURE_LIST,
      `${stats.fileTypes} built-in file type definitions.`,
      `${stats.extensions} registered extensions and ${stats.filenameMappings} filename mappings.`,
      `${stats.grammars} highlight query files.`,
    ],
  };

  const faq = {
    "@id": faqId,
    "@type": "FAQPage",
    mainEntity: faqs.map((item) => ({
      "@type": "Question",
      name: item.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.answer,
      },
    })),
  };

  const siteNavigation = [
    { name: "Home", url: base.homeUrl },
    { name: "Download", url: base.downloadPageUrl },
    { name: "Security", url: base.securityPageUrl },
    { name: "GitHub Releases", url: config.releasesUrl ?? base.downloadPageUrl },
  ].map((item, index) => ({
    "@type": "SiteNavigationElement",
    "@id": `${base.homeUrl}#nav-${index + 1}`,
    name: item.name,
    url: item.url,
  }));

  return {
    "@context": "https://schema.org",
    "@graph": [
      base.organization,
      base.creator,
      base.website,
      appWithStats,
      webpage,
      faq,
      ...siteNavigation,
    ],
  };
}

export function buildSecuritySchema(config: SiteConfig, latestRelease: ReleaseRecord | null) {
  const base = buildBaseGraph(config);
  const securityPageId = `${base.securityPageUrl}#webpage`;
  const breadcrumbId = `${base.securityPageUrl}#breadcrumb`;
  const trustListId = `${base.securityPageUrl}#trust-signals`;
  const latestDmg = latestRelease?.dmgAsset ?? null;
  const latestChecksum = latestRelease?.checksumAsset ?? null;

  const software = {
    ...base.software,
    softwareVersion: normalizeVersion(latestRelease?.tagName),
    releaseNotes: latestRelease?.htmlUrl ?? undefined,
    downloadUrl: latestDmg?.browser_download_url ?? base.latestDownloadUrl,
    sameAs: [config.repoUrl, config.releasesUrl, config.appStoreUrl].filter(Boolean),
    subjectOf: [
      latestRelease?.htmlUrl
        ? {
            "@type": "CreativeWork",
            name: latestRelease.name,
            url: latestRelease.htmlUrl,
          }
        : null,
      latestChecksum
        ? {
            "@type": "CreativeWork",
            name: latestChecksum.name,
            url: latestChecksum.browser_download_url,
            encodingFormat: "text/plain",
          }
        : null,
    ].filter(Boolean),
  };

  const webpage = {
    "@id": securityPageId,
    "@type": "AboutPage",
    name: "dotViewer Security and Trust",
    url: base.securityPageUrl,
    description:
      "Security, signing, notarization, official download, checksum, privacy, and contact details for dotViewer.",
    isPartOf: { "@id": base.websiteId },
    about: { "@id": base.appId },
    mainEntity: { "@id": base.appId },
    primaryImageOfPage: absoluteUrl(config.siteUrl, "/brand/dotviewer-icon-light.png"),
  };

  const breadcrumb = {
    "@id": breadcrumbId,
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: APP_NAME,
        item: base.homeUrl,
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "Security",
        item: base.securityPageUrl,
      },
    ],
  };

  const trustList = {
    "@id": trustListId,
    "@type": "ItemList",
    name: "dotViewer trust signals",
    itemListElement: [
      "Developer ID signed macOS app.",
      "Apple-notarized releases.",
      "Official DMG assets and SHA-256 checksum files published on GitHub Releases.",
      "Optional App Store distribution.",
      "No website login form, account portal, credential collection, or payment-card collection.",
    ].map((name, index) => ({
      "@type": "ListItem",
      position: index + 1,
      name,
    })),
  };

  return {
    "@context": "https://schema.org",
    "@graph": [
      base.organization,
      base.creator,
      base.website,
      software,
      webpage,
      breadcrumb,
      trustList,
    ],
  };
}

export function buildDownloadSchema(
  config: SiteConfig,
  releases: ReleaseRecord[],
  downloadHref: string | null,
) {
  const base = buildBaseGraph(config);
  const downloadPageId = `${base.downloadPageUrl}#webpage`;
  const breadcrumbId = `${base.downloadPageUrl}#breadcrumb`;
  const releaseListId = `${base.downloadPageUrl}#releases`;
  const latestRelease = releases[0] ?? null;

  const software = {
    ...base.software,
    softwareVersion: normalizeVersion(latestRelease?.tagName),
    releaseNotes: latestRelease?.htmlUrl ?? undefined,
    downloadUrl: downloadHref ?? base.latestDownloadUrl,
    offers: {
      ...base.software.offers,
      url: downloadHref ?? base.downloadPageUrl,
    },
  };

  const webpage = {
    "@id": downloadPageId,
    "@type": "CollectionPage",
    name: "Download dotViewer for macOS",
    url: base.downloadPageUrl,
    description:
      "Download the notarized dotViewer DMG for macOS and browse version history from GitHub Releases.",
    isPartOf: { "@id": base.websiteId },
    about: { "@id": base.appId },
    primaryImageOfPage: absoluteUrl(config.siteUrl, "/product/settings-appearance.jpeg"),
  };

  const breadcrumb = {
    "@id": breadcrumbId,
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: APP_NAME,
        item: base.homeUrl,
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "Download",
        item: base.downloadPageUrl,
      },
    ],
  };

  const releaseList =
    releases.length > 0
      ? {
          "@id": releaseListId,
          "@type": "ItemList",
          name: "dotViewer release history",
          itemListOrder: "https://schema.org/ItemListOrderDescending",
          numberOfItems: releases.length,
          itemListElement: releases.map((release, index) => ({
            "@type": "ListItem",
            position: index + 1,
            url: release.htmlUrl,
            name: release.name,
          })),
        }
      : null;

  return {
    "@context": "https://schema.org",
    "@graph": [
      base.organization,
      base.creator,
      base.website,
      software,
      webpage,
      breadcrumb,
      ...(releaseList ? [releaseList] : []),
    ],
  };
}
