#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { channelWindowPaths, raiseOldest } from "./channel-window.mjs";

const apiRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = join(apiRoot, "..");
const paths = channelWindowPaths(apiRoot);

if (!process.argv.includes("--confirm-fleet-drained")) {
  console.error(
    "channel:drop: raising ChannelProtocol.Oldest locks out every host still on the oldest version; check that no host still speaks it, then run npm run channel:drop -- --confirm-fleet-drained",
  );
  process.exit(1);
}

const { oldest, version, removed } = raiseOldest(paths);
const { status } = spawnSync("npm", ["run", "generate"], { cwd: repoRoot, stdio: "inherit" });
if (status !== 0) {
  console.error("channel:drop: npm run generate failed; fix the error above and run npm run generate again");
  process.exit(1);
}
console.log(
  `channel:drop: ChannelProtocol speaks ${oldest} to ${version}; removed ${removed.map((path) => relative(repoRoot, path)).join(", ")}`,
);
