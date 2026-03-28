export type GitHubAsset = {
  browser_download_url: string;
  content_type?: string;
  download_count?: number;
  name: string;
  size?: number;
};

type GitHubReleaseResponse = {
  assets?: GitHubAsset[];
  body?: string;
  draft?: boolean;
  html_url?: string;
  name?: string;
  prerelease?: boolean;
  published_at?: string;
  tag_name?: string;
};

export type ReleaseRecord = {
  body: string;
  checksumAsset: GitHubAsset | null;
  dmgAsset: GitHubAsset | null;
  htmlUrl: string;
  isPrerelease: boolean;
  name: string;
  publishedAt: string | null;
  tagName: string;
};

function buildHeaders() {
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "User-Agent": "dotviewer-site",
    "X-GitHub-Api-Version": "2022-11-28",
  };

  if (process.env.GITHUB_TOKEN) {
    headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
  }

  return headers;
}

export async function getLatestDmgAssetUrl(githubRepo: string): Promise<string | null> {
  const releases = await getGitHubReleases(githubRepo, 1);
  return releases[0]?.dmgAsset?.browser_download_url ?? null;
}

function pickDmgAsset(assets: GitHubAsset[]): GitHubAsset | null {
  const dmgAssets = assets.filter((asset) => asset.name.toLowerCase().endsWith(".dmg"));

  const preferred =
    dmgAssets.find((asset) => asset.name.toLowerCase().includes("dotviewer")) ??
    dmgAssets[0] ??
    null;

  return preferred;
}

function pickChecksumAsset(assets: GitHubAsset[]): GitHubAsset | null {
  return (
    assets.find((asset) => {
      const name = asset.name.toLowerCase();
      return name.endsWith(".sha256") || name.endsWith(".sha256.txt");
    }) ?? null
  );
}

export async function getGitHubReleases(
  githubRepo: string,
  limit = 12,
): Promise<ReleaseRecord[]> {
  try {
    const response = await fetch(
      `https://api.github.com/repos/${githubRepo}/releases?per_page=${limit}`,
      {
        headers: buildHeaders(),
        next: { revalidate: 300 },
        signal: AbortSignal.timeout(4000),
      },
    );

    if (!response.ok) {
      return [];
    }

    const releases = (await response.json()) as GitHubReleaseResponse[];

    return releases
      .filter((release) => !release.draft && !release.prerelease)
      .map((release) => {
        const assets = release.assets ?? [];

        return {
          body: release.body?.trim() ?? "",
          checksumAsset: pickChecksumAsset(assets),
          dmgAsset: pickDmgAsset(assets),
          htmlUrl: release.html_url ?? `https://github.com/${githubRepo}/releases`,
          isPrerelease: Boolean(release.prerelease),
          name: release.name?.trim() || release.tag_name?.trim() || "Untitled release",
          publishedAt: release.published_at ?? null,
          tagName: release.tag_name?.trim() ?? "untagged",
        };
      });
  } catch {
    return [];
  }
}
