import { NextResponse } from "next/server";
import { bearerMatches } from "../../../../lib/stats/auth";
import { collectSnapshots } from "../../../../lib/stats/collect";
import { applyRetention, type RetentionResult } from "../../../../lib/stats/retention";

// Daily download snapshot and data retention, run by Vercel Cron (vercel.json). Vercel sends
// `Authorization: Bearer $CRON_SECRET`; without the variable the route refuses to run.
// A snapshot failure answers 502, so it shows in the cron's logs, and /stats flags a stale snapshot.
// Retention runs either way and reports its own result without changing the status.

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

  let retention: RetentionResult | { error: string } | null;
  try {
    retention = await applyRetention();
  } catch (error) {
    console.error("[stats] retention failed", error);
    retention = { error: "Retention failed" };
  }

  try {
    const result = await collectSnapshots();
    return NextResponse.json({ ...result, retention }, { status: result.ok ? 200 : 502 });
  } catch (error) {
    console.error("[stats] snapshot failed", error);
    return NextResponse.json({ error: "Snapshot failed", ok: false, retention }, { status: 502 });
  }
}
