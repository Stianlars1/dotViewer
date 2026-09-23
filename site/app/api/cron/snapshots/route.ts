import { NextResponse } from "next/server";
import { bearerMatches } from "../../../../lib/stats/auth";
import { collectSnapshots } from "../../../../lib/stats/collect";

// Daily download snapshot, run by Vercel Cron (vercel.json). Vercel sends
// `Authorization: Bearer $CRON_SECRET`; without the variable the route refuses to run.
// A failure answers 502, so it shows in the cron's logs, and /stats flags a stale snapshot.

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const maxDuration = 60;

export async function GET(request: Request) {
  const secret = process.env.CRON_SECRET;
  if (!secret) {
    return NextResponse.json({ error: "CRON_SECRET is not set" }, { status: 503 });
  }
  if (!bearerMatches(request.headers.get("authorization"), secret)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const result = await collectSnapshots();
    return NextResponse.json(result, { status: result.ok ? 200 : 502 });
  } catch (error) {
    console.error("[stats] snapshot failed", error);
    return NextResponse.json({ error: "Snapshot failed", ok: false }, { status: 502 });
  }
}
