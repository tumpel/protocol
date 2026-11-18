TYPESPEC_MODULES := typespec/node_modules/.package-lock.json
ROOT_MODULES := node_modules/.package-lock.json
TYPESPEC_SOURCES := $(shell find typespec -path typespec/node_modules -prune -o -type f -print)
XTASK_SOURCES := $(shell find crates/xtask -type f)

.PHONY: generate generate-ts generate-rust pack

generate: generate-ts generate-rust

generate-ts: build/.typespec

generate-rust: build/.rust

$(TYPESPEC_MODULES): typespec/package.json typespec/package-lock.json
	npm ci --prefix typespec --prefer-offline --no-audit --no-fund
	@touch $@

$(ROOT_MODULES): package.json package-lock.json
	npm ci --prefer-offline --no-audit --no-fund
	@touch $@

# The install is order-only: a fresh install in a job that downloaded build/ must not mark it stale.
build/.typespec: $(TYPESPEC_SOURCES) Cargo.toml | $(TYPESPEC_MODULES)
	rm -rf build/.typespec build/schemas build/openapi build/api build/json-schema
	typespec/node_modules/.bin/tsp compile typespec
	node typespec/npm-scripts/whole-numbers.mjs
	node typespec/npm-scripts/enum-names.mjs
	node typespec/npm-scripts/union-schemas.mjs
	node typespec/npm-scripts/channel-wire.mjs
	node typespec/npm-scripts/tenant-api-wire.mjs
	typespec/node_modules/.bin/openapi-typescript build/openapi/openapi.json -o build/openapi/paths.ts
	node typespec/npm-scripts/packages.mjs
	@touch $@

build/.rust: build/.typespec $(XTASK_SOURCES) Cargo.lock
	rm -rf build/.rust crates/tumpel-api/generated
	cargo run --quiet -p xtask -- generate-api
	cp build/json-schema/TenantConfig.json crates/tumpel-api/generated/
	cargo fmt -p tumpel-api
	@touch $@

pack: build/.typespec | $(ROOT_MODULES)
	rm -rf dist
	mkdir -p dist
	cp packages/api/*.ts build/api/
	node_modules/.bin/tsc -p tsconfig.json
	npm pack ./build/schemas ./build/openapi ./build/api --pack-destination dist
	cd dist && for tarball in *.tgz; do sha256sum "$$tarball" > "$$tarball.sha256"; done
