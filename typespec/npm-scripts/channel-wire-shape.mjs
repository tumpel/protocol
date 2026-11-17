const REF = "#/components/schemas/";

const refs = (schema) =>
  [...JSON.stringify(schema).matchAll(/"\$ref":"#\/components\/schemas\/([^"]+)"/g)].map(([, name]) => name);

const canonical = (value) => {
  if (Array.isArray(value)) return value.map(canonical);
  if (value === null || typeof value !== "object") return value;
  return Object.fromEntries(
    Object.keys(value)
      .filter((key) => key !== "description" && key !== "x-enum-varnames")
      .sort()
      .map((key) => [key, canonical(value[key])]),
  );
};

const sorted = (entries) => Object.fromEntries(entries.sort(([a], [b]) => a.localeCompare(b)));

const schemaShape = (schema) => {
  const variants = schema.oneOf ?? schema.anyOf;
  if (Array.isArray(variants)) {
    return {
      variants: variants.map((variant) =>
        variant.$ref?.startsWith(REF) ? variant.$ref.slice(REF.length) : JSON.stringify(canonical(variant)),
      ),
    };
  }
  if (Array.isArray(schema.enum) && schema.type !== "object") return { enum: schema.enum.map(String) };
  if (schema.properties !== undefined) {
    const required = new Set(schema.required ?? []);
    return {
      fields: sorted(
        Object.entries(schema.properties).map(([field, property]) => [
          field,
          `${required.has(field) ? "" : "optional "}${JSON.stringify(canonical(property))}`,
        ]),
      ),
    };
  }
  return { scalar: JSON.stringify(canonical(schema)) };
};

export const channelProtocolRange = (schemas) => {
  const protocol = schemas.ChannelProtocol;
  if (protocol?.["x-bound-names"]?.join() !== "Oldest,Version")
    throw new Error("channel-wire: openapi.json has no ChannelProtocol bounded by Oldest and Version");
  return { oldest: protocol.minimum, version: protocol.maximum };
};

export const channelWireLock = (schemas) => {
  const reachable = new Set();
  const pending = Object.keys(schemas).filter((name) => name.startsWith("Channel."));
  while (pending.length > 0) {
    const name = pending.pop();
    if (reachable.has(name)) continue;
    if (schemas[name] === undefined)
      throw new Error(`channel-wire: ${name} is referenced but not defined in openapi.json`);
    reachable.add(name);
    pending.push(...refs(schemas[name]));
  }
  return {
    channelProtocolVersion: channelProtocolRange(schemas).version,
    schemas: sorted([...reachable].map((name) => [name, schemas[name]])),
  };
};

export const lockShape = (lock) => ({
  channelProtocolVersion: lock.channelProtocolVersion,
  schemas: sorted(
    Object.entries(lock.schemas)
      .filter(([name]) => name !== "ChannelProtocol")
      .map(([name, schema]) => [name, schemaShape(schema)]),
  ),
});

export const channelWireShape = (schemas) => lockShape(channelWireLock(schemas));

const flatten = (shape) =>
  new Map(
    Object.entries(shape.schemas).flatMap(([name, schema]) => {
      if (schema.variants !== undefined) {
        return [[name, "union"], ...schema.variants.map((variant) => [`${name} variant ${variant}`, "variant"])];
      }
      if (schema.enum !== undefined)
        return [[name, "enum"], ...schema.enum.map((member) => [`${name}.${member}`, "member"])];
      if (schema.fields !== undefined) {
        return [[name, "model"], ...Object.entries(schema.fields).map(([field, type]) => [`${name}.${field}`, type])];
      }
      return [[name, schema.scalar]];
    }),
  );

export const wireChanges = (previous, current) => {
  const before = flatten(previous);
  const after = flatten(current);
  return [
    ...[...before.keys()].filter((key) => !after.has(key)).map((key) => `removed ${key}`),
    ...[...after.keys()]
      .filter((key) => !before.has(key) && !after.get(key).startsWith("optional "))
      .map((key) => `added ${key}`),
    ...[...before.keys()]
      .filter((key) => after.has(key) && after.get(key) !== before.get(key))
      .map((key) => `changed ${key}`),
  ];
};

export const checkChannelWire = (previous, current) => {
  const changes = wireChanges(previous, current);
  if (changes.length === 0) return { ok: true };
  if (current.channelProtocolVersion > previous.channelProtocolVersion) return { ok: true };
  return { ok: false, changes };
};

const protocolWindow = (oldest, version) =>
  Array.from({ length: Math.max(version - oldest + 1, 0) }, (_, at) => oldest + at);

const ascending = (versions) => versions.sort((a, b) => a - b);

export const checkChannelLocks = (baseline, locks, current, oldest) => {
  const held = new Set([...locks.keys(), current.channelProtocolVersion]);
  const expected = protocolWindow(oldest, current.channelProtocolVersion);
  const missing = expected.filter((version) => !held.has(version));
  const unexpected = ascending([...held].filter((version) => !expected.includes(version)));
  const older = [...locks].filter(([version]) => version < current.channelProtocolVersion);
  const unbased = ascending(older.filter(([version]) => !baseline.has(version)).map(([version]) => version));
  const frozen = ascending(
    older
      .filter(([version, text]) => baseline.has(version) && baseline.get(version) !== text)
      .map(([version]) => version),
  );
  const newest = baseline.get(Math.max(...baseline.keys()));
  const wire = checkChannelWire(lockShape(JSON.parse(newest)), current);
  const changes = wire.ok ? [] : wire.changes;
  if ([missing, unexpected, unbased, frozen, changes].every((found) => found.length === 0)) return { ok: true };
  return { ok: false, missing, unexpected, unbased, frozen, changes };
};
