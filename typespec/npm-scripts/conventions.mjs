#!/usr/bin/env node
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { compile, getNamespaceFullName, NodeHost, navigateProgram } from "@typespec/compiler";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const program = await compile(NodeHost, join(root, "main.tsp"), { noEmit: true });
if (program.hasError()) throw new Error("main.tsp does not compile; run npm run generate to see why");

const PASCAL = /^[A-Z][A-Za-z0-9]*$/;
const BARE_KEYS = new Set(["id", "version"]);
const MISNAMED_KEY = /(?:_id|ID|_version)$/;
const ZONELESS_DATES = new Set(["utcDateTime", "plainDate", "plainDateTime", "plainTime"]);
const METADATA_TIMESTAMPS = new Set(["createdAt", "updatedAt", "lastUsedAt", "lastIssuedAt"]);
const KEY_EXCEPTIONS = new Map([
  ["client_id", "RFC 6749 names the OAuth wire field"],
  ["GuestImageComponent.version", "a published guest image manifest field; renaming it changes the manifest format"],
]);

const ours = (type) => type?.namespace !== undefined && getNamespaceFullName(type.namespace).startsWith("Tumpel");

const scalarChain = (type) => {
  const names = [];
  for (let scalar = type.kind === "Scalar" ? type : undefined; scalar; scalar = scalar.baseScalar)
    names.push(scalar.name);
  return names;
};

const failures = new Set();
navigateProgram(program, {
  enum: (declared) => {
    if (!ours(declared)) return;
    if (!PASCAL.test(declared.name)) failures.add(`enum ${declared.name} is not PascalCase`);
    for (const member of declared.members.values()) {
      if (!PASCAL.test(member.name)) failures.add(`enum member ${declared.name}.${member.name} is not PascalCase`);
      if (member.name === "Unrecognised" || member.value === "Unrecognised") {
        failures.add(
          `enum member ${declared.name}.${member.name} uses Unrecognised; choose a different name and value`,
        );
      }
    }
  },
  modelProperty: (property) => {
    if (!ours(property.model)) return;
    const qualified = `${property.model.name}.${property.name}`;
    if (
      !KEY_EXCEPTIONS.has(qualified) &&
      !KEY_EXCEPTIONS.has(property.name) &&
      (BARE_KEYS.has(property.name) || MISNAMED_KEY.test(property.name))
    ) {
      failures.add(`${qualified} is a key; name it <entity>Id or <entity>Version`);
    }
    const chain = scalarChain(property.type);
    if (chain.some((name) => ZONELESS_DATES.has(name))) {
      failures.add(`${qualified} is a ${chain[0]}; business dates are offsetDateTime, ISO 8601 with an offset`);
    }
    if (chain.includes("integer") && property.name.endsWith("At") && !METADATA_TIMESTAMPS.has(property.name)) {
      failures.add(
        `${qualified} is an epoch integer; only createdAt, updatedAt, lastUsedAt and lastIssuedAt may be, use offsetDateTime`,
      );
    }
  },
});

if (failures.size > 0) {
  console.error(`TypeSpec conventions failed (AGENTS.md: keys, dates, enums):\n  ${[...failures].join("\n  ")}`);
  process.exit(1);
}
console.log("conventions: TypeSpec keys, business dates and enums follow AGENTS.md");
