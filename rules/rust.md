# Rust

1. Propagate errors with `?`.
2. A library crate returns a typed error enum that implements `std::error::Error`.
3. Never call `unwrap()`, `expect()`, `panic!`, `todo!` or `unimplemented!` outside tests. The workspace lints in `Cargo.toml` deny them.
4. A proven invariant is the one exception to rule 3. Mark that item with `#[expect(clippy::expect_used, reason = "...")]`, and name the invariant in the reason.
5. Never discard a `Result` with `let _ =`, `.ok()` or `.unwrap_or_default()`. Best-effort cleanup inside `Drop` is the one exception.
6. Parse external input with serde into a typed struct at the boundary. Never pass a `serde_json::Value` past it.
7. Use the API types generated into `tumpel-api`. Never hand-write one. `npm run generate` rebuilds them from TypeSpec.
8. Silence a lint with `#[expect(lint, reason = "...")]` on the narrowest item. Only generated code carries `#[allow]`.
9. `npm run clippy` (pedantic, warnings as errors) and `npm run fmt:check` pass. `npm run fix` formats.

## Client compatibility

Every generated Rust enum must decode an unknown value into an explicit Unrecognised variant and preserve its wire value. Discriminated unions must select known variants by their discriminator and propagate errors for malformed known payloads. Retain payloads with unmatched discriminators for clients to report an update without crashing.
