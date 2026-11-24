#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { compile, NodeHost, navigateProgram } from "@typespec/compiler";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const build = join(root, "..", "build");
const program = await compile(NodeHost, join(root, "main.tsp"), { noEmit: true });
if (program.hasError()) throw new Error("main.tsp does not compile; run npm run generate to see why");

const numeric = new Map();
navigateProgram(program, {
  enum: (declared) => {
    const members = [...declared.members.values()];
    if (members.length === 0 || !members.every((member) => Number.isInteger(member.value))) return;
    numeric.set(
      declared.name,
      members.map((member) => [member.name, member.value]),
    );
  },
});

const openapiFile = join(build, "openapi", "openapi.json");
const openapi = JSON.parse(readFileSync(openapiFile, "utf8"));
for (const [qualified, schema] of Object.entries(openapi.components.schemas)) {
  const members = numeric.get(qualified.slice(qualified.lastIndexOf(".") + 1));
  if (members === undefined) continue;
  schema.type = "integer";
  schema["x-enum-varnames"] = members.map(([name]) => name);
}
writeFileSync(openapiFile, JSON.stringify(openapi, null, 2));

const schemasFile = join(build, "schemas", "schemas.ts");
const named = [...numeric].reduce(
  (text, [name, members]) => {
    const declared = new RegExp(`^export const ${name}Schema = openEnum\\(\\[[^\\]]*\\]\\);\\n`, "m");
    if (!declared.test(text)) throw new Error(`no generated openEnum to name: ${name}Schema`);
    const entries = members.map(([member, value]) => `${member}: ${value}`).join(", ");
    const replacement = `export const ${name} = { ${entries} } as const;\n\nexport const ${name}Schema = openEnum(Object.values(${name}));\n`;
    return text.replace(declared, () => replacement);
  },
  readFileSync(schemasFile, "utf8"),
);
const bounded = Object.entries(openapi.components.schemas)
  .filter(([, schema]) => schema["x-bound-names"] !== undefined)
  .map(([qualified, schema]) => {
    const [low, high] = schema["x-bound-names"];
    const name = qualified.slice(qualified.lastIndexOf(".") + 1);
    return `export const ${name} = { ${low}: ${schema.minimum}, ${high}: ${schema.maximum} } as const;\n\n`;
  })
  .join("");
const imported = /^import \{ z \} from "zod";\n/m;
if (!imported.test(named)) throw new Error("schemas.ts has no zod import to place the bounded constants after");
writeFileSync(
  schemasFile,
  named.replace(imported, (line) => `${line}${bounded}`),
);
