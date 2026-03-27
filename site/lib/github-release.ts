type GitHubAsset = {
  browser_download_url: string;
  name: string;
};

type GitHubRelease = {
  assets?: GitHubAsset[];
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
  const response = await fetch(`https://api.github.com/repos/${githubRepo}/releases/latest`, {
    headers: buildHeaders(),
    next: { revalidate: 300 },
    signal: AbortSignal.timeout(4000),
  });

  if (!response.ok) {
    return null;
  }

  const release = (await response.json()) as GitHubRelease;
  const assets = release.assets ?? [];
  const dmgAssets = assets.filter((asset) => asset.name.toLowerCase().endsWith(".dmg"));

  const preferred =
    dmgAssets.find((asset) => asset.name.toLowerCase().includes("dotviewer")) ??
    dmgAssets[0];

  return preferred?.browser_download_url ?? null;
}
