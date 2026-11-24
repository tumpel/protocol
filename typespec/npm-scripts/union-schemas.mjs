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
import ts from "typescript";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const build = join(root, "..", "build");
const schemasDir = join(build, "schemas");
const schemasFile = join(schemasDir, "schemas.ts");
const program = await compile(NodeHost, join(root, "main.tsp"), { noEmit: true });
if (program.hasError()) throw new Error("main.tsp does not compile; run npm run generate to see why");

const unions = [];
const enums = new Set();
const ours = ({ namespace }) => namespace !== undefined && getNamespaceFullName(namespace).startsWith("Tumpel");

function responseSchemaNames(openapi) {
  const refs = new Set();
  const resolve = (ref) =>
    ref
      .slice(2)
      .split("/")
      .reduce((node, key) => node[key.replaceAll("~1", "/").replaceAll("~0", "~")], openapi);
  const visit = (schema) => {
    if (schema === null || typeof schema !== "object") return;
    const ref = schema.$ref;
    if (ref?.startsWith("#/components/schemas/") && !refs.has(ref)) {
      refs.add(ref);
      visit(resolve(ref));
    }
    visit(schema.items);
    visit(schema.additionalProperties);
    visit(schema.not);
    for (const child of Object.values(schema.properties ?? {})) visit(child);
    for (const variant of [...(schema.allOf ?? []), ...(schema.anyOf ?? []), ...(schema.oneOf ?? [])]) visit(variant);
    for (const ref of Object.values(schema.discriminator?.mapping ?? {})) visit({ $ref: ref });
  };
  for (const path of Object.values(openapi.paths)) {
    for (const operation of Object.values(path)) {
      for (const response of Object.values(operation.responses ?? {})) {
        const body = response.$ref === undefined ? response : resolve(response.$ref);
        for (const media of Object.values(body.content ?? {})) visit(media.schema);
      }
    }
  }
  return new Set([...refs].map((ref) => ref.split("/").at(-1).split(".").at(-1)));
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
    const members = variants.map((type) => `${type.name}Schema`);
    const discriminator = discriminated?.options.discriminatorPropertyName;
    const key = JSON.stringify(discriminator);
    unions.push({
      name: declared.name,
      variants,
      members,
      discriminator,
      tags: discriminated && [...discriminated.variants.keys()],
      schema:
        discriminator === undefined
          ? `z.union([${members.join(", ")}])`
          : `z.discriminatedUnion(${key}, [${members.join(", ")}])`,
    });
  },
});

const declare = ({ name, schema }) => `export const ${name}Schema = ${schema};\n`;
const models = readFileSync(schemasFile, "utf8");
writeFileSync(schemasFile, `${models}\n${unions.map(declare).join("\n")}`);

const reachable = responseSchemaNames(JSON.parse(readFileSync(join(build, "openapi", "openapi.json"), "utf8")));
const source = ts.createSourceFile(schemasFile, models, ts.ScriptTarget.Latest, true);
const emitted = new Map(
  source.statements
    .filter(ts.isVariableStatement)
    .map((statement) => [statement.declarationList.declarations[0].name.getText(), statement]),
);

function fieldsOf(variant) {
  const model = emitted.get(`${variant.name}Schema`)?.declarationList.declarations[0].initializer;
  const shape = model?.arguments?.[0];
  if (!shape || !ts.isObjectLiteralExpression(shape)) {
    throw new Error(`response union member ${variant.name} has no generated object shape`);
  }
  const expressions = new Map(
    shape.properties.filter(ts.isPropertyAssignment).map((field) => [field.name.text, field.initializer.getText()]),
  );
  return new Map(
    [...walkPropertiesInherited(variant)].map(({ name, optional }) => {
      const expression = expressions.get(name);
      if (expression === undefined)
        throw new Error(`response union member ${variant.name} has no generated field ${name}`);
      return [name, { schema: expression.replace(/\.optional\(\)$/, ""), optional }];
    }),
  );
}

const openUnions = new Map();
const responses = unions
  .filter(({ name }) => reachable.has(name))
  .map((union) => {
    const { name, schema, variants, discriminator, members, tags } = union;
    if (discriminator === undefined) return declare(union);
    if (tags.includes("Unrecognised")) throw new Error(`union ${name} uses the reserved tag Unrecognised`);
    openUnions.set(schema, name);
    const [first, ...rest] = variants.map(fieldsOf);
    const shared = [...first].filter(
      ([field, { schema }]) => field !== discriminator && rest.every((fields) => fields.get(field)?.schema === schema),
    );
    const fields = shared.map(([field, { optional }]) => {
      const allowMissing = !optional && rest.some((fields) => fields.get(field).optional);
      return `[${JSON.stringify(field)}]: ${members[0]}.shape[${JSON.stringify(field)}]${allowMissing ? ".optional()" : ""}`;
    });
    const key = JSON.stringify(discriminator);
    const fallback = `z.object({ ${[...fields, `[${key}]: unrecognisedTag`].join(", ")} })`;
    return declare({
      name,
      schema: `openUnion(z.discriminatedUnion(${key}, [${[...members, fallback].join(", ")}]), ${JSON.stringify(tags)})`,
    });
  });

const responseNames = new Set(
  [...reachable].flatMap((name) => (enums.has(name) ? [`${name}Schema`, name] : [`${name}Schema`])),
);
const responseModels = [...emitted]
  .filter(([name]) => responseNames.has(name))
  .map(([name, statement]) => {
    const initializer = statement.declarationList.declarations[0].initializer.getText();
    if (!initializer.startsWith("z.enum(")) return statement.getText();
    return `export const ${name} = openEnum(${initializer});`;
  })
  .join("\n\n")
  .replace(/z\.discriminatedUnion\("[^"]+", \[[^\]]*\]\)/g, (schema) => {
    const name = openUnions.get(schema);
    return name === undefined ? schema : `z.lazy(() => ${name}Schema)`;
  });

copyFileSync(join(root, "schemas", "response-decoding.ts"), join(schemasDir, "response-decoding.ts"));
writeFileSync(
  join(schemasDir, "responses.ts"),
  `import { z } from "zod";\nimport { openEnum, openUnion, unrecognisedTag } from "./response-decoding.js";\n` +
    `export { containsUnrecognised } from "./response-decoding.js";\n${responseModels}\n${responses.join("\n")}`,
);
