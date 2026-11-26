import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { after, test } from "node:test";
import { fileURLToPath } from "node:url";
import { HostFrameSchema } from "../build/schemas/schemas.ts";
import { channelWindowPaths, raiseOldest, raiseVersion } from "../typespec/npm-scripts/channel-window.mjs";
import { baselineLockTexts, LOCK_DIR_PATH } from "../typespec/npm-scripts/channel-wire-baseline.mjs";
import {
  channelProtocolRange,
  channelWireLock,
  channelWireShape,
  checkChannelLocks,
  checkChannelWire,
  lockShape,
} from "../typespec/npm-scripts/channel-wire-shape.mjs";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
mkdirSync(join(ROOT, ".tmp"), { recursive: true });
const DIR = mkdtempSync(join(ROOT, ".tmp", "channel-wire-test-"));
after(() => rmSync(DIR, { recursive: true, force: true }));

const REF = "#/components/schemas/";

const schemas = (version, offer) => ({
  ChannelProtocol: { type: "integer", minimum: version, maximum: version, "x-bound-names": ["Oldest", "Version"] },
  "Channel.ControlMessage": { oneOf: [{ $ref: `${REF}Channel.TurnOffer` }] },
  "Channel.TurnOffer": offer,
  Harness: { type: "string", enum: ["ClaudeCode", "Codex"] },
});

const OFFER = {
  type: "object",
  required: ["type", "harness"],
  properties: { type: { type: "string", enum: ["TurnOffer"] }, harness: { $ref: `${REF}Harness` } },
};

const WITH_IMAGE = {
  ...OFFER,
  required: [...OFFER.required, "image"],
  properties: { ...OFFER.properties, image: { type: "string", description: "The boot image." } },
};

test("a required field added without a protocol bump fails", () => {
  const result = checkChannelWire(channelWireShape(schemas(14, OFFER)), channelWireShape(schemas(14, WITH_IMAGE)));
  assert.deepEqual(result, { ok: false, changes: ["added Channel.TurnOffer.image"] });
});

test("the same field added with a protocol bump passes", () => {
  const result = checkChannelWire(channelWireShape(schemas(14, OFFER)), channelWireShape(schemas(15, WITH_IMAGE)));
  assert.deepEqual(result, { ok: true });
});

test("a retyped field, a new message and a removed enum member fail without a bump", () => {
  const previous = channelWireShape(schemas(14, WITH_IMAGE));
  const next = schemas(14, {
    ...WITH_IMAGE,
    properties: { ...WITH_IMAGE.properties, image: { $ref: `${REF}Harness` } },
  });
  next["Channel.ControlMessage"] = {
    oneOf: [{ $ref: `${REF}Channel.TurnOffer` }, { $ref: `${REF}Channel.TurnClaimed` }],
  };
  next["Channel.TurnClaimed"] = { type: "object", required: [], properties: {} };
  next.Harness = { type: "string", enum: ["ClaudeCode"] };
  assert.deepEqual(checkChannelWire(previous, channelWireShape(next)), {
    ok: false,
    changes: [
      "removed Harness.Codex",
      "added Channel.ControlMessage variant Channel.TurnClaimed",
      "changed Channel.TurnOffer.image",
    ],
  });
});

test("a changed description is not a wire change", () => {
  const described = { ...WITH_IMAGE, properties: { ...WITH_IMAGE.properties, image: { type: "string" } } };
  const result = checkChannelWire(channelWireShape(schemas(14, WITH_IMAGE)), channelWireShape(schemas(14, described)));
  assert.deepEqual(result, { ok: true });
});

const openapi = JSON.parse(readFileSync(new URL("../build/openapi/openapi.json", import.meta.url), "utf8"));
const { version: committedVersion } = channelProtocolRange(openapi.components.schemas);
const lock = lockShape(
  JSON.parse(readFileSync(new URL(`../typespec/channel-wire/v${committedVersion}.json`, import.meta.url), "utf8")),
);

const withField = (shape, version) => {
  const [name, schema] = Object.entries(shape.schemas).find(([, entry]) => entry.fields !== undefined);
  return {
    channelProtocolVersion: version,
    schemas: { ...shape.schemas, [name]: { fields: { ...schema.fields, addedField: '{"type":"string"}' } } },
  };
};

test("the committed lock matches the generated schemas", () => {
  assert.deepEqual(checkChannelWire(lock, channelWireShape(openapi.components.schemas)), { ok: true });
});

test("a field added to the committed lock without a bump fails against it", () => {
  const result = checkChannelWire(lock, withField(lock, lock.channelProtocolVersion));
  assert.equal(result.ok, false);
  assert.match(result.changes.join(), /^added .+\.addedField$/);
});

test("a field added to the committed lock with a bump passes against it", () => {
  assert.deepEqual(checkChannelWire(lock, withField(lock, lock.channelProtocolVersion + 1)), { ok: true });
});

test("a lowered version does not excuse a change", () => {
  const base = channelWireShape(schemas(15, OFFER));
  const lowered = channelWireShape(schemas(14, WITH_IMAGE));
  assert.equal(checkChannelWire(base, lowered).ok, false);
});

test("a lock holds the raw schemas, and its shape ignores descriptions", () => {
  const described = { ...OFFER, description: "A turn on offer." };
  const raw = channelWireLock({ ...schemas(14, described), Session: { type: "object" } });
  assert.deepEqual(raw.schemas["Channel.TurnOffer"], described);
  assert.equal(raw.schemas.Session, undefined);
  assert.deepEqual(lockShape(raw), channelWireShape(schemas(14, OFFER)));
});

const lockText = (version, offer) => `${JSON.stringify(channelWireLock(schemas(version, offer)), null, 2)}\n`;

const verdict = (found) => ({ ok: false, missing: [], unexpected: [], unbased: [], frozen: [], changes: [], ...found });

test("an optional field added without a protocol bump passes, since both ends ignore fields they do not know", () => {
  const optional = { ...OFFER, properties: { ...OFFER.properties, note: { type: "string" } } };
  const result = checkChannelWire(channelWireShape(schemas(14, OFFER)), channelWireShape(schemas(14, optional)));
  assert.deepEqual(result, { ok: true });
});

test("a new model reached only through a new optional field passes without a protocol bump", () => {
  const next = schemas(14, { ...OFFER, properties: { ...OFFER.properties, range: { $ref: `${REF}Range` } } });
  next.Range = { type: "object", required: ["oldest"], properties: { oldest: { type: "integer" } } };
  assert.deepEqual(checkChannelWire(channelWireShape(schemas(14, OFFER)), channelWireShape(next)), { ok: true });
});

test("a new model behind a new required field fails without a protocol bump", () => {
  const next = schemas(14, {
    ...OFFER,
    required: [...OFFER.required, "range"],
    properties: { ...OFFER.properties, range: { $ref: `${REF}Range` } },
  });
  next.Range = { type: "object", required: ["oldest"], properties: { oldest: { type: "integer" } } };
  assert.deepEqual(checkChannelWire(channelWireShape(schemas(14, OFFER)), channelWireShape(next)), {
    ok: false,
    changes: ["added Channel.TurnOffer.range"],
  });
});

test("an optional field of a new enum added without a protocol bump passes, and that enum as a required field fails", () => {
  const next = (required) => {
    const shape = schemas(14, {
      ...OFFER,
      required: [...OFFER.required, ...required],
      properties: { ...OFFER.properties, setup: { $ref: `${REF}SetupHarness` } },
    });
    shape.SetupHarness = { type: "string", enum: ["ClaudeCode", "Codex"] };
    return channelWireShape(shape);
  };
  const previous = channelWireShape(schemas(14, OFFER));
  assert.deepEqual(checkChannelWire(previous, next([])), { ok: true });
  assert.deepEqual(checkChannelWire(previous, next(["setup"])), {
    ok: false,
    changes: ["added Channel.TurnOffer.setup"],
  });
});

test("an optional field removed without a protocol bump fails", () => {
  const optional = { ...OFFER, properties: { ...OFFER.properties, note: { type: "string" } } };
  const result = checkChannelWire(channelWireShape(schemas(14, optional)), channelWireShape(schemas(14, OFFER)));
  assert.deepEqual(result, { ok: false, changes: ["removed Channel.TurnOffer.note"] });
});

test("an optional field turned required is a wire change", () => {
  const optional = { ...WITH_IMAGE, required: OFFER.required };
  const result = checkChannelWire(channelWireShape(schemas(14, optional)), channelWireShape(schemas(14, WITH_IMAGE)));
  assert.deepEqual(result, { ok: false, changes: ["changed Channel.TurnOffer.image"] });
});

test("an edit to a frozen lock fails", () => {
  const baseline = new Map([
    [14, lockText(14, OFFER)],
    [15, lockText(15, WITH_IMAGE)],
  ]);
  const locks = new Map([
    [14, lockText(14, WITH_IMAGE)],
    [15, lockText(15, WITH_IMAGE)],
  ]);
  const current = channelWireShape(schemas(15, WITH_IMAGE));
  assert.deepEqual(checkChannelLocks(baseline, locks, current, 14), verdict({ frozen: [14] }));
});

test("an edit to a frozen lock that keeps its shape still fails", () => {
  const described = { ...OFFER, description: "A turn on offer." };
  const baseline = new Map([
    [14, lockText(14, OFFER)],
    [15, lockText(15, WITH_IMAGE)],
  ]);
  const locks = new Map([
    [14, lockText(14, described)],
    [15, lockText(15, WITH_IMAGE)],
  ]);
  const current = channelWireShape(schemas(15, WITH_IMAGE));
  assert.deepEqual(checkChannelLocks(baseline, locks, current, 14), verdict({ frozen: [14] }));
});

test("a data change with no new version fails against the newest lock", () => {
  const baseline = new Map([
    [14, lockText(14, OFFER)],
    [15, lockText(15, OFFER)],
  ]);
  const current = channelWireShape(schemas(15, WITH_IMAGE));
  assert.deepEqual(
    checkChannelLocks(baseline, new Map([...baseline]), current, 14),
    verdict({ changes: ["added Channel.TurnOffer.image"] }),
  );
});

test("a bump that keeps the old lock and changes the data passes", () => {
  const locks = new Map([
    [14, lockText(14, OFFER)],
    [15, lockText(15, WITH_IMAGE)],
  ]);
  const current = channelWireShape(schemas(15, WITH_IMAGE));
  assert.deepEqual(checkChannelLocks(new Map([[14, lockText(14, OFFER)]]), locks, current, 14), { ok: true });
});

test("a lock below Version that main never had fails", () => {
  const locks = new Map([
    [14, lockText(14, OFFER)],
    [15, lockText(15, OFFER)],
    [16, lockText(16, WITH_IMAGE)],
  ]);
  const current = channelWireShape(schemas(16, WITH_IMAGE));
  assert.deepEqual(
    checkChannelLocks(new Map([[14, lockText(14, OFFER)]]), locks, current, 14),
    verdict({ unbased: [15] }),
  );
});

test("a deleted lock inside the range and an invented one outside it fail", () => {
  const baseline = new Map([[15, lockText(15, OFFER)]]);
  const locks = new Map([
    [13, lockText(13, OFFER)],
    [15, lockText(15, OFFER)],
  ]);
  const current = channelWireShape(schemas(15, OFFER));
  assert.deepEqual(
    checkChannelLocks(baseline, locks, current, 14),
    verdict({ missing: [14], unexpected: [13], unbased: [13] }),
  );
});

test("the baseline locks are found from typespec and from the repository root alike", () => {
  const repo = join(DIR, "baseline-repo");
  const lockDir = join(repo, LOCK_DIR_PATH);
  mkdirSync(lockDir, { recursive: true });
  writeFileSync(join(lockDir, "v17.json"), lockText(17, OFFER));
  writeFileSync(join(lockDir, "v18.json"), lockText(18, WITH_IMAGE));
  const git = (...args) => {
    const { status, stderr } = spawnSync("git", args, { cwd: repo, encoding: "utf8" });
    assert.equal(status, 0, stderr);
  };
  git("init", "--quiet");
  git("add", ".");
  git("-c", "user.name=test", "-c", "user.email=test@example.test", "commit", "--quiet", "-m", "locks");
  const fromApi = baselineLockTexts(join(repo, "typespec"), "HEAD");
  const fromRoot = baselineLockTexts(repo, "HEAD");
  const expected = {
    ok: true,
    locks: new Map([
      [17, lockText(17, OFFER)],
      [18, lockText(18, WITH_IMAGE)],
    ]),
  };
  assert.deepEqual(fromApi, expected);
  assert.deepEqual(fromRoot, expected);
});

test("raising Version edits only the version constant", () => {
  const paths = channelWindowPaths(join(DIR, "bump"));
  mkdirSync(paths.locks, { recursive: true });
  mkdirSync(dirname(paths.models), { recursive: true });
  writeFileSync(paths.models, "const ChannelProtocolOldest = 18;\nconst ChannelProtocolVersion = 18;\n");
  assert.deepEqual(raiseVersion(paths), { oldest: 18, version: 19 });
  assert.equal(
    readFileSync(paths.models, "utf8"),
    "const ChannelProtocolOldest = 18;\nconst ChannelProtocolVersion = 19;\n",
  );
});

test("raising Oldest removes the locks below it", () => {
  const paths = channelWindowPaths(join(DIR, "drop"));
  mkdirSync(paths.locks, { recursive: true });
  mkdirSync(dirname(paths.models), { recursive: true });
  writeFileSync(paths.models, "const ChannelProtocolOldest = 16;\nconst ChannelProtocolVersion = 18;\n");
  for (const version of [16, 17, 18]) writeFileSync(join(paths.locks, `v${version}.json`), "{}\n");
  const { oldest, version, removed } = raiseOldest(paths);
  assert.deepEqual({ oldest, version, removed }, { oldest: 17, version: 18, removed: [join(paths.locks, "v16.json")] });
  assert.equal(
    readFileSync(paths.models, "utf8"),
    "const ChannelProtocolOldest = 17;\nconst ChannelProtocolVersion = 18;\n",
  );
  assert.equal(existsSync(join(paths.locks, "v16.json")), false);
  assert.equal(existsSync(join(paths.locks, "v17.json")), true);
});

test("raising Oldest past Version fails", () => {
  const paths = channelWindowPaths(join(DIR, "floor"));
  mkdirSync(paths.locks, { recursive: true });
  mkdirSync(dirname(paths.models), { recursive: true });
  writeFileSync(paths.models, "const ChannelProtocolOldest = 18;\nconst ChannelProtocolVersion = 18;\n");
  assert.throws(() => raiseOldest(paths), /ChannelProtocolOldest already equals ChannelProtocolVersion \(18\)/);
});

const dropFixture = (name) => {
  const repo = join(DIR, name);
  const scripts = join(repo, "typespec", "npm-scripts");
  mkdirSync(scripts, { recursive: true });
  for (const script of ["channel-wire-drop.mjs", "channel-window.mjs"])
    copyFileSync(join(ROOT, "typespec", "npm-scripts", script), join(scripts, script));
  writeFileSync(join(repo, "package.json"), '{ "private": true, "scripts": { "generate": "node --version" } }\n');
  const paths = channelWindowPaths(join(repo, "typespec"));
  mkdirSync(paths.locks, { recursive: true });
  mkdirSync(dirname(paths.models), { recursive: true });
  writeFileSync(paths.models, "const ChannelProtocolOldest = 17;\nconst ChannelProtocolVersion = 18;\n");
  for (const version of [17, 18]) writeFileSync(join(paths.locks, `v${version}.json`), "{}\n");
  const drop = (...args) =>
    spawnSync(process.execPath, [join(scripts, "channel-wire-drop.mjs"), ...args], { cwd: repo, encoding: "utf8" });
  return { paths, drop };
};

test("channel:drop refuses without --confirm-fleet-drained and changes nothing", () => {
  const { paths, drop } = dropFixture("drop-refused");
  const run = drop();
  assert.equal(run.status, 1);
  assert.match(run.stderr, /locks out every host still on the oldest version.+--confirm-fleet-drained/);
  assert.equal(
    readFileSync(paths.models, "utf8"),
    "const ChannelProtocolOldest = 17;\nconst ChannelProtocolVersion = 18;\n",
  );
  assert.equal(existsSync(join(paths.locks, "v17.json")), true);
});

test("channel:drop with --confirm-fleet-drained raises Oldest and removes the lock below it", () => {
  const { paths, drop } = dropFixture("drop-confirmed");
  const run = drop("--confirm-fleet-drained");
  assert.equal(run.status, 0, run.stderr);
  assert.equal(
    readFileSync(paths.models, "utf8"),
    "const ChannelProtocolOldest = 18;\nconst ChannelProtocolVersion = 18;\n",
  );
  assert.equal(existsSync(join(paths.locks, "v17.json")), false);
  assert.equal(existsSync(join(paths.locks, "v18.json")), true);
});

test("a chunk check frame takes 1 to 100 digests", () => {
  const check = (count) =>
    HostFrameSchema.safeParse({
      type: "Frame",
      seq: 1,
      ack: 0,
      message: {
        type: "SnapshotChunkCheck",
        snapshotId: "snp_01",
        check: 1,
        digests: Array.from({ length: count }, (_, i) => i.toString(16).padStart(64, "0")),
      },
    }).success;
  assert.deepEqual([check(0), check(1), check(100), check(101)], [false, true, true, false]);
});
