import { after, NextResponse } from "next/server";
import { getLatestRelease } from "../../../lib/github-release";
import { getSiteConfig } from "../../../lib/site-config";
import { sanitizeSource } from "../../../lib/analytics/classify";
import { getRequestContext, recordDownload } from "../../../lib/analytics/server";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const config = getSiteConfig();
  const source = sanitizeSource(new URL(request.url).searchParams.get("source"));
  const context = getRequestContext(request);

  // Logged after the redirect is sent, so a download never waits for the database.
  const log = (targetUrl: string, releaseTag: string | null) =>
    after(() =>
      recordDownload(
        { assetKind: "dmg", channel: "website", path: "/download/latest", referrerHost: null, releaseTag, source, targetUrl },
        context,
      ),
    );

  if (config.directDownloadUrl) {
    log(config.directDownloadUrl, null);
    return NextResponse.redirect(config.directDownloadUrl, 307);
  }

  if (config.githubRepo) {
    try {
      const latestRelease = await getLatestRelease(config.githubRepo);
      const assetUrl = latestRelease?.dmgAsset?.browser_download_url ?? null;
      if (latestRelease && assetUrl) {
        log(assetUrl, latestRelease.tagName);
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
