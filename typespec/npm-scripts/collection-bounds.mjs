#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const build = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "build");
const declared = JSON.parse(readFileSync(join(build, "openapi", "openapi.json"), "utf8")).components.schemas;
const schemas = Object.fromEntries(
  Object.entries(declared).map(([name, schema]) => [name.slice(name.lastIndexOf(".") + 1), schema]),
);

const resolved = (schema) => {
  if (schema.allOf?.length === 1) return resolved(schema.allOf[0]);
  const ref = schema.$ref;
  if (!ref) return schema;
  const target = declared[ref.slice(ref.lastIndexOf("/") + 1)];
  if (!target) throw new Error(`the OpenAPI names a schema it does not define: ${ref}`);
  return { ...target, ...Object.fromEntries(Object.entries(schema).filter(([key]) => key !== "$ref")) };
};

const closing = (text, open) => {
  let depth = 0;
  for (let at = open; at < text.length; at += 1) {
    const char = text[at];
    if (char === '"' || char === "'" || char === "`") {
      at = text.indexOf(char, at + 1);
      while (text[at - 1] === "\\") at = text.indexOf(char, at + 1);
      continue;
    }
    if (char === "/" && text[at - 1] === "(") {
      at += 1;
      while (text[at] !== "/" || text[at - 1] === "\\") at += 1;
      continue;
    }
    if (char === "(" || char === "[") depth += 1;
    if (char === ")" || char === "]") depth -= 1;
    if (depth === 0) return at;
  }
  throw new Error(`unbalanced zod expression: ${text.slice(open, open + 80)}`);
};

const topLevelSplit = (text) => {
  const parts = [];
  let depth = 0;
  let start = 0;
  for (let at = 0; at < text.length; at += 1) {
    const char = text[at];
    if (char === '"' || char === "'" || char === "`") {
      at = text.indexOf(char, at + 1);
      continue;
    }
    if (char === "(" || char === "[" || char === "{") depth += 1;
    if (char === ")" || char === "]" || char === "}") depth -= 1;
    if (char === "," && depth === 0) {
      parts.push(text.slice(start, at));
      start = at + 1;
    }
  }
  parts.push(text.slice(start));
  return parts;
};

const KEY = "z.string().max(256)";

const entriesCheck = (limit) =>
  `.refine((entries) => Object.keys(entries).length <= ${limit}, { message: "at most ${limit} entries" })`;

const bound = (expression, schema) => {
  const shape = resolved(schema);
  const trimmed = expression.trim();
  const call = /^z\.(array|record|union)\(/.exec(trimmed);
  if (!call) return expression;
  const open = call[0].length - 1;
  const close = closing(trimmed, open);
  const inner = trimmed.slice(open + 1, close);
  const rest = trimmed.slice(close + 1);
  if (call[1] === "union") {
    if (!trimmed.startsWith("z.union([")) return expression;
    const variants = topLevelSplit(inner.slice(1, -1));
    const bounded = variants.map((variant) => (variant.trim() === "z.null()" ? variant : bound(variant, shape)));
    return `z.union([${bounded.join(",")}])${rest}`;
  }
  if (call[1] === "array") {
    const items = shape.items === undefined ? inner : bound(inner, shape.items);
    const limit = shape.maxItems !== undefined && !/^(\.min\(\d+\))?\.max\(/.test(rest);
    return `z.array(${items})${limit ? `.max(${shape.maxItems})` : ""}${rest}`;
  }
  const [key, ...value] = topLevelSplit(inner);
  const values = value.join(",");
  const boundedValue =
    typeof shape.additionalProperties === "object" ? bound(values, shape.additionalProperties) : values;
  const limit =
    shape.maxProperties !== undefined && !rest.startsWith(".refine(") ? entriesCheck(shape.maxProperties) : "";
  return `z.record(${key.trim() === "z.string()" ? KEY : key},${boundedValue})${limit}${rest}`;
};

const valueSchema = (schema) => {
  const shape = resolved(schema);
  if (Object.keys(shape).filter((key) => key !== "description").length === 0) return "z.unknown()";
  if (shape.type === "string" && shape.maxLength !== undefined) return `z.string().max(${shape.maxLength})`;
  throw new Error(`collection-bounds: no zod value schema for ${JSON.stringify(schema)}`);
};

const file = join(build, "schemas", "schemas.ts");
const blocks = readFileSync(file, "utf8").split(/(?=^const )/m);

const fieldExpression = /^(\t)(\w+): /gm;

const marked = blocks.map((block) => {
  const name = /^const (\w+)Schema = /.exec(block)?.[1];
  const schema = name === undefined ? undefined : schemas[name];
  if (!schema) return block;
  const rest = block.slice(block.indexOf(";\n") + 1);
  if (schema.type === "array" && schema.items?.$ref !== undefined) {
    const item = schema.items.$ref.slice(schema.items.$ref.lastIndexOf("/") + 1);
    const itemName = item.slice(item.lastIndexOf(".") + 1);
    return `const ${name}Schema = ${bound(`z.array(z.lazy(() => ${itemName}Schema))`, schema)};${rest}`;
  }
  if (schema.type === "object" && schema.properties === undefined && schema.maxProperties !== undefined) {
    return `const ${name}Schema = z.record(${KEY}, ${valueSchema(schema.additionalProperties ?? {})})${entriesCheck(schema.maxProperties)};${rest}`;
  }
  const properties = schema.properties ?? {};
  let output = "";
  let from = 0;
  for (const match of block.matchAll(fieldExpression)) {
    const property = properties[match[2]];
    const start = match.index + match[0].length;
    if (property === undefined || start < from || !/^z\.(array|record|union)\(/.test(block.slice(start))) continue;
    const end = closing(block, block.indexOf("(", start));
    let tail = end + 1;
    while (/^\.(min|max|optional|nullable)\(/.test(block.slice(tail)))
      tail = closing(block, block.indexOf("(", tail)) + 1;
    output += block.slice(from, start) + bound(block.slice(start, tail), property);
    from = tail;
  }
  return output + block.slice(from);
});

writeFileSync(file, marked.join(""));
