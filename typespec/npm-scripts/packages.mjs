#!/usr/bin/env node
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const build = join(root, "build");
const cargo = readFileSync(join(root, "Cargo.toml"), "utf8");
const version = cargo.match(/^version = "([^"]+)"$/m)?.[1];
if (version === undefined)
  throw new Error("Cargo.toml names no workspace package version; add version under [workspace.package]");

const packages = {
  schemas: {
    name: "@tumpel/schemas",
    files: [
      "schemas.js",
      "schemas.d.ts",
      "responses.js",
      "responses.d.ts",
      "response-decoding.js",
      "response-decoding.d.ts",
    ],
    exports: {
      ".": { types: "./schemas.d.ts", default: "./schemas.js" },
      "./responses": { types: "./responses.d.ts", default: "./responses.js" },
    },
    dependencies: { zod: "^4.6.7" },
  },
  openapi: {
    name: "@tumpel/openapi",
    files: ["openapi.json", "paths.js", "paths.d.ts", "frozen/*.js", "frozen/*.d.ts"],
    exports: {
      "./openapi.json": "./openapi.json",
      "./paths": { types: "./paths.d.ts", default: "./paths.js" },
      "./frozen/*": { types: "./frozen/*.d.ts", default: "./frozen/*.js" },
    },
  },
  api: {
    name: "@tumpel/api",
    files: ["constants.js", "constants.d.ts", "credentials.js", "credentials.d.ts"],
    exports: {
      "./constants": { types: "./constants.d.ts", default: "./constants.js" },
      "./credentials": { types: "./credentials.d.ts", default: "./credentials.js" },
    },
    peerDependencies: { "@tumpel/schemas": version, zod: "^4.6.7" },
  },
};

for (const [dir, { name, ...rest }] of Object.entries(packages)) {
  const manifest = {
    name,
    version,
    license: "Apache-2.0",
    repository: { type: "git", url: "git+https://github.com/tumpel/protocol.git" },
    type: "module",
    ...rest,
  };
  mkdirSync(join(build, dir), { recursive: true });
  writeFileSync(join(build, dir, "package.json"), `${JSON.stringify(manifest, null, 2)}\n`);
}
