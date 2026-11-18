import "@typespec/openapi";
import "@typespec/http";

using TypeSpec.Http;

namespace Tumpel;

@minLength(1)
@maxLength(64)
scalar EntityId extends string;

@minLength(1)
@maxLength(100)
scalar DisplayName extends string;

@minLength(3)
@maxLength(320)
scalar EmailAddress extends string;

@minLength(1)
@maxLength(200)
scalar ModelName extends string;

@minLength(1)
@maxLength(500)
scalar RepositoryUrl extends string;

@minLength(1)
@maxLength(1000)
scalar StorageKey extends string;

@minLength(1)
@maxLength(100000)
scalar Prompt extends string;

@doc("A condition the harness keeps working toward until it holds.")
@minLength(1)
@maxLength(100000)
scalar Goal extends string;

@minValue(0)
scalar Sequence extends int64;

@doc("The name of a secret set member, which is also the environment variable a box gets its value in.")
@pattern("^[A-Z_][A-Z0-9_]*$")
@maxLength(100)
scalar SecretName extends string;

@minLength(1)
scalar HarnessVersion extends string;

@doc("A lower-case hex SHA-256 digest: the name of a file in the image cache, or of a persona file blob.")
@pattern("^[0-9a-f]{64}$")
scalar Sha256Digest extends string;

@doc("""
  A host channel protocol version, from Oldest, the oldest version whose wire lock and data types
  the repository still keeps, to Version, the one in Hello and Welcome; the control plane closes a
  connection that speaks another with UnsupportedVersion.
  """)
@minValue(ChannelProtocolOldest)
@maxValue(ChannelProtocolVersion)
@TypeSpec.OpenAPI.extension("x-bound-names", #["Oldest", "Version"])
scalar ChannelProtocol extends int32;

const ChannelProtocolOldest = 18;
const ChannelProtocolVersion = 22;

@doc("""
  The most chunks one SnapshotChunks, SnapshotPacks or RestoreChunks part names, and so the most
  placements or packs one answer carries.
  """)
enum ChunkExchange {
  DigestsPerPart: 500,
}

const DigestsPerPart = 500;

@doc("""
  A guest protocol version, from Oldest, the oldest version the supervisor still speaks, to Version,
  the one this build's guest names in GuestHello; the supervisor fails a box whose guest speaks a
  version outside it.
  """)
@minValue(GuestProtocolOldest)
@maxValue(GuestProtocolVersion)
@TypeSpec.OpenAPI.extension("x-bound-names", #["Oldest", "Version"])
scalar GuestProtocol extends int32;

const GuestProtocolOldest = 9;
const GuestProtocolVersion = 11;

@doc("""
  The contract between the base image's stub init and the guest drive's init: the base writes it to
  /etc/tumpel/base-layout and the guest drive holds it as base-layout. The guest drive's init fails
  base-layout when they differ.
  """)
enum BaseLayout {
  Version: 1,
}

@doc("""
  The byte caps on a persona's files. A file of at most InlineFileBytes travels in the request body;
  a larger one is uploaded through a presigned URL and then named by digest. A persona's files
  together hold at most PersonaBytes.
  """)
enum PersonaFileLimit {
  InlineFileBytes: 65536,
  PersonaBytes: 262144,
}

@doc("""
  The memory of a box in MiB. A persona that names no boxMemoryMib runs its boxes with DefaultMib;
  one that names it may ask for up to MaxMib.
  """)
enum BoxMemoryLimit {
  DefaultMib: 4096,
  MaxMib: 65536,
}

@doc("A path relative to the harness home in the box, such as .claude/settings.json. The harness catalog lists the paths each harness accepts.")
@pattern("^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$")
@maxLength(200)
scalar PersonaFilePath extends string;

@doc("The size of a persona file in bytes, at most PersonaFileLimit.PersonaBytes.")
@minValue(0)
@maxValue(262144)
scalar PersonaFileSize extends int64;

@doc("A persona file's bytes, base64: at most PersonaFileLimit.InlineFileBytes before encoding.")
@maxLength(87384)
scalar PersonaFileContent extends string;

@doc("A label a host carries for placement, such as gpu or region-eu.")
@pattern("^[a-z0-9][a-z0-9._=-]{0,62}$")
scalar HostLabel extends string;

enum HealthStatus {
  Ok: "Ok",
}

enum PrincipalRole {
  Owner: "Owner",
  Member: "Member",
}

enum HostState {
  Enrolled: "Enrolled",
  Online: "Online",
  Offline: "Offline",
  Revoked: "Revoked",
}

@doc("""
  The phase a supervisor update entered. Fetching downloads and verifies the candidate binary,
  DryRunning runs it with `check` beside the running binary and keeps it once it passes, Staged
  is what supervisors before the box handover send while a candidate waits for the host to run no
  box, Restarting swaps the binaries, parks every running turn and execs the new one, which takes
  over the running boxes, and Online is the new binary reaching Welcome. WaitingForIdle is what supervisors before the idle claim send between DryRunning and
  Restarting; the control plane accepts it and records nothing.
  """)
enum SupervisorUpdatePhase {
  Fetching: "Fetching",
  DryRunning: "DryRunning",
  Staged: "Staged",
  WaitingForIdle: "WaitingForIdle",
  Restarting: "Restarting",
  Online: "Online",
}

@doc("Why a supervisor update stopped. Every one but SupervisorUpdateRolledBack leaves the running binary in place.")
enum SupervisorUpdateFailureReason {
  @doc("Reading the current release or downloading the binary failed or ran past its limit.")
  SupervisorUpdateFetchFailed: "SupervisorUpdateFetchFailed",

  @doc("The downloaded binary does not hash to the sha256 the release names.")
  SupervisorUpdateChecksumMismatch: "SupervisorUpdateChecksumMismatch",

  @doc("The candidate's `check` exited non-zero, ran past its limit, or reported another channel protocol than the release.")
  SupervisorUpdateDryRunFailed: "SupervisorUpdateDryRunFailed",

  @doc("update-refusal.json in the supervisor directory does not match SupervisorUpdateRefusal; the host skips every update until it is deleted.")
  SupervisorUpdateStateUnreadable: "SupervisorUpdateStateUnreadable",

  @doc("Sent only by supervisors before the idle claim: the host ran a box for the whole wait, and the update starts over on the next trigger.")
  SupervisorUpdateIdleTimedOut: "SupervisorUpdateIdleTimedOut",

  @doc("Keeping the running binary as the previous one, or moving the candidate into place, failed.")
  SupervisorUpdateSwapFailed: "SupervisorUpdateSwapFailed",

  @doc("The new binary failed to start or did not reach Welcome in time, and systemd runs the previous binary again.")
  SupervisorUpdateRolledBack: "SupervisorUpdateRolledBack",
}

@doc("""
  A phase a host's supervisor update entered: from the binary `fromSha256` to `toSha256` of the
  release `releaseVersion`, at `at`. `boxesRunning` counts the boxes the host ran as it entered
  the phase; on Staged, the boxes the swap waits on, and on Restarting, the boxes handed over.
  """)
model SupervisorUpdateStepReport {
  fromSha256: Sha256Digest;
  toSha256: Sha256Digest;
  @minLength(1) releaseVersion: string;
  @minValue(0) boxesRunning: int32;
  phase: SupervisorUpdatePhase;
  at: offsetDateTime;
}

@doc("""
  A host's supervisor update that stopped. `detail` states what failed and what fixes it.
  `outputTail` holds the last lines the candidate printed in its dry run, token-shaped runs
  hidden, and is empty for every other reason.
  """)
model SupervisorUpdateFailureReport {
  fromSha256: Sha256Digest;
  toSha256: Sha256Digest;
  reason: SupervisorUpdateFailureReason;
  detail: string;
  @maxItems(20) outputTail: string[];
  failedAt: offsetDateTime;
}

@doc("The host has reported no supervisor update step, or no failure, since it enrolled.")
model SupervisorUpdateNotReported {
  state: "NotReported";
}

@doc("The latest supervisor update phase the host reported.")
model SupervisorUpdateStepReported {
  state: "Reported";
  step: SupervisorUpdateStepReport;
}

@doc("The latest supervisor update failure the host reported.")
model SupervisorUpdateFailureReported {
  state: "Reported";
  failure: SupervisorUpdateFailureReport;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union SupervisorUpdateLatestStep {
  NotReported: SupervisorUpdateNotReported,
  Reported: SupervisorUpdateStepReported,
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union SupervisorUpdateLatestFailure {
  NotReported: SupervisorUpdateNotReported,
  Reported: SupervisorUpdateFailureReported,
}

enum HostArchitecture {
  Amd64: "Amd64",
  Arm64: "Arm64",
}

@doc("""
  What a host holds at one moment, sent on Hello and on every host Heartbeat. `boxesWarm` counts
  the paused boxes in their warm window, `loadAverage` is the one-minute load average of the host,
  and `memoryAvailableMib` is MemAvailable of /proc/meminfo in MiB.
  """)
model HostUsage {
  @minValue(0) boxesWarm: int32;
  @minValue(0) loadAverage: float64;
  @minValue(0) memoryAvailableMib: int64;
}

@doc("""
  A host's box slots and its last reported usage, kept by its tenant from the host's Hello and
  Heartbeats. `boxCapacity` comes from Hello. `boxesRunning` counts the tenant's Offered and
  Running turns on the host. A slot that neither a running nor a warm box holds is free.
  `channelProtocol` is the protocol version the host's latest Hello negotiated; the control plane
  closes the connection with UnsupportedVersion instead of sending a frame of a newer version,
  and resends it once the host reconnects on a version that speaks it. A host that has not connected since it enrolled has none.
  """)
model ReportedHostUsage {
  @key @visibility(Lifecycle.Read) hostId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @minValue(1) @maxValue(256) boxCapacity: int32;
  @minValue(0) boxesRunning: int32;
  ...HostUsage;
  @visibility(Lifecycle.Read) channelProtocol: ChannelProtocol;
  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

enum EnrolmentTokenState {
  Unused: "Unused",
  Spent: "Spent",
}

enum SessionState {
  @doc("A turn of the session is offered to its host and not claimed yet.")
  Starting: "Starting",

  @doc("No turn of the session is in flight.")
  Idle: "Idle",

  @doc("The host claimed a turn of the session and its harness runs it.")
  Running: "Running",

  @doc("A stop asked the host to snapshot the session and tear its box down; a send waits until the box is gone.")
  Stopping: "Stopping",

  @doc("The session has no box; its next turn boots a fresh box from its snapshots.")
  Stopped: "Stopped",

  @doc("The session's snapshots are deleted and its transcript stays readable; it takes no more turns.")
  Archived: "Archived",

  @doc("The box could not clone the session's repository, and the failure of its last turn says why. The session takes no more turns; archive it and start a new session.")
  Failed: "Failed",
}

enum TurnState {
  Offered: "Offered",
  Running: "Running",
  Completed: "Completed",
  Failed: "Failed",
}

@doc("Why a turn ended Failed. Each reason names the phase the turn stopped in.")
enum TurnFailureReason {
  @doc("The host reports the control plane did not answer its TurnClaim in time and the harness never started; the control plane offers the turn again, so no turn fails NotClaimed.")
  NotClaimed: "NotClaimed",

  @doc("The dead letter: no host claimed the turn within turnTotalBudgetSeconds of its offer, so it never ran. The detail names the host and whether it is online.")
  Undelivered: "Undelivered",

  NoFirstOutput: "NoFirstOutput",
  HostOffline: "HostOffline",
  CredentialRefused: "CredentialRefused",

  @doc("The dispatch credential of the offer expired before the turn reached a box.")
  DispatchCredentialExpired: "DispatchCredentialExpired",

  @doc("The session's subscription token expired before the turn was offered.")
  CredentialExpired: "CredentialExpired",

  BoxBootFailed: "BoxBootFailed",

  @doc("Every box slot of the host is claimed and no paused box has its last turn in a snapshot, so none can be evicted.")
  PoolExhausted: "PoolExhausted",

  SnapshotUnreadable: "SnapshotUnreadable",
  HarnessExited: "HarnessExited",

  @doc("The box ran out of memory and the kernel killed the harness; the detail names the box memory and the process the kernel picked, so the persona can run lighter builds or ask for more boxMemoryMib.")
  HarnessOutOfMemory: "HarnessOutOfMemory",

  @doc("The harness exited without printing a successful result, so the turn did not finish its work; the detail carries the tail of the harness's standard error.")
  HarnessExitedWithoutResult: "HarnessExitedWithoutResult",

  TurnTimedOut: "TurnTimedOut",

  @doc("A line or the turn's completion skipped a lineSeq the control plane never received.")
  TranscriptGap: "TranscriptGap",

  @doc("A persona file could not be fetched from the store or did not match its digest.")
  PersonaFileUnreadable: "PersonaFileUnreadable",

  @doc("The box could not clone the session's repository within the image's cloneSeconds; the detail carries what git reported and the persona's secret set.")
  RepositoryCloneFailed: "RepositoryCloneFailed",

  @doc("The harness ended the turn with an error result other than a refused credential, such as a model the provider does not serve; the detail carries what the harness reported.")
  HarnessReportedError: "HarnessReportedError",

  @doc("The turn has no GitHub credential to clone, commit and push with when it is offered: GitHub did not mint an installation token for the session's repository, the secret set holds no GITHUB_TOKEN to take its place, or the GitHub user to commit as is unknown; the detail quotes GitHub where it answered and names the fix.")
  RepositoryTokenRefused: "RepositoryTokenRefused",

  @doc("The current release carries no guest image of the session's harness version for the architecture of the host the turn was offered to; the detail names both.")
  ImageNotReleased: "ImageNotReleased",

  @doc("The host's image cache lacks the offer's imageDigest and fetching it failed: a download failed, a file missed its digest, the manifest named another image or the host could not move the files into its image cache; the detail names the digest, what failed and the fix.")
  ImageFetchFailed: "ImageFetchFailed",

  @doc("The host did not fetch the offer's guest image within its fetch budget, the offer's image.fetchSeconds, or did not claim the turn within the claim budget after it; the detail names the digest.")
  ImageFetchTimedOut: "ImageFetchTimedOut",

  @doc("The host was handing its boxes to a new supervisor binary when the offer arrived, so it took no turn; the control plane offers the turn to another host at once, or keeps it Offered and offers it again once the host is back, so no turn fails HostUpdating.")
  HostUpdating: "HostUpdating",

  @doc("The host's first Heartbeat after it reconnected named no box for the turn's session, for example after its supervisor restarted, so the turn's work since its last snapshot is gone; the detail names the host.")
  BoxLost: "BoxLost",
}

@doc("Why the box could not clone the session's repository.")
enum RepositoryCloneFailureCause {
  @doc("The repository host asked for credentials and did not accept the ones the box had, if any.")
  Refused: "Refused",

  @doc("The clone ran past the image's cloneSeconds and git was stopped.")
  TimedOut: "TimedOut",

  @doc("The harness working directory holds files but no repository.")
  DirectoryNotEmpty: "DirectoryNotEmpty",

  Other: "Other",
}

enum Harness {
  ClaudeCode: "ClaudeCode",
  Codex: "Codex",
  OpenCode: "OpenCode",
  PiDev: "PiDev",
  MistralAgent: "MistralAgent",
}

enum ModelProvider {
  Anthropic: "Anthropic",
  OpenAi: "OpenAi",
  Mistral: "Mistral",
  Google: "Google",
  OpenRouter: "OpenRouter",
}

@doc("An account that owns principals, hosts and sessions.")
model Tenant {
  @key @visibility(Lifecycle.Read) tenantId: EntityId;
  name: DisplayName;
  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("""
  A person as a member of one tenant. One principal per email across every tenant it belongs
  to; `tenantId` and `role` are its membership of the tenant it is read in.
  """)
model Principal {
  @key @visibility(Lifecycle.Read) principalId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @visibility(Lifecycle.Read) email: EmailAddress;
  @visibility(Lifecycle.Read) role: PrincipalRole;
  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("A tenant the caller's principal belongs to, the role it holds there and when it joined.")
model Membership {
  tenant: Tenant;
  role: PrincipalRole;
  createdAt: int64;
}

@doc("""
  An open invitation to join the tenant in a role. `principalId` is the owner who invited. It
  stays open until it is accepted, revoked or past `expiresAt`; only the person signed in to the
  identity proxy as `email` accepts it, once.
  """)
model Invitation {
  @key @visibility(Lifecycle.Read) invitationId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @visibility(Lifecycle.Read) principalId: EntityId;
  email: EmailAddress;
  role: PrincipalRole;
  @visibility(Lifecycle.Read) expiresAt: offsetDateTime;
  @visibility(Lifecycle.Read) createdAt: int64;
}

@doc("A CLI or MCP client a principal signed in through the device flow.")
model Device {
  @key @visibility(Lifecycle.Read) deviceId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @visibility(Lifecycle.Read) principalId: EntityId;
  name: DisplayName;
  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) lastUsedAt: int64;
}

@doc("One authorization of an OAuth client that holds a live token for the caller in this tenant.")
model OAuthGrant {
  @doc("The grant the client's tokens belong to; revoking it signs the client out.")
  @key
  grantId: EntityId;

  @doc("The client_id the client registered with, or tumpel-dashboard for the dashboard.")
  clientId: string;

  @doc("The name the client registered with, such as Claude.")
  clientName: string;

  @doc("The origin of the client's registered callback, such as https://claude.ai.")
  redirectOrigin: url;

  @doc("When the client was last issued a token for the caller.")
  lastIssuedAt: int64;
}

@doc("A machine the tenant owns, running the supervisor and enrolled to exactly one tenant.")
model Host {
  @key @visibility(Lifecycle.Read) hostId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  name: DisplayName;
  @visibility(Lifecycle.Read) state: HostState;
  architecture: HostArchitecture;
  @minValue(1) cpuCount: int32;
  @minValue(1) memoryBytes: int64;

  @doc("The host's Ed25519 public key, base64. The private key never leaves the host.")
  @minLength(1)
  publicKey: string;

  @minLength(1) supervisorVersion: string;
  @visibility(Lifecycle.Read) labels: HostLabel[];

  @doc("The latest supervisor update phase the host reported, kept by its tenant.")
  @visibility(Lifecycle.Read)
  supervisorUpdateStep: SupervisorUpdateLatestStep;

  @doc("The latest supervisor update failure the host reported, kept by its tenant.")
  @visibility(Lifecycle.Read)
  supervisorUpdateFailure: SupervisorUpdateLatestFailure;

  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("A one-time, tenant-scoped token that enrols one host before it expires.")
model EnrolmentToken {
  @key @visibility(Lifecycle.Read) enrolmentTokenId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @visibility(Lifecycle.Read) principalId: EntityId;
  @visibility(Lifecycle.Read) state: EnrolmentTokenState;
  @visibility(Lifecycle.Read) expiresAt: offsetDateTime;
  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("A repository-scoped conversation with one harness and model. It outlives the boxes that run it. Its harness is its persona's, at the version the tenant pins.")
model Session {
  @key @visibility(Lifecycle.Read) sessionId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @visibility(Lifecycle.Read) principalId: EntityId;
  @visibility(Lifecycle.Read) hostId: EntityId;
  @visibility(Lifecycle.Read) boxId: EntityId;
  personaId: EntityId;

  @doc("A GitHub repository as owner/name, github.com/owner/name or https://github.com/owner/name, with or without .git. A start refuses any other form and stores it as https://github.com/owner/name.")
  repository: RepositoryUrl;

  @doc("What the session's first prompt came from: a prompt sent with Sessions_start, or the issue of Sessions_startFromIssue.")
  @visibility(Lifecycle.Read)
  origin: SessionOrigin;

  @visibility(Lifecycle.Read) harness: Harness;
  @visibility(Lifecycle.Read) harnessVersion: string;
  `model`: ModelName;
  @visibility(Lifecycle.Read) state: SessionState;

  @doc("The session's latest turn. A start offers the first turn together with the session, so every session has one.")
  @visibility(Lifecycle.Read)
  lastTurnId: EntityId;

  @visibility(Lifecycle.Read) lastTurnState: TurnState;

  @doc("When the latest turn last changed state.")
  @visibility(Lifecycle.Read)
  lastTurnAt: offsetDateTime;

  @doc("The session's latest turn, with why it failed once it is Failed.")
  @visibility(Lifecycle.Read)
  lastTurn: Turn;

  @doc("The image the latest turn's box boots. Present once the control plane offered the latest turn.")
  @visibility(Lifecycle.Read)
  lastTurnImage?: TurnImage;

  @doc("""
    The prebuild layer the session's files start from, or why they start without one. The control
    plane records it for each box it boots while the session holds no snapshot of its own; once a
    snapshot exists, every box restores that snapshot and the layer stays. Present once the control
    plane offered the session's first turn.
    """)
  @visibility(Lifecycle.Read)
  prebuildLayer?: SessionPrebuildLayer;

  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("The GitHub issue of the session's repository that the session was started from, and the branch its first prompt asks for.")
model SessionIssue {
  @key sessionId: EntityId;
  issueNumber: GitHubIssueNumber;
  title: string;
  htmlUrl: url;
  branch: string;
}

@doc("The session started with a prompt sent with Sessions_start.")
model SessionPromptOrigin {
  kind: "Prompt";
}

@doc("The session started from a GitHub issue with Sessions_startFromIssue, with the branch its first prompt asks for.")
model SessionIssueOrigin {
  kind: "Issue";
  ...OmitProperties<SessionIssue, "sessionId">;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SessionOrigin {
  Prompt: SessionPromptOrigin,
  Issue: SessionIssueOrigin,
}

@doc("Why a stop returned its session to Idle with its box kept.")
enum StopFailureReason {
  @doc("The host kept the box: it holds a completed turn no snapshot holds yet.")
  BoxDirty: "BoxDirty",

  @doc("The control plane's own: the host did not answer the teardown within snapshotDeadlineSeconds.")
  NotAnswered: "NotAnswered",
}

@doc("A stop that failed and returned its session to Idle with its box kept.")
model StopFailure {
  @key stopFailureId: EntityId;
  tenantId: EntityId;
  sessionId: EntityId;
  reason: StopFailureReason;

  @doc("What failed and what fixes it.")
  detail: string;

  failedAt: offsetDateTime;
  createdAt: int64;
}

@doc("The fields every turn carries, whatever its state.")
model TurnBase {
  @key @visibility(Lifecycle.Read) turnId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @visibility(Lifecycle.Read) sessionId: EntityId;

  @doc("The control plane mints the id of the box that runs the turn.")
  @visibility(Lifecycle.Read)
  boxId: EntityId;

  prompt: Prompt;

  @doc("A condition the harness keeps working toward until it holds; only a session whose harness has goals in the harness catalog accepts it.")
  goal?: Goal;

  @doc("How many transcript lines this turn has written so far, counting its own lines alone. A line's `lineSeq` numbers the session's lines instead, so the turn's last line is the `lineSeq` the session held before the turn plus `lineCount`.")
  @visibility(Lifecycle.Read)
  lineCount: Sequence;

  @doc("The image the turn's box boots, recorded when the control plane offers the turn. A turn not yet offered has none.")
  @visibility(Lifecycle.Read)
  image?: TurnImage;

  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

model OfferedTurn {
  ...TurnBase;
  state: TurnState.Offered;
}

model RunningTurn {
  ...TurnBase;
  state: TurnState.Running;
}

model CompletedTurn {
  ...TurnBase;
  state: TurnState.Completed;
}

@doc("A turn that ended Failed, with why.")
model FailedTurn {
  ...TurnBase;
  state: TurnState.Failed;
  reason: TurnFailureReason;

  @doc("What failed and what fixes it, with the tail of the harness's standard error when there is one.")
  detail: string;

  failedAt: offsetDateTime;
}

@doc("One prompt and the harness's completion of it, run on a session's box.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union Turn {
  Offered: OfferedTurn,
  Running: RunningTurn,
  Completed: CompletedTurn,
  Failed: FailedTurn,
}

@doc("Why a turn ended Failed. Exists only for a turn in state Failed.")
model TurnFailure {
  @key turnId: EntityId;
  tenantId: EntityId;
  sessionId: EntityId;
  reason: TurnFailureReason;

  @doc("What failed and what fixes it, with the tail of the harness's standard error when there is one.")
  detail: string;

  failedAt: offsetDateTime;
  createdAt: int64;
}

@doc("Why a session's files start without a prebuild's layer.")
enum PrebuildLayerAbsence {
  @doc("The session builds a prebuild, so its box starts from the guest image alone.")
  BuildsPrebuild: "BuildsPrebuild",

  @doc("The session's host is not Amd64, and prebuilds build on Amd64 alone.")
  HostNotAmd64: "HostNotAmd64",

  @doc("The current release carries no Amd64 guest image for the session's harness version, the image prebuilds build on.")
  NoAmd64Image: "NoAmd64Image",

  @doc("The repository has no stored prebuild.")
  NoPrebuild: "NoPrebuild",

  @doc("The repository's stored prebuilds are built on another guest image, and a layer fits only the image it was built on.")
  OtherGuestImage: "OtherGuestImage",

  @doc("The session's first box booted before the control plane recorded the layer, so it does not know which layer that box restored.")
  NotRecorded: "NotRecorded",
}

@doc("The session's files start from a stored prebuild's layer.")
model SessionPrebuildLayerStored {
  layer: "Prebuild";
  prebuildId: EntityId;

  @doc("The digest the prebuild's read names for its layer.")
  layerDigest: Sha256Digest;
}

@doc("The session's files start without a prebuild's layer. `detail` states why and what fixes it.")
model SessionPrebuildLayerAbsent {
  layer: "None";
  reason: PrebuildLayerAbsence;
  detail: string;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "layer" })
union SessionPrebuildLayer {
  Prebuild: SessionPrebuildLayerStored,
  None: SessionPrebuildLayerAbsent,
}

@doc("The turn's box boots a full guest image. `guestImageDigest` names the same image as a prebuild's guestImageDigest.")
model TurnFullImage {
  kind: "Full";
  guestImageDigest: Sha256Digest;
}

@doc("The turn's box boots a base image with the harness layer of the session's harness version.")
model TurnLayeredImage {
  kind: "Layered";
  baseImageDigest: Sha256Digest;
  harnessLayerDigest: Sha256Digest;
}

@doc("The image a turn's box boots.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union TurnImage {
  Full: TurnFullImage,
  Layered: TurnLayeredImage,
}

@doc("""
  One harness-native JSONL line of a turn. `lineSeq` numbers the lines of a session from 1 and
  never restarts, so a cursor stays valid across snapshots, cold boots and host moves.
  """)
model TranscriptLine {
  @key sessionId: EntityId;
  @key lineSeq: Sequence;
  tenantId: EntityId;
  turnId: EntityId;
  text: string;
  createdAt: int64;
}

@doc("The host stored the snapshot's root under its storage key. `uploadedBytes` counts the bytes that left the host: the packs the tenant held no object for, plus the root.")
model SnapshotStored {
  state: "Stored";
  @minValue(0) uploadedBytes: int64;
}

@doc("The snapshot was not stored. `detail` states what failed and what fixes it.")
model SnapshotFailure {
  state: "Failed";
  reason: Channel.SnapshotFailureReason;
  detail: string;
  failedAt: offsetDateTime;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union SnapshotOutcome {
  Stored: SnapshotStored,
  Failed: SnapshotFailure,
}

@doc("""
  The overlay upper directory of a box: a SnapshotRoot under `storageKey` naming the chunks of a
  SnapshotManifest that lists every entry, with the contents of its files as chunks in packs stored
  under the tenant and shared by every snapshot and session of the tenant that holds the same bytes.
  Exists once the host answered its request, or the snapshot deadline passed: `outcome` says
  whether the root is stored or why not.
  """)
model Snapshot {
  @key snapshotId: EntityId;
  tenantId: EntityId;
  sessionId: EntityId;
  boxId: EntityId;
  turnId: EntityId;

  @doc("Orders a session's snapshots from 1; each one holds the whole upper directory, and a restore reads the latest.")
  snapshotSeq: Sequence;

  storageKey: StorageKey;
  outcome: SnapshotOutcome;
  createdAt: int64;
  updatedAt: int64;
}

@doc("""
  One offer of a turn's credentials to its box, appended when the control plane sent the turn offer.
  `variableNames` lists the variables handed over; values are never recorded or returned.
  """)
model CredentialHandover {
  @key credentialHandoverId: EntityId;
  tenantId: EntityId;
  sessionId: EntityId;
  turnId: EntityId;
  hostId: EntityId;
  boxId: EntityId;
  variableNames: string[];

  @doc("Where the GITHUB_TOKEN this offer carried came from.")
  repositoryCredentialSource: RepositoryCredentialSource;

  createdAt: int64;
}

@doc("A harness version the control plane can install in a box.")
model HarnessCatalogEntry {
  @key harness: Harness;
  @key harnessVersion: HarnessVersion;
  @doc("""
    The credentials the harness accepts, in order of preference: a `kind` of credential from a
    `provider` that serves a model API the harness speaks. A turn gets the first one the secret set
    holds under `variable`, beside its `fixed` variables; the session's model passes through.
    """)
  @minItems(1)
  credentials: HarnessCredential[];

  credentialChoice: CredentialChoice;

  @doc("The paths, relative to the harness home in the box, this harness reads persona files from. A persona file at any other path is refused.")
  personaFilePaths: PersonaFilePath[];

  @doc("How the guest image installs this version.")
  installRecipe: InstallRecipe;

  @doc("Whether a transcript read with compact accepts a session on this harness.")
  compactTranscript: boolean;

  @doc("Whether a turn send with a goal accepts a session on this harness.")
  goals: boolean;
}

@doc("How the guest image installs a harness version.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union InstallRecipe {
  Npm: NpmInstallRecipe,
  Archive: ArchiveInstallRecipe,
}

@doc("The single native npm package the harness ships as; the build installs `<package>-linux-<arch>` at `packageVersion`.")
model NpmInstallRecipe {
  kind: "Npm";
  @minLength(1) package: string;
  @minLength(1) packageVersion: string;
}

@doc("The pinned release tarball the harness ships as, one per architecture; the build refuses an archive whose sha256 differs.")
model ArchiveInstallRecipe {
  kind: "Archive";
  @minItems(1) archives: InstallArchive[];

  @doc("How many leading path components tar strips when it unpacks an archive.")
  @minValue(0)
  stripComponents: int32;
}

@doc("The release tarball of a harness version for one architecture.")
model InstallArchive {
  architecture: HostArchitecture;
  @minLength(1) url: string;
  sha256: Sha256Digest;

  @doc("""
    The path of the harness binary in the unpacked archive, after stripComponents, such as
    codex-x86_64-unknown-linux-musl; the build moves it to the binary name the guest runs.
    """)
  @minLength(1)
  binaryPath: string;

  @doc("""
    The paths of the other executables in the unpacked archive that the harness spawns from beside
    its binary, such as codex-code-mode-host; the build moves each next to the binary under its file name.
    """)
  siblingBinaryPaths: string[];
}

@doc("How a turn picks one of the credentials a harness accepts.")
enum CredentialChoice {
  @doc("The first accepted credential the secret set holds.")
  CatalogOrder: "CatalogOrder",

  @doc("The first accepted credential of the provider the session's model names: Anthropic for a model starting `anthropic/`, OpenAi for `openai/`, OpenRouter for any other.")
  ModelProvider: "ModelProvider",
}

@doc("The kinds of provider credential a secret set can hold.")
enum CredentialKind {
  ApiKey: "ApiKey",
  SubscriptionToken: "SubscriptionToken",

  @doc("A harness's whole login file, such as the auth.json Codex writes on sign-in; the guest writes it under the harness home at the credential's path instead of setting a variable.")
  CredentialFile: "CredentialFile",
}

@doc("""
  Whether a turn on a credential reports what it cost and whether that cost is billed. A turn records
  its tokens as turn.tokens and, unless NotReported, its cost as turn.cost in micro-US-dollars, both
  with the basis as their costBasis dimension.
  """)
enum CostBasis {
  @doc("The harness reports the cost the provider bills the credential for.")
  Billed: "Billed",

  @doc("The credential is a subscription: the harness reports what the turn would cost on the provider's API, and nothing is billed per turn.")
  NotBilled: "NotBilled",

  @doc("The harness reports tokens only, or a cost that is not what the provider charges, so the turn records no cost.")
  NotReported: "NotReported",
}

@doc("The kind of tokens a turn.tokens point counts, as its tokenKind dimension.")
enum TokenKind {
  Input: "Input",
  Output: "Output",
  CacheRead: "CacheRead",
  CacheWrite: "CacheWrite",
}

@doc("""
  A credential a harness accepts, and what a turn gets from it: the credential under `variable`,
  the `fixed` variables beside it, and the `arguments` the guest adds to the harness command, such
  as the Codex model provider that reads `variable`. The arguments hold no secret.
  """)
model HarnessCredential {
  provider: ModelProvider;
  kind: CredentialKind;
  variable: SecretName;
  fixed: FixedVariable[];
  arguments: string[];
  costBasis: CostBasis;

  @doc("For a CredentialFile, the file under the harness home the guest writes it to, mode 0600, in place of the variable; the harness may rewrite it, and a changed file is stored back in the secret set at the end of the turn.")
  path?: PersonaFilePath;
}

@doc("A variable a turn gets with a fixed value beside a credential, such as the base URL of the provider serving the harness's model API.")
model FixedVariable {
  name: SecretName;
  @minLength(1) value: string;
}

@doc("The harness version a tenant runs for one harness. It names an entry of the harness catalog.")
model HarnessPin {
  @key harness: Harness;
  harnessVersion: HarnessVersion;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("The version new sessions of one harness of the catalog run: the tenant's pin, or the catalog's default version when the tenant has not pinned the harness.")
model EffectiveHarnessVersion {
  @key harness: Harness;
  harnessVersion: HarnessVersion;
  pinned: boolean;
}

@doc("A persona's harness, its config files and the secret set its sessions run on.")
model Persona {
  @key @visibility(Lifecycle.Read) personaId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  name: DisplayName;

  @doc("The harness every session of the persona runs, at the version the tenant pins. It is fixed when the persona is created.")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  harness: Harness;

  @doc("The secret set every session of the persona runs on; its members are all a turn's box receives.")
  secretSetId: EntityId;

  @doc("""
    The memory in MiB of each box the persona's sessions boot, from BoxMemoryLimit.DefaultMib up to
    BoxMemoryLimit.MaxMib; left out, the boxes get BoxMemoryLimit.DefaultMib. A session is placed only on a host
    whose available memory holds it, and a box already running keeps the memory it booted with.
    """)
  @minValue(4096)
  @maxValue(65536)
  boxMemoryMib?: int32;

  @doc("The harness's own config files, written under the harness home in the box before the harness starts.")
  @visibility(Lifecycle.Read)
  files: PersonaFile[];

  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

enum PersonaFileSource {
  @doc("The file's bytes travel in the request, base64, up to PersonaFileLimit.InlineFileBytes.")
  Inline: "Inline",

  @doc("The file names bytes the store already holds by digest: uploaded through a presigned URL, or kept from an earlier write.")
  Stored: "Stored",
}

model InlinePersonaFile {
  source: PersonaFileSource.Inline;
  path: PersonaFilePath;
  content: PersonaFileContent;
}

model StoredPersonaFile {
  source: PersonaFileSource.Stored;
  path: PersonaFilePath;
  digest: Sha256Digest;
  sizeBytes: PersonaFileSize;
}

@doc("One file of a persona write: inline bytes, or bytes the store holds under their digest.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "source" })
union PersonaFileWrite {
  Inline: InlinePersonaFile,
  Stored: StoredPersonaFile,
}

@doc("A persona file of at most PersonaFileLimit.InlineFileBytes as a read returns it: the Inline write with the digest and size of its bytes.")
model InlinePersonaFileRead {
  ...InlinePersonaFile;
  digest: Sha256Digest;
  sizeBytes: PersonaFileSize;
  createdAt: int64;
  updatedAt: int64;
}

@doc("A persona file larger than PersonaFileLimit.InlineFileBytes as a read returns it: the Stored write with a presigned GET of its bytes, valid until `downloadExpiresAt`.")
model StoredPersonaFileRead {
  ...StoredPersonaFile;
  downloadUrl: url;
  downloadExpiresAt: offsetDateTime;
  createdAt: int64;
  updatedAt: int64;
}

@doc("""
  One config file of a persona, at a path relative to the harness home in the box. Its bytes live
  in the store under their sha256 digest; the box receives the path and digest of each file. Each
  variant is the matching PersonaFileWrite with fields the server adds, so a read without them
  is a valid write.
  """)
@discriminated(#{ envelope: "none", discriminatorPropertyName: "source" })
union PersonaFile {
  Inline: InlinePersonaFileRead,
  Stored: StoredPersonaFileRead,
}

@doc("""
  What a secret set member holds. A Variable reaches the box under its own name. An ApiKey or a
  SubscriptionToken is the set's credential for one provider; a session whose harness reads that
  provider gets it under the variable the harness catalog maps its kind to. A CredentialFile is a
  harness's login file, written into the box at the path the harness catalog names.
  """)
enum SecretKind {
  Variable: "Variable",
  ApiKey: "ApiKey",
  SubscriptionToken: "SubscriptionToken",
  CredentialFile: "CredentialFile",
}

model SecretVariableMember {
  kind: SecretKind.Variable;
  name: SecretName;
}

model ApiKeyMember {
  kind: SecretKind.ApiKey;
  name: SecretName;
  provider: ModelProvider;
}

model SubscriptionTokenMember {
  kind: SecretKind.SubscriptionToken;
  name: SecretName;
  provider: ModelProvider;

  @doc("When the token stops working. A turn offered at or after it fails CredentialExpired.")
  expiresAt: offsetDateTime;
}

model CredentialFileMember {
  kind: SecretKind.CredentialFile;
  name: SecretName;
  provider: ModelProvider;

  @doc("When the access token in the file stops working. Shown only: the harness refreshes the file itself, so a turn is not refused for it.")
  expiresAt: offsetDateTime;
}

model SecretVariableKey {
  ...SecretVariableMember;
  updatedAt: int64;
}

model ApiKeyKey {
  ...ApiKeyMember;
  updatedAt: int64;
}

model SubscriptionTokenKey {
  ...SubscriptionTokenMember;
  updatedAt: int64;
}

model CredentialFileKey {
  ...CredentialFileMember;
  updatedAt: int64;
}

@doc("One member of a secret set, without its value. The value never leaves the control plane in a response.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SecretKey {
  Variable: SecretVariableKey,
  ApiKey: ApiKeyKey,
  SubscriptionToken: SubscriptionTokenKey,
  CredentialFile: CredentialFileKey,
}

@minLength(1)
@maxLength(10000)
scalar SecretText extends string;

model SecretVariableValue {
  ...SecretVariableMember;
  value: SecretText;
}

model ApiKeyValue {
  ...ApiKeyMember;
  value: SecretText;
}

model SubscriptionTokenValue {
  ...SubscriptionTokenMember;
  value: SecretText;
}

model CredentialFileValue {
  ...CredentialFileMember;
  value: SecretText;
}

@doc("One member of a secret set with its value, written once and never read back.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SecretValue {
  Variable: SecretVariableValue,
  ApiKey: ApiKeyValue,
  SubscriptionToken: SubscriptionTokenValue,
  CredentialFile: CredentialFileValue,
}

model StoredValueChange {
  @doc("The new value of the member. Left out, the member keeps the value it has stored.")
  value?: SecretText;

  @doc("The name the member had before this update, when the update renames it; its stored value moves with it.")
  previousName?: SecretName;
}

model SecretVariableUpdate {
  ...SecretVariableMember;
  ...StoredValueChange;
}

model ApiKeyUpdate {
  ...ApiKeyMember;
  ...StoredValueChange;
}

model SubscriptionTokenUpdate {
  ...SubscriptionTokenMember;
  ...StoredValueChange;
}

model CredentialFileUpdate {
  ...CredentialFileMember;
  ...StoredValueChange;
}

@doc("One member of a secret set update: a new value, or none to keep the value stored under its name or its previousName.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SecretMemberUpdate {
  Variable: SecretVariableUpdate,
  ApiKey: ApiKeyUpdate,
  SubscriptionToken: SubscriptionTokenUpdate,
  CredentialFile: CredentialFileUpdate,
}

@doc("A named set of secrets: at most one credential per provider, and any number of variables. Values are write-only.")
model SecretSet {
  @key @visibility(Lifecycle.Read) secretSetId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  name: DisplayName;
  @visibility(Lifecycle.Read) keys: SecretKey[];
  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("""
  The control plane's timing and storage settings: the TUMPEL_SETTINGS variable of the Worker, one
  JSON object. Every turn budget and the snapshot deadline run as a timer of the session and end in
  a named failure.
  """)
model ControlPlaneSettings {
  @doc("How long after a TurnOffer is sent the supervisor still hands its dispatch variables to a box, at least; the expiresAt of its DispatchGrant is the longer of this and turnOfferTtlSeconds plus turnImageFetchBudgetSeconds.")
  @minValue(1)
  dispatchGrantTtlSeconds: int32;

  @doc("How long a session stays idle after a completed turn before the control plane asks for a snapshot. A turn sent sooner resets the wait.")
  @minValue(0)
  snapshotDelaySeconds: int32;

  @doc("How long the host may take to answer a SnapshotRequest before the snapshot fails NotAnswered; its presigned upload expires then too.")
  @minValue(1)
  snapshotDeadlineSeconds: int32;

  @doc("How long the credential, restore URLs and image URLs of each send of a TurnOffer stay valid, plus turnImageFetchBudgetSeconds for the image. It bounds no turn: a turn no host claims stays Offered.")
  @minValue(1)
  turnOfferTtlSeconds: int32;

  @doc("How long the host may take to download a guest image its cache lacks, after it sends TurnImageFetching; the offer's image.fetchSeconds. The image URLs stay valid for turnOfferTtlSeconds plus this. A host that runs past it fails the turn ImageFetchTimedOut.")
  @minValue(1)
  turnImageFetchBudgetSeconds: int32;

  @doc("How long a turn may take from TurnRepositoryReady to its first line before it fails NoFirstOutput; it stays at or above firstLineSeconds of the host.")
  @minValue(1)
  turnFirstLineBudgetSeconds: int32;

  @doc("How long a claimed turn may run before it fails TurnTimedOut, and how long an unclaimed turn stays Offered before it fails Undelivered.")
  @minValue(1)
  turnTotalBudgetSeconds: int32;

  @doc("How many lines of a turn go into one transcript chunk object; the last chunk of a turn holds the rest.")
  @minValue(1)
  @maxValue(1000)
  transcriptChunkLines: int32;

  @doc("How long the presigned PUTs a build job gets for its layer stay valid.")
  @minValue(1)
  @maxValue(604800)
  prebuildUploadBudgetSeconds: int32;

  @doc("How long a dispatched prebuild may wait for its run to start before it fails in phase Dispatch; the rootfs URL its dispatch hands the run stays valid for this plus prebuildBuildBudgetSeconds.")
  @minValue(1)
  @maxValue(86400)
  prebuildDispatchBudgetSeconds: int32;

  @doc("How long a prebuild may run from the start of its run to the completion of its layer upload before it fails in phase Build, or in phase Upload once its upload started.")
  @minValue(1)
  @maxValue(86400)
  prebuildBuildBudgetSeconds: int32;

  @doc("How long a Claude setup box may take from its offer to printing the sign-in URL before the setup fails SetupUrlMissing; it covers the guest image fetch, the boot and claude setup-token starting.")
  @minValue(1)
  @maxValue(3600)
  claudeSetupUrlBudgetSeconds: int32;

  @doc("How long a person may take from the sign-in URL to submitting the code before the setup fails SetupTimedOut.")
  @minValue(1)
  @maxValue(3600)
  claudeSetupCodeBudgetSeconds: int32;

  @doc("How long the box may take from the code to storing the minted token before the setup fails SetupTimedOut.")
  @minValue(1)
  @maxValue(3600)
  claudeSetupMintBudgetSeconds: int32;

  @doc("How long past claudeSetupMintBudgetSeconds the control plane waits for the box to report that Claude Code minted no token before it fails the setup SetupTimedOut on its own.")
  @minValue(1)
  @maxValue(60)
  claudeSetupMintGraceSeconds: int32;

  @doc("The heartbeat interval of the channel, 10 in production: the control plane answers a host message with a Heartbeat once it has sent nothing for half of it. It matches heartbeatIntervalSeconds of the hosts' runtime.json.")
  @minValue(1)
  @maxValue(300)
  heartbeatIntervalSeconds: int32;

  @doc("How long a host connection may stay silent before the control plane closes it HeartbeatDeadline and reads the host Offline, 30 in production; a claimed turn whose host stays Offline this long fails HostOffline.")
  @minValue(1)
  @maxValue(900)
  heartbeatDeadlineSeconds: int32;

  @doc("The interval a new device code asks the CLI to poll the token endpoint at, 5 in production; a poll sooner is answered slow_down.")
  @minValue(1)
  @maxValue(60)
  devicePollIntervalSeconds: int32;

  @doc("How much a slow_down answer adds to the polling interval of its device code, 5 in production per RFC 8628.")
  @minValue(1)
  @maxValue(60)
  deviceSlowDownStepSeconds: int32;

  @doc("The OIDC issuer of GitHub Actions job tokens, https://token.actions.githubusercontent.com on github.com; its keys are at <issuer>/.well-known/jwks.")
  gitHubActionsIssuer: url;
}

model Health {
  status: HealthStatus;
}

@doc("A metric name in the OpenTelemetry style: dotted lower-case segments, at most 64 characters.")
@pattern("^[a-z][a-z0-9_]*(\\.[a-z0-9_]+)*$")
@maxLength(64)
scalar MetricName extends string;

enum MetricKind {
  @doc("Each point belongs to a turn and keeps its turn and session for drill-down.")
  Turn: "Turn",

  @doc("Each point samples a host or the control plane and lands in rollups only.")
  Sample: "Sample",
}

@doc("A metric's declaration: its unit as OpenTelemetry writes it (s, MiB, {token}), its kind and what it measures.")
model MetricInstrument {
  metric: MetricName;
  @minLength(1) unit: string;
  kind: MetricKind;
  @minLength(1) description: string;
}

@doc("One value of a Sample metric at a moment, with its dimensions.")
model SamplePoint {
  metric: MetricName;
  at: offsetDateTime;
  value: float64;
  dimensions: Record<string>;
}

@doc("One value of a Turn metric, with the turn and session it belongs to.")
model TurnPoint {
  ...SamplePoint;
  turnId: EntityId;
  sessionId: EntityId;
}

@doc("""
  The points one call writes into a tenant's metrics store, with the instruments that declare their
  metrics. A point whose metric the batch and the store both lack is refused.
  """)
model MetricBatch {
  instruments: MetricInstrument[];
  @maxItems(500) samples: SamplePoint[];
  @maxItems(500) turns: TurnPoint[];
}

enum MetricBucket {
  @doc("Minute buckets, read from minute rollups; they reach back 8 days.")
  Minute: "Minute",

  @doc("Hour buckets, read from hour rollups.")
  Hour: "Hour",

  @doc("Day buckets that start at midnight in the offset of `from`, summed from hour rollups.")
  Day: "Day",
}

@doc("Every metric with series seen in the window, each with its dimensions and their values.")
model MetricCatalog {
  metrics: MetricEntry[];
}

model MetricEntry {
  ...MetricInstrument;
  facets: MetricFacet[];
}

@doc("One dimension of a metric's series in the window and the values it takes.")
model MetricFacet {
  dimension: string;
  values: MetricFacetValue[];
}

model MetricFacetValue {
  value: string;
  seriesCount: int32;
}

@doc("""
  A metric's buckets in the window, one series per group. Past 20 groups the rest fold into one
  group whose values read Other.
  """)
model MetricSeriesSet {
  metric: MetricName;
  unit: string;
  bucket: MetricBucket;
  series: MetricSeries[];
}

@doc("The buckets of one group, keyed by the values of its groupBy dimensions; a bucket with no points is left out.")
model MetricSeries {
  group: Record<string>;
  points: MetricPoint[];
}

@doc("One bucket of a series, in the offset of `from`; percentiles come from merged rollup histograms.")
model MetricPoint {
  bucketStart: offsetDateTime;
  count: int64;
  sum: float64;
  min: float64;
  max: float64;
  p50: float64;
  p90: float64;
  p99: float64;
}

@doc("""
  A page of the turn points behind a metric, oldest first. Pass `cursor` to read on; `finished`
  is true when no point in the window follows it.
  """)
model MetricTurnPage {
  points: MetricTurnPoint[];
  cursor: string;
  finished: boolean;
}

model MetricTurnPoint {
  turnId: EntityId;
  sessionId: EntityId;
  at: offsetDateTime;
  value: float64;
  dimensions: Record<string>;
}
