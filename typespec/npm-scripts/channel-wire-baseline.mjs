import { spawnSync } from "node:child_process";
import { basename } from "node:path";
import { lockVersion } from "./channel-window.mjs";

export const LOCK_DIR_PATH = "typespec/channel-wire";

export const git = (cwd, args) => {
  const { status, stdout, stderr } = spawnSync("git", args, { cwd, encoding: "utf8" });
  return { ok: status === 0, stdout, stderr: stderr.trim() };
};

export const baselineRef = (root, fail) => {
  if (!git(root, ["rev-parse", "--verify", "--quiet", "origin/main"]).ok) {
    const fetched = git(root, ["fetch", "--no-tags", "--depth=1", "origin", "main"]);
    if (!fetched.ok)
      fail(
        `origin/main is not in this checkout and fetching it failed (${fetched.stderr}); the wire shape needs it as the baseline, so add a remote named origin that holds main and run the check again`,
      );
    if (!git(root, ["update-ref", "refs/remotes/origin/main", "FETCH_HEAD"]).ok)
      fail("fetched origin main but could not point origin/main at it; run git fetch origin main and try again");
  }
  const base = git(root, ["merge-base", "HEAD", "origin/main"]);
  if (base.ok) return base.stdout.trim();
  if (git(root, ["rev-parse", "--is-shallow-repository"]).stdout.trim() === "true") return "origin/main";
  return fail(
    `HEAD and origin/main share no commit (${base.stderr}), so there is no baseline for the wire shape; rebase onto origin/main and run the check again`,
  );
};

export const baselineLockTexts = (cwd, ref, dir = LOCK_DIR_PATH) => {
  const list = (dir) => git(cwd, ["ls-tree", "--full-tree", "--name-only", ref, `${dir}/`]);
  const listed = list(dir);
  if (!listed.ok) return { ok: false, error: listed.stderr };
  const paths = listed.stdout.split("\n").filter((path) => lockVersion(basename(path)) !== undefined);
  const shown = paths.map((path) => [lockVersion(basename(path)), git(cwd, ["show", `${ref}:${path}`])]);
  const failed = shown.find(([, result]) => !result.ok);
  if (failed !== undefined) return { ok: false, error: failed[1].stderr };
  return { ok: true, locks: new Map(shown.map(([version, result]) => [version, result.stdout])) };
};
