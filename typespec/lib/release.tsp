import "@typespec/http";
import "./models.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("The harness of a guest image's GuestHarness: a catalog harness, or Shell for the test image the proof's Shell harness steps boot.")
enum ImageHarness {
  ...Harness,
  Shell: "Shell",
}

@doc("""
  One supervisor binary of a release, stored in the release bucket under
  `supervisor/<arch>/<sha256>`, where `<arch>` is the architecture in lower case. Releases build
  amd64 only until an arm64 host passes the proof. The bucket is private, so the control plane answers presigned GETs of it.
  """)
model ReleaseSupervisor {
  architecture: HostArchitecture;
  sha256: Sha256Digest;
  @minValue(1) sizeBytes: int64;

  @doc("The version of the supervisor release this binary comes from, the one it reports in Hello.")
  @minLength(1)
  supervisorVersion: string;

  @doc("The GuestProtocol.Version the supervisor and the guest drive inside it speak; a release that keeps this supervisor refuses to publish from a commit whose GuestProtocol.Oldest to GuestProtocol.Version leaves it out.")
  @minValue(1)
  guestProtocolVersion: int32;
}

@doc("""
  The `release.json` asset of a supervisor release: its version, the tumpel-api version it was
  built with, the ChannelProtocol and GuestProtocol ranges it speaks, and one binary per
  architecture. A control plane release reads it to refuse a supervisor whose ranges miss its own.
  """)
model SupervisorRelease {
  @pattern("^[0-9]+\\.[0-9]+\\.[0-9]+$") supervisorVersion: string;
  @pattern("^[0-9]+\\.[0-9]+\\.[0-9]+$") tumpelApiVersion: string;
  @minValue(1) channelProtocolOldest: int32;
  @minValue(1) channelProtocolVersion: int32;
  @minValue(1) guestProtocolOldest: int32;
  @minValue(1) guestProtocolVersion: int32;
  @minItems(1) binaries: SupervisorReleaseBinary[];
}

@doc("One static supervisor binary of a supervisor release, attached as `tumpel-supervisor-<arch>-linux`.")
model SupervisorReleaseBinary {
  architecture: HostArchitecture;
  sha256: Sha256Digest;
  @minValue(1) sizeBytes: int64;
}

@doc("""
  One `tumpel` CLI binary of a release, built with the same static target as the supervisor and
  stored in the release bucket under `cli/<arch>/<sha256>`, where `<arch>` is the architecture in
  lower case. Releases build amd64 only until an arm64 host passes the proof.
  """)
model ReleaseCli {
  architecture: HostArchitecture;
  sha256: Sha256Digest;
  @minValue(1) sizeBytes: int64;
}

@doc("""
  One guest image of a release, for one harness version and architecture. The ext4 image and its
  GuestImageManifest document are stored under `images/<harness>/<harnessVersion>/<arch>/<digest>`
  by `imageDigest` and `manifestDigest`, the kernel under `kernels/<arch>/<kernelDigest>`. The same
  root filesystem is published as an OCI image of one gzip layer: its manifest, config and layer
  blobs are stored under `oci/<harness>/<harnessVersion>/<arch>/<digest>`, each by its own sha256,
  and `ociDigest` names the manifest. The uncompressed layer, a tar of the root filesystem, is
  stored under `images/<harness>/<harnessVersion>/<arch>/rootfs/<rootfsDigest>`, the diff_id the
  OCI config names, for a build job to load with docker import.
  """)
model ReleaseImage {
  harness: ImageHarness;
  harnessVersion: HarnessVersion;
  architecture: HostArchitecture;
  imageDigest: Sha256Digest;
  kernelDigest: Sha256Digest;
  manifestDigest: Sha256Digest;
  ociDigest: Sha256Digest;
  rootfsDigest: Sha256Digest;
}

@doc("""
  The base image of an image release for one architecture: Ubuntu and the dev tools, with no
  harness and no guest agent. The ext4 image and its BaseImageManifest document are stored under
  `images/base/<arch>/<digest>` by `imageDigest` and `manifestDigest`, the kernel under
  `kernels/<arch>/<kernelDigest>`. The OCI image's blobs are stored under `oci/base/<arch>/<digest>`
  and `ociDigest` names its manifest. The uncompressed layer is stored under
  `images/base/<arch>/rootfs/<rootfsDigest>`, the diff_id the OCI config names, for a prebuild job
  to load with docker import.
  """)
model ReleaseBaseImage {
  architecture: HostArchitecture;
  imageDigest: Sha256Digest;
  kernelDigest: Sha256Digest;
  manifestDigest: Sha256Digest;
  ociDigest: Sha256Digest;
  rootfsDigest: Sha256Digest;
}

@doc("""
  What `npm run guest:image -- base` built, <imageDigest>.json in the base directory of the image
  output next to <imageDigest>.ext4. `baseLayoutVersion` is the BaseLayout.Version the image
  writes to /etc/tumpel/base-layout; a guest drive of another version refuses to boot it.
  """)
model BaseImageManifest {
  imageDigest: Sha256Digest;
  kernelUrl: url;
  kernelDigest: Sha256Digest;
  baseRootfsUrl: url;
  baseRootfsDigest: Sha256Digest;
  @minValue(1) baseLayoutVersion: int32;
  components: GuestImageComponent[];
}

@doc("""
  One harness layer of a release, for one harness version and architecture: a read-only squashfs
  image compressed with zstd whose root is `/opt/harness/<harness>/<harnessVersion>` in the box.
  The squashfs file and its HarnessLayerManifest document are stored under
  `layers/<harness>/<harnessVersion>/<arch>/<digest>` by `layerDigest` and `manifestDigest`.
  `sizeBytes` is the size of the squashfs file. A host attaches a layer only once its sha256
  matches `layerDigest`.
  """)
model ReleaseHarnessLayer {
  harness: ImageHarness;
  harnessVersion: HarnessVersion;
  architecture: HostArchitecture;
  layerDigest: Sha256Digest;
  manifestDigest: Sha256Digest;
  @minValue(1) sizeBytes: int64;
}

@doc("""
  What `npm run harness:layer` built, <layerDigest>.json next to <layerDigest>.squashfs.
  `recipeDigest` is the sha256 of the recipe the layer was built from: the GuestHarness, the
  catalog's install recipe, the architecture and the build script. The release run stores the
  layer's ReleaseHarnessLayer under `layers/<harness>/<harnessVersion>/<arch>/recipes/<recipeDigest>`
  and builds a layer only when that object is missing. `harness` is the GuestHarness the layer
  carries as `tumpel-harness.json` at its root.
  """)
model HarnessLayerManifest {
  layerDigest: Sha256Digest;
  recipeDigest: Sha256Digest;
  architecture: HostArchitecture;
  harness: GuestHarness;
}

@doc("""
  The current release, `current.json` in the release bucket, the one
  object there that changes; every other object is stored once under its digest. The control plane
  validates it against this schema each time it reads it, and places a session only on a host whose
  architecture has an image of the session's harness version here, or a base image and a harness
  layer of it. A release lists at most one
  supervisor and one CLI per architecture and one image per harness, harness version and architecture.
  """)
model ReleaseManifest {
  @minLength(1) releaseVersion: string;
  @pattern("^[0-9a-f]{40}$") commit: string;
  @doc("The ChannelProtocol.Version the release's supervisors speak; the host channel handshake accepts a supervisor that speaks ChannelProtocol.Oldest to ChannelProtocol.Version and refuses one outside it.")
  @minValue(1)
  channelProtocolVersion: int32;
  @minItems(1) supervisors: ReleaseSupervisor[];
  @minItems(1) clis: ReleaseCli[];
  @doc("The images of the latest image release, copied from `images.json` when the release is published.")
  images: ReleaseImage[];

  @doc("The harness layers of the release, one per harness, harness version and architecture; the binaries job builds the ones whose recipe the release bucket lacks.")
  @minItems(1)
  harnessLayers: ReleaseHarnessLayer[];

  @doc("The base images of the latest image release, one per architecture, copied from `images.json` when the release is published. A turn boots layered on a host whose architecture has a base here and a harness layer of the session's harness version.")
  @minItems(1)
  bases: ReleaseBaseImage[];
}

@doc("""
  The latest image release, `images.json` in the release bucket. A push
  of a tag `images-vX.Y.Z` builds the guest images, stores them by digest and replaces this
  object; every release published after it carries these images. `imageReleaseVersion` is the tag
  and `commit` the commit it names. `guestProtocolVersion` is the GuestProtocol.Version its guests
  speak; a release whose supervisor speaks GuestProtocol.Oldest to GuestProtocol.Version without
  it refuses to publish until a new image release.
  """)
model ImageRelease {
  @pattern("^images-v[0-9]+\\.[0-9]+\\.[0-9]+$") imageReleaseVersion: string;
  @pattern("^[0-9a-f]{40}$") commit: string;
  @minValue(1) guestProtocolVersion: int32;
  @minItems(1) images: ReleaseImage[];

  @doc("The BaseLayout.Version the base images of this image release carry.")
  @minValue(1)
  baseLayoutVersion: int32;

  @doc("One base image per architecture.")
  @minItems(1)
  bases: ReleaseBaseImage[];
}

model ReleaseSupervisorPath {
  @path architecture: HostArchitecture;
}

@doc("The current supervisor binary: `location` is a presigned GET valid for five minutes.")
model SupervisorDownload {
  @statusCode statusCode: 302;
  @header location: string;
}

model ReleaseCliPath {
  @path architecture: HostArchitecture;
}

@doc("The current CLI binary: `location` is a presigned GET valid for five minutes.")
model CliDownload {
  @statusCode statusCode: 302;
  @header location: string;
}

@doc("""
  The CLI install script: POSIX sh that downloads the current CLI for the machine's architecture,
  checks it against the sha256 the current release publishes and installs it.
  """)
model CliInstallScript {
  @header contentType: "text/plain";
  @body script: string;
}

@doc("""
  The deploy drain. While it is in place the control plane starts no session and no turn, and
  refuses both with DeployInProgress. The deploy reads `GET /v1/releases/rollout` with `drainToken`
  as the bearer until the control plane reports the new commit.
  """)
model DeployDrain {
  @pattern("^[A-Za-z0-9_-]{43}$") drainToken: string;
}

@doc("A host with turns Offered or Running on it.")
model RolloutHost {
  hostId: EntityId;
  tenantId: EntityId;
  @minValue(0) runningTurns: int32;
}

@doc("""
  The stage-wide view of a release rollout: the commit the control plane Worker was deployed from,
  each host that has turns Offered or Running, and `drained` once no host has any.
  """)
model ReleaseRollout {
  @pattern("^[0-9a-f]{40}$") deployedCommit: string;
  drained: boolean;
  hosts: RolloutHost[];
}

@doc("The drainToken of the deploy drain in place.")
model DeployDrainToken is BearerAuth;
