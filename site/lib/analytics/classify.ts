// Pure helpers for the first-party analytics log. Nothing here touches the network or the database,
// so `node --test` can run them directly (tests/classify.test.ts).
//
// The log keeps coarse facts only — browser and OS family, a bot flag, a referrer host — never the
// full user agent, an IP address or a visitor ID. See /privacy.

export type Device = "bot" | "desktop" | "mobile" | "tablet" | "unknown";

export type UserAgentSummary = {
  browser: string | null;
  device: Device;
  isBot: boolean;
  os: string | null;
};

export type DownloadChannel = "direct" | "homebrew" | "sparkle" | "website";

// Tools that download dotViewer on a person's behalf. Checked before the bot pattern, because
// Homebrew's user agent ends in "curl/…".
const HOMEBREW = /\bHomebrew\//;
const SPARKLE = /\bSparkle\//;

const BOT =
  /bot\b|bot\/|crawl|spider|slurp|preview|facebookexternalhit|embedly|whatsapp|telegram|discord|slack|headless|lighthouse|pingdom|uptime|monitor|python|go-http-client|java\/|okhttp|axios|node-fetch|undici|wget|curl|libwww|httpie|scrapy|ahrefs|semrush|mj12|petalbot|bytespider|gptbot|claude|anthropic|perplexity|ccbot|amazon|applebot|google-inspectiontool|sqlmap|nikto|zgrab|masscan|nuclei/i;

function detectOs(ua: string): string | null {
  if (/iPad/.test(ua)) return "iPadOS";
  if (/iPhone|iPod/.test(ua)) return "iOS";
  if (/Android/.test(ua)) return "Android";
  if (/CrOS/.test(ua)) return "ChromeOS";
  if (/Mac OS X|Macintosh/.test(ua)) return "macOS";
  if (/Windows/.test(ua)) return "Windows";
  if (/Linux|X11/.test(ua)) return "Linux";
  return null;
}

function detectBrowser(ua: string): string | null {
  if (/Edg(e|A|iOS)?\//.test(ua)) return "Edge";
  if (/OPR\/|Opera/.test(ua)) return "Opera";
  if (/Firefox\/|FxiOS\//.test(ua)) return "Firefox";
  if (/Chrome\/|CriOS\//.test(ua)) return "Chrome";
  if (/Safari\//.test(ua) && /Version\//.test(ua)) return "Safari";
  return null;
}

/** Browser and OS family, device class and a bot flag — all that is kept of a user agent. */
export function summarizeUserAgent(userAgent: string | null | undefined): UserAgentSummary {
  const ua = userAgent?.trim() ?? "";
  if (!ua) {
    return { browser: null, device: "unknown", isBot: false, os: null };
  }

  if (HOMEBREW.test(ua)) {
    return { browser: "Homebrew", device: "desktop", isBot: false, os: "macOS" };
  }
  if (SPARKLE.test(ua)) {
    return { browser: "Sparkle", device: "desktop", isBot: false, os: "macOS" };
  }

  const os = detectOs(ua);
  if (BOT.test(ua)) {
    return { browser: null, device: "bot", isBot: true, os };
  }

  const browser = detectBrowser(ua);
  let device: Device = "unknown";
  if (os === "iPadOS" || (os === "Android" && !/Mobile/.test(ua))) {
    device = "tablet";
  } else if (os === "iOS" || os === "Android") {
    device = "mobile";
  } else if (os === "macOS" || os === "Windows" || os === "Linux" || os === "ChromeOS") {
    device = "desktop";
  }

  return { browser, device, isBot: false, os };
}

/** Which tool fetched an update archive, from its user agent. */
export function downloadChannel(userAgent: string | null | undefined): Exclude<DownloadChannel, "website"> {
  const ua = userAgent ?? "";
  if (SPARKLE.test(ua)) return "sparkle";
  if (HOMEBREW.test(ua)) return "homebrew";
  return "direct";
}

const SOURCE = /^[a-z0-9_]{1,64}$/;

/**
 * The `source` query parameter names the link that was clicked. It is free text from the URL, so
 * anything that is not a plain identifier is stored as "other" (a scanner once left SQL there).
 */
export function sanitizeSource(source: string | null | undefined): string {
  const value = source?.trim() ?? "";
  if (!value) return "direct";
  return SOURCE.test(value) ? value : "other";
}

/** The host of a referrer URL, lower-cased and without "www.", or null when there is none. */
export function referrerHost(referrer: string | null | undefined): string | null {
  if (!referrer) return null;
  try {
    const url = new URL(referrer);
    if (url.protocol !== "http:" && url.protocol !== "https:") return null;
    const host = url.hostname.toLowerCase().replace(/^www\./, "");
    return host ? host.slice(0, 255) : null;
  } catch {
    return null;
  }
}

/**
 * Requests to preview and production deployment URLs (`*.vercel.app`, behind Vercel
 * Authentication) and to a local server are the owner's own, not visitors'.
 */
export function isInternalHost(host: string | null | undefined): boolean {
  if (!host) return false;
  const name = host.toLowerCase().replace(/:\d+$/, "");
  return name.endsWith(".vercel.app") || name === "localhost" || name === "127.0.0.1";
}

export type UpdateFile = {
  file: string;
  tag: string;
  version: string;
};

const UPDATE_FILE = /^dotViewer-(\d{1,3}\.\d{1,3}\.\d{1,3})\.dmg$/;

/** `dotViewer-1.6.0.dmg` → the release it belongs to; anything else is not an update archive. */
export function parseUpdateFile(file: string): UpdateFile | null {
  const match = UPDATE_FILE.exec(file);
  if (!match) return null;
  const version = match[1];
  return { file, tag: `v${version}`, version };
}
