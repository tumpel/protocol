import "@typespec/http";
import "./models.tsp";
import "./operations.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("A GitHub webhook event type a trigger listens to, as GitHub names it in X-GitHub-Event.")
enum GitHubTriggerEvent {
  PullRequest: "pull_request",
  Push: "push",
  Status: "status",
  Issues: "issues",
}

@doc("""
  A dotted path into an event's JSON payload, such as pull_request.base.ref. A path that crosses
  an array reaches every element, so pull_request.labels.name reaches each label's name.
  """)
@pattern("^[A-Za-z0-9_\\-]+(\\.[A-Za-z0-9_\\-]+)*$")
@maxLength(200)
scalar TriggerFieldPath extends string;

@doc("A value a condition compares against: the JSON text of a scalar, so true matches a boolean and 42 a number.")
@maxLength(500)
scalar TriggerConditionValue extends string;

@doc("The id the source gives one delivery of an event, such as GitHub's X-GitHub-Delivery. A redelivery keeps it.")
@minLength(1)
@maxLength(200)
scalar TriggerDeliveryId extends string;

@doc("""
  Holds when the event's value at `field` equals one of `values`. When the path crosses an array,
  it holds when any element equals one. A path the event leaves absent or null holds for no value.
  """)
model TriggerCondition {
  field: TriggerFieldPath;

  @minItems(1)
  @maxItems(20)
  values: TriggerConditionValue[];
}

@doc("Events of the stage's GitHub App: the event type and the conditions on its payload that must all hold.")
model GitHubTriggerSource {
  kind: "GitHub";
  event: GitHubTriggerEvent;

  @doc("None matches every event of the type.")
  @maxItems(20)
  conditions: TriggerCondition[];
}

@doc("Where a trigger's events come from and which of them it matches. Each source names its own event types and filter.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union TriggerSource {
  GitHub: GitHubTriggerSource,
}

@doc("""
  Starts a fresh session whenever an event of its source and type arrives on which every condition
  holds. The session runs on the persona and model the trigger names, with the prompt filled from
  the event, on the event's repository.html_url, as the principal who last created or changed the
  trigger. Each delivery starts at most one session. Tumpel only listens: the session reports back
  to the source because its prompt tells it to.
  """)
model Trigger {
  @key @visibility(Lifecycle.Read) triggerId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;

  @doc("Unique in the tenant, such as agent-review.")
  name: DisplayName;

  source: TriggerSource;

  @doc("The persona of every session the trigger starts. A start after the persona is deleted is refused.")
  personaId: EntityId;

  @doc("The model of every session the trigger starts; it must be one the persona's harness runs.")
  `model`: ModelName;

  @doc("""
    The first prompt, with {{field}} placeholders, each a TriggerFieldPath filled with the event's
    value at that path. An array fills as a comma-separated list. A placeholder the event lacks
    refuses the start.
    """)
  prompt: Prompt;

  @doc("The Owner who created or last changed the trigger. Every session the trigger starts runs as this principal.")
  @visibility(Lifecycle.Read)
  principalId: EntityId;

  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

model TriggerCreate is Create<Trigger>;

@doc("Changes the trigger fields it names and leaves every other field as it is. A named source replaces the whole source, its event and conditions included.")
model TriggerPatch is OptionalProperties<Update<Trigger>>;

model TriggerPath {
  @path triggerId: EntityId;
}

@doc("An event's JSON payload as the source sent it, such as the body of a GitHub webhook delivery.")
model TriggerPayload is Record<unknown>;

@doc("Tests a stored trigger against a payload.")
model StoredTriggerTest {
  kind: "Stored";
  triggerId: EntityId;
  payload: TriggerPayload;
}

@doc("Tests a trigger that is not stored yet, such as an unsaved form, against a payload.")
model DraftTriggerTest {
  kind: "Draft";
  trigger: TriggerCreate;
  payload: TriggerPayload;
}

@doc("A trigger and a pasted payload to match it against. The payload carries no event type, so the test takes it to be of the event its source names.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union TriggerTest {
  Stored: StoredTriggerTest,
  Draft: DraftTriggerTest,
}

@doc("One condition of a test with what the payload holds at its field.")
model TriggerConditionVerdict {
  ...TriggerCondition;

  @doc("The JSON text of each value the payload holds at the field: one for a scalar, one per element when the path crosses an array, none when the path leads nowhere.")
  actual: string[];

  holds: boolean;
}

@doc("What a trigger would do with a payload. A test starts nothing.")
model TriggerTestResult {
  @doc("Whether every condition holds, so a delivery of the payload would start a session.")
  matched: boolean;

  conditions: TriggerConditionVerdict[];

  @doc("The prompt the session would get. A placeholder the payload lacks stays as written.")
  prompt: string;

  @doc("Each placeholder of the prompt the payload lacks; a delivery with any is refused TriggerFieldMissing.")
  missingFields: TriggerFieldPath[];
}

@doc("Why a trigger matched a delivery and started no session.")
model TriggerStartRefusal {
  @doc("The code Sessions_start answers for the same refusal, or TriggerFieldMissing when the prompt names a field the event lacks.")
  code: ProblemCode;

  @doc("What failed and the fix, in plain words.")
  detail: string;
}

namespace V1 {
  @route("/triggers")
  interface Triggers {
    @doc("""
      Creates a trigger that runs as the caller. Only an Owner creates one: a Member is refused
      OwnerRequired and a call with a turn token Forbidden. Refused NotFound for an unknown persona,
      ModelUnsupported for a model the persona's harness does not run, and Conflict when the tenant
      has a trigger of the same name.
      """)
    @post
    create(@body body: TriggerCreate): Trigger | ProblemResponse;

    @doc("Lists the tenant's triggers.")
    @get
    list(): Trigger[] | ProblemResponse;

    @doc("Reads one trigger.")
    @route("/{triggerId}")
    @get
    get(...TriggerPath): Trigger | ProblemResponse;

    @doc("""
      Changes the fields the patch names and keeps the rest; the trigger then runs as the caller.
      Only an Owner changes one, and refusals are those of create.
      """)
    @route("/{triggerId}")
    @patch(#{ implicitOptionality: false })
    update(...TriggerPath, @body body: TriggerPatch): Trigger | ProblemResponse;

    @doc("Deletes a trigger; sessions it started stay. Only an Owner deletes one, and refusals are those of create.")
    @route("/{triggerId}")
    @delete
    delete(...TriggerPath): NoContentResponse | ProblemResponse;

    @doc("""
      Matches a stored or draft trigger against a pasted payload and answers each condition's
      verdict and the prompt it would fill. It starts nothing, and every member may call it.
      Refused NotFound for an unknown stored trigger.
      """)
    @route("/test")
    @post
    test(@body body: TriggerTest): TriggerTestResult | ProblemResponse;
  }
}
