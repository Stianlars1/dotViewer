const DEFAULT_SITE_URL = "https://dotviewer.app";

function normalizeUrl(value: string | undefined): string | null {
  if (!value) {
    return null;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  return trimmed.replace(/\/+$/, "");
}

function normalizeRepo(value: string | undefined): string | null {
  if (!value) {
    return null;
  }

  const trimmed = value.trim().replace(/^https?:\/\/github\.com\//i, "").replace(/\/+$/, "");
  if (!trimmed || !trimmed.includes("/")) {
    return null;
  }

  return trimmed;
}

function inferRepoFromVercel(): string | null {
  const owner = process.env.VERCEL_GIT_REPO_OWNER?.trim();
  const slug = process.env.VERCEL_GIT_REPO_SLUG?.trim();

  if (!owner || !slug) {
    return null;
  }

  return `${owner}/${slug}`;
}

export type SiteConfig = {
  directDownloadUrl: string | null;
  githubRepo: string | null;
  hasDownloadSource: boolean;
  releasesUrl: string | null;
  repoUrl: string | null;
  siteUrl: string;
};

export function getSiteConfig(): SiteConfig {
  const directDownloadUrl = normalizeUrl(process.env.DIRECT_DOWNLOAD_URL);
  const githubRepo =
    normalizeRepo(process.env.GITHUB_REPO) ??
    normalizeRepo(process.env.NEXT_PUBLIC_GITHUB_REPO) ??
    inferRepoFromVercel();
  const repoUrl = githubRepo ? `https://github.com/${githubRepo}` : null;
  const releasesUrl = githubRepo ? `${repoUrl}/releases` : null;
  const siteUrl = normalizeUrl(process.env.NEXT_PUBLIC_SITE_URL) ?? DEFAULT_SITE_URL;

  return {
    directDownloadUrl,
    githubRepo,
    hasDownloadSource: Boolean(directDownloadUrl || githubRepo),
    releasesUrl,
    repoUrl,
    siteUrl,
  };
}
