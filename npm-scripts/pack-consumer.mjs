import assert from "node:assert/strict";
import { test } from "node:test";
import { MCP_PATH } from "@tumpel/api/constants";
import openapi from "@tumpel/openapi/openapi.json" with { type: "json" };
import * as schemas from "@tumpel/schemas";
import { z } from "zod";

const failed = {
  turnId: "turn-1",
  tenantId: "tenant-1",
  sessionId: "session-1",
  boxId: "box-1",
  prompt: "Check the build",
  lineCount: 0,
  createdAt: 1000,
  updatedAt: 2000,
  state: "Failed",
  reason: "HostOffline",
  detail: "Unrecognised",
  failedAt: "2026-11-24T08:30:00Z",
};
const session = {
  sessionId: failed.sessionId,
  tenantId: failed.tenantId,
  principalId: "principal-1",
  hostId: "host-1",
  boxId: failed.boxId,
  personaId: "persona-1",
  repository: "https://github.com/tumpel/protocol",
  origin: { kind: "Prompt" },
  startedBy: { kind: "Person", principalId: "principal-1" },
  tags: ["build"],
  harness: "ClaudeCode",
  harnessVersion: "1",
  model: "claude",
  lastTurnId: failed.turnId,
  lastTurnState: "Failed",
  lastTurnAt: failed.failedAt,
  lastTurn: failed,
  boxRetention: "Warm",
  createdAt: failed.createdAt,
  updatedAt: failed.updatedAt,
  state: "Idle",
};
test("the tarballs decode a mixed session list and name the unknown wire values", () => {
  assert.deepEqual([MCP_PATH, openapi.paths["/v1/sessions"].get.operationId], ["/mcp", "Sessions_list"]);
  const list = z.array(schemas.SessionSchema);
  const enumRow = { ...session, lastTurn: { ...failed, reason: "NewFailure" } };
  const unionRow = { ...session, state: "NewState", future: { status: "Ready" } };
  const decodedEnum = { ...enumRow, lastTurn: { ...failed, reason: "Unrecognised" } };
  assert.deepEqual(schemas.decode(list, [session, enumRow, unionRow]), {
    data: [session, decodedEnum, { ...unionRow, state: "Unrecognised" }],
    unrecognised: ["NewFailure", "NewState"],
  });
  const extra = { ...session, future: { reason: "NewFailure" } };
  assert.deepEqual(schemas.decode(list, [extra]), { data: [session], unrecognised: [] });
});

test("unknown tags retain payloads and known tags still validate required fields", () => {
  const connection = { kind: "GitHub", state: "NewConnection", account: "person" };
  assert.deepEqual(schemas.decode(schemas.ConnectionSummarySchema, connection), {
    data: { ...connection, state: "Unrecognised" },
    unrecognised: ["NewConnection"],
  });
  assert.throws(() => schemas.decode(schemas.TurnSchema, { ...failed, detail: undefined }), z.ZodError);
  assert.throws(() => schemas.decode(schemas.TurnSchema, { ...failed, reason: 7 }), z.ZodError);
});

test("plain unions record values from the successful branch", () => {
  const problem = { code: "NewProblem", title: "Read failed", detail: "The stream closed.", fix: "Open it again." };
  assert.deepEqual(schemas.decode(schemas.EventProblemSchema, problem), {
    data: { ...problem, code: "Unrecognised" },
    unrecognised: ["NewProblem"],
  });
  const message = { type: "SnapshotChunks", snapshotId: "snapshot", part: 1, digests: [] };
  const input = { hostId: "host", tenantId: "tenant", message };
  const extra = { ...input, message: { ...message, reason: "NewFailure" } };
  assert.deepEqual(schemas.decode(schemas.HostMessageInputSchema, extra), { data: input, unrecognised: [] });
});
