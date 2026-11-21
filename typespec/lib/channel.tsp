import "./models.tsp";
import "./claude-setup.tsp";

namespace Tumpel.Channel;

@doc("""
  The WebSocket close code each side closes a connection with. Revoked tells the host the tenant
  revoked it: the host stops its boxes, deletes its key and does not reconnect. On every other
  code but BadSignature and UnsupportedVersion the host reconnects.
  """)
enum CloseCode {
  ProtocolError: 4400,
  BadSignature: 4401,
  Revoked: 4403,
  HeartbeatDeadline: 4408,
  Replaced: 4409,
  UnsupportedVersion: 4426,
}

@doc("""
  Each direction of a host's channel numbers its frames from 1 in `seq`, and the count survives
  reconnects and restarts. `ack` is the highest `seq` the sender has received from the other side
  with no gap before it, 0 before the first one; it advances only with the sender's next frame. A
  receiver drops a frame whose `seq` is at or below the last one it accepted, and treats a gap as
  a protocol error that closes the connection. After Welcome each side resends, in order, every
  frame the other side has not acked, and the receiver drops the duplicates. The control plane
  keeps both counters and its unacked frames in durable storage. The supervisor writes its
  counters and unacked frames to disk before it sends a frame; when it starts without that state
  it does not dial, and exits with failure ChannelStateLost, and the host is enrolled again.
  Challenge, Hello, Welcome and Heartbeat belong to one connection and travel outside frames,
  with no `seq`; only Welcome carries an `ack`. Each side ignores fields it does not know.
  """)
model Sequenced {
  seq: Sequence;
  ack: Sequence;
}

@doc("""
  The first message on every connection, from the control plane: a fresh nonce, the unpadded
  base64url encoding of 32 random bytes, that the host must sign. A connection that sends anything
  but Hello next is closed.
  """)
model Challenge {
  type: "Challenge";
  @minLength(43) nonce: string;
}

@doc("""
  The host's answer to Challenge. `signature` is the base64 Ed25519 signature, by the host key
  made at enrolment, over these bytes in order: the ASCII string `tumpel-channel-hello-v1`, one
  0x00 byte, the ASCII bytes of the Challenge `nonce`, one 0x00 byte, and the UTF-8 bytes of
  `hostId`. The control plane rebuilds those bytes from the nonce it sent and verifies the
  signature against the host's stored public key. It answers Welcome, and closes the connection
  with BadSignature on a bad signature, Revoked for a revoked host, and UnsupportedVersion for a
  protocol version outside ChannelProtocol.Oldest to ChannelProtocol.Version. `boxCapacity` is the host's box slots from
  its runtime config and `usage` what it holds as it connects; the control plane keeps both for
  the host's tenant before it reads the host Online. `channelProtocolOldest` is the oldest
  channel protocol version the host speaks, and `protocolVersion` its newest; a host that leaves
  it out speaks only `protocolVersion`. `guestProtocol` is the guest protocol range the host
  accepts from a box. The control plane records both ranges and shows them on the host.
  """)
model Hello {
  type: "Hello";
  hostId: EntityId;
  @minValue(1) protocolVersion: int32;
  @minValue(1) channelProtocolOldest?: int32;
  @minLength(1) supervisorVersion: string;
  @minLength(1) signature: string;
  @minValue(1) @maxValue(256) boxCapacity: int32;
  usage: HostUsage;
  guestProtocol?: GuestProtocolRange;
}

@doc("""
  The control plane accepts the host. Both sides then resend their unacked frames. `ack` is the
  highest host `seq` the control plane has received with no gap before it. The host drops its
  unacked frames at or below it before it resends, so a frame the control plane took on an earlier
  connection is never counted as undelivered. A control plane that leaves it out acks only with its
  next frame.
  """)
model Welcome {
  type: "Welcome";
  hostId: EntityId;
  @minValue(1) protocolVersion: int32;
  ack?: Sequence;
}

@doc("""
  The control plane sends one when it has sent nothing else for its heartbeat interval of 10
  seconds. A side that has received nothing for 30 seconds treats the connection as dead and closes
  it; the control plane then reads the host Offline.
  """)
model Heartbeat {
  type: "Heartbeat";
  sentAt: offsetDateTime;
}

@doc("""
  The control plane sends one to every Online host when the release bucket stores a new current
  release, `releaseVersion` naming it. It travels outside frames, as Heartbeat does, so it is never
  resent: a host that misses it reads the release at its next Welcome. The host reads
  GET /v1/releases/current and updates its supervisor when the release names another binary. A
  supervisor that predates this message closes the connection with ProtocolError on it, and the
  Welcome of its reconnect reads the release.
  """)
model ReleasePublished {
  type: "ReleasePublished";
  @minLength(1) releaseVersion: string;
}

@doc("""
  The control plane's answer to a host frame whose message matches no HostMessage. It travels
  outside frames, as Heartbeat does. The control plane counts that `seq` as received, so the next
  frame follows it without a gap, records nothing for it, and names the mismatch in `reason`. The
  host drops the frame from its unacked frames and logs FrameRefused with the reason, so one frame
  no control plane reads never holds up the channel. A supervisor that predates this message closes
  the connection with ProtocolError on it, and its reconnect resends the frame, which the control
  plane drops as a duplicate.
  """)
model FrameRefused {
  type: "FrameRefused";
  seq: Sequence;
  @minLength(1) reason: string;
}

@doc("""
  A HostFrame as channel.json keeps it until the control plane acks it. The message stays as the
  supervisor wrote it, so a supervisor of another version loads it whatever message kinds it reads
  and resends it unchanged; a message no control plane reads is answered with FrameRefused.
  """)
model StoredHostFrame {
  type: "Frame";
  ...Sequenced;
  message: unknown;
}

@doc("""
  The host sends one every 10 seconds after Welcome, whatever else it sends, with its usage. The
  control plane keeps the last one per host for the host's tenant, which places a new session on
  the Online host with the most free box slots, then the most memory available.
  `heldSessionIds` names every session the host holds a box for, whether the box runs a turn, waits
  warm or still boots, and is empty when it holds none. The host sends every frame queued before it
  read the list ahead of the Heartbeat, so the first Heartbeat after Welcome follows the resent
  frames. On that Heartbeat the control plane fails each Running turn on the host whose session the
  list does not name with BoxLost.
  """)
model HostHeartbeat {
  type: "Heartbeat";
  sentAt: offsetDateTime;
  usage: HostUsage;
  heldSessionIds: EntityId[];
}

@doc("One environment variable for one turn: a secret set member's value. It lives in box memory only and is never written to the host's disk.")
model DispatchVariable {
  @minLength(1) name: string;
  @minLength(1) value: string;
}

@doc("""
  The dispatch variables for one offer: every member of the persona's secret set, the credential for
  the harness's provider under the variable its kind maps to and every other member under its own
  name. The control plane decrypts them from the secret set each time it sends or resends a
  TurnOffer, keeps no plaintext copy and records the variable names in an append-only handover log;
  `credentialHandoverId` names this handover in the supervisor's errors. `expiresAt`, the end of
  the turn's credential span (the longer of dispatchGrantTtlSeconds and turnOfferTtlSeconds plus
  turnImageFetchBudgetSeconds, from when the offer was sent), is when the supervisor stops handing
  the variables to a box and fails the turn DispatchCredentialExpired instead.
  """)
model DispatchGrant {
  credentialHandoverId: EntityId;
  expiresAt: offsetDateTime;
  variables: DispatchVariable[];

  @doc("The harness arguments the catalog maps the credential to; they hold no secret. A grant without them gives the guest none.")
  arguments?: string[];

  @doc("A CredentialFile credential: the guest writes `value` to `path` under the harness home, mode 0600, before the harness starts, and deletes it at the end of the turn.")
  credentialFile?: {
    @minLength(1) path: string;
    @minLength(1) value: string;
  };

  @doc("The session's connectors, none when its persona lists none. The guest forwarder serves each at its loopback route and fetches its access token from tokenUrl with tokenCredential. Neither reaches the harness.")
  connectors: DispatchConnector[];
}

@doc("""
  One connector of a turn. `url` is the upstream MCP server. `tokenUrl` is the control plane's
  ConnectorTokens_fetch for this turn and connector, and `tokenCredential` its ConnectorTurnToken,
  valid while the turn is Running. The guest keeps both in forwarder memory only: never in the
  harness environment, a file, a log or a snapshot, and a new tokenCredential never restarts the
  harness. `name` is the connector's name; the guest derives each harness's MCP server name from it,
  and from `connectorId` when a control plane leaves it out.
  """)
model DispatchConnector {
  connectorId: EntityId;
  name?: DisplayName;
  url: url;
  tokenUrl: url;
  @minLength(43) tokenCredential: string;
}

@doc("""
  One stored snapshot of a session, for a box that boots cold. `downloadUrl` is a presigned GET of
  the SnapshotRoot under `storageKey` alone, valid until `downloadExpiresAt`, the end of the turn's
  credential span, the DispatchGrant's expiresAt.
  """)
model SnapshotDownload {
  snapshotId: EntityId;
  snapshotSeq: Sequence;
  storageKey: StorageKey;
  downloadUrl: url;
  downloadExpiresAt: offsetDateTime;
}

@doc("""
  One file of the session's persona. `downloadUrl` is a presigned GET of the blob stored under
  `digest`, valid until `downloadExpiresAt`, the DispatchGrant's expiresAt. The supervisor
  checks the bytes against `digest` and keeps them in its cache, so a digest it already holds is
  not fetched again.
  """)
model PersonaFileDownload {
  path: PersonaFilePath;
  digest: Sha256Digest;
  sizeBytes: PersonaFileSize;
  downloadUrl: url;
  downloadExpiresAt: offsetDateTime;
}

@doc("""
  The full guest image of the turn, from the current ReleaseManifest, for the session's harness version
  and the architecture the host enrolled with, offered while the release lacks a base image or a
  harness layer for them. `imageUrl`, `kernelUrl` and `manifestUrl` are presigned
  GETs of the ext4 image, the kernel and the GuestImageManifest document stored under
  `imageDigest`, `kernelDigest` and `manifestDigest` in the release bucket, valid until
  `downloadExpiresAt`, turnOfferTtlSeconds plus `fetchSeconds` after the send of the offer. A supervisor whose
  image cache lacks `imageDigest` sends TurnImageFetching and downloads the three within `fetchSeconds` of
  sending it, counting the wait for another image the host is fetching; it fetches one image at a time,
  checks each against its digest and only then moves them into the cache, replacing the cached image
  of the same harness version; it skips the kernel when the cache holds `kernelDigest`. A download
  that fails, misses its digest or names another image in its manifest fails the turn ImageFetchFailed,
  one that outlasts `fetchSeconds` fails it ImageFetchTimedOut.
  """)
model GuestImageDownload {
  kind: "Full";
  imageDigest: Sha256Digest;
  kernelDigest: Sha256Digest;
  manifestDigest: Sha256Digest;
  imageUrl: url;
  kernelUrl: url;
  manifestUrl: url;
  downloadExpiresAt: offsetDateTime;
  @minValue(1) fetchSeconds: int32;
}

@doc("""
  The base image of a layered boot, the current release's ReleaseBaseImage for the host's
  architecture. `imageUrl`, `kernelUrl` and `manifestUrl` are presigned GETs of the ext4 image, the
  kernel and the BaseImageManifest document stored under `imageDigest`, `kernelDigest` and
  `manifestDigest` in the release bucket.
  """)
model BaseImageDownload {
  imageDigest: Sha256Digest;
  kernelDigest: Sha256Digest;
  manifestDigest: Sha256Digest;
  imageUrl: url;
  kernelUrl: url;
  manifestUrl: url;
}

@doc("""
  The harness layer of a layered boot, the current release's ReleaseHarnessLayer for the session's
  harness version and the host's architecture. `layerUrl` and `manifestUrl` are presigned GETs of
  the squashfs file and the HarnessLayerManifest document stored under `layer.layerDigest` and
  `layer.manifestDigest` in the release bucket.
  """)
model HarnessLayerDownload {
  layer: ReleaseHarnessLayer;
  layerUrl: url;
  manifestUrl: url;
}

@doc("""
  The layered boot of the turn, offered when the current release carries a base image for the
  host's architecture and a harness layer for the session's harness version on it. The box boots
  from the base, the guest drive of the host's supervisor and the layer. The URLs are valid until
  `downloadExpiresAt`, turnOfferTtlSeconds plus `fetchSeconds` after the send of the offer. A supervisor whose
  cache lacks the base or the layer sends TurnImageFetching naming the first part it lacks, then
  fetches base, kernel and layer within one `fetchSeconds` of sending it, counting the wait for
  another fetch on the host, and checks each against its digest before it moves it into the cache. A
  download that fails, misses its digest or names another part in its manifest fails the turn
  ImageFetchFailed, one that outlasts `fetchSeconds` fails it ImageFetchTimedOut. The host keeps the
  base and the layer in its cache while a box runs on them.
  """)
model LayeredImageDownload {
  kind: "Layered";
  base: BaseImageDownload;
  layer: HarnessLayerDownload;
  downloadExpiresAt: offsetDateTime;
  @minValue(1) fetchSeconds: int32;
}

@doc("What a box boots from: a full guest image, or a base image with a harness layer.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union BootImage {
  Full: GuestImageDownload,
  Layered: LayeredImageDownload,
}

@doc("""
  The control plane offers a turn to the host. The host answers TurnClaim, or TurnFailed when it
  cannot run it. `lastLineSeq` is the session's last transcript line, so the box numbers the turn's
  first line `lastLineSeq` + 1. `snapshots` holds the session's latest stored snapshot, which a box
  that boots cold restores from; it is empty for a session with none. `personaFiles` is the persona's file set as it stands when the offer is sent. `gitAuthorName` and
  `gitAuthorEmail` are the git identity the box commits as: the bot of the stage's GitHub App when the tenant
  installed it, else the GitHub user of the secret set's GITHUB_TOKEN, with its noreply address. `image` is the guest image
  the box boots. A resend of the offer keeps its `seq` and carries a new `credential`, `lastLineSeq`,
  `snapshots`, `personaFiles`, `image` and git identity.
  """)
model TurnOffer {
  type: "TurnOffer";
  turnId: EntityId;
  sessionId: EntityId;
  boxId: EntityId;
  repository: RepositoryUrl;
  harness: Harness;
  @minLength(1) harnessVersion: string;
  `model`: ModelName;
  prompt: Prompt;
  credential: DispatchGrant;
  lastLineSeq: Sequence;
  @maxItems(1) snapshots: SnapshotDownload[];
  personaFiles: PersonaFileDownload[];
  image: BootImage;
  gitAuthorName: DisplayName;
  gitAuthorEmail: EmailAddress;

  @doc("""
    The memory in MiB the box boots with: the persona's boxMemoryMib, or BoxMemoryLimit.DefaultMib. A box
    that is already warm keeps the memory it booted with. A supervisor given an offer without it boots
    the box with memoryMib of its runtime config.
    """)
  @minValue(128)
  @maxValue(65536)
  boxMemoryMib?: int32;

  @doc("""
    The disk in MiB the box boots with: the persona's boxDiskMib, or BoxDiskLimit.DefaultMib. A box that
    is already warm keeps the disk it booted with. A supervisor given an offer without it boots the
    box with overlayMib of its runtime config, and refuses the turn PoolExhausted when the disk does
    not fit its disk budget.
    """)
  @minValue(64)
  @maxValue(262144)
  boxDiskMib?: int32;

  @doc("""
    Set when the turn builds a prebuild: the box clones the repository at this commit and runs the
    repository's setup step, /opt/tumpel/prebuild.mjs run, in place of the harness, its output lines
    being the turn's lines. The credential then holds only a GITHUB_TOKEN that reads the
    repository's contents, and the snapshot the control plane asks for after the turn is the
    prebuild's layer.
    """)
  @pattern("^[0-9a-f]{40}$")
  prebuildCommitSha?: string;
}

@doc("""
  Takes the place of an unacked TurnOffer when the control plane resends it after its turn left
  Offered, so the resend keeps every `seq` and no key reaches a turn that already ended. It is also
  the answer to a TurnClaim for a turn that left Offered before the claim arrived: the host then
  hands the turn no prompt, keeps the box warm and reports nothing for the turn.
  """)
model TurnWithdrawn {
  type: "TurnWithdrawn";
  turnId: EntityId;
}

@doc("""
  The host accepts the offered turn. It sends this at once, before it fetches the image, restores the
  snapshot or boots the box; those keep their own budgets and failures. The control plane answers TurnClaimed
  and the turn reads Running, or answers TurnWithdrawn when the turn already left Offered. The host
  hands the prompt to the harness only once TurnClaimed arrived and the box is ready. A host that
  gives up waiting for the answer hands nothing and fails the turn NotClaimed, and the control plane
  offers the turn again. So a turn is either claimed and its result reaches the control plane, or
  refused before the harness starts.
  """)
model TurnClaim {
  type: "TurnClaim";
  turnId: EntityId;
  boxId: EntityId;
}

@doc("The control plane's answer to a TurnClaim for a turn that was still Offered; the turn now reads Running, and the host hands its prompt to the harness once the box is ready.")
model TurnClaimed {
  type: "TurnClaimed";
  turnId: EntityId;
}

@doc("""
  The host's cache lacks part of the offer's image and the host has started to download it: `imageDigest` names
  the full image, or the base image or harness layer of a layered boot, whichever it lacks first.
  It follows the TurnClaim; the host fails the turn ImageFetchTimedOut when the fetch outlasts the
  offer's `image.fetchSeconds`.
  """)
model TurnImageFetching {
  type: "TurnImageFetching";
  turnId: EntityId;
  imageDigest: Sha256Digest;
}

@doc("The box holds the session's repository and the harness is about to get the prompt; the first-line budget starts here.")
model TurnRepositoryReady {
  type: "TurnRepositoryReady";
  turnId: EntityId;
}

@doc("One harness-native JSONL line. `lineSeq` continues the session's line count, so lines of a turn arrive in `lineSeq` order with no gap.")
model TurnLine {
  type: "TurnLine";
  turnId: EntityId;
  lineSeq: Sequence;
  text: string;
}

@doc("The harness finished the turn. `lastLineSeq` is the turn's final line; the control plane holds every line up to it and stores the snapshot after it before the turn reads Completed, and fails the turn SnapshotNotStored when that snapshot is not stored.")
model TurnComplete {
  type: "TurnComplete";
  turnId: EntityId;
  lastLineSeq: Sequence;
  completedAt: offsetDateTime;

  @doc("The turn's credential file as the harness rewrote it; the control plane stores it in place of the secret set's CredentialFile member.")
  @minLength(1)
  credentialFile?: string;

  @doc("The guest's warning for a turn the harness completed, such as a box disk with less than a hundredth of it free; the control plane shows it on the turn read.")
  @minLength(1)
  warning?: string;
}

@doc("The box could not clone the session's repository; the turn fails RepositoryCloneFailed. `detail` carries what git reported.")
model TurnRepositoryCloneFailed {
  type: "TurnRepositoryCloneFailed";
  turnId: EntityId;
  cause: RepositoryCloneFailureCause;
  detail: string;
  failedAt: offsetDateTime;
}

model TurnFailed {
  type: "TurnFailed";
  turnId: EntityId;
  reason: TurnFailureReason;
  detail: string;
  failedAt: offsetDateTime;

  @doc("The turn's credential file as the harness rewrote it; the control plane stores it in place of the secret set's CredentialFile member.")
  @minLength(1)
  credentialFile?: string;
}

@doc("""
  Asks the host to end turn `turnId` at once, which the control plane already failed Cancelled. The
  host ends the harness and answers TurnFailed Cancelled with the turn's credential file, and the
  control plane keeps the reason and detail it recorded. The box is then a box after any turn, and the
  SnapshotRequest and BoxTeardown that follow snapshot and free it. A host that runs no such turn
  does nothing.
  """)
model TurnCancel {
  type: "TurnCancel";
  turnId: EntityId;
}

@doc("""
  Asks the host to store the upper directory of a box as a SnapshotRoot under `storageKey`. The
  host sends the chunk digests its files hold that the box's previous snapshot did not in
  SnapshotChunks parts, packs the ones the tenant lacks together with the chunks of its encoded
  SnapshotManifest, sends their placements in SnapshotPacks parts, uploads the packs each
  SnapshotPackUploads names, then PUTs the root to `uploadUrl`, a presigned PUT of `storageKey`
  alone, and answers SnapshotDone. Every URL expires at `uploadExpiresAt`, the snapshot deadline,
  after which the control plane records the snapshot failed NotAnswered.
  """)
model SnapshotRequest {
  type: "SnapshotRequest";
  snapshotId: EntityId;
  sessionId: EntityId;
  boxId: EntityId;
  turnId: EntityId;
  snapshotSeq: Sequence;
  storageKey: StorageKey;
  uploadUrl: url;
  uploadExpiresAt: offsetDateTime;
}

@doc("""
  Where one chunk is stored: the chunk whose bytes have the lower-case hex SHA-256 `digest` lies
  `length` bytes long at byte `offset` of the pack `packDigest`. A pack is chunks concatenated, about
  8 MiB of them, stored under `<tenantId>/packs/<packDigest>`, where `packDigest` is the SHA-256 of
  the whole pack.
  """)
model ChunkPlacement {
  digest: Sha256Digest;
  packDigest: Sha256Digest;
  @minValue(0) offset: int64;
  @minValue(1) length: int32;
}

@doc("One pack: `packDigest` is the SHA-256 of its `sizeBytes` bytes.")
model Pack {
  packDigest: Sha256Digest;
  @minValue(1) sizeBytes: int64;
}

@doc("""
  One pack object stored under `<tenantId>/packs/<packDigest>`, `sizeBytes` long, and `url` a
  presigned URL of that object alone.
  """)
model PackUrl {
  packDigest: Sha256Digest;
  @minValue(1) sizeBytes: int64;
  url: url;
}

@doc("""
  Part `part` of the chunk digests the files of a snapshot hold that the box's previous snapshot
  did not, at most ChunkExchange.DigestsPerPart of them. The host sends part 1 once its files are
  cut, and each next part once the answer to the one before arrived. The control plane answers
  SnapshotChunksHeld and counts each digest as referenced by the session.
  """)
model SnapshotChunks {
  type: "SnapshotChunks";
  snapshotId: EntityId;
  @minValue(1) part: int32;
  @maxItems(DigestsPerPart) digests: Sha256Digest[];
}

@doc("""
  The answer to SnapshotChunks part `part`: where the tenant stores each digest of that part it
  holds already. A digest left out is stored in no pack, and the host packs and uploads it.
  """)
model SnapshotChunksHeld {
  type: "SnapshotChunksHeld";
  snapshotId: EntityId;
  @minValue(1) part: int32;
  @maxItems(DigestsPerPart) held: ChunkPlacement[];
}

@doc("""
  Part `part` of the chunks a snapshot packed: where each chunk lies, at most
  ChunkExchange.DigestsPerPart of them, and the size of each pack they lie in. A pack whose chunks
  run past one part is listed again in the next. The host sends part 1 once its packs are written,
  and each next part once the answer to the one before arrived. The control plane keeps the
  placements until SnapshotDone, counts each digest as referenced by the session, and answers
  SnapshotPackUploads.
  """)
model SnapshotPacks {
  type: "SnapshotPacks";
  snapshotId: EntityId;
  @minValue(1) part: int32;
  @maxItems(DigestsPerPart) packs: Pack[];
  @maxItems(DigestsPerPart) chunks: ChunkPlacement[];
}

@doc("""
  The answer to SnapshotPacks part `part`: a presigned PUT for each pack of that part the tenant
  holds no object for, valid until `uploadExpiresAt`. Each URL signs the pack's SHA-256 as the
  x-amz-checksum-sha256 header, so the host sends that header and object storage refuses bytes that
  do not hash to the key. A pack left out is stored already.
  """)
model SnapshotPackUploads {
  type: "SnapshotPackUploads";
  snapshotId: EntityId;
  @minValue(1) part: int32;
  @maxItems(DigestsPerPart) uploads: PackUrl[];
  uploadExpiresAt: offsetDateTime;
}

@doc("""
  Part `part` of the chunks a box that boots cold needs for turn `turnId` and lacks in the host's
  chunk cache, each at the placement its manifest or root names, at most
  ChunkExchange.DigestsPerPart of them, grouped by pack. The host sends each next part once the
  answer to the one before arrived, and starts the downloads of each part as its answer arrives.
  The control plane answers RestoreDownloads.
  """)
model RestoreChunks {
  type: "RestoreChunks";
  turnId: EntityId;
  @minValue(1) part: int32;
  @maxItems(DigestsPerPart) chunks: ChunkPlacement[];
}

@doc("""
  The answer to RestoreChunks part `part`: a presigned GET for each pack that holds chunks of that
  part, valid until `downloadExpiresAt`, the DispatchGrant's expiresAt. A pack is left out when
  any chunk asked in it is no chunk of the session at that placement, and the host fails the turn
  SnapshotUnreadable.
  """)
model RestoreDownloads {
  type: "RestoreDownloads";
  turnId: EntityId;
  @minValue(1) part: int32;
  @maxItems(DigestsPerPart) packs: PackUrl[];
  downloadExpiresAt: offsetDateTime;
}

@doc("The host stored the snapshot's packs and root. `uploadedBytes` counts the bytes it uploaded: the packs the tenant lacked, plus the root.")
model SnapshotDone {
  type: "SnapshotDone";
  snapshotId: EntityId;
  @minValue(0) uploadedBytes: int64;
}

@doc("Why the host could not store a snapshot.")
enum SnapshotFailureReason {
  BoxNotFound: "BoxNotFound",
  UpperDirectoryUnreadable: "UpperDirectoryUnreadable",
  UploadExpired: "UploadExpired",
  UploadRejected: "UploadRejected",
  SnapshotTimedOut: "SnapshotTimedOut",

  @doc("The control plane's own: the host did not answer within snapshotDeadlineSeconds of the request.")
  NotAnswered: "NotAnswered",
}

@doc("The host could not store the snapshot. `detail` states what failed and what fixes it.")
model SnapshotFailed {
  type: "SnapshotFailed";
  snapshotId: EntityId;
  reason: SnapshotFailureReason;
  detail: string;
  failedAt: offsetDateTime;
}

@doc("""
  Asks the host to tear down the box of a session once a snapshot holds its last completed turn:
  when a person stops or archives the session, after each turn of an Off session, and when placement
  evicts an Auto box. A host keeps a paused box until BoxTeardown or BoxDiscard names it. The host
  answers BoxGone, also when it runs no box of the session with that boxId, or BoxTeardownFailed.
  """)
model BoxTeardown {
  type: "BoxTeardown";
  sessionId: EntityId;
  boxId: EntityId;
}

@doc("""
  Asks the host to drop a box of a session that moved to another host, even when the box holds a
  completed turn no snapshot holds, or of a session whose repository the box could not clone. The host answers BoxGone, also when it runs no such box.
  """)
model BoxDiscard {
  type: "BoxDiscard";
  sessionId: EntityId;
  boxId: EntityId;
}

@doc("The host runs no box of the session any more and returned its TAP device to the pool.")
model BoxGone {
  type: "BoxGone";
  sessionId: EntityId;
  boxId: EntityId;
}

@doc("Why the host kept a box it was asked to tear down.")
enum BoxTeardownFailureReason {
  @doc("The box holds a completed turn no snapshot holds yet.")
  BoxDirty: "BoxDirty",
}

@doc("The host kept the box. `detail` states what failed and what fixes it.")
model BoxTeardownFailed {
  type: "BoxTeardownFailed";
  sessionId: EntityId;
  boxId: EntityId;
  reason: BoxTeardownFailureReason;
  detail: string;
  failedAt: offsetDateTime;
}

@doc("""
  Asks the host to boot box `boxId` from `image` with no repository, no persona files and no
  credential, and run `claude setup-token` in it for Claude setup `claudeSetupId`. The host answers
  ClaudeSetupBoxUrl once the command prints its sign-in URL, hands the code of a ClaudeSetupBoxCode
  to the command's standard input, and answers ClaudeSetupBoxFailed when the box stops without
  storing the token. `harness` names the harness at `harnessVersion` that `image` boots, and an offer
  without it names ClaudeCode. Only the box writes the token: it POSTs it to `tokenUrl` with `tokenCredential`
  as its bearer token, and the host never sees it. `tokenCredential` is bound to this setup and
  writes its token once, while the setup is Minting. The host stops the box at `expiresAt`, when it stores the token, or on
  ClaudeSetupBoxDiscard, and deletes its drive.
  """)
model ClaudeSetupBoxOffer {
  type: "ClaudeSetupBoxOffer";
  claudeSetupId: EntityId;
  tenantId: EntityId;
  boxId: EntityId;
  harness?: ClaudeSetupHarness;
  harnessVersion: HarnessVersion;
  image: BootImage;
  tokenUrl: url;
  @minLength(43) tokenCredential: string;
  expiresAt: offsetDateTime;
}

@doc("""
  The code the person submitted, for the standard input of the setup's `claude setup-token`; the
  host forwards it to the box once and keeps no copy. The box fails the setup MintTimedOut when
  Claude Code prints no token within `mintBudgetSeconds` of the code.
  """)
model ClaudeSetupBoxCode {
  type: "ClaudeSetupBoxCode";
  claudeSetupId: EntityId;
  boxId: EntityId;
  code: ClaudeSetupCodeText;

  @minValue(1)
  @maxValue(3600)
  mintBudgetSeconds: int32;
}

@doc("""
  Asks the host to stop the setup's box and delete its drive, also in place of an unacked offer or
  code of a setup that ended. The host answers nothing, and does nothing when it runs no such box.
  """)
model ClaudeSetupBoxDiscard {
  type: "ClaudeSetupBoxDiscard";
  claudeSetupId: EntityId;
  boxId: EntityId;
}

@doc("The setup's `claude setup-token` printed the URL where the person signs in.")
model ClaudeSetupBoxUrl {
  type: "ClaudeSetupBoxUrl";
  claudeSetupId: EntityId;
  signInUrl: url;
  @minLength(1) @maxLength(64) userCode?: string;
}

@doc("""
  The setup's box stopped without storing the token and is gone. `detail` states what failed and
  what fixes it, and never holds the token.
  """)
model ClaudeSetupBoxFailed {
  type: "ClaudeSetupBoxFailed";
  claudeSetupId: EntityId;
  reason: ClaudeSetupFailureReason;
  detail: string;
  failedAt: offsetDateTime;
}

@doc("""
  The host's supervisor update from the binary `fromSha256` to `toSha256` entered `phase`. The new
  binary sends Online once it reaches Welcome after the swap.
  """)
model SupervisorUpdateStep {
  type: "SupervisorUpdateStep";
  ...SupervisorUpdateStepReport;
}

@doc("""
  The host's supervisor update stopped. `detail` states what failed and what fixes it.
  `outputTail` holds the last lines the candidate printed in its dry run, token-shaped runs
  hidden, and is empty for every other reason.
  """)
model SupervisorUpdateFailed {
  type: "SupervisorUpdateFailed";
  ...SupervisorUpdateFailureReport;
}

@doc("""
  Metric points the supervisor collected at its lifecycle edges and from its host sampler, sent
  while the channel is Welcomed. The control plane overwrites each point's `hostId` dimension with
  the host that signed the connection, stamps each turn.cost and turn.tokens point with the
  personaId, secretSetId, provider and costBasis of the turn as it offered it, drops a turn.cost
  point whose costBasis is NotReported, and writes the batch to the tenant's metrics store. A batch
  the store refuses is logged as TelemetryRejected and still acked. The control plane refuses this
  message on a connection that speaks a protocol version below 19.
  """)
model TelemetryBatch {
  type: "TelemetryBatch";
  ...MetricBatch;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "type" })
union HostMessage {
  TurnImageFetching: TurnImageFetching,
  TurnClaim: TurnClaim,
  TurnRepositoryReady: TurnRepositoryReady,
  TurnLine: TurnLine,
  TurnComplete: TurnComplete,
  TurnRepositoryCloneFailed: TurnRepositoryCloneFailed,
  TurnFailed: TurnFailed,
  SnapshotChunks: SnapshotChunks,
  SnapshotPacks: SnapshotPacks,
  RestoreChunks: RestoreChunks,
  SnapshotDone: SnapshotDone,
  SnapshotFailed: SnapshotFailed,
  BoxGone: BoxGone,
  BoxTeardownFailed: BoxTeardownFailed,
  ClaudeSetupBoxUrl: ClaudeSetupBoxUrl,
  ClaudeSetupBoxFailed: ClaudeSetupBoxFailed,
  SupervisorUpdateStep: SupervisorUpdateStep,
  SupervisorUpdateFailed: SupervisorUpdateFailed,
  TelemetryBatch: TelemetryBatch,
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "type" })
union ControlMessage {
  TurnOffer: TurnOffer,
  TurnWithdrawn: TurnWithdrawn,
  TurnClaimed: TurnClaimed,
  TurnCancel: TurnCancel,
  SnapshotRequest: SnapshotRequest,
  SnapshotChunksHeld: SnapshotChunksHeld,
  SnapshotPackUploads: SnapshotPackUploads,
  RestoreDownloads: RestoreDownloads,
  BoxTeardown: BoxTeardown,
  BoxDiscard: BoxDiscard,
  ClaudeSetupBoxOffer: ClaudeSetupBoxOffer,
  ClaudeSetupBoxCode: ClaudeSetupBoxCode,
  ClaudeSetupBoxDiscard: ClaudeSetupBoxDiscard,
}

@doc("One message from the host to the control plane, sequenced per Sequenced.")
model HostFrame {
  type: "Frame";
  ...Sequenced;
  message: HostMessage;
}

@doc("One message from the control plane to the host, sequenced per Sequenced.")
model ControlFrame {
  type: "Frame";
  ...Sequenced;
  message: ControlMessage;
}

@doc("""
  Everything the host sends on a connection: Hello, Heartbeat, or a sequenced frame. The host opens
  every connection itself, as a WebSocket to /v1/hosts/{hostId}/channel on the control plane's
  endpoint (wss for https, ws for http), and the control plane holds at most one per host: a new
  connection that reaches Welcome closes the one before it. Each message is one JSON text message.
  """)
@discriminated(#{ envelope: "none", discriminatorPropertyName: "type" })
union HostEnvelope {
  Hello: Hello,
  Heartbeat: HostHeartbeat,
  Frame: HostFrame,
}

@doc("Everything the control plane sends on a connection: Challenge, Welcome, Heartbeat, ReleasePublished, FrameRefused, or a sequenced frame.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "type" })
union ControlEnvelope {
  Challenge: Challenge,
  Welcome: Welcome,
  Heartbeat: Heartbeat,
  ReleasePublished: ReleasePublished,
  FrameRefused: FrameRefused,
  Frame: ControlFrame,
}
