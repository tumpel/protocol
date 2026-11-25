import assert from "node:assert/strict";
import { test } from "node:test";
import { decode, InvitationCreateSchema } from "../build/schemas/schemas.ts";

test("the named schemas refuse an unknown enum value", () => {
  assert.equal(InvitationCreateSchema.safeParse({ email: "a@example.com", role: "Admin" }).success, false);
});

test("decode reads an unknown enum value as Unrecognised and names it", () => {
  assert.deepEqual(decode("InvitationCreateSchema", { email: "a@example.com", role: "Admin" }), {
    success: true,
    data: { email: "a@example.com", role: "Unrecognised" },
    unrecognised: ["Admin"],
  });
});

test("decode keeps the payload of an unknown tag", () => {
  assert.deepEqual(decode("SessionOriginSchema", { kind: "Pull", pullNumber: 7 }), {
    success: true,
    data: { kind: "Unrecognised", pullNumber: 7 },
    unrecognised: ["Pull"],
  });
});

test("decode still validates a known tag", () => {
  assert.equal(decode("SessionOriginSchema", { kind: "Issue", issueNumber: 7 }).success, false);
});

test("decode names nothing from a plain union branch that failed", () => {
  const usage = [{ measure: "NewMeasure", window: "NewWindow", limit: 1 }];
  assert.deepEqual(decode("TenantLimitsSetSchema", { reset: true, usage }), {
    success: true,
    data: { reset: true },
    unrecognised: [],
  });
});
