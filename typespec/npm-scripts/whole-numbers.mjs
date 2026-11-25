#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const build = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "build");
const { schemas: declared, parameters } = JSON.parse(
  readFileSync(join(build, "openapi", "openapi.json"), "utf8"),
).components;
const schemas = Object.fromEntries(
  Object.entries(declared).map(([name, schema]) => [name.slice(name.lastIndexOf(".") + 1), schema]),
);

const resolved = (property) => {
  if (property.allOf?.length === 1) return resolved(property.allOf[0]);
  const ref = property.$ref;
  if (!ref) return property;
  const target = declared[ref.slice(ref.lastIndexOf("/") + 1)];
  if (!target) throw new Error(`the OpenAPI names a schema it does not define: ${ref}`);
  return target;
};

const integerFields = (schema) =>
  Object.entries(schema?.properties ?? {})
    .filter(([, property]) => resolved(property).type === "integer")
    .map(([field]) => field);

const integerQueryFields = Object.create(null);
for (const [key, parameter] of Object.entries(parameters)) {
  if (parameter.in !== "query" || resolved(parameter.schema).type !== "integer") continue;
  const [model, field = parameter.name] = key.split(".");
  integerQueryFields[model] ??= [];
  integerQueryFields[model].push(field);
}

const file = join(build, "schemas", "schemas.ts");
const blocks = readFileSync(file, "utf8").split(/(?=^const )/m);

const marked = blocks.map((block) => {
  const name = /^const (\w+)Schema = /.exec(block)?.[1];
  const fields = new Set([...integerFields(schemas[name]), ...(integerQueryFields[name] ?? [])]);
  for (const field of fields) {
    const whole = new RegExp(`(\\b${field}: (?:z\\.optional\\()?z\\.(?:union\\(\\[z\\.)?)number\\(\\)`);
    if (!whole.test(block)) throw new Error(`no generated z.number() to mark whole: ${name}.${field}`);
    block = block.replace(whole, "$1int()");
  }
  return block;
});

writeFileSync(file, marked.join(""));
