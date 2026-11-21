#!/usr/bin/env node
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  compile,
  getMaxItems,
  getMaxLength,
  getSourceLocation,
  isTemplateDeclarationOrInstance,
  NodeHost,
  navigateProgram,
} from "@typespec/compiler";
import { getMaxProperties } from "@typespec/json-schema";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const lib = join(root, "lib");
const program = await compile(NodeHost, join(root, "main.tsp"), { noEmit: true });
if (program.hasError()) throw new Error("main.tsp does not compile; run npm run generate to see why");

const declaredHere = (type) => getSourceLocation(type)?.file.path.startsWith(lib) ?? false;

const scalarChain = (scalar) => {
  const chain = [];
  for (let current = scalar; current; current = current.baseScalar) chain.push(current);
  return chain;
};

const isArray = (type) => type.kind === "Model" && type.name === "Array" && type.indexer !== undefined;
const isRecord = (type) => type.kind === "Model" && type.indexer?.key.name === "string" && type.name !== "Array";

const unbounded = (type, property) => {
  if (type.kind === "Scalar") {
    const chain = scalarChain(type);
    if (!chain.some((scalar) => scalar.name === "string")) return [];
    const bounded =
      chain.some((scalar) => getMaxLength(program, scalar) !== undefined) ||
      (property !== undefined && getMaxLength(program, property) !== undefined);
    return bounded ? [] : ["a string without @maxLength"];
  }
  if (isArray(type)) {
    const own = property !== undefined && getMaxItems(program, property) !== undefined;
    return [...(own ? [] : ["a list without @maxItems"]), ...unbounded(type.indexer.value)];
  }
  if (isRecord(type)) {
    const own =
      (property !== undefined && getMaxProperties(program, property) !== undefined) ||
      getMaxProperties(program, type) !== undefined;
    return [...(own ? [] : ["a map without @maxProperties"]), ...unbounded(type.indexer.value)];
  }
  if (type.kind === "Union") {
    return [...type.variants.values()].flatMap(({ type: variant }) =>
      unbounded(variant, isArray(variant) || isRecord(variant) ? property : undefined),
    );
  }
  return [];
};

const failures = new Set();
navigateProgram(program, {
  modelProperty: (property) => {
    if (!declaredHere(property)) return;
    if (property.model && isTemplateDeclarationOrInstance(property.model) && !property.model.name) return;
    for (const reason of unbounded(property.type, property)) {
      const owner = property.model?.name || "an operation";
      failures.add(`${owner}.${property.name} is ${reason}`);
    }
  },
  model: (model) => {
    if (!declaredHere(model) || !model.name || !isRecord(model)) return;
    for (const reason of unbounded(model)) failures.add(`${model.name} is ${reason}`);
  },
});

if (failures.size > 0) {
  console.error(
    `bounds: every string needs @maxLength, every list @maxItems and every map @maxProperties, on the property or its scalar:\n  ${[...failures].sort().join("\n  ")}`,
  );
  process.exit(1);
}
console.log("bounds: every string, list and map in the TypeSpec carries a limit");
