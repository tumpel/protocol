<p align="center"><img src="doc/assets/mascot.svg" alt="The tumpel salamander" width="160"></p>

# tumpel protocol

The TypeSpec for the tumpel API, the host channel between a supervisor and the control plane, and the release manifests. Every client, schema and type that speaks to tumpel is generated from it.

## Artifacts

Each stable release `vX.Y.Z` publishes four artifacts at the same version:

- `tumpel-api` on crates.io: Rust types and a typed client.
- `@tumpel/schemas`: zod schemas, as an npm tarball on the GitHub release.
- `@tumpel/openapi`: `openapi.json`, the `paths` types and the frozen channel types, as an npm tarball on the GitHub release.
- `@tumpel/api`: the credential checks and constants that clients share, over `@tumpel/schemas`, as an npm tarball on the GitHub release. It names `@tumpel/schemas` and `zod` as peer dependencies, so install the `@tumpel/schemas` tarball of the same version next to it.

Pin each exactly, because an added field breaks Rust callers.

```toml
tumpel-api = "=0.1.0"
```

```json
"@tumpel/schemas": "https://github.com/tumpel/protocol/releases/download/v0.1.0/tumpel-schemas-0.1.0.tgz"
```

## Releases

Only a change to the TypeSpec, the `tumpel-api` crate, its generator or the shared TypeScript in `packages/api` makes a new version. Docs, tests and CI never do. The conventional commits that changed those files since the latest stable tag pick the next version: a breaking change bumps major, `feat` bumps minor, and `fix` or `perf` bumps patch. Other types ride along with the next release.

- Release candidate: a push to `main` with such a change publishes the GitHub pre-release `vX.Y.Z-rc.N` with the three npm tarballs, where `N` counts the commits since the latest stable tag. An npm consumer pins a release candidate's tarball to try it. A release candidate never touches crates.io.
- Stable release: a person runs the `promote` workflow and names one release candidate. It tags that commit `vX.Y.Z`, publishes `tumpel-api` to crates.io and publishes the GitHub release as Latest. To ship several changes together, merge them and promote the last release candidate.

A failed run is rerun as it is and releases the same version: the stable tag is pushed first, a rerun skips a crate already on crates.io and finishes a draft release, and a published release is never overwritten.

## The channel wire guard

`typespec/channel-wire/v<N>.json` locks the host channel shape of every protocol version from `ChannelProtocol.Oldest` to `ChannelProtocol.Version`. `npm run generate` refuses a shape change that has no `npm run channel:bump`, comparing against the locks at the merge-base with `origin/main`. A new optional field on the current version passes without a bump.

## Development

```sh
npm install
npm run generate
npm run check
npm test
```

## Licence

Apache-2.0. See `LICENSE` and `NOTICE`.
