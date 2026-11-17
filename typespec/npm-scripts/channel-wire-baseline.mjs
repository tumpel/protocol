import { spawnSync } from "node:child_process";
import { basename } from "node:path";
import { lockVersion } from "./channel-window.mjs";

export const LOCK_DIR_PATH = "typespec/channel-wire";

export const git = (cwd, args) => {
  const { status, stdout, stderr } = spawnSync("git", args, { cwd, encoding: "utf8" });
  return { ok: status === 0, stdout, stderr: stderr.trim() };
};

export const baselineLockTexts = (cwd, ref) => {
  const list = (dir) => git(cwd, ["ls-tree", "--full-tree", "--name-only", ref, `${dir}/`]);
  const listed = list(LOCK_DIR_PATH);
  if (!listed.ok) return { ok: false, error: listed.stderr };
  const paths = listed.stdout.split("\n").filter((path) => lockVersion(basename(path)) !== undefined);
  const shown = paths.map((path) => [lockVersion(basename(path)), git(cwd, ["show", `${ref}:${path}`])]);
  const failed = shown.find(([, result]) => !result.ok);
  if (failed !== undefined) return { ok: false, error: failed[1].stderr };
  return { ok: true, locks: new Map(shown.map(([version, result]) => [version, result.stdout])) };
};
