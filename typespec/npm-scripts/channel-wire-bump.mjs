#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { channelWindowPaths, raiseVersion } from "./channel-window.mjs";

const apiRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = join(apiRoot, "..");
const paths = channelWindowPaths(apiRoot);

const run = (command, args) => {
  const { status } = spawnSync(command, args, { cwd: repoRoot, stdio: "inherit" });
  if (status === 0) return;
  console.error(`channel:bump: ${command} ${args.join(" ")} failed; fix the error above and run npm run generate`);
  process.exit(1);
};

const { oldest, version } = raiseVersion(paths);
run("npm", ["run", "generate"]);
console.log(`channel:bump: ChannelProtocol speaks ${oldest} to ${version}; change the data types for ${version} now`);
