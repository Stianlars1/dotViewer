import assert from "node:assert/strict";
import { test } from "node:test";
import {
  downloadChannel,
  isInternalHost,
  parseUpdateFile,
  referrerHost,
  sanitizeSource,
  summarizeUserAgent,
} from "../lib/analytics/classify.ts";

const UA = {
  chromeMac:
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
  safariMac:
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15",
  firefoxMac: "Mozilla/5.0 (Macintosh; Intel Mac OS X 15.7; rv:143.0) Gecko/20100101 Firefox/143.0",
  edgeWindows:
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36 Edg/140.0.0.0",
  iphone:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1",
  ipad: "Mozilla/5.0 (iPad; CPU OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1",
  androidPhone:
    "Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36",
  androidTablet:
    "Mozilla/5.0 (Linux; Android 14; SM-X710) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
  googlebot: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
  gptbot: "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; GPTBot/1.2; +https://openai.com/gptbot",
  claudebot: "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)",
  curl: "curl/8.7.1",
  homebrew: "Homebrew/7.0.6 (Macintosh; arm64 Mac OS X 15.7) curl/8.7.1",
  sparkle: "dotViewer/1.6.0 Sparkle/2.10.0",
};

test("people on a Mac are desktop macOS, with their browser", () => {
  assert.deepEqual(summarizeUserAgent(UA.chromeMac), { browser: "Chrome", device: "desktop", isBot: false, os: "macOS" });
  assert.deepEqual(summarizeUserAgent(UA.safariMac), { browser: "Safari", device: "desktop", isBot: false, os: "macOS" });
  assert.equal(summarizeUserAgent(UA.firefoxMac).browser, "Firefox");
});

test("Edge is not reported as Chrome", () => {
  assert.deepEqual(summarizeUserAgent(UA.edgeWindows), { browser: "Edge", device: "desktop", isBot: false, os: "Windows" });
});

test("phones and tablets are told apart", () => {
  assert.equal(summarizeUserAgent(UA.iphone).device, "mobile");
  assert.equal(summarizeUserAgent(UA.iphone).os, "iOS");
  assert.equal(summarizeUserAgent(UA.ipad).device, "tablet");
  assert.equal(summarizeUserAgent(UA.androidPhone).device, "mobile");
  assert.equal(summarizeUserAgent(UA.androidTablet).device, "tablet");
});

test("crawlers, AI bots and command-line tools are bots", () => {
  for (const ua of [UA.googlebot, UA.gptbot, UA.claudebot, UA.curl]) {
    const summary = summarizeUserAgent(ua);
    assert.equal(summary.isBot, true, ua);
    assert.equal(summary.device, "bot", ua);
    assert.equal(summary.browser, null, ua);
  }
});

test("Homebrew and Sparkle download for a person, so they are not bots", () => {
  assert.deepEqual(summarizeUserAgent(UA.homebrew), { browser: "Homebrew", device: "desktop", isBot: false, os: "macOS" });
  assert.deepEqual(summarizeUserAgent(UA.sparkle), { browser: "Sparkle", device: "desktop", isBot: false, os: "macOS" });
});

test("a missing user agent is unknown, not a bot", () => {
  assert.deepEqual(summarizeUserAgent(null), { browser: null, device: "unknown", isBot: false, os: null });
  assert.deepEqual(summarizeUserAgent("   "), { browser: null, device: "unknown", isBot: false, os: null });
});

test("download channel comes from the tool's user agent", () => {
  assert.equal(downloadChannel(UA.sparkle), "sparkle");
  assert.equal(downloadChannel(UA.homebrew), "homebrew");
  assert.equal(downloadChannel(UA.safariMac), "direct");
  assert.equal(downloadChannel(null), "direct");
});

test("source keeps plain identifiers and drops anything else", () => {
  assert.equal(sanitizeSource("download_page_latest_release"), "download_page_latest_release");
  assert.equal(sanitizeSource(null), "direct");
  assert.equal(sanitizeSource(""), "direct");
  assert.equal(sanitizeSource("1' OR '1'='1"), "other");
  assert.equal(sanitizeSource("Home_Page"), "other");
  assert.equal(sanitizeSource("a".repeat(65)), "other");
});

test("referrer is reduced to its host", () => {
  assert.equal(referrerHost("https://www.google.com/search?q=dotviewer"), "google.com");
  assert.equal(referrerHost("https://news.ycombinator.com/item?id=1"), "news.ycombinator.com");
  assert.equal(referrerHost("android-app://com.slack/"), null);
  assert.equal(referrerHost("not a url"), null);
  assert.equal(referrerHost(null), null);
});

test("deployment URLs and localhost are internal", () => {
  assert.equal(isInternalHost("dotviewer-abc123-stians-applications.vercel.app"), true);
  assert.equal(isInternalHost("localhost:3000"), true);
  assert.equal(isInternalHost("dotviewer.app"), false);
  assert.equal(isInternalHost(null), false);
});

test("only dotViewer DMG names map to a release", () => {
  assert.deepEqual(parseUpdateFile("dotViewer-1.6.0.dmg"), { file: "dotViewer-1.6.0.dmg", tag: "v1.6.0", version: "1.6.0" });
  assert.equal(parseUpdateFile("dotViewer-1.6.0.dmg.sha256"), null);
  assert.equal(parseUpdateFile("../../etc/passwd"), null);
  assert.equal(parseUpdateFile("dotViewer-latest.dmg"), null);
  assert.equal(parseUpdateFile("Other-1.0.0.dmg"), null);
});
