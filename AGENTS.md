# Agent rules

Always follow `rules/errors.md` and `rules/coding-standards.md`.

- When editing TypeSpec, follow `rules/typespec.md`.
- When adding or changing an operation or the host channel, follow `rules/api.md`.
- When writing TypeScript, follow `rules/typescript.md`.
- When writing Rust, follow `rules/rust.md`.
- When writing or changing a test, follow `rules/tests.md`.
- When committing or opening a pull request, follow `rules/commits-and-prs.md`.
- When writing text a user reads, docs, an issue or a PR body, follow `rules/writing.md`.

## Commands

- `npm install` installs dependencies and enables the pre-commit hook.
- `npm run generate` regenerates the TypeSpec output under `build/` and the Rust sources of `tumpel-api`. Commit the Rust sources: a Cargo git dependency builds from them, and CI fails when they are stale.
- `npm run check` runs every check. `npm run fix` formats.
- `npm test` runs the channel-wire guard tests and the Rust tests.
- `npm run pack` builds the npm tarballs into `dist/`.
- Releases are mechanical; never bump the version in `Cargo.toml`, tag or publish by hand. A merge to `main` that changes a shipped file publishes a GitHub pre-release `vX.Y.Z-rc.N`, versioned from the conventional commit types (breaking major, `feat` minor, `fix` and `perf` patch). Only the manual `promote` workflow ships a release candidate to crates.io as `vX.Y.Z`. A rerun releases the same version.
