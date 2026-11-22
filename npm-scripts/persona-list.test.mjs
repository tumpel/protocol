import assert from "node:assert/strict";
import { test } from "node:test";
import { PersonaMetadataListSchema, PersonaSchema } from "../build/schemas/schemas.ts";

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

test("metadata lists accept an older server's content and unknown fields while default lists and reads keep content", () => {
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
  assert.deepEqual(PersonaMetadataListSchema.parse([previous]), [
    { ...persona, files: [persona.files[0], { ...persona.files[0], path: ".claude/settings.json" }] },
  ]);
  const read = PersonaSchema.parse(previous);
  assert.deepEqual(PersonaSchema.array().parse([previous]), [read]);
  assert.equal(read.files[0].content, "aGVsbG8K");
  assert.equal(read.files[1].downloadUrl, "https://files.example.test/persona");
  assert.deepEqual(
    PersonaMetadataListSchema.parse([{ ...persona, files: [{ ...persona.files[0], source: "FutureSource" }] }]),
    [persona],
  );
});

test("metadata lists accept 10,000 entries and refuse one more", () => {
  assert.equal(PersonaMetadataListSchema.parse(Array(10_000).fill(persona)).length, 10_000);
  const result = PersonaMetadataListSchema.safeParse(Array(10_001).fill(persona));
  assert.equal(result.success, false);
  assert.equal(result.error.issues[0].code, "too_big");
  assert.equal(result.error.issues[0].maximum, 10_000);
});
