#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { copyFileSync, mkdirSync, readdirSync, rmSync, writeFileSync } from "node:fs";
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
copyFileSync(new URL("pack-consumer.mjs", import.meta.url), join(scratch, "check.mjs"));
execFileSync(process.execPath, ["--test", "check.mjs"], { cwd: scratch, stdio: "inherit", timeout: 45_000 });
