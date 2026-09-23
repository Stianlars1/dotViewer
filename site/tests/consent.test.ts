import assert from "node:assert/strict";
import { test } from "node:test";
import {
  CONSENT_MAX_AGE,
  CONSENT_VERSION,
  VISITOR_MAX_AGE,
  consentCookies,
  consentedVisitorId,
  cookieDomains,
  formatConsent,
  isCurrentConsent,
  isVisitorId,
  parseConsent,
  parseConsentRequest,
  readCookie,
  shouldShowBanner,
} from "../lib/consent/consent.ts";

const uuid = "3f2b8c1e-6a4d-4f0b-9c7e-2d5a1b8e9f00";

test("a choice survives formatting and parsing", () => {
  for (const choice of [
    { google: false, statistics: false },
    { google: true, statistics: true },
    { google: true, statistics: false },
  ]) {
    assert.deepEqual(parseConsent(formatConsent(choice)), { ...choice, version: CONSENT_VERSION });
  }
  assert.equal(formatConsent({ google: false, statistics: true }), "v1.s1.g0");
});

test("malformed consent values read as no choice", () => {
  for (const value of [null, undefined, "", "x", "v1.s2.g0", "v1.s1", "v1.s1.g0.x", "vx.s1.g1", " v1.s1.g1"]) {
    assert.equal(parseConsent(value), null, String(value));
  }
});

test("only the current version counts as a choice", () => {
  assert.equal(isCurrentConsent(parseConsent("v1.s1.g1")), true);
  assert.equal(isCurrentConsent(parseConsent("v0.s1.g1")), false);
  assert.equal(isCurrentConsent(null), false);
});

test("cookies are read from a Cookie header by exact name", () => {
  const header = `a=1; dv_consent=v1.s1.g0;  dv_visitor=${uuid}; eq=x=y`;
  assert.equal(readCookie(header, "dv_consent"), "v1.s1.g0");
  assert.equal(readCookie(header, "dv_visitor"), uuid);
  assert.equal(readCookie(header, "eq"), "x=y");
  assert.equal(readCookie(header, "missing"), null);
  assert.equal(readCookie("dv_consent_old=v1.s1.g1", "dv_consent"), null);
  assert.equal(readCookie(null, "a"), null);
});

test("visitor IDs are lowercase version 4 UUIDs", () => {
  assert.equal(isVisitorId(uuid), true);
  assert.equal(isVisitorId(uuid.toUpperCase()), false);
  assert.equal(isVisitorId("3f2b8c1e-6a4d-1f0b-9c7e-2d5a1b8e9f00"), false);
  assert.equal(isVisitorId("not-a-uuid"), false);
  assert.equal(isVisitorId(null), false);
});

test("a visitor ID is used only with a current consent to statistics", () => {
  assert.equal(consentedVisitorId(`dv_consent=v1.s1.g0; dv_visitor=${uuid}`), uuid);
  assert.equal(consentedVisitorId(`dv_consent=v1.s1.g1; dv_visitor=${uuid}`), uuid);
  assert.equal(consentedVisitorId(`dv_consent=v1.s0.g1; dv_visitor=${uuid}`), null);
  assert.equal(consentedVisitorId(`dv_visitor=${uuid}`), null);
  assert.equal(consentedVisitorId(`dv_consent=v0.s1.g1; dv_visitor=${uuid}`), null);
  assert.equal(consentedVisitorId("dv_consent=v1.s1.g0; dv_visitor=forged"), null);
  assert.equal(consentedVisitorId(null), null);
});

test("consent requests need the current version, two booleans and a known source", () => {
  assert.deepEqual(parseConsentRequest({ google: false, source: "banner", statistics: true, version: 1 }), {
    google: false,
    source: "banner",
    statistics: true,
  });
  assert.deepEqual(parseConsentRequest({ google: true, source: "settings", statistics: false, version: 1 }), {
    google: true,
    source: "settings",
    statistics: false,
  });
  for (const raw of [
    null,
    [],
    "yes",
    { google: false, source: "banner", statistics: true, version: 2 },
    { google: "true", source: "banner", statistics: true, version: 1 },
    { google: false, source: "banner", version: 1 },
    { google: false, source: "api", statistics: true, version: 1 },
  ]) {
    assert.equal(parseConsentRequest(raw), null, JSON.stringify(raw));
  }
});

test("consent cookies: the choice always, the visitor ID only with statistics", () => {
  const [consent, visitor] = consentCookies({ google: false, statistics: true }, uuid, true);
  assert.equal(consent, `dv_consent=v1.s1.g0; Path=/; SameSite=Lax; Secure; Max-Age=${CONSENT_MAX_AGE}`);
  assert.equal(visitor, `dv_visitor=${uuid}; Path=/; SameSite=Lax; Secure; Max-Age=${VISITOR_MAX_AGE}; HttpOnly`);

  const [, expired] = consentCookies({ google: true, statistics: false }, uuid, true);
  assert.equal(expired, "dv_visitor=; Path=/; SameSite=Lax; Secure; Max-Age=0; HttpOnly");

  const insecure = consentCookies({ google: false, statistics: false }, null, false);
  assert.ok(insecure.every((cookie) => !cookie.includes("Secure")));
  assert.equal(CONSENT_MAX_AGE, 31_536_000);
  assert.equal(VISITOR_MAX_AGE, 34_128_000);
});

test("the banner shows until there is a current choice, and never with Global Privacy Control", () => {
  assert.equal(shouldShowBanner(null, false), true);
  assert.equal(shouldShowBanner(parseConsent("v0.s1.g1"), false), true);
  assert.equal(shouldShowBanner(parseConsent("v1.s0.g0"), false), false);
  assert.equal(shouldShowBanner(null, true), false);
});

test("cookie domains cover the host and each parent domain", () => {
  assert.deepEqual(cookieDomains("www.dotviewer.app"), ["", ".www.dotviewer.app", ".dotviewer.app"]);
  assert.deepEqual(cookieDomains("dotviewer.app"), ["", ".dotviewer.app"]);
  assert.deepEqual(cookieDomains("localhost"), [""]);
  assert.deepEqual(cookieDomains("127.0.0.1"), [""]);
});
