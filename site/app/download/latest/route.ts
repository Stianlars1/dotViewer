import { NextResponse } from "next/server";
import { getLatestRelease } from "../../../lib/github-release";
import { getSiteConfig } from "../../../lib/site-config";
import { getRequestContext, recordDownload } from "../../../lib/analytics/server";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const config = getSiteConfig();
  const source = new URL(request.url).searchParams.get("source") ?? "direct";
  const context = getRequestContext(request);

  if (config.directDownloadUrl) {
    await recordDownload(
      {
        assetKind: "dmg",
        path: "/download/latest",
        releaseTag: null,
        source,
        targetUrl: config.directDownloadUrl,
      },
      context,
    );
    return NextResponse.redirect(config.directDownloadUrl, 307);
  }

  if (config.githubRepo) {
    try {
      const latestRelease = await getLatestRelease(config.githubRepo);
      const assetUrl = latestRelease?.dmgAsset?.browser_download_url ?? null;
      if (latestRelease && assetUrl) {
        await recordDownload(
          {
            assetKind: "dmg",
            path: "/download/latest",
            releaseTag: latestRelease.tagName,
            source,
            targetUrl: assetUrl,
          },
          context,
        );
        return NextResponse.redirect(assetUrl, 307);
      }
    } catch {
      // Fall through to the releases page.
    }
  }

  if (config.releasesUrl) {
    return NextResponse.redirect(config.releasesUrl, 307);
  }

  return NextResponse.redirect(new URL("/#install", request.url), 307);
}
