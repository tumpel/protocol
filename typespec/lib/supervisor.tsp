import "./models.tsp";
import "./channel.tsp";

namespace Tumpel;

@doc("""
  The supervisor's enrolment, supervisor.json in the supervisor directory: $TUMPEL_SUPERVISOR_DIR,
  or $XDG_STATE_HOME/tumpel-supervisor, or ~/.local/state/tumpel-supervisor. The directory is mode
  700 and every file in it mode 600. `tumpel-supervisor enrol` writes it; `run` reads it.
  """)
model SupervisorConfig {
  @doc("The base URL of the control plane the host enrolled with, such as https://tumpel.example.com.")
  endpoint: HttpUrl;

  hostId: EntityId;
  tenantId: EntityId;
}

@doc("""
  The host's Ed25519 key pair, host-key.json in the supervisor directory, made at enrolment.
  `privateKey` is the base64 PKCS#8 document; `publicKey` is the base64 raw 32-byte key the control
  plane holds. Revoke deletes this file.
  """)
model SupervisorHostKey {
  @minLength(1) publicKey: Token;
  @minLength(1) privateKey: Token;
}

@doc("""
  The host side of the channel's sequencing, channel.json in the supervisor directory, written
  before every frame the host sends. `received` is the highest control-plane `seq` accepted with no
  gap, `sent` the highest `seq` the host assigned, and `unacked` every host frame the control plane
  has not acked yet, in `seq` order. `replays` counts, for each unacked frame resent after a
  Welcome, how many Welcomes it has been resent after; a file written before the count existed
  leaves it out. A supervisor that finds this file missing exits with failure ChannelStateLost.
  """)
model SupervisorChannelState {
  received: Sequence;
  sent: Sequence;
  @maxItems(10000) unacked: Channel.StoredHostFrame[];
  @maxItems(10000) replays?: SupervisorChannelReplay[];
}

@doc("""
  How many Welcomes the unacked host frame `seq` has been resent after without the control plane
  acking it. The supervisor gives a frame up after 10.
  """)
model SupervisorChannelReplay {
  seq: Sequence;
  @minValue(1) replays: int32;
}

@doc("The named ways `tumpel-supervisor run` stops.")
enum SupervisorFailure {
  NotEnrolled: "NotEnrolled",
  ChannelStateLost: "ChannelStateLost",
  HostRevoked: "HostRevoked",
  ProtocolError: "ProtocolError",

  @doc("The supervisor could not read the host's usage from /proc for its Heartbeat.")
  UsageUnreadable: "UsageUnreadable",

  @doc("The supervisor could not write the guest drive it carries to the guest directory of imageCacheDir.")
  GuestDriveUnwritable: "GuestDriveUnwritable",

  @doc("""
    A supervisor on its update trial failed to start, or did not reach Welcome within 120 s of its
    start. systemd starts the unit again, and its ExecStartPre puts the previous binary back.
    """)
  UpdateNotOnline: "UpdateNotOnline",

  @doc("""
    The supervisor failed to reach Welcome on 10 connections in a row, waiting longer between each,
    up to 30 s. systemd starts the unit again.
    """)
  ChannelUnreachable: "ChannelUnreachable",

  @doc("""
    The control plane did not ack an unacked host frame after it was resent after 10 Welcomes, and
    the frame has no failure the host can send in its place. The host cannot skip a `seq`, so it
    stops; systemd starts the unit again, and a control plane that took the frame meanwhile acks it
    in its next Welcome.
    """)
  FrameUndelivered: "FrameUndelivered",
}

@doc("""
  A swap from the binary `fromSha256` to `toSha256`. The updater writes it as update-pending.json
  in the supervisor directory before it moves the candidate over the running binary. The new binary
  renames it to update-trial.json as it starts and deletes that once it reaches Welcome. The unit's
  ExecStartPre puts the previous binary back when update-trial.json is still there, and renames it
  to update-rolled-back.json, which the restored binary reports and deletes.
  """)
model SupervisorUpdatePending {
  fromSha256: Sha256Digest;
  toSha256: Sha256Digest;
  swappedAt: offsetDateTime;
}

@doc("""
  The boxes a supervisor hands to the binary it swapped in, handover.json in the supervisor
  directory. Once every running turn reached a point it can resume from, the old supervisor writes
  this file, renames update-pending.json to update-trial.json and execs the new binary with
  `run --handover` in its own process, so each Firecracker process stays its child and every
  descriptor named here stays open. The new binary reads the file as it starts, adopts each box
  whose process is still its child, resumes its turn or keeps it paused, fails the turn of a box
  whose process ended, and deletes the file once it reaches Welcome. A binary started without
  `--handover`, such as the previous one systemd puts back, fails the turns the file names and
  deletes it. A box handed over keeps no snapshot base, so its next snapshot reads
  every file of its drive again.
  """)
model SupervisorHandover {
  handedAt: offsetDateTime;
  @maxItems(1000) boxes: SupervisorHandoverBox[];
}

@doc("""
  One box of a handover. `queued` holds the commands that reached the box's session while its turn
  was parked, in arrival order; the new binary runs them once the turn ends.
  """)
model SupervisorHandoverBox {
  sessionId: EntityId;
  boxId: EntityId;
  @minValue(0) @maxValue(255) tapIndex: int32;
  machine: SupervisorHandoverMachine;
  image: SupervisorHandoverImage;
  dirty: boolean;
  credentialFile?: CredentialText;
  state: SupervisorHandoverBoxState;
  @maxItems(1000) queued: SupervisorHandoverCommand[];
}

@doc("""
  The Firecracker process of a handed box and the descriptors the exec keeps open: the guest
  connection on the box's vsock and the read ends of the process's standard output and error.
  `guestBuffer` and `consoleTail` are base64: the bytes read from the guest and not decoded yet, and
  the console tail kept for failure details.
  """)
model SupervisorHandoverMachine {
  @minValue(1) processId: int32;
  apiSocket: PathText;
  vsock: PathText;
  @minValue(0) guestFd: int32;
  guestBuffer: GuestBufferText;
  @minValue(0) stdoutFd: int32;
  @minValue(0) stderrFd: int32;
  consoleTail: Detail;
}

@doc("Guest bytes read and not decoded yet, base64: up to one whole guest frame of 4 MiB and its 4-byte length.")
@maxLength(5592412)
scalar GuestBufferText extends string;

@doc("The image a handed box booted from, so the new binary holds it in its cache and reads its harness.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SupervisorHandoverImage {
  Full: SupervisorHandoverFullImage,
  Layered: SupervisorHandoverLayeredImage,
}

model SupervisorHandoverFullImage {
  kind: "Full";
  manifest: GuestImageManifest;
}

model SupervisorHandoverLayeredImage {
  kind: "Layered";
  base: BaseImageManifest;
  layer: HarnessLayerManifest;
  layerPath: PathText;
}

@doc("What a handed box was doing: paused, or running a turn.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SupervisorHandoverBoxState {
  Warm: SupervisorHandoverWarm,
  Turn: SupervisorHandoverTurn,
}

@doc("""
  A paused box. It stays paused until BoxTeardown or BoxDiscard names it. A supervisor writes
  `warmMilliseconds` as 0 and `expired` as false and ignores both on read.
  """)
model SupervisorHandoverWarm {
  kind: "Warm";
  @minValue(0) warmMilliseconds: int64;
  expired: boolean;
}

@doc("""
  A box running a turn whose harness started. The milliseconds are what was left of the turn's
  budget and of its first-line budget at the handover; `error` is the error result the harness
  printed so far.
  """)
model SupervisorHandoverTurn {
  kind: "Turn";
  turnId: EntityId;
  @minValue(0) turnMilliseconds: int64;
  @minValue(0) firstLineMilliseconds: int64;
  repositoryReady: boolean;
  seenLine: boolean;
  error?: SupervisorHandoverTurnError;

  @doc("The control plane cancelled the turn, so the successor sends the guest TurnCancel when it resumes the turn.")
  cancelled?: boolean;
}

model SupervisorHandoverTurnError {
  reason: TurnFailureReason;
  detail: Detail;
}

@doc("A command that reached a handed box's session while its turn was parked: a snapshot, a teardown or a discard of the box.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SupervisorHandoverCommand {
  Snapshot: SupervisorHandoverSnapshot,
  Teardown: SupervisorHandoverTeardown,
  Discard: SupervisorHandoverDiscard,
}

model SupervisorHandoverSnapshot {
  kind: "Snapshot";
  snapshotId: EntityId;
  snapshotSeq: Sequence;
  uploadUrl: UrlText;
  uploadExpiresAt: offsetDateTime;
}

model SupervisorHandoverTeardown {
  kind: "Teardown";
}

model SupervisorHandoverDiscard {
  kind: "Discard";
}

@doc("""
  The candidate binary the updater refuses, update-refusal.json in the supervisor directory, after
  its dry run, its swap or its first start failed. The updater skips a release that names this
  sha256 again.
  """)
model SupervisorUpdateRefusal {
  toSha256: Sha256Digest;
  reason: SupervisorUpdateFailureReason;
  refusedAt: offsetDateTime;
}

@doc("""
  What `tumpel-supervisor check` prints on standard output as one JSON line once every check
  passed: its own version and the channel and guest protocol versions it speaks.
  """)
model SupervisorCheckReport {
  @minLength(1) supervisorVersion: ShortText;
  @minValue(1) channelProtocolVersion: int32;
  @minValue(1) guestProtocolVersion: int32;
}

@doc("How the guest hands a turn to the harness and reads where the turn ends.")
enum GuestHarnessProtocol {
  @doc("""
    Claude Code with --input-format stream-json --output-format stream-json: one user message per
    turn on standard input; the turn ends with the line whose `type` is `result`.
    """)
  ClaudeStreamJson: "ClaudeStreamJson",

  @doc("""
    Pi with --mode rpc: one `prompt` command per turn on standard input; the turn ends with the
    line whose `type` is `agent_settled`, or with the `response` to that prompt when Pi refuses it
    or handles it without a run. The guest leaves out the `message_update` and
    `tool_execution_update` deltas; the `_end` events carry the same content whole.
    """)
  PiRpc: "PiRpc",

  @doc("""
    A shell reading standard input: the prompt is written as script text, followed by a command
    that prints an end marker; every line before the marker belongs to the turn. For tests.
    """)
  ShellLines: "ShellLines",

  @doc("""
    One process per turn, such as opencode run --format json: the guest starts the command with
    --model and the turn's model, and --continue from the session's second turn on, writes the
    prompt to standard input and closes it. Every line on standard output belongs to the turn,
    which ends when the process exits: Completed on status 0, HarnessExited otherwise.
    """)
  PromptOnStdin: "PromptOnStdin",

  @doc("""
    Codex with exec --json: one process per turn. The guest starts the command with --model and
    the turn's model, then the arguments of the turn's credential, which name the model provider,
    then resume and the thread id once a turn recorded one; a credential without arguments fails
    the turn before Codex starts. The guest records the `thread_id` of each `thread.started` line
    under /var/lib/tumpel, so the session's snapshot carries it. It writes the prompt to standard
    input and closes it, and leaves out the `item.updated` deltas, because `item.completed` carries
    the same item whole. Every other line on standard output belongs to the turn, which ends when
    the process exits: Completed on status 0, HarnessExited otherwise.
    """)
  CodexExecJson: "CodexExecJson",
}

@doc("""
  The harness a guest image runs, /etc/tumpel/guest.json in the image. `harness` is the catalog's
  harness name, such as ClaudeCode, or Shell for the test image, which the catalog does not list.
  `cloneSeconds` is how long the clone of the session's repository may take before git is stopped
  and the turn ends RepositoryCloneFailed with cause TimedOut, 120 in the images `npm run guest:image` builds.
  `fixedVariables` are the non-secret variables the harness always runs with, such as the switches that
  turn off its self-updater and version check; the guest sets them after the image environment and
  before the turn's credential variables, so a credential variable of the same name wins.
  """)
model GuestHarness {
  @minLength(1) harness: ShortText;
  @minLength(1) harnessVersion: ShortText;
  protocol: GuestHarnessProtocol;
  @minItems(1) @maxItems(256) command: Detail[];
  @minLength(1) workingDirectory: PathText;
  @minValue(1) cloneSeconds: int32;

  environment: GuestEnvironment;
  @maxItems(100) fixedVariables: FixedVariable[];
}

@doc("""
  The image's environment. The guest starts the harness with it, the OCI image config carries it,
  and the prebuild script runs the devcontainer commands with it.
  """)
model GuestEnvironment {
  @minLength(1) PATH: Detail;
  @minLength(1) HOME: ShortText;
  @minLength(1) LANG: ShortText;
}

@doc("A pinned piece of a guest image besides the harness, such as the Node runtime.")
model GuestImageComponent {
  @minLength(1) name: ShortText;
  @minLength(1) version: ShortText;
  url: HttpUrl;
  digest: Sha256Digest;
}

@doc("""
  What `npm run guest:image` built, <imageDigest>.json in the image cache next to
  <imageDigest>.ext4 and <kernelDigest>.vmlinux.
  """)
model GuestImageManifest {
  imageDigest: Sha256Digest;
  kernelUrl: HttpUrl;
  kernelDigest: Sha256Digest;
  baseRootfsUrl: HttpUrl;
  baseRootfsDigest: Sha256Digest;
  harness: GuestHarness;
  @maxItems(100) components: GuestImageComponent[];
}

@doc("The time limits of a box's phases. Each one that runs out ends its phase with a named failure.")
model BoxBudgets {
  @doc("""
    Cold boot until the guest says GuestHello, after the session's latest snapshot is downloaded
    and its files reassembled from chunks, or resuming a warm box; BoxBootFailed. A root, pack or
    chunk that cannot be downloaded before its URL expires, or read, fails SnapshotUnreadable.
    """)
  @minValue(1)
  bootSeconds: int32;

  @doc("TurnRepositoryReady until the harness's first line, and TurnStart until the first line within the image's cloneSeconds plus this; NoFirstOutput.")
  @minValue(1)
  firstLineSeconds: int32;

  @doc("TurnStart until TurnEnd; TurnTimedOut.")
  @minValue(1)
  turnSeconds: int32;

  @doc("Reading the paused box's drive until its files are cut into chunks in the chunk cache; SnapshotTimedOut. The chunk exchanges, the packing and the uploads run until the request's uploadExpiresAt; UploadExpired.")
  @minValue(1)
  snapshotSeconds: int32;
}

@doc("""
  How the supervisor runs boxes, runtime.json in the supervisor directory, written with defaults by
  `tumpel-supervisor enrol`. `imageCacheDir` holds the images by digest, the harness layers under
  layers/<digest>.squashfs, and the snapshot chunks the host built or downloaded under chunks/<digest>.
  After a new harness layer lands, the supervisor deletes the least recently attached layers no box
  holds until the layers fit `layerCacheMib`, 8192 by default. `dataDir` holds each box's
  sockets under box<k>/, each session's overlay drive and snapshot files under
  sessions/<sessionId>/, and the persona file blobs it fetched under persona-files/<digest>.
  `boxCapacity` is the size of the TAP pool `tumpel-supervisor install` makes: devices tumpel0 up to
  tumpel<boxCapacity - 1>, device k with gateway 172.16.<k>.1/30 and guest 172.16.<k>.2. Each box
  claims one device and returns it at teardown; a turn past the pool fails PoolExhausted.
  `memoryMib` is the memory of a box whose TurnOffer names no boxMemoryMib, BoxMemoryLimit.DefaultMib by default.
  `overlayMib` is the disk of a box whose TurnOffer names no boxDiskMib, 32768 by default; the drive
  is a sparse file, so the host's disk holds only what the box wrote.
  A paused box stays until BoxTeardown or BoxDiscard names it, and a box that does not fit is
  refused PoolExhausted without touching another box.
  `heartbeatIntervalSeconds` is how often the supervisor sends a Heartbeat after Welcome, 10 by
  default; it matches heartbeatIntervalSeconds of the control plane, whose heartbeatDeadlineSeconds
  stays above it.
  `updateGraceSeconds` is how long a supervisor told of a new release waits while a box runs a turn,
  600 by default. It updates at once when no box runs a turn, and when the wait ends it hands its
  boxes to the new supervisor anyway.
  """)
model SupervisorRuntime {
  @minLength(1) firecrackerPath: PathText;
  @minLength(1) imageCacheDir: PathText;
  @minLength(1) dataDir: PathText;
  @minValue(1) @maxValue(256) boxCapacity: int32;
  @minValue(1) vcpuCount: int32;
  @minValue(128) memoryMib: int32;
  @minValue(64) overlayMib: int32;
  @minValue(1) layerCacheMib: int32;
  budgets: BoxBudgets;
  @minValue(1) @maxValue(300) heartbeatIntervalSeconds: int32;
  @minValue(0) updateGraceSeconds: int32;
}

@doc("""
  The guest's first frame on every vsock connection, and the frame it sends once to the host's
  ready port after it starts listening. `protocolVersion` is the guest's GuestProtocol.Version.
  `lastLineSeq` is the session's line count so far.
  Frames on the guest's vsock connection are a 4-byte big-endian length followed by that many
  bytes of UTF-8 JSON: one GuestMessage from the guest, one GuestInput from the host.
  """)
model GuestHello {
  type: "GuestHello";
  @minValue(1) protocolVersion: int32;
  @minLength(1) harness: ShortText;
  @minLength(1) harnessVersion: ShortText;
  lastLineSeq: Sequence;
}

@doc("One persona file for the guest to write under the harness home: its path, digest and base64 bytes.")
model GuestPersonaFile {
  path: PersonaFilePath;
  digest: Sha256Digest;
  content: GuestPersonaFileContent;
}

@doc("""
  The host hands a turn to the guest. The guest starts the harness with every variable of the
  credential in its environment and never writes them to disk or logs them. Before the harness
  starts it writes each of `files` under the harness home and deletes the files of an earlier
  set the new one leaves out. The guest keeps one harness process per box and starts it again,
  continuing the conversation, only when the variables, the files or the model differ from the
  ones it runs on, or the process has exited.
  Before the harness starts, a harness working directory that holds no repository gets a clone of
  `repository` at its default branch. Git reads GITHUB_TOKEN from the environment through a
  credential helper, so the token is never in the URL or on disk; a clone that fails, or runs past
  the image's cloneSeconds, ends the turn with TurnRepositoryCloneFailed. Once the directory holds the repository the guest sends
  TurnRepositoryReady, at once when it held one already. The harness environment carries `gitAuthorName` and `gitAuthorEmail` as
  the git author and committer, and GITHUB_TOKEN also as GH_TOKEN.
  `lastLineSeq` is the TurnOffer's: the guest numbers the turn's first line `lastLineSeq` + 1.
  """)
model GuestTurnStart {
  type: "TurnStart";
  turnId: EntityId;
  `model`: ModelName;
  prompt: Prompt;
  credential: Channel.DispatchGrant;
  @maxItems(100) files: GuestPersonaFile[];
  repository: RepositoryUrl;
  gitAuthorName: DisplayName;
  gitAuthorEmail: EmailAddress;
  lastLineSeq: Sequence;

  @doc("""
    The TurnOffer's: once the working directory holds the repository, the guest resets its branch
    to this commit, writes the marker .git/tumpel-prebuilt and runs /opt/tumpel/prebuild.mjs run as
    the turn's process with the image environment and no credential, in place of the harness. A
    later turn that finds the marker, in a box restored from the prebuild's snapshot, pulls the
    branch fast-forward before the harness starts and deletes the marker.
    """)
  @pattern("^[0-9a-f]{40}$")
  prebuildCommitSha?: ShortText;

  @doc("The host's turn budget, budgets.turnSeconds of its runtime config, which the guest names to the harness beside the box's memory, disk and CPUs.")
  @minValue(1)
  turnSeconds?: int32;
}

@doc("The harness working directory holds the session's repository; the first-line budget starts here.")
model GuestTurnRepositoryReady {
  type: "TurnRepositoryReady";
  turnId: EntityId;
}

@doc("One line the harness wrote. `lineSeq` continues the session's line count from GuestHello.")
model GuestTurnLine {
  type: "TurnLine";
  turnId: EntityId;
  lineSeq: Sequence;
  text: LongText;
}

enum GuestTurnEndReason {
  Completed: "Completed",
  HarnessExited: "HarnessExited",
  HarnessStartFailed: "HarnessStartFailed",

  @doc("The kernel ran out of memory and killed the harness tree; the detail names the box memory and the process the kernel picked.")
  HarnessOutOfMemory: "HarnessOutOfMemory",

  @doc("The host sent TurnCancel for the turn and the guest killed the harness; a guest older than guest protocol 12 never sends it.")
  Cancelled: "Cancelled",

  @doc("The harness failed while the box's disk was full; the detail names its size. A guest older than guest protocol 13 never sends it.")
  BoxDiskFull: "BoxDiskFull",
}

@doc("The guest could not clone the session's repository and did not start the harness. `detail` carries what git reported.")
model GuestTurnRepositoryCloneFailed {
  type: "TurnRepositoryCloneFailed";
  turnId: EntityId;
  cause: RepositoryCloneFailureCause;
  detail: Detail;
}

@doc("The turn ended. `detail` carries the tail of the harness's standard error when it did not complete.")
model GuestTurnEnd {
  type: "TurnEnd";
  turnId: EntityId;
  reason: GuestTurnEndReason;
  lastLineSeq: Sequence;
  detail: Detail;

  @doc("The turn's credential file as the harness left it, when it differs from the one the turn wrote; the guest deletes the file at the end of the turn.")
  @minLength(1)
  credentialFile?: CredentialText;

  @doc("""
    What the harness reported the turn used, read from its lines: turn.tokens per TokenKind and,
    when the harness reported a cost the provider charges, turn.cost. Empty when the harness
    reported no usage; a guest older than guest protocol 11 sends none.
    """)
  @maxItems(1000) metrics?: GuestMetric[];

  @doc("Set on a Completed end when the box's disk has less than a hundredth of it free: its size and the boxDiskMib that raises it. A guest older than guest protocol 13 never sends it.")
  @minLength(1)
  warning?: Detail;
}

@doc("""
  One value the guest read from the harness at the end of a turn. The supervisor records it as a
  turn point with the turn's dimensions beside its own.
  """)
model GuestMetric {
  ...MetricInstrument;
  value: float64;
  @TypeSpec.JsonSchema.maxProperties(32) dimensions: Record<ShortText>;
}

@doc("""
  The host hands the guest a Claude setup. The guest runs the image harness's program with the
  argument `setup-token` on a pseudo-terminal, with the image's environment and nothing else, and
  sends GuestClaudeSetupUrl once it prints a sign-in URL. Once Claude Code prints the token, the
  guest POSTs it to `tokenUrl` as a ClaudeSetupTokenWrite naming `tenantId`, with
  `tokenCredential` as its bearer token, keeps it in memory only and never logs it or sends it to
  the host. A Codex image runs `codex login --device-auth` instead and sends GuestClaudeSetupUrl
  with the one-time code it prints; once Codex exits signed in, the guest reads
  its auth.json and POSTs the whole file with the expiry of the exp claim of its access token.
  """)
model GuestClaudeSetupStart {
  type: "ClaudeSetupStart";
  claudeSetupId: EntityId;
  tenantId: EntityId;
  tokenUrl: HttpUrl;
  @minLength(43) tokenCredential: Token;
}

@doc("""
  The code for the standard input of the setup's `claude setup-token`, followed by Enter. The guest
  sends GuestClaudeSetupFailed MintTimedOut when Claude Code prints no token within
  `mintBudgetSeconds` of the code.
  """)
model GuestClaudeSetupCode {
  type: "ClaudeSetupCode";
  claudeSetupId: EntityId;
  code: ClaudeSetupCodeText;

  @minValue(1)
  @maxValue(3600)
  mintBudgetSeconds: int32;
}

@doc("""
  The host ends turn `turnId`: the guest reads its connection while a turn runs, kills the harness
  and every process it started, whatever the harness protocol, and sends TurnEnd Cancelled with the
  turn's credential file. A guest that runs no such turn
  ignores it. A guest older than guest protocol 12 reads nothing mid-turn, so the host's cancel
  budget runs out and the host ends the turn by closing the connection.
  """)
model GuestTurnCancel {
  type: "TurnCancel";
  turnId: EntityId;
}

@doc("One frame from the host to the guest.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "type" })
union GuestInput {
  TurnStart: GuestTurnStart,
  TurnCancel: GuestTurnCancel,
  ClaudeSetupStart: GuestClaudeSetupStart,
  ClaudeSetupCode: GuestClaudeSetupCode,
}

@doc("The setup's `claude setup-token` or `codex login --device-auth` printed the URL where the person signs in, and Codex the one-time code to enter there.")
model GuestClaudeSetupUrl {
  type: "ClaudeSetupUrl";
  claudeSetupId: EntityId;
  signInUrl: HttpUrl;
  userCode?: ClaudeSetupUserCode;
}

@doc("Why a guest Claude setup ended without storing the token.")
enum GuestClaudeSetupFailureReason {
  @doc("Claude Code exited before it printed a sign-in URL.")
  UrlNotPrinted: "UrlNotPrinted",

  @doc("Claude Code printed an OAuth error for the code.")
  CodeRejected: "CodeRejected",

  @doc("Claude Code exited after the code without printing a token, or Codex exited without signing in.")
  ClaudeCodeExited: "ClaudeCodeExited",

  @doc("Claude Code printed a token and the control plane did not store it.")
  TokenNotStored: "TokenNotStored",

  @doc("Claude Code printed no token within the code's mintBudgetSeconds; the detail quotes the last lines it printed after the code, with every token- or code-shaped run hidden.")
  MintTimedOut: "MintTimedOut",
}

@doc("The control plane stored the setup's token.")
model GuestClaudeSetupStored {
  type: "ClaudeSetupStored";
  claudeSetupId: EntityId;
}

@doc("The setup ended without storing the token. `detail` states what failed and never holds the token or the code.")
model GuestClaudeSetupFailed {
  type: "ClaudeSetupFailed";
  claudeSetupId: EntityId;
  reason: GuestClaudeSetupFailureReason;
  detail: Detail;
}

@doc("One frame from the guest to the host.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "type" })
union GuestMessage {
  GuestHello: GuestHello,
  TurnRepositoryReady: GuestTurnRepositoryReady,
  TurnLine: GuestTurnLine,
  TurnRepositoryCloneFailed: GuestTurnRepositoryCloneFailed,
  TurnEnd: GuestTurnEnd,
  ClaudeSetupUrl: GuestClaudeSetupUrl,
  ClaudeSetupStored: GuestClaudeSetupStored,
  ClaudeSetupFailed: GuestClaudeSetupFailed,
}

@doc("""
  The fields every entry of a SnapshotManifest carries: `path` relative to the overlay upper
  directory, the permission bits in `mode`, the owner and the modification time in seconds and
  nanoseconds.
  """)
model SnapshotEntryCommon {
  @minLength(1) path: PathText;
  @minValue(0) @maxValue(4095) mode: int32;
  @minValue(0) uid: int64;
  @minValue(0) gid: int64;
  mtimeSeconds: int64;
  @minValue(0) @maxValue(999999999) mtimeNanos: int32;
}

@doc("A regular file: its bytes are its chunks in `chunks` order, `sizeBytes` in all, each at the placement it names.")
model SnapshotFileEntry {
  kind: "File";
  ...SnapshotEntryCommon;
  @minValue(0) sizeBytes: int64;
  @maxItems(1000000) chunks: Channel.ChunkPlacement[];
}

@doc("A directory that merges with the directory of the same path in the image.")
model SnapshotDirectoryEntry {
  kind: "Directory";
  ...SnapshotEntryCommon;
}

@doc("A directory that replaces the image's directory of the same path, marked trusted.overlay.opaque.")
model SnapshotOpaqueDirectoryEntry {
  kind: "OpaqueDirectory";
  ...SnapshotEntryCommon;
}

@doc("A symbolic link to `target`.")
model SnapshotSymlinkEntry {
  kind: "Symlink";
  ...SnapshotEntryCommon;
  @minLength(1) target: PathText;
}

@doc("A file or directory of the image that the box deleted, an overlay whiteout: a character device 0/0.")
model SnapshotWhiteoutEntry {
  kind: "Whiteout";
  ...SnapshotEntryCommon;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SnapshotEntry {
  File: SnapshotFileEntry,
  Directory: SnapshotDirectoryEntry,
  OpaqueDirectory: SnapshotOpaqueDirectoryEntry,
  Symlink: SnapshotSymlinkEntry,
  Whiteout: SnapshotWhiteoutEntry,
}

@doc("""
  Every entry of the box's overlay upper directory, in byte order of `path`. The contents of each
  file are chunks cut by content-defined chunking (FastCDC, 16 KiB minimum, 64 KiB average, 256 KiB
  maximum) and stored in packs under `<tenantId>/packs/<packDigest>`, so a chunk any snapshot of
  the tenant holds already is not uploaded again. The encoded manifest is cut by the same chunker
  and its chunks packed with the file chunks; SnapshotRoot names them.
  """)
model SnapshotManifest {
  @maxItems(1000000) entries: SnapshotEntry[];
}

@doc("""
  A snapshot as stored under its storage key: the chunks of its encoded SnapshotManifest in order,
  each at its placement. A snapshot uploads only the manifest chunks that changed. A restore reads
  the latest root only, reassembles the manifest and then each file from its chunks, and hands the
  box the whole upper directory.
  """)
model SnapshotRoot {
  @maxItems(1000000) manifest: Channel.ChunkPlacement[];
}
