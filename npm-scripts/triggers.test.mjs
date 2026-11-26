import assert from "node:assert/strict";
import { test } from "node:test";
import { ConfigTriggerSchema, TriggerCreateSchema, TriggerSchema } from "../build/schemas/schemas.ts";

test("a trigger may target a session and listen to check suites and reviews", () => {
  for (const event of ["check_suite", "pull_request_review"]) {
    const create = {
      name: `wake-session-1-pr-7-${event}`,
      source: { kind: "GitHub", event, conditions: [{ field: "repository.full_name", values: ['"tumpel/protocol"'] }] },
      sessionId: "session-1",
      personaId: "persona-1",
      model: "claude-opus-5-5",
      prompt: "PR 7: {{action}}",
    };
    assert.deepEqual(TriggerCreateSchema.parse(create), create);
    const trigger = {
      ...create,
      triggerId: "trigger-1",
      tenantId: "tenant-1",
      principalId: "principal-1",
      createdAt: 1,
      updatedAt: 1,
    };
    assert.deepEqual(TriggerSchema.parse(trigger), trigger);
  }
});

test("a config trigger naming a target session is refused", () => {
  const configTrigger = {
    name: "agent-review",
    source: { kind: "GitHub", event: "status", conditions: [] },
    model: "claude-opus-5-5",
    prompt: "Review {{sha}}",
    personaName: "reviewer",
  };
  assert.deepEqual(ConfigTriggerSchema.parse(configTrigger), configTrigger);
  const refused = ConfigTriggerSchema.safeParse({ ...configTrigger, sessionId: "session-1" });
  assert.equal(refused.success, false);
  assert.deepEqual(
    refused.error.issues.map((issue) => issue.path),
    [["sessionId"]],
  );
});
