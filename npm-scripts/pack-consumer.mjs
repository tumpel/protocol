import assert from "node:assert/strict";
import { test } from "node:test";
import { MCP_PATH } from "@tumpel/api/constants";
import openapi from "@tumpel/openapi/openapi.json" with { type: "json" };
import { decode, SessionSchema } from "@tumpel/schemas";

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
  const enumRow = { ...session, lastTurn: { ...failed, reason: "NewFailure" } };
  const unionRow = { ...session, state: "NewState", future: { status: "Ready" } };
  assert.equal(SessionSchema.safeParse(unionRow).success, false);
  assert.deepEqual(decode("ListSessionsResultSchema", { sessions: [session, enumRow, unionRow] }), {
    success: true,
    data: {
      sessions: [
        session,
        { ...enumRow, lastTurn: { ...failed, reason: "Unrecognised" } },
        { ...unionRow, state: "Unrecognised" },
      ],
    },
    unrecognised: ["NewFailure", "NewState"],
  });
  assert.deepEqual(decode("SessionSchema", { ...session, future: "NewFailure" }).unrecognised, []);
  assert.equal(decode("TurnSchema", { ...failed, reason: 7 }).success, false);
});
