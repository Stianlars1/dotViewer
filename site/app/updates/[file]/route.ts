import { after, NextResponse } from "next/server";
import { downloadChannel, parseUpdateFile } from "../../../lib/analytics/classify";
import { getRequestContext, recordDownload } from "../../../lib/analytics/server";
import { getSiteConfig } from "../../../lib/site-config";

// Stable download URLs for update archives: https://dotviewer.app/updates/dotViewer-1.6.0.dmg.
// Sparkle's appcast (and, optionally, the Homebrew cask) point here; the route logs which tool
// fetched which version and redirects to the GitHub release asset. Sparkle verifies the archive's
// EdDSA signature, so the redirect cannot swap its content.

export const runtime = "nodejs";

async function redirectToRelease(request: Request, params: Promise<{ file: string }>) {
  const update = parseUpdateFile((await params).file);
  const { githubRepo } = getSiteConfig();
  if (!update || !githubRepo) {
    return new NextResponse("Not found", { status: 404 });
  }

  const targetUrl = `https://github.com/${githubRepo}/releases/download/${update.tag}/${update.file}`;
  const context = getRequestContext(request);
  // Homebrew only sends HEAD here and fetches the resolved URL itself; Sparkle and browsers GET.
  after(() =>
    recordDownload(
      {
        assetKind: "dmg",
        channel: downloadChannel(context.userAgent),
        path: `/updates/${update.file}`,
        referrerHost: null,
        releaseTag: update.tag,
        source: "updates",
        targetUrl,
      },
      context,
    ),
  );

  return NextResponse.redirect(targetUrl, 302);
}

export async function GET(request: Request, { params }: { params: Promise<{ file: string }> }) {
  return redirectToRelease(request, params);
}

export async function HEAD(request: Request, { params }: { params: Promise<{ file: string }> }) {
  return redirectToRelease(request, params);
}
