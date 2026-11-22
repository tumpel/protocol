import assert from "node:assert/strict";
import { test } from "node:test";
import { PersonaListSchema, PersonaSchema } from "../build/schemas/schemas.ts";

const persona = {
  personaId: "persona-test",
  tenantId: "tenant-test",
  name: "reviewer",
  harness: "ClaudeCode",
  secretSetId: "secret-set-test",
  connectorIds: [],
  boxRetention: "Auto",
  tumpelMcp: true,
  files: [
    {
      path: ".claude/CLAUDE.md",
      digest: "a".repeat(64),
      sizeBytes: 6,
      createdAt: 1000,
      updatedAt: 2000,
    },
  ],
  createdAt: 1000,
  updatedAt: 2000,
};

test("persona lists accept an older server's content and unknown fields while reads keep content", () => {
  const previous = {
    ...persona,
    futureField: "unknown",
    files: [
      { ...persona.files[0], source: "Inline", content: "aGVsbG8K", futureField: "unknown" },
      {
        ...persona.files[0],
        path: ".claude/settings.json",
        source: "Stored",
        downloadUrl: "https://files.example.test/persona",
        downloadExpiresAt: "2026-11-22T12:00:00Z",
      },
    ],
  };
  assert.deepEqual(PersonaListSchema.parse([previous]), [
    { ...persona, files: [persona.files[0], { ...persona.files[0], path: ".claude/settings.json" }] },
  ]);
  const read = PersonaSchema.parse(previous);
  assert.equal(read.files[0].content, "aGVsbG8K");
  assert.equal(read.files[1].downloadUrl, "https://files.example.test/persona");
  assert.deepEqual(
    PersonaListSchema.parse([{ ...persona, files: [{ ...persona.files[0], source: "FutureSource" }] }]),
    [persona],
  );
});

test("persona lists accept 10,000 entries and refuse one more", () => {
  assert.equal(PersonaListSchema.parse(Array(10_000).fill(persona)).length, 10_000);
  const result = PersonaListSchema.safeParse(Array(10_001).fill(persona));
  assert.equal(result.success, false);
  assert.equal(result.error.issues[0].code, "too_big");
  assert.equal(result.error.issues[0].maximum, 10_000);
});
