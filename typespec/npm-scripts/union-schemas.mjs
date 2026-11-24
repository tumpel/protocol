#!/usr/bin/env node
import { copyFileSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  compile,
  getDiscriminatedUnion,
  getNamespaceFullName,
  NodeHost,
  navigateProgram,
  walkPropertiesInherited,
} from "@typespec/compiler";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const schemasDir = join(root, "..", "build", "schemas");
const schemasFile = join(schemasDir, "schemas.ts");
const program = await compile(NodeHost, join(root, "main.tsp"), { noEmit: true });
if (program.hasError()) throw new Error("main.tsp does not compile; run npm run generate to see why");

const unions = [];
const enums = new Set();
const ours = ({ namespace }) => namespace !== undefined && getNamespaceFullName(namespace).startsWith("Tumpel");

function ancestors(model) {
  const sources = model.sourceModels.map((source) => source.model);
  if (model.baseModel) sources.unshift(model.baseModel);
  return new Set(sources.flatMap((source) => [source, ...ancestors(source)]));
}

function sharedBase(variants, discriminator) {
  const [first, ...rest] = variants.map(ancestors);
  const bases = [...first].filter((base) => base.name && rest.every((sources) => sources.has(base)));
  if (bases.length > 0) return `${bases[0].name}Schema`;
  const sharedFields = [...walkPropertiesInherited(variants[0])].some(
    (field) =>
      field.name !== discriminator &&
      variants.length > 1 &&
      variants
        .slice(1)
        .every((variant) =>
          [...walkPropertiesInherited(variant)].some(
            (property) =>
              property.name === field.name && property.type === field.type && property.optional === field.optional,
          ),
        ),
  );
  if (!sharedFields) return "z.object({})";
}

navigateProgram(program, {
  enum: (declared) => {
    if (ours(declared)) enums.add(declared.name);
  },
  union: (declared) => {
    if (!declared.name || !ours(declared)) return;
    const variants = [...declared.variants.values()].map((variant) => variant.type);
    if (!variants.every((type) => type.kind === "Model" && type.name)) return;
    const [discriminated] = getDiscriminatedUnion(program, declared);
    const discriminator = discriminated?.options.discriminatorPropertyName;
    unions.push({
      name: declared.name,
      members: variants.map((type) => `${type.name}Schema`),
      discriminator,
      tags: discriminated && [...discriminated.variants.keys()],
      base: discriminator && sharedBase(variants, discriminator),
    });
  },
});

const declarations = unions.map(({ name, members, discriminator }) => ({
  name,
  schema:
    discriminator === undefined
      ? `z.union([${members.join(", ")}])`
      : `z.discriminatedUnion(${JSON.stringify(discriminator)}, [${members.join(", ")}])`,
}));
const declare = ({ name, schema }) => `export const ${name}Schema = ${schema};\n`;
const models = readFileSync(schemasFile, "utf8");
writeFileSync(schemasFile, `${models}\n${declarations.map(declare).join("\n")}`);

const openUnions = new Map();
const responses = declarations.map(({ name, schema }, index) => {
  const { base, discriminator, members, tags } = unions[index];
  if (base === undefined) return declare({ name, schema });
  if (tags.includes("Unrecognised")) throw new Error(`union ${name} uses the reserved tag Unrecognised`);
  openUnions.set(schema, name);
  const key = JSON.stringify(discriminator);
  const fallback = `${base}.extend({ [${key}]: unrecognisedTag })`;
  return declare({
    name,
    schema: `openUnion(z.discriminatedUnion(${key}, [${[...members, fallback].join(", ")}]), ${JSON.stringify(tags)})`,
  });
});

const responseModels = models
  .replace(/^export const (\w+)Schema = (z\.enum\(.*\));$/gm, (line, name, expression) =>
    enums.has(name) ? declare({ name, schema: `openEnum(${expression})` }).trimEnd() : line,
  )
  .replace(/z\.discriminatedUnion\("[^"]+", \[[^\]]*\]\)/g, (schema) => {
    const name = openUnions.get(schema);
    return name === undefined ? schema : `z.lazy(() => ${name}Schema)`;
  });

copyFileSync(join(root, "schemas", "response-decoding.ts"), join(schemasDir, "response-decoding.ts"));
writeFileSync(
  join(schemasDir, "responses.ts"),
  `import { openEnum, openUnion, unrecognisedTag } from "./response-decoding.js";\n` +
    `export { containsUnrecognised } from "./response-decoding.js";\n${responseModels}\n${responses.join("\n")}`,
);
