import { existsSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const RANGE = /const ChannelProtocolOldest = (\d+);\nconst ChannelProtocolVersion = (\d+);/;

export const lockVersion = (name) => {
  const matched = /^v(\d+)\.json$/.exec(name);
  return matched === null ? undefined : Number(matched[1]);
};

export const channelWindowPaths = (apiRoot) => ({
  models: join(apiRoot, "lib", "models.tsp"),
  locks: join(apiRoot, "channel-wire"),
});

const readRange = (paths) => {
  const matched = RANGE.exec(readFileSync(paths.models, "utf8"));
  if (matched === null)
    throw new Error(
      `${paths.models} has no ChannelProtocolOldest and ChannelProtocolVersion constants next to each other; restore them and run the script again`,
    );
  return { oldest: Number(matched[1]), version: Number(matched[2]) };
};

const writeRange = (paths, { oldest, version }) => {
  const models = readFileSync(paths.models, "utf8");
  writeFileSync(
    paths.models,
    models.replace(RANGE, `const ChannelProtocolOldest = ${oldest};\nconst ChannelProtocolVersion = ${version};`),
  );
};

export const raiseVersion = (paths) => {
  const range = readRange(paths);
  const raised = { ...range, version: range.version + 1 };
  writeRange(paths, raised);
  return raised;
};

export const raiseOldest = (paths) => {
  const range = readRange(paths);
  if (range.oldest >= range.version)
    throw new Error(
      `ChannelProtocolOldest already equals ChannelProtocolVersion (${range.version}), and the control plane must speak at least one version; raise the version with npm run channel:bump first`,
    );
  const raised = { ...range, oldest: range.oldest + 1 };
  writeRange(paths, raised);
  const removed = existsSync(paths.locks)
    ? readdirSync(paths.locks)
        .filter((name) => (lockVersion(name) ?? raised.oldest) < raised.oldest)
        .map((name) => {
          rmSync(join(paths.locks, name));
          return join(paths.locks, name);
        })
    : [];
  return { ...raised, removed };
};
