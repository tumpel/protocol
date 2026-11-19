#!/usr/bin/env node
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { lockVersion } from "./channel-window.mjs";
import { baselineLockTexts, git } from "./channel-wire-baseline.mjs";
import {
  channelProtocolRange,
  channelWireLock,
  lockShape,
  TENANT_API_WIRE,
  wireChanges,
} from "./channel-wire-shape.mjs";

export const TENANT_API_LOCK_DIR_PATH = "typespec/tenant-api";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const lockDir = join(root, "tenant-api");
const schemas = JSON.parse(readFileSync(join(root, "..", "build", "openapi", "openapi.json"), "utf8")).components
  .schemas;
const range = channelProtocolRange(schemas, TENANT_API_WIRE);
const currentLock = channelWireLock(schemas, TENANT_API_WIRE);
const current = lockShape(currentLock, TENANT_API_WIRE);

const fail = (message) => {
  console.error(`tenant-api-wire: ${message}`);
  process.exit(1);
};

const base = git(root, ["merge-base", "HEAD", "origin/main"]);
if (!base.ok)
  fail(`HEAD has no merge-base with origin/main (${base.stderr}); fetch origin main and run the check again`);
const baseline = baselineLockTexts(root, base.stdout.trim(), TENANT_API_LOCK_DIR_PATH);
if (!baseline.ok) fail(`could not read ${TENANT_API_LOCK_DIR_PATH} at origin/main (${baseline.error})`);
const locks = new Map(
  readdirSync(lockDir)
    .filter((name) => lockVersion(name) !== undefined)
    .map((name) => [lockVersion(name), readFileSync(join(lockDir, name), "utf8")]),
);
const frozen = [...locks].filter(([version, text]) => version < range.version && baseline.locks.get(version) !== text);
if (frozen.length > 0)
  fail(
    `the frozen locks ${frozen.map(([version]) => `v${version}`).join(", ")} differ from origin/main; restore them with git checkout origin/main -- ${TENANT_API_LOCK_DIR_PATH}`,
  );
const stale = [...locks.keys()].filter((version) => version < range.oldest || version > range.version);
if (stale.length > 0)
  fail(
    `TenantApiProtocol speaks ${range.oldest} to ${range.version} but the locks hold ${stale.map((version) => `v${version}`).join(", ")}; delete them`,
  );
const release = git(root, ["describe", "--tags", "--abbrev=0", "--match", "v[0-9]*", base.stdout.trim()]);
const released = release.ok
  ? baselineLockTexts(root, release.stdout.trim(), TENANT_API_LOCK_DIR_PATH)
  : { ok: true, locks: baseline.locks };
if (!released.ok) fail(`could not read ${TENANT_API_LOCK_DIR_PATH} at ${release.stdout.trim()} (${released.error})`);
const newest = Math.max(...released.locks.keys());
if (released.locks.size > 0 && range.version === newest) {
  const before = lockShape(JSON.parse(released.locks.get(newest)), TENANT_API_WIRE);
  const changes = wireChanges(before, current).filter(
    (change) => !change.startsWith("added TenantApi.TenantRequest variant "),
  );
  if (changes.length > 0)
    fail(
      `the Tenant API changed while TenantApiVersion stays ${range.version} (${changes.join(", ")}); a new operation is the only change that keeps the version, so raise TenantApiVersion and keep serving the previous version for one deploy`,
    );
}
writeFileSync(join(lockDir, `v${range.version}.json`), `${JSON.stringify(currentLock, null, 2)}\n`);
