import { NextResponse } from "next/server";
import { getRequestContext, recordDownload, recordPageView } from "../../../lib/analytics/server";

export const runtime = "nodejs";

type AnalyticsPayload =
  | {
      path: string;
      title: string;
      type: "page_view";
      url: string;
      utmCampaign: string | null;
      utmContent: string | null;
      utmMedium: string | null;
      utmSource: string | null;
      utmTerm: string | null;
    }
  | {
      assetKind: "dmg" | "checksum";
      path: string;
      releaseTag: string | null;
      source: string;
      targetUrl: string;
      type: "download";
    };

function isPageViewPayload(payload: unknown): payload is Extract<AnalyticsPayload, { type: "page_view" }> {
  return (
    payload !== null &&
    typeof payload === "object" &&
    "path" in payload &&
    "title" in payload &&
    "type" in payload &&
    "url" in payload &&
    payload.type === "page_view"
  );
}

function isDownloadPayload(payload: unknown): payload is Extract<AnalyticsPayload, { type: "download" }> {
  return (
    payload !== null &&
    typeof payload === "object" &&
    "assetKind" in payload &&
    "path" in payload &&
    "source" in payload &&
    "targetUrl" in payload &&
    "type" in payload &&
    payload.type === "download"
  );
}

export async function POST(request: Request) {
  let payload: unknown;

  try {
    payload = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid analytics payload" }, { status: 400 });
  }

  const context = getRequestContext(request);

  if (isPageViewPayload(payload)) {
    await recordPageView(payload, context);
    return NextResponse.json({ ok: true }, { status: 202 });
  }

  if (isDownloadPayload(payload)) {
    await recordDownload(payload, context);
    return NextResponse.json({ ok: true }, { status: 202 });
  }

  return NextResponse.json({ error: "Unsupported analytics payload" }, { status: 400 });
}
