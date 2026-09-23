import { createHash, timingSafeEqual } from "node:crypto";

// Constant-time checks for the two secrets that guard the stats: the cron's bearer token and the
// /stats page's Basic Auth credentials. Both sides are hashed first so their lengths match.

function sameSecret(given: string, expected: string): boolean {
  const a = createHash("sha256").update(given).digest();
  const b = createHash("sha256").update(expected).digest();
  return timingSafeEqual(a, b);
}

/** `Authorization: Bearer <secret>`, as Vercel Cron sends when CRON_SECRET is set. */
export function bearerMatches(header: string | null, secret: string): boolean {
  if (!header?.startsWith("Bearer ") || !secret) return false;
  return sameSecret(header.slice("Bearer ".length), secret);
}

/** `Authorization: Basic base64(user:password)`. */
export function basicCredentialsMatch(header: string | null, user: string, password: string): boolean {
  if (!header?.startsWith("Basic ") || !user || !password) return false;

  let decoded: string;
  try {
    decoded = Buffer.from(header.slice("Basic ".length), "base64").toString("utf8");
  } catch {
    return false;
  }

  const separator = decoded.indexOf(":");
  if (separator < 0) return false;
  // Evaluate both so a wrong user name takes as long as a wrong password.
  const userMatches = sameSecret(decoded.slice(0, separator), user);
  const passwordMatches = sameSecret(decoded.slice(separator + 1), password);
  return userMatches && passwordMatches;
}
