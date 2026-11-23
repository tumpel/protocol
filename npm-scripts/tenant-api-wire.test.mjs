import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { copyFileSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

test("a stacked tenant version freezes inherited locks without changing main's locks", (t) => {
  const repo = mkdtempSync(join(tmpdir(), "tenant-api-wire-"));
  t.after(() => rmSync(repo, { recursive: true, force: true }));
  const scripts = join(repo, "typespec/npm-scripts");
  const locks = join(repo, "typespec/tenant-api");
  mkdirSync(scripts, { recursive: true });
  mkdirSync(locks, { recursive: true });
  mkdirSync(join(repo, "build/openapi"), { recursive: true });
  for (const name of ["tenant-api-wire", "channel-wire-baseline", "channel-wire-shape", "channel-window"])
    copyFileSync(new URL(`../typespec/npm-scripts/${name}.mjs`, import.meta.url), join(scripts, `${name}.mjs`));
  const git = (...args) => {
    const result = spawnSync("git", args, { cwd: repo, encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
  };
  git("init", "--quiet");
  writeFileSync(join(locks, "v28.json"), "{}\n");
  git("add", "typespec/tenant-api");
  git("-c", "user.name=test", "-c", "user.email=test@example.test", "commit", "--quiet", "-m", "main lock");
  git("update-ref", "refs/remotes/origin/main", "HEAD");
  writeFileSync(join(locks, "v29.json"), "{}\n");
  git("add", "typespec/tenant-api");
  git("-c", "user.name=test", "-c", "user.email=test@example.test", "commit", "--quiet", "-m", "inherited lock");
  writeFileSync(
    join(repo, "build/openapi/openapi.json"),
    JSON.stringify({
      components: {
        schemas: {
          TenantApiProtocol: { type: "integer", minimum: 28, maximum: 30, "x-bound-names": ["Oldest", "Version"] },
        },
      },
    }),
  );
  const run = () => spawnSync(process.execPath, [join(scripts, "tenant-api-wire.mjs")], { encoding: "utf8" });
  const inherited = run();
  assert.equal(inherited.status, 0, inherited.stderr);
  writeFileSync(join(locks, "v29.json"), '{"changed":true}\n');
  const changedInherited = run();
  assert.equal(changedInherited.status, 1);
  assert.match(changedInherited.stderr, /frozen locks v29/);
  writeFileSync(join(locks, "v29.json"), "{}\n");
  writeFileSync(join(locks, "v28.json"), '{"changed":true}\n');
  git("add", "typespec/tenant-api/v28.json");
  git("-c", "user.name=test", "-c", "user.email=test@example.test", "commit", "--quiet", "-m", "changed main lock");
  const changedMain = run();
  assert.equal(changedMain.status, 1);
  assert.match(changedMain.stderr, /frozen locks v28/);
});
