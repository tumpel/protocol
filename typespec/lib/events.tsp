import "@typespec/http";
import "./models.tsp";
import "./prebuild.tsp";
import "./subscriptions.tsp";
import "./triggers.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("The kind of a tenant event, named for the state change it records.")
enum TenantEventType {
  @doc("A host claimed a turn and its harness runs it.")
  TurnStarted: "TurnStarted",

  @doc("A turn ended Completed.")
  TurnCompleted: "TurnCompleted",

  @doc("A turn ended Failed.")
  TurnFailed: "TurnFailed",

  @doc("A session entered Idle: no turn of it is in flight.")
  SessionIdle: "SessionIdle",

  @doc("A session entered Stopped: its box is gone and its snapshots remain.")
  SessionStopped: "SessionStopped",

  @doc("A session entered Failed.")
  SessionFailed: "SessionFailed",

  @doc("A session entered Archived.")
  SessionArchived: "SessionArchived",

  @doc("A host's channel opened.")
  HostOnline: "HostOnline",

  @doc("A host's last open channel closed.")
  HostOffline: "HostOffline",

  @doc("The control plane changed a host's health.")
  HostHealthChanged: "HostHealthChanged",

  @doc("A prebuild entered Done: its layer is stored.")
  PrebuildDone: "PrebuildDone",

  @doc("A prebuild entered Failed.")
  PrebuildFailed: "PrebuildFailed",

  @doc("A subscription entered Paused.")
  SubscriptionPaused: "SubscriptionPaused",

  @doc("A subscription entered Ended.")
  SubscriptionEnded: "SubscriptionEnded",

  @doc("A trigger matched a delivery and started no session.")
  TriggerStartRefused: "TriggerStartRefused",

  @doc("The tenant used 80% of one of its limits in the current window.")
  UsageNearLimit: "UsageNearLimit",

  @doc("The tenant reached one of its limits; requests it counts are refused until the window ends.")
  UsageLimitReached: "UsageLimitReached",
}

@doc("""
  What every tenant event carries. `eventId` orders the tenant's events: each is greater than every
  event before it, so a reader resumes after the last id it saw.
  """)
model TenantEventEnvelope {
  eventId: Sequence;
  tenantId: EntityId;
  createdAt: int64;
}

model TurnStartedEvent {
  event: "TurnStarted";
  ...TenantEventEnvelope;
  turnId: EntityId;
  sessionId: EntityId;
}

model TurnCompletedEvent {
  event: "TurnCompleted";
  ...TenantEventEnvelope;
  turnId: EntityId;
  sessionId: EntityId;
}

model TurnFailedEvent {
  event: "TurnFailed";
  ...TenantEventEnvelope;
  turnId: EntityId;
  sessionId: EntityId;
  reason: TurnFailureReason;

  @doc("What failed and what fixes it, as the turn's failure reads.")
  detail: Detail;
}

model SessionIdleEvent {
  event: "SessionIdle";
  ...TenantEventEnvelope;
  sessionId: EntityId;

  @doc("The turn whose end left the session Idle.")
  turnId: EntityId;
}

model SessionStoppedEvent {
  event: "SessionStopped";
  ...TenantEventEnvelope;
  sessionId: EntityId;
}

model SessionFailedEvent {
  event: "SessionFailed";
  ...TenantEventEnvelope;
  sessionId: EntityId;
}

model SessionArchivedEvent {
  event: "SessionArchived";
  ...TenantEventEnvelope;
  sessionId: EntityId;
}

model HostOnlineEvent {
  event: "HostOnline";
  ...TenantEventEnvelope;
  hostId: EntityId;
}

model HostOfflineEvent {
  event: "HostOffline";
  ...TenantEventEnvelope;
  hostId: EntityId;
}

model HostHealthChangedEvent {
  event: "HostHealthChanged";
  ...TenantEventEnvelope;
  hostId: EntityId;
  health: HostHealth;
  detail: Detail;
}

model PrebuildDoneEvent {
  event: "PrebuildDone";
  ...TenantEventEnvelope;
  prebuildId: EntityId;
  repository: RepositoryUrl;
}

model PrebuildFailedEvent {
  event: "PrebuildFailed";
  ...TenantEventEnvelope;
  prebuildId: EntityId;
  repository: RepositoryUrl;
  phase: PrebuildFailurePhase;
}

model SubscriptionPausedEvent {
  event: "SubscriptionPaused";
  ...TenantEventEnvelope;
  subscriptionId: EntityId;

  @doc("The session the subscription sends its turns to.")
  sessionId: EntityId;

  reason: SubscriptionPauseReason;
}

model SubscriptionEndedEvent {
  event: "SubscriptionEnded";
  ...TenantEventEnvelope;
  subscriptionId: EntityId;

  @doc("The session the subscription sent its turns to.")
  sessionId: EntityId;

  reason: SubscriptionEndReason;
}

model TriggerStartRefusedEvent {
  event: "TriggerStartRefused";
  ...TenantEventEnvelope;
  triggerId: EntityId;
  deliveryId: TriggerDeliveryId;
  refusal: TriggerStartRefusal;
}

model UsageNearLimitEvent {
  event: "UsageNearLimit";
  ...TenantEventEnvelope;
  tier: TenantTier;
  ...TenantUsageCounter;
}

model UsageLimitReachedEvent {
  event: "UsageLimitReached";
  ...TenantEventEnvelope;
  tier: TenantTier;
  ...TenantUsageCounter;
}

@doc("""
  A record that something happened in a tenant. The control plane appends it in the same
  transaction as the state change it reports. It holds ids and the fact that changed; read the
  resource for the rest.
  """)
@discriminated(#{ envelope: "none", discriminatorPropertyName: "event" })
union TenantEvent {
  TurnStarted: TurnStartedEvent,
  TurnCompleted: TurnCompletedEvent,
  TurnFailed: TurnFailedEvent,
  SessionIdle: SessionIdleEvent,
  SessionStopped: SessionStoppedEvent,
  SessionFailed: SessionFailedEvent,
  SessionArchived: SessionArchivedEvent,
  HostOnline: HostOnlineEvent,
  HostOffline: HostOfflineEvent,
  HostHealthChanged: HostHealthChangedEvent,
  PrebuildDone: PrebuildDoneEvent,
  PrebuildFailed: PrebuildFailedEvent,
  SubscriptionPaused: SubscriptionPausedEvent,
  SubscriptionEnded: SubscriptionEndedEvent,
  TriggerStartRefused: TriggerStartRefusedEvent,
  UsageNearLimit: UsageNearLimitEvent,
  UsageLimitReached: UsageLimitReachedEvent,
}

@doc("""
  A page of the tenant's events, oldest first, at most 100. `lastEventId` is the id the read
  reached; pass it as `afterEventId` to read on.
  """)
model EventPage {
  @maxItems(100)
  events: TenantEvent[];

  lastEventId: Sequence;
}

@doc("The event cursor is older than the oldest event the log keeps.")
model EventCursorExpiredProblem {
  ...OmitProperties<Problem, "code">;
  code: ProblemCode.EventCursorExpired;
  oldestEventId: Sequence;
}

union EventProblem {
  CursorExpired: EventCursorExpiredProblem,
  Other: Problem,
}

@error
model EventProblemResponse {
  @statusCode statusCode: 400 | 401 | 403 | 404 | 409 | 410 | 413 | 422 | 429 | 503;
  @body body: EventProblem;
}

model EventQuery {
  @doc("""
    The id after which this page starts. Leave it out to start at the current end of the log. An
    id older than the log keeps, 7 days, is refused EventCursorExpired.
    """)
  @query
  afterEventId?: Sequence;

  @doc("Keep events of this type; repeat it for several types. Leave it out to keep every type.")
  @query(#{ explode: true })
  @maxItems(1000) event?: TenantEventType[];

  @doc("Keep events of this session.")
  @query
  sessionId?: EntityId;

  @doc("Keep events of this trigger.")
  @query
  triggerId?: EntityId;

  @doc("The most seconds to wait when no event matches yet.")
  @query
  @minValue(0)
  @maxValue(50)
  waitSeconds: int32;
}

namespace V1 {
  @route("/events")
  interface Events {
    @doc("""
      Reads the tenant's events after afterEventId, waiting up to waitSeconds for one to match.
      With Accept: text/event-stream it answers a stream instead: one message per event, whose id
      is its eventId, resumed after the Last-Event-ID a reconnect sends.
      """)
    @get
    list(...EventQuery): EventPage | EventProblemResponse;
  }
}
