import assert from "node:assert/strict";
import { test } from "node:test";
import {
  ControlPlaneSettingsSchema,
  PersonaCreateSchema,
  PersonaPatchSchema,
  PersonaSchema,
  PersonaUpdateSchema,
  SessionSchema,
  SessionStartFromIssueSchema,
  SessionStartSchema,
} from "../build/schemas/schemas.ts";

test("persona, session and setting budgets accept only whole seconds from 1 through 86400", () => {
  for (const model of [
    PersonaSchema,
    PersonaCreateSchema,
    PersonaUpdateSchema,
    PersonaPatchSchema,
    SessionSchema,
    SessionStartSchema,
    SessionStartFromIssueSchema,
    ControlPlaneSettingsSchema,
  ]) {
    const budget = model.shape.turnTotalBudgetSeconds;
    for (const value of [1, 3600, 14400, 86400]) assert.equal(budget.safeParse(value).success, true);
    for (const value of [0, -1, 86401, 1.5, null]) assert.equal(budget.safeParse(value).success, false);
  }
});
