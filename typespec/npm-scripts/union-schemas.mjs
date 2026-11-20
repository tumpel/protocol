#!/usr/bin/env node
import { appendFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { compile, getDiscriminatedUnion, getNamespaceFullName, NodeHost, navigateProgram } from "@typespec/compiler";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const schemasFile = join(root, "..", "build", "schemas", "schemas.ts");
const program = await compile(NodeHost, join(root, "main.tsp"), { noEmit: true });
if (program.hasError()) throw new Error("main.tsp does not compile; run npm run generate to see why");

const unions = [];
navigateProgram(program, {
  union: (declared) => {
    if (
      !declared.name ||
      declared.namespace === undefined ||
      !getNamespaceFullName(declared.namespace).startsWith("Tumpel")
    ) {
      return;
    }
    const variants = [...declared.variants.values()].map((variant) => variant.type);
    if (!variants.every((type) => type.kind === "Model" && type.name)) return;
    const [discriminated] = getDiscriminatedUnion(program, declared);
    unions.push({
      name: declared.name,
      members: variants.map((type) => `${type.name}Schema`),
      discriminator: discriminated?.options.discriminatorPropertyName,
    });
  },
});

const declarations = unions.map(({ name, members, discriminator }) => {
  const schema =
    discriminator === undefined
      ? `z.union([${members.join(", ")}])`
      : `z.discriminatedUnion(${JSON.stringify(discriminator)}, [${members.join(", ")}])`;
  return `export const ${name}Schema = ${schema};\n`;
});
if (declarations.length > 0) appendFileSync(schemasFile, `\n${declarations.join("\n")}`);
