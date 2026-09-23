import assert from "node:assert/strict";
import { test } from "node:test";
import { clientIp, dayVisitorCode, saltFor, utcDay, type SaltStore } from "../lib/analytics/day-visitor.ts";

const safari =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15";

test("days are UTC calendar days", () => {
  assert.equal(utcDay(new Date("2026-09-23T23:59:59Z")), "2026-09-23");
  assert.equal(utcDay(new Date("2026-09-24T00:00:00+02:00")), "2026-09-23");
});

test("the client IP comes from x-real-ip, else the first x-forwarded-for entry", () => {
  assert.equal(clientIp(new Headers({ "x-forwarded-for": "198.51.100.7, 10.0.0.1", "x-real-ip": "203.0.113.9" })), "203.0.113.9");
  assert.equal(clientIp(new Headers({ "x-forwarded-for": " 198.51.100.7 , 10.0.0.1" })), "198.51.100.7");
  assert.equal(clientIp(new Headers()), null);
});

test("a code is stable within a salt and changes with the salt, the IP or the browser", () => {
  const code = dayVisitorCode("salt-a", "203.0.113.9", safari);
  assert.match(code, /^[0-9a-f]{16}$/);
  assert.equal(dayVisitorCode("salt-a", "203.0.113.9", safari), code);
  assert.notEqual(dayVisitorCode("salt-b", "203.0.113.9", safari), code);
  assert.notEqual(dayVisitorCode("salt-a", "203.0.113.10", safari), code);
  assert.notEqual(dayVisitorCode("salt-a", "203.0.113.9", "curl/8.7.1"), code);
  assert.match(dayVisitorCode("salt-a", null, null), /^[0-9a-f]{16}$/);
});

function memoryStore(initial: Record<string, string> = {}) {
  const salts = new Map(Object.entries(initial));
  const calls: string[] = [];
  const store: SaltStore = {
    async deleteBefore(day) {
      calls.push(`deleteBefore ${day}`);
      for (const key of [...salts.keys()]) if (key < day) salts.delete(key);
    },
    async get(day) {
      calls.push(`get ${day}`);
      return salts.get(day) ?? null;
    },
    async insert(day, salt) {
      calls.push(`insert ${day}`);
      if (!salts.has(day)) salts.set(day, salt);
    },
  };
  return { calls, salts, store };
}

test("a new day's salt is created once and the days before it are deleted", async () => {
  const { calls, salts, store } = memoryStore({ "2026-09-21": "old", "2026-09-22": "yesterday" });
  const salt = await saltFor(store, "2026-09-23", () => "fresh");
  assert.equal(salt, "fresh");
  assert.deepEqual([...salts.keys()], ["2026-09-23"]);
  assert.deepEqual(calls, ["get 2026-09-23", "deleteBefore 2026-09-23", "insert 2026-09-23", "get 2026-09-23"]);

  calls.length = 0;
  assert.equal(await saltFor(store, "2026-09-23", () => "other"), "fresh");
  assert.deepEqual(calls, [], "the same day is served from memory");
});

test("when another instance created the salt first, its salt wins", async () => {
  const { store } = memoryStore();
  const racing: SaltStore = {
    ...store,
    async get(day) {
      return (await store.get(day)) ?? null;
    },
    async insert(day, salt) {
      await store.insert(day, "theirs");
      await store.insert(day, salt);
    },
  };
  assert.equal(await saltFor(racing, "2026-09-30", () => "mine"), "theirs");
});
