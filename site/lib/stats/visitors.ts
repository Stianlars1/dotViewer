// Pure aggregation for the Visitors section of /stats (tests/visitors.test.ts).
//
// Two kinds of visitor identity reach these functions. Day codes cover every visitor but only within
// one UTC day, so they answer "how many today" and "visited and downloaded the same day". Visitor IDs
// exist only for visitors who allowed dotViewer statistics, and answer everything across days.
// Bots and internal traffic never count.

import { isoWeekStart } from "./snapshots.ts";

export type VisitorEvent = {
  createdAt: Date;
  dayVisitor: string | null;
  isBot: boolean | null;
  isInternal: boolean | null;
  kind: "download" | "view";
  referrerHost: string | null;
  visitorId: string | null;
};

export type ConsentRow = { createdAt: Date; google: boolean; statistics: boolean };

export type Conversion = {
  downloaders: number;
  rate: number | null;
  sources: { downloaders: number; key: string; visitors: number }[];
  visitors: number;
};

const DAY_MS = 86_400_000;

const utcDay = (date: Date) => date.toISOString().slice(0, 10);
const counts = (event: VisitorEvent) => !event.isBot && !event.isInternal;
const bareHost = (host: string) => host.replace(/^www\./, "");

function lastDays(now: Date, days: number): string[] {
  return Array.from({ length: days }, (_, index) => utcDay(new Date(now.getTime() - (days - 1 - index) * DAY_MS)));
}

/** Different day codes per UTC day, for the last `days` days including today. */
export function dailyVisitors(events: VisitorEvent[], now: Date, days = 30): { day: string; visitors: number }[] {
  const perDay = new Map<string, Set<string>>();
  for (const event of events) {
    if (!counts(event) || !event.dayVisitor) continue;
    const day = utcDay(event.createdAt);
    const codes = perDay.get(day) ?? new Set<string>();
    codes.add(event.dayVisitor);
    perDay.set(day, codes);
  }
  return lastDays(now, days).map((day) => ({ day, visitors: perDay.get(day)?.size ?? 0 }));
}

/**
 * Visitor-days in the last `days` days, how many of them included a download, and the same split by
 * where the visitor came from (the first outside referrer that day, else "direct").
 */
export function sameDayConversion(events: VisitorEvent[], now: Date, siteHost: string, days = 30): Conversion {
  const since = now.getTime() - days * DAY_MS;
  const site = bareHost(siteHost);
  const units = new Map<string, { downloaded: boolean; source: string | null }>();

  for (const event of [...events].sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime())) {
    if (!counts(event) || !event.dayVisitor || event.createdAt.getTime() < since) continue;
    const key = `${utcDay(event.createdAt)} ${event.dayVisitor}`;
    const unit = units.get(key) ?? { downloaded: false, source: null };
    if (event.kind === "download") unit.downloaded = true;
    // The site answers on both dotviewer.app and www.dotviewer.app; neither is an outside source.
    if (!unit.source && event.referrerHost && bareHost(event.referrerHost) !== site) unit.source = event.referrerHost;
    units.set(key, unit);
  }

  const bySource = new Map<string, { downloaders: number; key: string; visitors: number }>();
  let downloaders = 0;
  for (const unit of units.values()) {
    const key = unit.source ?? "direct";
    const row = bySource.get(key) ?? { downloaders: 0, key, visitors: 0 };
    row.visitors += 1;
    if (unit.downloaded) {
      row.downloaders += 1;
      downloaders += 1;
    }
    bySource.set(key, row);
  }

  return {
    downloaders,
    rate: units.size > 0 ? downloaders / units.size : null,
    sources: [...bySource.values()]
      .sort((a, b) => b.visitors - a.visitors || a.key.localeCompare(b.key))
      .slice(0, 6),
    visitors: units.size,
  };
}

/** Consented visitors per ISO week: new that week, or first seen in an earlier week. */
export function returningVisitors(
  events: VisitorEvent[],
  now: Date,
  weeks = 8,
): { newVisitors: number; returning: number; week: string }[] {
  const firstWeek = new Map<string, string>();
  const active = new Map<string, Set<string>>();
  for (const event of events) {
    if (!counts(event) || !event.visitorId) continue;
    const week = isoWeekStart(utcDay(event.createdAt));
    const first = firstWeek.get(event.visitorId);
    if (!first || week < first) firstWeek.set(event.visitorId, week);
    const visitors = active.get(week) ?? new Set<string>();
    visitors.add(event.visitorId);
    active.set(week, visitors);
  }

  const thisWeek = isoWeekStart(utcDay(now));
  const labels = Array.from({ length: weeks }, (_, index) =>
    isoWeekStart(utcDay(new Date(new Date(`${thisWeek}T00:00:00Z`).getTime() - (weeks - 1 - index) * 7 * DAY_MS))),
  );
  return labels.map((week) => {
    let newVisitors = 0;
    let returning = 0;
    for (const visitor of active.get(week) ?? []) {
      if (firstWeek.get(visitor) === week) newVisitors += 1;
      else returning += 1;
    }
    return { newVisitors, returning, week };
  });
}

/**
 * Consented visitors' downloads, split by whether they came in the visitor's first visit. A visit ends
 * after `gapMinutes` without activity.
 */
export function downloadsByVisit(events: VisitorEvent[], gapMinutes = 30): { firstVisit: number; laterVisit: number } {
  const byVisitor = new Map<string, VisitorEvent[]>();
  for (const event of events) {
    if (!counts(event) || !event.visitorId) continue;
    byVisitor.set(event.visitorId, [...(byVisitor.get(event.visitorId) ?? []), event]);
  }

  const gap = gapMinutes * 60_000;
  let firstVisit = 0;
  let laterVisit = 0;
  for (const visitorEvents of byVisitor.values()) {
    visitorEvents.sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    let visit = 0;
    let previous: number | null = null;
    for (const event of visitorEvents) {
      const time = event.createdAt.getTime();
      if (previous !== null && time - previous > gap) visit += 1;
      previous = time;
      if (event.kind !== "download") continue;
      if (visit === 0) firstVisit += 1;
      else laterVisit += 1;
    }
  }
  return { firstVisit, laterVisit };
}

/** Choices made in the last `days` days, and the share that allowed each purpose. */
export function consentRate(
  rows: ConsentRow[],
  now: Date,
  days = 30,
): { choices: number; google: number | null; statistics: number | null } {
  const since = now.getTime() - days * DAY_MS;
  const recent = rows.filter((row) => row.createdAt.getTime() >= since);
  if (recent.length === 0) return { choices: 0, google: null, statistics: null };
  return {
    choices: recent.length,
    google: recent.filter((row) => row.google).length / recent.length,
    statistics: recent.filter((row) => row.statistics).length / recent.length,
  };
}
