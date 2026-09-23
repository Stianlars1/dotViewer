import { after, NextResponse } from "next/server";
import {
  CONSENT_VERSION,
  VISITOR_COOKIE,
  consentCookies,
  isSameOriginRequest,
  isVisitorId,
  parseConsentRequest,
  readCookie,
} from "../../../lib/consent/consent";
import { getDb } from "../../../lib/db/client";
import { analyticsConsents } from "../../../lib/db/schema";

// A consent choice from the banner or Cookie settings: sets the cookies that carry it and records it
// as proof of consent (docs/plans/2026-09-23-consent-banner-design.md). The choice is applied even if
// recording fails, so a Reject never depends on the database.

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const MAX_BODY_BYTES = 512;

export async function POST(request: Request) {
  if (!isSameOriginRequest(request.headers, request.url)) {
    return NextResponse.json({ error: "Consent can only be given on this site" }, { status: 403 });
  }

  const body = await request.text();
  if (body.length > MAX_BODY_BYTES) {
    return NextResponse.json({ error: "Consent payload too large" }, { status: 413 });
  }

  let raw: unknown;
  try {
    raw = JSON.parse(body);
  } catch {
    return NextResponse.json({ error: "Invalid consent payload" }, { status: 400 });
  }

  const choice = parseConsentRequest(raw);
  if (!choice) {
    return NextResponse.json({ error: "Unsupported consent payload" }, { status: 400 });
  }

  // A visitor who already has an ID keeps it, so changing only the Google choice doesn't start over.
  const existing = readCookie(request.headers.get("cookie"), VISITOR_COOKIE);
  const visitorId = choice.statistics ? (isVisitorId(existing) ? existing : crypto.randomUUID()) : null;
  const protocol = request.headers.get("x-forwarded-proto") ?? new URL(request.url).protocol.replace(":", "");

  const response = new NextResponse(null, { headers: { "Cache-Control": "no-store" }, status: 204 });
  for (const cookie of consentCookies(choice, visitorId, protocol === "https")) {
    response.headers.append("Set-Cookie", cookie);
  }

  after(async () => {
    const db = getDb();
    if (!db) return;
    try {
      await db.insert(analyticsConsents).values({
        google: choice.google,
        source: choice.source,
        statistics: choice.statistics,
        version: CONSENT_VERSION,
        visitorId,
      });
    } catch (error) {
      console.error("[consent] failed to record a choice", error);
    }
  });

  return response;
}
