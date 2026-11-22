import "@typespec/openapi";
import "@typespec/http";
import "./triggers.tsp";
import "./limits.tsp";

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
@maxLength(100)
scalar HarnessVersion extends string;

@doc("A lower-case hex SHA-256 digest: the name of a file in the image cache, or of a persona file blob.")
@pattern("^[0-9a-f]{64}$")
@maxLength(64)
scalar Sha256Digest extends string;

@doc("""
  A host channel protocol version, from Oldest, the oldest version whose wire lock and data types
  the repository still keeps, to Version, the one in Hello and Welcome; the control plane closes a
  connection that speaks another with UnsupportedVersion. Version 34 lacks `heldTurnIds` on Hello
  and Heartbeat and the TurnFailureReason members HostDropped and HostRevoked; version 35 lacks
  HostRevoked. A speaker of 36 downgrades to 34 or 35 by sending that version's shape: it leaves
  out the fields the version lacks and never sends a member it lacks. No host sends HostDropped or
  HostRevoked, since the control plane records both, so the reason needs no mapping on the wire.
  """)
@minValue(ChannelProtocolOldest)
@maxValue(ChannelProtocolVersion)
@TypeSpec.OpenAPI.extension("x-bound-names", #["Oldest", "Version"])
scalar ChannelProtocol extends int32;

const ChannelProtocolOldest = 34;
const ChannelProtocolVersion = 36;

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
const GuestProtocolVersion = 14;

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
  one that names it may ask for MinMib up to MaxMib.
  """)
enum BoxMemoryLimit {
  MinMib: 512,
  DefaultMib: 2048,
  MaxMib: 65536,
}

@doc("""
  The disk of a box in MiB, a sparse drive that costs the host only what the box writes. A persona
  that names no boxDiskMib runs its boxes with DefaultMib; one that names it may ask for up to MaxMib.
  """)
enum BoxDiskLimit {
  DefaultMib: 32768,
  MaxMib: 262144,
}

@doc("What happens to a session's box after each of its turns, whatever the turn's outcome. A snapshot follows every turn in each mode.")
enum BoxRetention {
  @doc("The control plane snapshots the box and tears it down as soon as the turn ends; the session reads Stopped, and its next turn boots a fresh box from the snapshot.")
  Off: "Off",

  @doc("The box stays paused until a person stops or archives the session. Idleness never tears it down and placement never evicts it.")
  Warm: "Warm",

  @doc("The box stays paused until it has been idle for the turn offer's idleSeconds, when the host tears it down and reports BoxGone, or until placement evicts it sooner to free room for another session's turn, when the eviction snapshots the box when needed and tears it down; either way the session reads Stopped.")
  Auto: "Auto",
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

@doc("A persona file the host hands its guest, base64: at most PersonaFileLimit.PersonaBytes before encoding, since a file uploaded by digest may exceed InlineFileBytes.")
@maxLength(349528)
scalar GuestPersonaFileContent extends string;

@doc("A label a host carries for placement, such as gpu or region-eu.")
@pattern("^[a-z0-9][a-z0-9._=-]{0,62}$")
@maxLength(63)
scalar HostLabel extends string;

@doc("A tag that groups sessions, such as crew:docs. A session carries at most 16.")
@pattern("^[a-z0-9][a-z0-9:._-]{0,62}$")
@maxLength(63)
scalar SessionTag extends string;

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

@doc("Whether the control plane offers a host work. It is the control plane's own judgement of the host, kept by its tenant and written once per change.")
enum HostHealth {
  @doc("The host stays within the tenant's limits and gets offers.")
  Healthy: "Healthy",

  @doc("The host sent more channel frames in a minute than the tenant's limits allow. It gets no offers until a full window passes without a limit hit.")
  RateLimited: "RateLimited",

  @doc("The host went RateLimited three times within an hour. It gets no offers until a person restores it or the host reconnects with a new Hello.")
  Unhealthy: "Unhealthy",
}

@doc("Whether the control plane has heard from a host lately, derived when read from the time of the host's latest Hello or Heartbeat. Nothing is written when it changes.")
enum HostPresence {
  @doc("The host sent a Hello or Heartbeat within the last 90 seconds and is not revoked. Only an Online host is placeable.")
  Online: "Online",

  @doc("The host sent a Hello once, but nothing in the last 90 seconds. It gets no offers, and its Offered and Running turns and its Starting, Running, Idle and Stopping sessions read Unknown until it reports again.")
  Degraded: "Degraded",

  @doc("The host never sent a Hello, or it is revoked. It gets no offers.")
  Offline: "Offline",
}

@doc("The health a host reports of itself in its Heartbeat.")
enum HostReportedHealth {
  @doc("The supervisor sends at its normal pace and takes offers.")
  Healthy: "Healthy",

  @doc("The supervisor backs off after a rate refusal and refuses offers until a full window passes without one.")
  RateLimited: "RateLimited",
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
  @minLength(1) releaseVersion: ShortText;
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
  detail: Detail;
  @maxItems(20) outputTail: Detail[];
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

@doc("The guest protocol versions a host accepts from a box, from `guestProtocolOldest` to `guestProtocolVersion`.")
model GuestProtocolRange {
  @minValue(1) guestProtocolOldest: int32;
  @minValue(1) guestProtocolVersion: int32;
}

@doc("The host has not announced this protocol range since it enrolled.")
model HostProtocolNotReported {
  state: "NotReported";
}

@doc("The channel protocol versions the host announced at its latest Hello.")
model HostChannelProtocolReported {
  state: "Reported";
  @minValue(1) channelProtocolOldest: int32;
  @minValue(1) channelProtocolVersion: int32;
}

@doc("The guest protocol versions the host announced at its latest Hello.")
model HostGuestProtocolReported {
  state: "Reported";
  @minValue(1) guestProtocolOldest: int32;
  @minValue(1) guestProtocolVersion: int32;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union HostChannelProtocol {
  NotReported: HostProtocolNotReported,
  Reported: HostChannelProtocolReported,
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union HostGuestProtocol {
  NotReported: HostProtocolNotReported,
  Reported: HostGuestProtocolReported,
}

enum HostArchitecture {
  Amd64: "Amd64",
  Arm64: "Arm64",
}

@doc("""
  What a host holds at one moment, sent on Hello and on every host Heartbeat. `boxesWarm` counts
  the paused boxes it holds, `loadAverage` is the one-minute load average of the host,
  and `memoryAvailableMib` is MemAvailable of /proc/meminfo in MiB. `diskBudgetMib` is the disk the
  host gives box disks: the free disk under its dataDir and what its boxes already wrote, less the
  headroom it keeps free. `diskHeldMib` is the sum of the disk sizes of the boxes it holds. A host
  admits a box only while its disk fits the budget beside the held ones; a supervisor older than
  the box disk budget sends neither. `memoryBudgetMib` is the memory the host gives boxes: MemTotal
  less the headroom it keeps free. `memoryHeldMib` is the sum of the `boxMemoryMib` of the boxes it
  holds. A host admits a box only while its memory fits the budget beside the held ones, whatever
  their count; a supervisor older than the memory budget sends neither.
  """)
model HostUsage {
  @minValue(0) boxesWarm: int32;
  @minValue(0) loadAverage: float64;
  @minValue(0) memoryAvailableMib: int64;
  @minValue(0) diskBudgetMib?: int64;
  @minValue(0) diskHeldMib?: int64;
  @minValue(0) memoryBudgetMib?: int64;
  @minValue(0) memoryHeldMib?: int64;
}

@doc("""
  A host's box slots and its last reported usage, kept by its tenant from the host's Hello and
  Heartbeats. `boxCapacity` comes from Hello. `boxesRunning` counts the tenant's Offered and
  Running turns on the host. Placement counts the boxes a host holds from the tenant's own
  sessions, never from the reported `boxesWarm`, which lags by a Heartbeat.
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
  @visibility(Lifecycle.Read) channelProtocol: int32;
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

  @doc("The host is Degraded; the last stored state is unknown until it reports again. A read-only projection of a Starting, Running, Idle or Stopping session, never stored; heardAt says when the host last reported.")
  Unknown: "Unknown",
}

enum TurnState {
  Offered: "Offered",
  Running: "Running",
  Completed: "Completed",
  Failed: "Failed",

  @doc("The host is Degraded; the last stored state is unknown until it reports again. A read-only projection of an Offered or Running turn, never stored: on the host's next Hello or Heartbeat a turn the host still holds carries on, and one it no longer holds fails HostDropped.")
  Unknown: "Unknown",
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

  @doc("The host has no box slot, memory or disk budget left for the box, and no paused box with its last turn in a snapshot can be evicted to make room; the detail names what ran out, what the host holds and what the box asked for.")
  PoolExhausted: "PoolExhausted",

  @doc("The tenant has hosts but none is healthy: every host missed its heartbeat plus the grace period and counts as Degraded until a heartbeat or reconnect shows otherwise, so the turn was refused.")
  HostDegraded: "HostDegraded",

  SnapshotUnreadable: "SnapshotUnreadable",
  HarnessExited: "HarnessExited",

  @doc("The box ran out of memory and the kernel killed the harness; the detail names the box memory and the process the kernel picked, so the persona can run lighter builds or ask for more boxMemoryMib.")
  HarnessOutOfMemory: "HarnessOutOfMemory",

  @doc("The harness failed while the box's disk was full; the detail names the disk's size, so the persona can ask for more boxDiskMib. A turn the harness completed on a full disk stays Completed and carries a warning instead.")
  BoxDiskFull: "BoxDiskFull",

  @doc("The harness exited without printing a successful result, so the turn did not finish its work; the detail carries the tail of the harness's standard error.")
  HarnessExitedWithoutResult: "HarnessExitedWithoutResult",

  TurnTimedOut: "TurnTimedOut",

  @doc("A line or the turn's completion skipped a lineSeq the control plane never received.")
  TranscriptGap: "TranscriptGap",

  @doc("A persona file could not be fetched from the store or did not match its digest.")
  PersonaFileUnreadable: "PersonaFileUnreadable",

  @doc("The box could not clone the session's repository within the image's cloneSeconds; the detail carries what git reported and the persona's secret set.")
  RepositoryCloneFailed: "RepositoryCloneFailed",

  @doc("The harness ended the turn with an error result other than a refused credential or exhausted credit, such as a model the provider does not serve; the detail carries what the harness reported.")
  HarnessReportedError: "HarnessReportedError",

  @doc("The harness reported that the provider's credit balance is too low. Add credits to the provider account before starting another turn.")
  CreditExhausted: "CreditExhausted",

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

  @doc("The host's Hello or Heartbeat did not name the turn among the turns it holds: a Running turn the host no longer runs, or an offer the host never took by the second Heartbeat after it was sent; the detail names the host. The control plane records it, so no host sends it.")
  HostDropped: "HostDropped",

  @doc("A person revoked the turn's host while the turn was Offered or Running; the detail names the host. The control plane records it, so no host sends it.")
  HostRevoked: "HostRevoked",

  @doc("A person stopped the session with cancelTurn while the turn was in flight or waiting, or cancelled the turn while it waited; the detail names who.")
  Cancelled: "Cancelled",

  @doc("A connector the session lists was disconnected before the turn began running; the detail names it. Reconnect it, or start a session on a persona without it.")
  ConnectorDisconnected: "ConnectorDisconnected",

  @doc("The harness finished the turn, but the snapshot of the box after it was not stored, so the turn holds no durable record of its work and does not complete; the detail names why the snapshot failed. The control plane records it, so no host sends it.")
  SnapshotNotStored: "SnapshotNotStored",

  @doc("The turn's host sent more channel frames in a minute than the tenant's limits allow, so the control plane failed every running turn on that host and dropped its further frames; the detail names the limit. The control plane records it, so no host sends it.")
  RateLimited: "RateLimited",
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

@doc("""
  The limits a tenant runs under. Free keeps the tenant inside the allowances the hosting plan
  includes at no charge and refuses traffic past them; Configured runs under the limits its
  deployment configures.
  """)
enum TenantTier {
  Free: "Free",
  Configured: "Configured",
}

@doc("What a tenant limit counts.")
enum TenantUsageMeasure {
  @doc("Every request the tenant serves: API calls, MCP tool calls and host channel frames.")
  Requests: "Requests",

  @doc("The requests that change the tenant's state.")
  Writes: "Writes",

  @doc("The database rows the tenant's requests write.")
  RowsWritten: "RowsWritten",

  @doc("The database rows the tenant's requests read.")
  RowsRead: "RowsRead",
}

@doc("The fixed window a tenant limit counts over.")
enum TenantUsageWindow {
  Minute: "Minute",
  Hour: "Hour",
  Day: "Day",
}

@doc("""
  One limit of a tenant and how much of it the current window has used. A request past `limit`
  is refused 429 until the window ends at `resetsAt`.
  """)
model TenantUsageCounter {
  measure: TenantUsageMeasure;
  window: TenantUsageWindow;
  used: int64;
  limit: int64;
  resetsAt: offsetDateTime;
}

@doc("The tenant's tier and its usage against each of its limits, as of the current windows.")
model TenantUsage {
  tier: TenantTier;
  @maxItems(32) counters: TenantUsageCounter[];
}

@doc("One usage budget of a tenant: at most `limit` of `measure` in each `window`.")
model TenantLimit {
  measure: TenantUsageMeasure;
  window: TenantUsageWindow;
  @minValue(1) limit: int64;
}

@doc("""
  Every limit one tenant runs under. The tenant Durable Object counts the writing requests and the
  usage budgets, and the host channel counts the frames of each host. A request rate is a usage
  budget of Requests per Minute.
  """)
model TenantLimitsProfile {
  @doc("Requests a minute the tenant may send that change its state.")
  @minValue(1)
  writesPerMinute: int32;

  @doc("Numbered channel frames a minute one host of the tenant may send, counted in memory by its host channel. Past it the control plane fails the host's running turns, snapshots and setups RateLimited, refuses its further frames with FrameRateLimited and offers it nothing until the next window.")
  @minValue(1)
  hostFramesPerMinute: int32;

  @doc("The usage budgets of the tenant.")
  @maxItems(32)
  usage: TenantLimit[];
}

@doc("Where the profile a tenant runs under comes from.")
enum TenantLimitsSource {
  @doc("The Free preset, which keeps the tenant inside the allowances the hosting plan includes at no charge.")
  Free: "Free",

  @doc("The deployment's default profile.")
  Configured: "Configured",

  @doc("A profile set for this tenant.")
  Custom: "Custom",
}

@doc("The limits profile a tenant runs under and where it comes from.")
model TenantLimits {
  source: TenantLimitsSource;
  profile: TenantLimitsProfile;
}

@doc("Drops the profile set for the tenant, so it runs under the preset of the tier it has. It never changes the tier.")
model TenantLimitsReset {
  reset: true;
}

@doc("What a limits change sets: a reset to the preset of the tenant's tier, or a profile of the tenant's own.")
union TenantLimitsSet {
  TenantLimitsReset,
  TenantLimitsProfile,
}

@doc("""
  The per-tenant limits of a deployment: the TUMPEL_LIMITS variable of the Worker, one JSON
  object. The free tier derives its limits from the Cloudflare free plan in the control plane's
  limits module; a configured tenant gets `configured`. The per-minute request rates are the
  limits of the Workers Rate Limiting bindings named beside them and must match them. A tenant
  with a profile of its own runs under it instead; `ceiling` bounds what a profile holds.
  """)
model ControlPlaneLimits {
  @doc("The tier a new tenant gets; an existing tenant keeps the tier it has.")
  defaultTier: TenantTier;

  @doc("How many free tenants share one Cloudflare free plan; each gets this share of every daily allowance.")
  @minValue(1)
  freeTenantsPerAccount: int32;

  @doc("The limits of a configured tenant, checked inside its Durable Object.")
  @maxItems(32)
  configured: TenantLimit[];

  @doc("Requests a minute one tenant may send that only read: binding TENANT_READ_RATE.")
  @minValue(1)
  readsPerMinute: int32;

  @doc("Requests a minute one tenant may send that write: binding TENANT_WRITE_RATE.")
  @minValue(1)
  writesPerMinute: int32;

  @doc("Numbered channel frames a minute one host may send, counted in memory by its host channel, for every tier. Past it the control plane fails the host's running turns, snapshots and setups RateLimited, refuses its further frames with FrameRateLimited and offers it nothing until the next window.")
  @minValue(1)
  hostFramesPerMinute: int32;

  @doc("""
    The most a profile set through the API may hold: each rate at most the ceiling's, and each usage
    budget at most the ceiling's budget of the same measure and window. Its `writesPerMinute` and
    any Requests per Minute budget must not pass `writesPerMinute` and `readsPerMinute`, the limits
    of the Workers Rate Limiting bindings the Worker checks before it knows the tenant.
    """)
  ceiling: TenantLimitsProfile;
}

@doc("An account that owns principals, hosts and sessions.")
model Tenant {
  @key @visibility(Lifecycle.Read) tenantId: EntityId;
  name: DisplayName;

  @doc("The limits the tenant runs under; a new tenant gets its deployment's default tier.")
  @visibility(Lifecycle.Read) tier: TenantTier;

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
  clientId: ShortText;

  @doc("The name the client registered with, such as Claude.")
  clientName: Summary;

  @doc("The origin of the client's registered callback, such as https://claude.ai.")
  redirectOrigin: HttpUrl;

  @doc("When the client was last issued a token for the caller.")
  lastIssuedAt: int64;
}

@doc("The fields every host carries, whatever its presence.")
model HostBase {
  @key @visibility(Lifecycle.Read) hostId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  name: DisplayName;
  @visibility(Lifecycle.Read) state: HostState;

  @doc("The control plane's judgement of the host; it offers work to a Healthy host only.")
  @visibility(Lifecycle.Read)
  health: HostHealth;

  @doc("The health the host reported in its latest Heartbeat, Healthy for a host that reports none.")
  @visibility(Lifecycle.Read)
  reportedHealth: HostReportedHealth;

  architecture: HostArchitecture;
  @minValue(1) cpuCount: int32;
  @minValue(1) memoryBytes: int64;

  @doc("The host's Ed25519 public key, base64. The private key never leaves the host.")
  @minLength(1)
  publicKey: Token;

  @minLength(1) supervisorVersion: ShortText;
  @visibility(Lifecycle.Read) @maxItems(64) labels: HostLabel[];

  @doc("The latest supervisor update phase the host reported, kept by its tenant.")
  @visibility(Lifecycle.Read)
  supervisorUpdateStep: SupervisorUpdateLatestStep;

  @doc("The latest supervisor update failure the host reported, kept by its tenant.")
  @visibility(Lifecycle.Read)
  supervisorUpdateFailure: SupervisorUpdateLatestFailure;

  @doc("The channel protocol range the host announced at its latest Hello.")
  @visibility(Lifecycle.Read)
  channelProtocol: HostChannelProtocol;

  @doc("The guest protocol range the host announced at its latest Hello.")
  @visibility(Lifecycle.Read)
  guestProtocol: HostGuestProtocol;

  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("A host that sent a Hello or Heartbeat within the last 90 seconds and is not revoked.")
model OnlineHost {
  ...HostBase;
  @visibility(Lifecycle.Read) presence: HostPresence.Online;

  @doc("When the host last sent a Hello or Heartbeat.")
  @visibility(Lifecycle.Read)
  heardAt: offsetDateTime;
}

@doc("A host that sent a Hello once, but nothing in the last 90 seconds.")
model DegradedHost {
  ...HostBase;
  @visibility(Lifecycle.Read) presence: HostPresence.Degraded;

  @doc("When the host last sent a Hello or Heartbeat.")
  @visibility(Lifecycle.Read)
  heardAt: offsetDateTime;
}

@doc("A host that never sent a Hello, or is revoked.")
model OfflineHost {
  ...HostBase;
  @visibility(Lifecycle.Read) presence: HostPresence.Offline;
}

@doc("A machine the tenant owns, running the supervisor and enrolled to exactly one tenant, with its presence.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "presence" })
union Host {
  Online: OnlineHost,
  Degraded: DegradedHost,
  Offline: OfflineHost,
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

@doc("The fields every session carries, whatever its state.")
model SessionBase {
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

  @doc("Who started the session: a person, a turn of another session that called Tumpel with a turn token, or a trigger.")
  @visibility(Lifecycle.Read)
  startedBy: SessionStartedBy;

  @doc("The tags the session carries, each once.")
  @visibility(Lifecycle.Read)
  @maxItems(16)
  tags: SessionTag[];

  @visibility(Lifecycle.Read) harness: Harness;
  @visibility(Lifecycle.Read) harnessVersion: ShortText;
  `model`: ModelName;
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

  @doc("What happens to the session's box after each turn, fixed when the session starts.")
  @visibility(Lifecycle.Read)
  boxRetention: BoxRetention;

  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

model StartingSession {
  ...SessionBase;
  @visibility(Lifecycle.Read) state: SessionState.Starting;
}

model IdleSession {
  ...SessionBase;
  @visibility(Lifecycle.Read) state: SessionState.Idle;
}

model RunningSession {
  ...SessionBase;
  @visibility(Lifecycle.Read) state: SessionState.Running;
}

model StoppingSession {
  ...SessionBase;
  @visibility(Lifecycle.Read) state: SessionState.Stopping;
}

model StoppedSession {
  ...SessionBase;
  @visibility(Lifecycle.Read) state: SessionState.Stopped;
}

model ArchivedSession {
  ...SessionBase;
  @visibility(Lifecycle.Read) state: SessionState.Archived;
}

model FailedSession {
  ...SessionBase;
  @visibility(Lifecycle.Read) state: SessionState.Failed;
}

@doc("A Starting, Running, Idle or Stopping session whose host is Degraded, read in place of its stored state until the host reports again.")
model UnknownSession {
  ...SessionBase;
  @visibility(Lifecycle.Read) state: SessionState.Unknown;

  @doc("When the session's host last sent a Hello or Heartbeat.")
  @visibility(Lifecycle.Read)
  heardAt: offsetDateTime;
}

@doc("A repository-scoped conversation with one harness and model. It outlives the boxes that run it. Its harness is its persona's, at the version the tenant pins.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union Session {
  Starting: StartingSession,
  Idle: IdleSession,
  Running: RunningSession,
  Stopping: StoppingSession,
  Stopped: StoppedSession,
  Archived: ArchivedSession,
  Failed: FailedSession,
  Unknown: UnknownSession,
}

@doc("The GitHub issue of the session's repository that the session was started from, and the branch its first prompt asks for.")
model SessionIssue {
  @key sessionId: EntityId;
  issueNumber: GitHubIssueNumber;
  title: Summary;
  htmlUrl: HttpUrl;
  branch: ShortText;
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

@doc("A person started the session.")
model PersonOrigin {
  kind: "Person";
  principalId: EntityId;
}

@doc("A turn of another session started the session, calling Tumpel with that turn's token.")
model TurnOrigin {
  kind: "Turn";
  sessionId: EntityId;
  turnId: EntityId;
}

@doc("A trigger started the session when one delivery of an event matched it. The session runs as the trigger's principalId.")
model TriggerOrigin {
  kind: "Trigger";
  triggerId: EntityId;
  deliveryId: TriggerDeliveryId;
}

@doc("Who started a session: a person, a turn of another session or a trigger. What the first prompt came from is SessionOrigin.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SessionStartedBy {
  Person: PersonOrigin,
  Turn: TurnOrigin,
  Trigger: TriggerOrigin,
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
  detail: Detail;

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

  @doc("A condition the turn completed under that the persona should act on, such as a box disk with less than a hundredth of it free, with its size and the boxDiskMib that raises it. Absent when there was none.")
  @minLength(1)
  warning?: Detail;
}

@doc("A turn that ended Failed, with why.")
model FailedTurn {
  ...TurnBase;
  state: TurnState.Failed;
  reason: TurnFailureReason;

  @doc("What failed and what fixes it, with the tail of the harness's standard error when there is one.")
  detail: Detail;

  failedAt: offsetDateTime;
}

@doc("An Offered or Running turn whose host is Degraded, read in place of its stored state until the host reports again.")
model UnknownTurn {
  ...TurnBase;
  state: TurnState.Unknown;

  @doc("When the turn's host last sent a Hello or Heartbeat.")
  heardAt: offsetDateTime;

  @doc("Which host went silent and since when.")
  detail: Detail;
}

@doc("One prompt and the harness's completion of it, run on a session's box.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union Turn {
  Offered: OfferedTurn,
  Running: RunningTurn,
  Completed: CompletedTurn,
  Failed: FailedTurn,
  Unknown: UnknownTurn,
}

enum SteerState {
  @doc("The turn runs and its harness has not taken the steer yet.")
  Pending: "Pending",

  @doc("The harness took the steer inside the turn.")
  Delivered: "Delivered",

  @doc("The turn ended before its harness took the steer.")
  TurnEnded: "TurnEnded",
}

@doc("A prompt sent to a turn while it runs; the harness reads it between its steps, inside the same turn.")
model Steer {
  @key @visibility(Lifecycle.Read) steerId: EntityId;
  @visibility(Lifecycle.Read) turnId: EntityId;
  prompt: Prompt;
  @visibility(Lifecycle.Read) state: SteerState;
  @visibility(Lifecycle.Read) createdAt: int64;
}

model SteerCreate is Create<Steer>;

@doc("Why a turn ended Failed. Exists only for a turn in state Failed.")
model TurnFailure {
  @key turnId: EntityId;
  tenantId: EntityId;
  sessionId: EntityId;
  reason: TurnFailureReason;

  @doc("What failed and what fixes it, with the tail of the harness's standard error when there is one.")
  detail: Detail;

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
  detail: Detail;
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
  text: LongText;
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
  detail: Detail;
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
  @maxItems(1000) variableNames: ShortText[];

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
  @maxItems(1000) credentials: HarnessCredential[];

  credentialChoice: CredentialChoice;

  @doc("The paths, relative to the harness home in the box, this harness reads persona files from. A persona file at any other path is refused.")
  @maxItems(1000) personaFilePaths: PersonaFilePath[];

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
  @minLength(1) package: ShortText;
  @minLength(1) packageVersion: ShortText;
}

@doc("The pinned release tarball the harness ships as, one per architecture; the build refuses an archive whose sha256 differs.")
model ArchiveInstallRecipe {
  kind: "Archive";
  @minItems(1) @maxItems(100) archives: InstallArchive[];

  @doc("How many leading path components tar strips when it unpacks an archive.")
  @minValue(0)
  stripComponents: int32;
}

@doc("The release tarball of a harness version for one architecture.")
model InstallArchive {
  architecture: HostArchitecture;
  @minLength(1) url: UrlText;
  sha256: Sha256Digest;

  @doc("""
    The path of the harness binary in the unpacked archive, after stripComponents, such as
    codex-x86_64-unknown-linux-musl; the build moves it to the binary name the guest runs.
    """)
  @minLength(1)
  binaryPath: PathText;

  @doc("""
    The paths of the other executables in the unpacked archive that the harness spawns from beside
    its binary, such as codex-code-mode-host; the build moves each next to the binary under its file name.
    """)
  @maxItems(100) siblingBinaryPaths: ShortText[];
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
  @maxItems(100) fixed: FixedVariable[];
  @maxItems(64) arguments: Summary[];
  costBasis: CostBasis;

  @doc("For a CredentialFile, the file under the harness home the guest writes it to, mode 0600, in place of the variable; the harness may rewrite it, and a changed file is stored back in the secret set at the end of the turn.")
  path?: PersonaFilePath;

  @doc("Which models the harness runs with this credential.")
  modelSupport: ModelSupport;
}

@doc("The harness runs only the listed models with the credential. A session start or turn send naming another model is refused before a box boots.")
model ModelSupportListed {
  kind: "Listed";
  @minItems(1) @maxItems(1000) models: ModelName[];
}

@doc("The provider serves more models than the catalog lists, so any model passes to the provider and the provider checks it.")
model ModelSupportProviderChecked {
  kind: "ProviderChecked";
}

@doc("The models a harness runs with one credential.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union ModelSupport {
  Listed: ModelSupportListed,
  ProviderChecked: ModelSupportProviderChecked,
}

@doc("A variable a turn gets with a fixed value beside a credential, such as the base URL of the provider serving the harness's model API.")
model FixedVariable {
  name: SecretName;
  @minLength(1) value: CredentialText;
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

  @doc("The connectors every session of the persona reaches, each once; a repeated id is refused InvalidRequest and another tenant's NotFound. A session copies the list when it starts; a later edit changes later sessions only.")
  @maxItems(100) connectorIds: EntityId[];

  @doc("""
    The memory in MiB of each box the persona's sessions boot, from BoxMemoryLimit.MinMib up to
    BoxMemoryLimit.MaxMib; left out, the boxes get BoxMemoryLimit.DefaultMib. A session is placed only on a host
    whose available memory holds it, and a box already running keeps the memory it booted with.
    """)
  @minValue(512)
  @maxValue(65536)
  boxMemoryMib?: int32;

  @doc("""
    The disk in MiB of each box the persona's sessions boot, from BoxDiskLimit.DefaultMib up to BoxDiskLimit.MaxMib; left
    out, the boxes get BoxDiskLimit.DefaultMib. A host refuses a box whose disk does not fit its disk
    budget, and a box already running keeps the disk it booted with.
    """)
  @minValue(32768)
  @maxValue(262144)
  boxDiskMib?: int32;

  @doc("What happens to the box of each of the persona's sessions after each turn, unless the start names another mode.")
  @visibility(Lifecycle.Read)
  boxRetention: BoxRetention;

  @doc("Whether every session of the persona reaches the Tumpel MCP server as the built-in connector `tumpel`, calling it with a token of its turn.")
  @visibility(Lifecycle.Read)
  tumpelMcp: boolean;

  @doc("The harness's own config files, written under the harness home in the box before the harness starts.")
  @visibility(Lifecycle.Read)
  @maxItems(100) files: PersonaFile[];

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
  downloadUrl: HttpUrl;
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
  @visibility(Lifecycle.Read) @maxItems(200) keys: SecretKey[];
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

  @doc("How long the host may take to answer a SnapshotRequest before the snapshot fails NotAnswered; its presigned upload expires then too.")
  @minValue(1)
  snapshotDeadlineSeconds: int32;

  @doc("How long the credential, restore URLs and image URLs of each send of a TurnOffer stay valid, plus turnImageFetchBudgetSeconds for the image. It bounds no turn: a turn no host claims stays Offered.")
  @minValue(1)
  turnOfferTtlSeconds: int32;

  @doc("How long the host may take to download a guest image its cache lacks, after it sends TurnImageFetching; the offer's image.fetchSeconds. The image URLs stay valid for turnOfferTtlSeconds plus this. A host that runs past it fails the turn ImageFetchTimedOut.")
  @minValue(1)
  turnImageFetchBudgetSeconds: int32;

  @doc("How long a claimed turn may run before it fails TurnTimedOut, and how long an unclaimed turn stays Offered before it fails Undelivered.")
  @minValue(1)
  turnTotalBudgetSeconds: int32;

  @doc("How many lines of a turn go into one transcript chunk object; the last chunk of a turn holds the rest.")
  @minValue(1)
  @maxValue(1000)
  transcriptChunkLines: int32;

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
  @minLength(1) unit: ShortText;
  kind: MetricKind;
  @minLength(1) description: Detail;
}

@doc("One value of a Sample metric at a moment, with its dimensions.")
model SamplePoint {
  metric: MetricName;
  at: offsetDateTime;
  value: float64;
  @TypeSpec.JsonSchema.maxProperties(32) dimensions: Record<ShortText>;
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
  @maxItems(1000) instruments: MetricInstrument[];
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
  @maxItems(10000) metrics: MetricEntry[];
}

@doc("The metric catalog of a window, with the tenant's usage against its limits in the current windows.")
model TenantMetricCatalog {
  ...MetricCatalog;
  usage: TenantUsage;
}

model MetricEntry {
  ...MetricInstrument;
  @maxItems(100) facets: MetricFacet[];
}

@doc("One dimension of a metric's series in the window and the values it takes.")
model MetricFacet {
  dimension: ShortText;
  @maxItems(10000) values: MetricFacetValue[];
}

model MetricFacetValue {
  value: ShortText;
  seriesCount: int32;
}

@doc("""
  A metric's buckets in the window, one series per group. Past 20 groups the rest fold into one
  group whose values read Other.
  """)
model MetricSeriesSet {
  metric: MetricName;
  unit: ShortText;
  bucket: MetricBucket;
  @maxItems(10000) series: MetricSeries[];
}

@doc("The buckets of one group, keyed by the values of its groupBy dimensions; a bucket with no points is left out.")
model MetricSeries {
  @TypeSpec.JsonSchema.maxProperties(32) group: Record<ShortText>;
  @maxItems(10000) points: MetricPoint[];
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
  @maxItems(10000) points: MetricTurnPoint[];
  cursor: Summary;
  finished: boolean;
}

model MetricTurnPoint {
  turnId: EntityId;
  sessionId: EntityId;
  at: offsetDateTime;
  value: float64;
  @TypeSpec.JsonSchema.maxProperties(32) dimensions: Record<ShortText>;
}
