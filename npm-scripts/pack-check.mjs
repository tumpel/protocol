#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { mkdirSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const dist = join(root, "dist");
const scratch = join(root, ".tmp", "pack-check");
const tarballs = readdirSync(dist)
  .filter((name) => name.endsWith(".tgz"))
  .map((name) => join(dist, name));
if (tarballs.length !== 3) throw new Error(`dist holds ${tarballs.length} tarballs, not 3; run npm run pack first`);

rmSync(scratch, { recursive: true, force: true });
mkdirSync(scratch, { recursive: true });
writeFileSync(join(scratch, "package.json"), '{ "private": true, "type": "module" }\n');
execFileSync("npm", ["install", "--no-audit", "--no-fund", ...tarballs], { cwd: scratch, stdio: "inherit" });
writeFileSync(
  join(scratch, "check.mjs"),
  [
    'import { BaseLayout, HostEnrolSchema } from "@tumpel/schemas";',
    'import openapi from "@tumpel/openapi/openapi.json" with { type: "json" };',
    'import { MCP_PATH } from "@tumpel/api/constants";',
    'import { checkCredential } from "@tumpel/api/credentials";',
    'if (BaseLayout.Version !== 1 || typeof HostEnrolSchema.safeParse !== "function" || !openapi.components.schemas.SupervisorRelease)',
    '  throw new Error("the installed tarballs do not export the generated schemas");',
    'if (MCP_PATH !== "/mcp" || typeof checkCredential !== "function")',
    '  throw new Error("the installed @tumpel/api tarball does not export its constants and credential checks");',
    'console.log("pack-check: all three tarballs install and import with plain node");',
    "",
  ].join("\n"),
);
execFileSync(process.execPath, ["check.mjs"], { cwd: scratch, stdio: "inherit" });
