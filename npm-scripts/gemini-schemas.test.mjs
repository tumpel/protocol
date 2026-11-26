import assert from "node:assert/strict";
import { test } from "node:test";
import {
  ClaudeSetupHarnessSchema,
  ClaudeSetupMemberSchema,
  GuestHarnessProtocolSchema,
  HarnessSchema,
  InstallRecipeSchema,
} from "../build/schemas/schemas.ts";

test("the named schemas accept the Gemini harness values", () => {
  assert.equal(HarnessSchema.parse("Gemini"), "Gemini");
  assert.equal(ClaudeSetupHarnessSchema.parse("Gemini"), "Gemini");
  assert.equal(ClaudeSetupMemberSchema.parse("GEMINI_OAUTH_CREDS_JSON"), "GEMINI_OAUTH_CREDS_JSON");
  assert.equal(GuestHarnessProtocolSchema.parse("GeminiStreamJson"), "GeminiStreamJson");
});

test("a zip install recipe lets both architectures name the same bundle", () => {
  const archive = {
    url: "https://github.com/google-gemini/gemini-cli/releases/download/v0.71.1/gemini-cli-bundle.zip",
    sha256: "a".repeat(64),
    binaryPath: "gemini.js",
    siblingBinaryPaths: [],
  };
  const recipe = {
    kind: "Zip",
    archives: [
      { architecture: "Amd64", ...archive },
      { architecture: "Arm64", ...archive },
    ],
    stripComponents: 0,
  };
  assert.deepEqual(InstallRecipeSchema.parse(recipe), recipe);
});
