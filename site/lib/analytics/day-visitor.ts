import { createHash, randomBytes } from "node:crypto";
import { sql } from "drizzle-orm";
import type { getDb } from "../db/client";

// A code that tells visitors apart within one UTC day, without a cookie: a hash of that day's random
// salt, the IP address and the user agent. The IP and user agent are used here and never stored; the
// salt is deleted once the day is over, after which nobody can recompute a code or link two days.
// The same scheme as Plausible's. Tests: tests/day-visitor.test.ts.

type Database = NonNullable<ReturnType<typeof getDb>>;

export type SaltStore = {
  deleteBefore(day: string): Promise<void>;
  get(day: string): Promise<string | null>;
  insert(day: string, salt: string): Promise<void>;
};

/** The UTC calendar day, `YYYY-MM-DD`. Salts and the stats' daily counts both use it. */
export function utcDay(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/** The client's address as Vercel passes it: `x-real-ip`, else the first `x-forwarded-for` entry. */
export function clientIp(headers: Headers): string | null {
  const real = headers.get("x-real-ip")?.trim();
  if (real) return real;
  return headers.get("x-forwarded-for")?.split(",")[0]?.trim() || null;
}

/** 16 hex characters (64 bits): plenty to count one day's visitors, little to go on otherwise. */
export function dayVisitorCode(salt: string, ip: string | null, userAgent: string | null): string {
  return createHash("sha256").update(`${salt}\n${ip ?? ""}\n${userAgent ?? ""}`).digest("hex").slice(0, 16);
}

export function randomSalt(): string {
  return randomBytes(32).toString("hex");
}

// One salt per store and function instance, so a busy day reads the table once.
const cached = new WeakMap<SaltStore, { day: string; salt: string }>();

/**
 * The salt for `day`. The first request of a new day deletes the earlier days' salts and inserts a new
 * one; a concurrent instance's insert is ignored and the stored salt re-read, so every instance agrees.
 */
export async function saltFor(store: SaltStore, day: string, makeSalt: () => string = randomSalt): Promise<string> {
  const known = cached.get(store);
  if (known?.day === day) return known.salt;

  let salt = await store.get(day);
  if (!salt) {
    await store.deleteBefore(day);
    await store.insert(day, makeSalt());
    salt = await store.get(day);
  }
  if (!salt) throw new Error(`No visitor salt for ${day}`);

  cached.set(store, { day, salt });
  return salt;
}

export function dbSaltStore(db: Database): SaltStore {
  return {
    async deleteBefore(day) {
      await db.execute(sql`DELETE FROM analytics_daily_salts WHERE day < ${day}::date`);
    },
    async get(day) {
      const result = await db.execute<{ salt: string }>(sql`SELECT salt FROM analytics_daily_salts WHERE day = ${day}::date`);
      return result.rows[0]?.salt ?? null;
    },
    async insert(day, salt) {
      await db.execute(sql`
        INSERT INTO analytics_daily_salts (day, salt) VALUES (${day}::date, ${salt})
        ON CONFLICT (day) DO NOTHING`);
    },
  };
}
