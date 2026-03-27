import { NextResponse } from "next/server";
import { getLatestDmgAssetUrl } from "../../lib/github-release";
import { getSiteConfig } from "../../lib/site-config";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const config = getSiteConfig();

  if (config.directDownloadUrl) {
    return NextResponse.redirect(config.directDownloadUrl, 307);
  }

  if (config.githubRepo) {
    try {
      const assetUrl = await getLatestDmgAssetUrl(config.githubRepo);
      if (assetUrl) {
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
