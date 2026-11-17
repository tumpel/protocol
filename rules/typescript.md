# TypeScript

1. Never use `any`. Use `unknown` and narrow it with a type guard (`value is T`). Prefer a type guard over an `as` cast.
2. Give explicit types to parameters, return values and exported state. Let inference handle local bodies.
3. Import types, schemas, enums and clients from the generated packages (`@tumpel/schemas`, `@tumpel/openapi`). Never redefine one by hand. When one is missing, fix the TypeSpec and run `npm run generate` (`rules/typespec.md`).
4. Parse external input with the generated zod schema and `safeParse` at the boundary. Derive the type with `z.infer`.
5. Return a discriminated union for an expected outcome: `{ ok: true; value } | { ok: false; ... }`.
6. Handle a rejection with `.catch()` on that promise. Never wrap an `await` in `try`/`catch` to rethrow: the `try` block also catches unrelated throws.
7. Return early. Never write `else` after a `return`.
8. `npm run lint` (Biome) passes. `npm run fix` formats.
