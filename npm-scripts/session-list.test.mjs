import assert from "node:assert/strict";
import { test } from "node:test";
import { SessionListQuerySchema } from "../build/schemas/schemas.ts";

test("session list accepts page sizes from 1 through 50 and a session cursor", () => {
  assert.deepEqual(SessionListQuerySchema.parse({ limit: 1 }), { limit: 1 });
  assert.deepEqual(SessionListQuerySchema.parse({ limit: 50, after: "session-test" }), {
    limit: 50,
    after: "session-test",
  });
  assert.equal(SessionListQuerySchema.safeParse({ limit: 0 }).success, false);
  assert.equal(SessionListQuerySchema.safeParse({ limit: 51 }).success, false);
});
