import "@typespec/http";
import "./models.tsp";
import "./build-provider.tsp";

using TypeSpec.Http;

namespace Tumpel;

enum PrebuildState {
  @doc("The prebuild's turn is offered to a host.")
  Dispatched: "Dispatched",

  @doc("The host claimed the turn and runs the setup step, then stores the box's snapshot as the layer.")
  Building: "Building",

  @doc("The layer is uploaded and the control plane cuts it into chunks.")
  Converting: "Converting",

  @doc("The layer is stored; a session of the repository on the same guest image restores it on its first turn instead of cloning and installing.")
  Done: "Done",

  @doc("The prebuild stopped in one phase; its failure names the phase and the fix.")
  Failed: "Failed",
}

@doc("Where the commands a prebuild runs came from.")
enum PrebuildConfigSource {
  @doc("The repository's .devcontainer/devcontainer.json or .devcontainer.json.")
  RepositoryFile: "RepositoryFile",

  @doc("The repository holds neither file, so the build ran the default config: npm ci when the root holds package-lock.json or npm-shrinkwrap.json, as npm is the one package manager the guest image carries. A session that commits a devcontainer.json replaces it.")
  Default: "Default",
}

@doc("The phase a Failed prebuild stopped in. A provider that refuses the job refuses the start, and no prebuild exists.")
enum PrebuildFailurePhase {
  @doc("The turn ended before its host claimed it: no host claimed it within turnClaimBudgetSeconds, or no installation token could be minted for the clone.")
  Dispatch: "Dispatch",

  @doc("The turn failed: the clone or the setup step failed, or it ran past its budget.")
  Build: "Build",

  @doc("The host did not store the box's snapshot.")
  Upload: "Upload",

  @doc("The uploaded layer could not be cut into chunks.")
  Conversion: "Conversion",
}

model PrebuildDispatched {
  state: PrebuildState.Dispatched;
}

model PrebuildBuilding {
  state: PrebuildState.Building;
}

model PrebuildConverting {
  state: PrebuildState.Converting;

  @doc("The sha256 of the compressed OCI layer the job uploaded.")
  layerDigest: Sha256Digest;

  @minValue(1) layerSizeBytes: int64;
  uploadedAt: offsetDateTime;
}

model PrebuildDone {
  state: PrebuildState.Done;

  @doc("The sha256 of the OCI layer the provider uploaded.")
  layerDigest: Sha256Digest;

  @minValue(0) layerSizeBytes: int64;
  finishedAt: offsetDateTime;
}

model PrebuildFailed {
  state: PrebuildState.Failed;
  phase: PrebuildFailurePhase;
  finishedAt: offsetDateTime;
}

@doc("Where a prebuild is, with the facts of its state: the layer once Done, the failed phase once Failed.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union PrebuildStatus {
  Dispatched: PrebuildDispatched,
  Building: PrebuildBuilding,
  Converting: PrebuildConverting,
  Done: PrebuildDone,
  Failed: PrebuildFailed,
}

@doc("""
  A repository's dependencies installed once by a build provider on the tenant's account, stored as
  one layer. The repository, the input digest and the guest image digest are its key: every commit
  with the same devcontainer files and lockfiles, built on the same guest image, shares one
  prebuild. A prebuild exists only once its provider accepted the job.
  """)
model Prebuild {
  @key prebuildId: EntityId;
  tenantId: EntityId;

  @doc("The persona whose secret set's GITHUB_TOKEN read the inputs when the tenant has no GitHub App installation for the repository, whose harness version picks the guest image, and whose name the job's subject carries.")
  personaId: EntityId;

  @doc("The repository as https://github.com/<owner>/<name> in lower case, whatever form the start named it in.")
  repository: RepositoryUrl;

  @doc("""
    The sha256 over the repository's devcontainer files and lockfiles on its default branch: every
    file under .devcontainer/, the file .devcontainer.json, and these lockfiles at the repository
    root: package-lock.json, npm-shrinkwrap.json, yarn.lock, pnpm-lock.yaml, bun.lock, bun.lockb,
    Cargo.lock, go.sum, uv.lock, poetry.lock, Pipfile.lock, Gemfile.lock, composer.lock, mix.lock,
    pubspec.lock and flake.lock, and the manifest the default config reads: package.json. For each
    file present, in byte order of its path, one line
    `<path>` NUL `<git blob sha of the file>` LF; the digest is the sha256 of those lines.
    """)
  inputDigest: Sha256Digest;

  @doc("""
    The digest of the guest image the layer is built on: the current release's image of the
    persona's harness version for Amd64. A layer is a diff against its image, so a new image needs
    a new prebuild. Prebuilds build on Amd64 until the release carries Arm64 images.
    """)
  guestImageDigest: Sha256Digest;

  @doc("The provider the start named. The prebuild runs on one of the tenant's online Amd64 hosts, as a turn of a session the session list leaves out.")
  provider: BuildProvider;

  configSource: PrebuildConfigSource;

  status: PrebuildStatus;
  startedAt: offsetDateTime;

  @doc("The transcript of the prebuild's turn: the output of the repository's setup step.")
  logUrl: url;

  createdAt: int64;
  updatedAt: int64;
}

@doc("Why a prebuild ended Failed. Exists only for a prebuild in state Failed; the prebuild's status holds when.")
model PrebuildFailure {
  @key prebuildId: EntityId;
  tenantId: EntityId;
  phase: PrebuildFailurePhase;

  @doc("What failed, with what the provider reported.")
  detail: string;

  @doc("What fixes it.")
  fix: string;

  createdAt: int64;
}

model PrebuildPath {
  @path prebuildId: EntityId;
}

@doc("Starts a prebuild of a repository's default branch.")
model PrebuildStart {
  @doc("A GitHub repository, such as https://github.com/acme/app.git or acme/app.")
  repository: RepositoryUrl;

  @doc("The persona whose secret set's GITHUB_TOKEN reads the repository when the tenant's GitHub App installation does not cover it, and whose harness version picks the guest image.")
  personaId: EntityId;

  @doc("Recorded on the prebuild; the prebuild runs on one of the tenant's online Amd64 hosts, which builds no other prebuild.")
  provider: BuildProvider;

  @doc("Start a job even when a prebuild with the same key is stored or running; false when left out.")
  rebuild?: boolean;
}

model PrebuildListQuery {
  @doc("A GitHub repository, in any form a start accepts. Leave it out to list every prebuild of the tenant.")
  @query
  repository?: RepositoryUrl;
}

@doc("""
  What a GitHub Actions run of the caller workflow needs to build its prebuild. The start keeps the
  rest of the job's inputs out of the caller workflow, so the workflow holds only the API origin.
  """)
model PrebuildJobInputs {
  prebuildId: EntityId;
  tenantId: EntityId;

  @doc("A presigned GET of the guest image's root filesystem tar, valid for the dispatch and build budgets from this answer.")
  rootfsUrl: url;

  @doc("The digest of the guest image the layer is built on.")
  imageDigest: Sha256Digest;
}

@doc("""
  The OIDC token of the prebuild's upload job: a GitHub Actions token, or a CircleCI V2 job token
  that circleci run oidc get mints. Its aud is the origin of the API the job calls with no trailing
  slash, such as https://api.example.com.
  """)
model ProviderJobToken is BearerAuth;

@doc("Asks for the presigned upload of a prebuild's layer: one OCI layer tar, named by its sha256 and size.")
model PrebuildUploadStart {
  @doc("The tenant that started the prebuild; the dispatch hands it to the job with the prebuild id.")
  tenantId: EntityId;

  layerDigest: Sha256Digest;

  @doc("At most 5 GiB, what one presigned PUT takes.")
  @minValue(1)
  @maxValue(5368709120)
  layerSizeBytes: int64;
}

@doc("""
  Where to PUT the layer: one PUT to `url` carrying content-length of the layer size and
  x-amz-checksum-sha256 of `sha256`, the two headers the URL signs,
  before `uploadExpiresAt`, the prebuild upload budget after the exchange. /opt/tumpel/prebuild.mjs
  upload in the guest image asks for it and makes the PUT.
  """)
model PrebuildUploadGrant {
  prebuildId: EntityId;
  tenantId: EntityId;

  @doc("The layer digest the PUT is signed for.")
  sha256: Sha256Digest;

  url: url;
  uploadExpiresAt: offsetDateTime;
}

@doc("Tells the control plane the job uploaded the layer its start recorded.")
model PrebuildUploadComplete {
  tenantId: EntityId;
}
