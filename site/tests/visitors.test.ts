import assert from "node:assert/strict";
import { test } from "node:test";
import {
  consentRate,
  dailyVisitors,
  downloadsByVisit,
  returningVisitors,
  sameDayConversion,
  type VisitorEvent,
} from "../lib/stats/visitors.ts";

const now = new Date("2026-09-23T12:00:00Z");

function event(overrides: Partial<VisitorEvent> & { at: string }): VisitorEvent {
  const { at, ...rest } = overrides;
  return {
    createdAt: new Date(at),
    dayVisitor: null,
    isBot: false,
    isInternal: false,
    kind: "view",
    referrerHost: null,
    visitorId: null,
    ...rest,
  };
}

test("daily visitors count each day code once per UTC day, leaving out bots and internal traffic", () => {
  const events = [
    event({ at: "2026-09-23T08:00:00Z", dayVisitor: "a" }),
    event({ at: "2026-09-23T09:00:00Z", dayVisitor: "a" }),
    event({ at: "2026-09-23T10:00:00Z", dayVisitor: "b", kind: "download" }),
    event({ at: "2026-09-23T10:30:00Z", dayVisitor: "c", isBot: true }),
    event({ at: "2026-09-23T10:40:00Z", dayVisitor: "d", isInternal: true }),
    event({ at: "2026-09-22T23:59:00Z", dayVisitor: "a" }),
    event({ at: "2026-09-10T12:00:00Z", dayVisitor: "z" }),
  ];
  const days = dailyVisitors(events, now, 3);
  assert.deepEqual(days, [
    { day: "2026-09-21", visitors: 0 },
    { day: "2026-09-22", visitors: 1 },
    { day: "2026-09-23", visitors: 2 },
  ]);
});

test("same-day conversion joins page views and downloads by day code, per source", () => {
  const events = [
    event({ at: "2026-09-23T08:00:00Z", dayVisitor: "a", referrerHost: "github.com" }),
    event({ at: "2026-09-23T08:05:00Z", dayVisitor: "a", kind: "download" }),
    event({ at: "2026-09-23T09:00:00Z", dayVisitor: "b", referrerHost: "github.com" }),
    event({ at: "2026-09-23T09:10:00Z", dayVisitor: "c", referrerHost: "www.dotviewer.app" }),
    event({ at: "2026-09-22T09:00:00Z", dayVisitor: "a" }),
    event({ at: "2026-09-23T11:00:00Z", dayVisitor: "e", isBot: true, kind: "download" }),
  ];
  const conversion = sameDayConversion(events, now, "www.dotviewer.app", 30);
  assert.equal(conversion.visitors, 4);
  assert.equal(conversion.downloaders, 1);
  assert.equal(conversion.rate, 0.25);
  assert.deepEqual(conversion.sources, [
    { downloaders: 0, key: "direct", visitors: 2 },
    { downloaders: 1, key: "github.com", visitors: 2 },
  ]);
  assert.equal(sameDayConversion([], now, "www.dotviewer.app").rate, null);
  // Configured as the bare domain, while visits arrive on www.
  assert.deepEqual(sameDayConversion(events, now, "dotviewer.app", 30).sources, conversion.sources);
});

test("returning visitors: seen in an earlier ISO week than the one counted", () => {
  const events = [
    event({ at: "2026-09-08T10:00:00Z", visitorId: "v1" }),
    event({ at: "2026-09-16T10:00:00Z", visitorId: "v1" }),
    event({ at: "2026-09-16T11:00:00Z", visitorId: "v2" }),
    event({ at: "2026-09-22T10:00:00Z", visitorId: "v2" }),
    event({ at: "2026-09-22T12:00:00Z", visitorId: "v3" }),
    event({ at: "2026-09-22T12:00:00Z", visitorId: "bot", isBot: true }),
  ];
  assert.deepEqual(returningVisitors(events, now, 3), [
    { newVisitors: 1, returning: 0, week: "2026-09-07" },
    { newVisitors: 1, returning: 1, week: "2026-09-14" },
    { newVisitors: 1, returning: 1, week: "2026-09-21" },
  ]);
});

test("downloads on a first visit versus after an earlier visit, visits split at 30 minutes", () => {
  const events = [
    event({ at: "2026-09-20T10:00:00Z", visitorId: "v1" }),
    event({ at: "2026-09-20T10:10:00Z", visitorId: "v1", kind: "download" }),
    event({ at: "2026-09-20T10:00:00Z", visitorId: "v2" }),
    event({ at: "2026-09-21T10:00:00Z", visitorId: "v2" }),
    event({ at: "2026-09-21T10:20:00Z", visitorId: "v2", kind: "download" }),
    event({ at: "2026-09-21T10:20:00Z", visitorId: null, kind: "download" }),
  ];
  assert.deepEqual(downloadsByVisit(events), { firstVisit: 1, laterVisit: 1 });
});

test("consent rate over the window, null without choices", () => {
  const rows = [
    { createdAt: new Date("2026-09-22T10:00:00Z"), google: true, statistics: true },
    { createdAt: new Date("2026-09-22T11:00:00Z"), google: false, statistics: true },
    { createdAt: new Date("2026-09-22T12:00:00Z"), google: false, statistics: false },
    { createdAt: new Date("2026-09-22T13:00:00Z"), google: false, statistics: false },
    { createdAt: new Date("2026-07-01T10:00:00Z"), google: true, statistics: true },
  ];
  assert.deepEqual(consentRate(rows, now, 30), { choices: 4, google: 0.25, statistics: 0.5 });
  assert.deepEqual(consentRate([], now), { choices: 0, google: null, statistics: null });
});
