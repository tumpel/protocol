import assert from "node:assert/strict";
import { test } from "node:test";
import { ListSessionsInputSchema, ListSessionsResultSchema, SessionListQuerySchema } from "../build/schemas/schemas.ts";

test("session list accepts whole page sizes from 1 through 50", () => {
  assert.deepEqual(SessionListQuerySchema.parse({ limit: 1 }), { limit: 1 });
  assert.deepEqual(SessionListQuerySchema.parse({ limit: 50 }), { limit: 50 });
  assert.equal(SessionListQuerySchema.safeParse({ limit: 0 }).success, false);
  assert.equal(SessionListQuerySchema.safeParse({ limit: 2.5 }).success, false);
  assert.equal(SessionListQuerySchema.safeParse({ limit: 51 }).success, false);
});

test("session list refuses a query without a page size", () => {
  assert.equal(SessionListQuerySchema.safeParse({}).success, false);
  assert.equal(SessionListQuerySchema.safeParse({ after: "session-1" }).success, false);
});

test("tenant session list accepts a cursor and whole page sizes from 1 through 50", () => {
  const tenantId = "tenant-1";
  const after = "session-1";
  for (const limit of [1, 50]) {
    const input = { tenantId, filter: { limit, after } };
    assert.deepEqual(ListSessionsInputSchema.parse(input), input);
  }
  for (const limit of [0, 2.5, 51]) {
    assert.equal(ListSessionsInputSchema.safeParse({ tenantId, filter: { limit, after } }).success, false);
  }
  assert.equal(ListSessionsInputSchema.safeParse({ tenantId, filter: {} }).success, false);
  assert.equal(ListSessionsInputSchema.safeParse({ tenantId, filter: { after } }).success, false);
});

test("tenant session list accepts null when the cursor session is unknown", () => {
  assert.deepEqual(ListSessionsResultSchema.parse({ sessions: null }), { sessions: null });
});
