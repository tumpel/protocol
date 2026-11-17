# TypeSpec

1. TypeSpec (`typespec/main.tsp`, `typespec/lib`) is the single source of truth for the API, the host channel and every config file.
2. `npm run generate` writes OpenAPI, JSON Schema and zod output under `build/` and the Rust output under `crates/tumpel-api/generated/`. Never commit either. Never hand-write or hand-edit generated output.
3. Name keys `<entity>Id` and `<entity>Version`, never bare `id` or `version`. A foreign key takes the name of the key it references.
4. A business date is an ISO 8601 string with an explicit offset. An epoch integer is only for a UTC metadata timestamp (`createdAt`, `updatedAt`).
5. Enums are PascalCase with string-valued members.
6. Give each variant its own model. Never one model with a `kind` field or an optional key.
7. Derive inputs from the model: `model XCreate is Create<X>;`.
8. `alias` is a reserved keyword. Never use it as a field name (use `ref`, `label` or `key`).
9. `npm run conventions:check` enforces rules 3 to 5.
