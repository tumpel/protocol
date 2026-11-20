import "@typespec/http";
import "./models.tsp";
import "./events.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("The note a session leaves when it pauses its own subscription to wait for a decision, which reaches the person with SubscriptionPaused.")
@minLength(1)
@maxLength(500)
scalar SubscriptionPauseMessage extends string;

enum SubscriptionState {
  @doc("Each matching event of the crew reaches the session in a delivery turn.")
  Active: "Active",

  @doc("No delivery turn starts; matching events wait after the cursor until a resume.")
  Paused: "Paused",

  @doc("The subscription is over and sends no further turn.")
  Ended: "Ended",
}

@doc("Someone paused the subscription with Subscriptions_pause, leaving a message.")
model SubscriptionPausedByRequest {
  kind: "ByRequest";
  message: SubscriptionPauseMessage;
}

@doc("3 delivery turns in a row failed; the last one is turnId, whose failure Turns_getFailure reads.")
model SubscriptionPausedDeliveryFailed {
  kind: "DeliveryFailed";
  turnId: EntityId;
}

@doc("10 turns or sessions of the crew in a row failed.")
model SubscriptionPausedCrewFailing {
  kind: "CrewFailing";
}

@doc("Why a subscription is Paused.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union SubscriptionPauseReason {
  ByRequest: SubscriptionPausedByRequest,
  DeliveryFailed: SubscriptionPausedDeliveryFailed,
  CrewFailing: SubscriptionPausedCrewFailing,
}

@doc("Why a subscription is Ended.")
enum SubscriptionEndReason {
  @doc("Its session was archived.")
  SessionArchived: "SessionArchived",

  @doc("Its session entered Failed.")
  SessionFailed: "SessionFailed",

  @doc("Its expiresAt passed.")
  Expired: "Expired",

  @doc("Its session called Subscriptions_complete: the goal holds.")
  GoalMet: "GoalMet",
}

model SubscriptionActive {
  state: SubscriptionState.Active;
}

model SubscriptionPaused {
  state: SubscriptionState.Paused;
  reason: SubscriptionPauseReason;
  pausedAt: offsetDateTime;
}

model SubscriptionEnded {
  state: SubscriptionState.Ended;
  reason: SubscriptionEndReason;
  endedAt: offsetDateTime;
}

@doc("Whether a subscription delivers, with why it is Paused or Ended.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union SubscriptionStatus {
  Active: SubscriptionActive,
  Paused: SubscriptionPaused,
  Ended: SubscriptionEnded,
}

@doc("""
  A plan and a goal tied to one session, which receives a delivery turn whenever a session of its
  crew records one of the listed events. The crew is every other session that carries every crew
  tag at the moment of the event and holds no Active subscription itself. Each delivery turn holds
  the plan and the events after the cursor, one JSON line each, and works toward the goal. Every
  field but the status and the counts is fixed at create.
  """)
model Subscription {
  @key @visibility(Lifecycle.Read) subscriptionId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;

  @doc("The session that receives the delivery turns. Its harness must take a goal.")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  sessionId: EntityId;

  @doc("The plan, sent at the top of every delivery turn. The plan and the goal must leave room for one event inside the 4,000 characters of a delivery turn's message.")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  prompt: Prompt;

  @doc("The condition that ends the work, sent as the goal of every delivery turn. The session calls Subscriptions_complete once it holds.")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  goal: Goal;

  @doc("The event types that start a delivery turn, each a type whose event names a session.")
  @minItems(1)
  @visibility(Lifecycle.Read, Lifecycle.Create)
  events: TenantEventType[];

  @doc("The tags a session must all carry to be part of the crew.")
  @minItems(1)
  @maxItems(16)
  @visibility(Lifecycle.Read, Lifecycle.Create)
  crewTags: SessionTag[];

  @doc("When the subscription ends Expired.")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  expiresAt: offsetDateTime;

  @doc("The last event a completed delivery turn held. A create sets it to the end of the log.")
  @visibility(Lifecycle.Read)
  cursorEventId: Sequence;

  @doc("Crew turns and sessions that failed since a crew turn last completed; at 10 the subscription pauses CrewFailing.")
  @minValue(0)
  @visibility(Lifecycle.Read)
  crewFailuresInARow: int32;

  @doc("Delivery turns that failed since one last completed; at 3 the subscription pauses DeliveryFailed.")
  @minValue(0)
  @visibility(Lifecycle.Read)
  deliveryFailuresInARow: int32;

  @visibility(Lifecycle.Read) status: SubscriptionStatus;
  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

model SubscriptionCreate is Create<Subscription>;

@doc("Pauses a subscription with a note for the person who resumes it.")
model SubscriptionPause {
  message: SubscriptionPauseMessage;
}

model SubscriptionPath {
  @path subscriptionId: EntityId;
}

model SubscriptionListQuery {
  @query sessionId?: EntityId;
  @query state?: SubscriptionState;
}

namespace V1 {
  @route("/subscriptions")
  interface Subscriptions {
    @doc("""
      Creates an Active subscription whose cursor starts at the end of the event log. Only a person
      creates one: a call with a turn token is refused Forbidden. Refused InvalidRequest when the
      session's harness takes no goal, when an event type names no session, or when the plan and the
      goal leave no room for one event; SessionArchived or SessionFailed when the session is.
      """)
    @post
    create(@body body: SubscriptionCreate): Subscription | ProblemResponse;

    @doc("Lists the tenant's subscriptions, optionally only those of one session or in one state.")
    @get
    list(...SubscriptionListQuery): Subscription[] | ProblemResponse;

    @doc("Reads one subscription with its failure counts and why it is Paused or Ended.")
    @route("/{subscriptionId}")
    @get
    get(...SubscriptionPath): Subscription | ProblemResponse;

    @doc("""
      Pauses a subscription with reason ByRequest and its message, and cancels its waiting delivery
      turn; its events wait after the cursor. Pausing a Paused subscription replaces its reason. The
      subscription's own session pauses it with a turn token to wait for a decision. Refused
      SubscriptionEnded when it is Ended.
      """)
    @route("/{subscriptionId}/pause")
    @post
    pause(...SubscriptionPath, @body body: SubscriptionPause): Subscription | ProblemResponse;

    @doc("""
      Resumes a Paused subscription: it sets both failure counts to 0 and delivers the events after
      its cursor. Resuming an Active subscription answers it as it is. Only a person resumes one: a
      call with a turn token is refused Forbidden. Refused SubscriptionEnded when it is Ended, and
      SubscriptionCursorExpired when its cursor is older than the event log keeps.
      """)
    @route("/{subscriptionId}/resume")
    @post
    resume(...SubscriptionPath): Subscription | ProblemResponse;

    @doc("Deletes a subscription and cancels its waiting delivery turn. Its own session deletes it with a turn token too.")
    @route("/{subscriptionId}")
    @delete
    delete(...SubscriptionPath): NoContentResponse | ProblemResponse;

    @doc("""
      Ends a subscription with reason GoalMet and cancels its waiting delivery turn. Its own session
      calls it with a turn token once the goal holds. Refused SubscriptionEnded when it is Ended.
      """)
    @route("/{subscriptionId}/complete")
    @post
    complete(...SubscriptionPath): Subscription | ProblemResponse;
  }
}
