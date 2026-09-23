import assert from "node:assert/strict";
import { test } from "node:test";
import { getRequestContext } from "../lib/analytics/context.ts";

const uuid = "3f2b8c1e-6a4d-4f0b-9c7e-2d5a1b8e9f00";
const url = "https://www.dotviewer.app/api/analytics";

function request(headers: Record<string, string>) {
  return new Request(url, { headers: { "x-forwarded-host": "www.dotviewer.app", ...headers }, method: "POST" });
}

test("the visitor ID comes only from the request's own consent cookies", () => {
  assert.equal(getRequestContext(request({ cookie: `dv_consent=v1.s1.g0; dv_visitor=${uuid}` })).visitorId, uuid);
  assert.equal(getRequestContext(request({ cookie: `dv_consent=v1.s0.g1; dv_visitor=${uuid}` })).visitorId, null);
  assert.equal(getRequestContext(request({ cookie: `dv_visitor=${uuid}` })).visitorId, null);
  assert.equal(getRequestContext(request({})).visitorId, null);
});

test("the context carries what the day code and the classification need", () => {
  const context = getRequestContext(
    request({ "user-agent": "curl/8.7.1", "x-real-ip": "203.0.113.9", "x-vercel-ip-country": "NO" }),
  );
  assert.deepEqual(context, {
    country: "NO",
    internal: false,
    ip: "203.0.113.9",
    userAgent: "curl/8.7.1",
    visitorId: null,
  });
});

test("preview and local hosts are internal; odd country headers are dropped", () => {
  const preview = getRequestContext(request({ "x-forwarded-host": "dotviewer-abc.vercel.app", "x-vercel-ip-country": "norway" }));
  assert.equal(preview.internal, true);
  assert.equal(preview.country, null);
});
