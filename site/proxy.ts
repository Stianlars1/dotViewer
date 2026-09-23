import { NextResponse, type NextRequest } from "next/server";
import { basicCredentialsMatch } from "./lib/stats/auth";

// /stats is for the owner only: HTTP Basic Auth against STATS_USER / STATS_PASSWORD. Without
// both variables the page stays closed.

const PRIVATE_HEADERS = { "Cache-Control": "no-store", "X-Robots-Tag": "noindex, nofollow" };

export function proxy(request: NextRequest) {
  const user = process.env.STATS_USER;
  const password = process.env.STATS_PASSWORD;
  if (!user || !password) {
    return new NextResponse("Stats are not configured.", { headers: PRIVATE_HEADERS, status: 503 });
  }

  if (basicCredentialsMatch(request.headers.get("authorization"), user, password)) {
    const response = NextResponse.next();
    for (const [name, value] of Object.entries(PRIVATE_HEADERS)) response.headers.set(name, value);
    return response;
  }

  return new NextResponse("Authentication required.", {
    headers: { ...PRIVATE_HEADERS, "WWW-Authenticate": 'Basic realm="dotViewer stats", charset="UTF-8"' },
    status: 401,
  });
}

export const config = {
  matcher: ["/stats", "/stats/:path*"],
};
