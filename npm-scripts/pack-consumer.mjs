import assert from "node:assert/strict";
import { test } from "node:test";
import { MCP_PATH } from "@tumpel/api/constants";
import { checkCredential } from "@tumpel/api/credentials";
import openapi from "@tumpel/openapi/openapi.json" with { type: "json" };
import { BaseLayout, HostEnrolSchema, StartedSessionSchema as StrictStartedSession } from "@tumpel/schemas";
import {
  ConnectionSummarySchema,
  containsUnrecognised,
  EventProblemSchema,
  PersonaFileSchema,
  SecretKeySchema,
  SessionSchema,
  StartedSessionSchema,
  TranscriptPageSchema,
  TurnSchema,
} from "@tumpel/schemas/responses";
import { z } from "zod";

const turn = {
  turnId: "turn-1",
  tenantId: "tenant-1",
  sessionId: "session-1",
  boxId: "box-1",
  prompt: "Check the build",
  goal: "Pass all tests",
  lineCount: 0,
  image: { kind: "Full", guestImageDigest: "a".repeat(64) },
  createdAt: 1000,
  updatedAt: 2000,
};
const failed = {
  ...turn,
  state: "Failed",
  reason: "HostOffline",
  detail: "Unrecognised",
  failedAt: "2026-11-24T08:30:00Z",
};
const session = {
  sessionId: turn.sessionId,
  tenantId: turn.tenantId,
  principalId: "principal-1",
  hostId: "host-1",
  boxId: turn.boxId,
  personaId: "persona-1",
  repository: "https://github.com/tumpel/protocol",
  origin: { kind: "Prompt" },
  startedBy: { kind: "Person", principalId: "principal-1" },
  tags: ["build"],
  harness: "ClaudeCode",
  harnessVersion: "1",
  model: "claude",
  lastTurnId: turn.turnId,
  lastTurnState: "Failed",
  lastTurnAt: failed.failedAt,
  lastTurn: failed,
  lastTurnImage: turn.image,
  prebuildLayer: { layer: "None", reason: "NotRecorded", detail: "No prebuild was recorded." },
  boxRetention: "Warm",
  createdAt: turn.createdAt,
  updatedAt: turn.updatedAt,
};
const known = { ...session, state: "Idle" };
const sessions = z.array(SessionSchema);

test("all three tarballs install and import with plain Node", () => {
  assert.equal(BaseLayout.Version, 1);
  assert.equal(typeof HostEnrolSchema.safeParse, "function");
  assert.ok(openapi.components.schemas.SupervisorRelease);
  assert.equal(MCP_PATH, "/mcp");
  assert.equal(typeof checkCredential, "function");
});

test("a new failure reason in a session answer decodes only with the response schema", () => {
  const newerTurn = { ...failed, reason: "NewFailure" };
  const answer = { session: { ...known, lastTurn: newerTurn }, turn: newerTurn };
  const decoded = StartedSessionSchema.parse(answer);
  assert.deepEqual(decoded, {
    session: { ...known, lastTurn: { ...failed, reason: "Unrecognised" } },
    turn: { ...failed, reason: "Unrecognised" },
  });
  assert.equal(containsUnrecognised(StartedSessionSchema, decoded), true);
  assert.equal(StartedSessionSchema.safeParse({ ...answer, turn: { ...failed, reason: 7 } }).success, false);
  assert.equal(StrictStartedSession.safeParse(answer).success, false);
  assert.deepEqual(StrictStartedSession.parse({ session: known, turn: failed }), { session: known, turn: failed });
});

test("unknown states preserve the session and turn base fields", () => {
  assert.deepEqual(SessionSchema.parse({ ...session, state: "NewSessionState", newField: 7 }), {
    ...session,
    state: "Unrecognised",
  });
  assert.deepEqual(TurnSchema.parse({ ...turn, state: "NewTurnState", newField: 7 }), {
    ...turn,
    state: "Unrecognised",
  });
  assert.equal(TurnSchema.safeParse({ ...turn, state: "Failed", reason: "NewFailure" }).success, false);
  assert.equal(SessionSchema.safeParse({ ...known, repository: undefined, state: "NewSessionState" }).success, false);
});

test("a session list keeps all rows and signals an unknown enum or state", () => {
  const enumRow = { ...known, sessionId: "session-2", lastTurn: { ...failed, sessionId: "session-2" } };
  const stateRow = { ...session, sessionId: "session-3", lastTurn: { ...failed, sessionId: "session-3" } };
  const decoded = sessions.parse([
    known,
    { ...enumRow, lastTurn: { ...enumRow.lastTurn, reason: "NewFailure" } },
    { ...stateRow, state: "NewSessionState", newField: true },
  ]);
  assert.deepEqual(decoded, [
    known,
    { ...enumRow, lastTurn: { ...enumRow.lastTurn, reason: "Unrecognised" } },
    { ...stateRow, state: "Unrecognised" },
  ]);
  assert.equal(containsUnrecognised(sessions, decoded), true);
  assert.equal(containsUnrecognised(sessions, [decoded[1]]), true);
  assert.equal(containsUnrecognised(sessions, [decoded[2]]), true);
});

test("free text and extra fields in a list answer give no update signal", () => {
  const answer = [known];
  assert.equal(containsUnrecognised(sessions, sessions.parse(answer)), false);
  const withExtraField = sessions.parse([{ ...known, newField: "Unrecognised" }]);
  assert.deepEqual(withExtraField, answer);
  assert.equal(containsUnrecognised(sessions, withExtraField), false);
});

test("unknown tags preserve fields shared by connection, persona file, secret key and transcript variants", () => {
  assert.deepEqual(ConnectionSummarySchema.parse({ kind: "GitHub", state: "NewState", account: "person" }), {
    kind: "GitHub",
    state: "Unrecognised",
  });
  const file = { path: "README.md", digest: "a".repeat(64), sizeBytes: 42, createdAt: 1000, updatedAt: 2000 };
  assert.deepEqual(PersonaFileSchema.parse({ ...file, source: "NewSource", content: "ignored" }), {
    ...file,
    source: "Unrecognised",
  });
  assert.equal(PersonaFileSchema.safeParse({ ...file, source: "Inline" }).success, false);
  assert.deepEqual(SecretKeySchema.parse({ kind: "NewKind", name: "API_KEY", updatedAt: 2000 }), {
    kind: "Unrecognised",
    name: "API_KEY",
    updatedAt: 2000,
  });
  const page = { sessionState: "Idle", cursor: 42, finished: false };
  assert.deepEqual(TranscriptPageSchema.parse({ ...page, form: "NewForm" }), { ...page, form: "Unrecognised" });
});

test("an event problem with an unknown code keeps its details and signals an update", () => {
  const problem = { title: "Could not read events", detail: "The read failed.", fix: "Open the stream again." };
  const decoded = EventProblemSchema.parse({ ...problem, code: "NewProblem" });
  assert.deepEqual(decoded, { ...problem, code: "Unrecognised" });
  assert.equal(containsUnrecognised(EventProblemSchema, decoded), true);
});

test("request-only unions are absent from the response entry point", async () => {
  const responses = await import("@tumpel/schemas/responses");
  for (const name of ["ConfigFileWriteSchema", "BootImageSchema", "TenantRequestSchema", "UnplaceableSchema"]) {
    assert.equal(Object.hasOwn(responses, name), false, name);
  }
});
