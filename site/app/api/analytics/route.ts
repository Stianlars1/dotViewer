import { after, NextResponse } from "next/server";
import { MAX_PAYLOAD_BYTES, parseAnalyticsPayload } from "../../../lib/analytics/payload";
import { getRequestContext, recordDownload, recordPageView } from "../../../lib/analytics/server";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const body = await request.text();
  if (body.length > MAX_PAYLOAD_BYTES) {
    return NextResponse.json({ error: "Analytics payload too large" }, { status: 413 });
  }

  let raw: unknown;
  try {
    raw = JSON.parse(body);
  } catch {
    return NextResponse.json({ error: "Invalid analytics payload" }, { status: 400 });
  }

  const parsed = parseAnalyticsPayload(raw);
  if (!parsed) {
    return NextResponse.json({ error: "Unsupported analytics payload" }, { status: 400 });
  }

  // The beacon does not wait for the database.
  const context = getRequestContext(request);
  after(() =>
    parsed.type === "page_view"
      ? recordPageView(parsed.event, context)
      : recordDownload({ ...parsed.event, channel: "website" }, context),
  );

  return NextResponse.json({ ok: true }, { status: 202 });
}
