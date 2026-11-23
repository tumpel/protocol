#!/usr/bin/env node
import { mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import openapiTS, { astToString } from "openapi-typescript";
import { lockVersion } from "./channel-window.mjs";
import { baselineLockTexts, baselineRef, droppedLockText, LOCK_DIR_PATH } from "./channel-wire-baseline.mjs";
import { channelProtocolRange, channelWireLock, checkChannelLocks, lockShape } from "./channel-wire-shape.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const lockDir = join(root, "channel-wire");
const openapiDir = join(root, "..", "build", "openapi");
const schemas = JSON.parse(readFileSync(join(openapiDir, "openapi.json"), "utf8")).components.schemas;
const range = channelProtocolRange(schemas);
const currentLock = channelWireLock(schemas);
const current = lockShape(currentLock);
const frozenDir = join(openapiDir, "frozen");

const fail = (message) => {
  console.error(`channel-wire: ${message}`);
  process.exit(1);
};

const baselineLocks = (ref) => {
  const baseline = baselineLockTexts(root, ref);
  if (!baseline.ok)
    fail(
      `could not read the channel wire locks under ${LOCK_DIR_PATH} at ${ref} (${baseline.error}); a missing baseline is never a pass, so fetch origin main and run the check again`,
    );
  if (baseline.locks.size === 0)
    fail(
      `no channel wire locks under ${LOCK_DIR_PATH} at ${ref}; a missing baseline is never a pass, so fetch origin main and run the check again`,
    );
  return baseline.locks;
};

const workingLocks = () =>
  new Map(
    readdirSync(lockDir)
      .filter((name) => lockVersion(name) !== undefined)
      .map((name) => [lockVersion(name), readFileSync(join(lockDir, name), "utf8")]),
  );

const frozenTypes = async (version, lock) => {
  const document = {
    openapi: "3.0.0",
    info: { title: `Tumpel channel protocol ${version}`, version: String(version) },
    paths: {},
    components: { schemas: lock.schemas },
  };
  writeFileSync(join(frozenDir, `v${version}.ts`), astToString(await openapiTS(document)));
};

mkdirSync(lockDir, { recursive: true });
mkdirSync(frozenDir, { recursive: true });
const locks = workingLocks();
const base = baselineRef(root, fail);
const baseline = baselineLocks(base);
for (const version of locks.keys()) {
  if (baseline.has(version) || version >= range.version) continue;
  const shipped = droppedLockText(root, base, version);
  if (shipped !== undefined) baseline.set(version, shipped);
}
const result = checkChannelLocks(baseline, locks, current, range.oldest);
const lockList = (versions) => versions.map((version) => `${LOCK_DIR_PATH}/v${version}.json`).join(", ");
if (!result.ok && result.missing.length > 0)
  fail(
    `ChannelProtocol speaks ${range.oldest} to ${range.version} but ${lockList(result.missing)} is missing; every version in that range needs its lock, so restore it with git checkout origin/main -- ${LOCK_DIR_PATH}`,
  );
if (!result.ok && result.unexpected.length > 0)
  fail(
    `ChannelProtocol speaks ${range.oldest} to ${range.version} but ${lockList(result.unexpected)} lies outside that range; delete it, or raise Oldest with npm run channel:drop, which deletes it for you`,
  );
if (!result.ok && result.unbased.length > 0)
  fail(
    `ChannelProtocol speaks ${range.oldest} to ${range.version} but version ${result.unbased.join(", ")} is not in the baseline (the merge-base with origin/main), so it never shipped; every version from Oldest to Version needs a lock that shipped, so lower ChannelProtocol.Version to ${Math.max(...baseline.keys()) + 1} and fold the changes into that one lock`,
  );
if (!result.ok && result.frozen.length > 0)
  fail(
    `the frozen locks ${lockList(result.frozen)} differ from origin/main; their frozen types are generated from them byte for byte and hosts on those versions still speak the shape they lock, so restore them with git checkout origin/main -- ${LOCK_DIR_PATH} and change only the newest version`,
  );
if (!result.ok)
  fail(
    `the channel wire shape changed while ChannelProtocol.Version stays ${current.channelProtocolVersion} (${result.changes.join(", ")}); a host on the old shape would be accepted and misread. Every wire change but a new optional field needs npm run channel:bump, and before that bump ships the control plane must accept Hello for every version from ChannelProtocol.Oldest to Version and send a new message only to hosts whose version carries it`,
  );

writeFileSync(join(lockDir, `v${range.version}.json`), `${JSON.stringify(currentLock, null, 2)}\n`);
for (const name of readdirSync(frozenDir)) rmSync(join(frozenDir, name), { recursive: true });
for (const [version, text] of locks) if (version < range.version) await frozenTypes(version, JSON.parse(text));
