import "@typespec/http";
import "./models.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("Why an OpenRouter authorization ended Failed. Each reason names the phase it stopped in.")
enum OpenRouterAuthorizationFailureReason {
  @doc("No callback with a code arrived within 10 minutes of the authorization, the lifetime OpenRouter gives a code.")
  AuthorizationTimedOut: "AuthorizationTimedOut",

  @doc("OpenRouter sent the browser back without a code, as it does when the person declines.")
  NotConnected: "NotConnected",

  @doc("OpenRouter's key endpoint refused the code: it was spent, it expired, or the verifier does not match.")
  CodeRefused: "CodeRefused",

  @doc("OpenRouter answered the key exchange with another error, without a key, or not within 15 seconds, or the exchange stopped before it stored a key.")
  ExchangeFailed: "ExchangeFailed",

  @doc("OpenRouter minted a key and the secret set could not take it: the set was deleted or took another OpenRouter credential. The key is discarded; delete it on OpenRouter.")
  KeyNotStored: "KeyNotStored",
}

@doc("The phase an OpenRouter authorization is in.")
enum OpenRouterAuthorizationState {
  @doc("The person approves at authorizeUrl; OpenRouter then sends the browser to the control plane's callback with a code.")
  AwaitingCallback: "AwaitingCallback",

  @doc("The callback arrived with a code; the control plane is spending it at OpenRouter for a key.")
  Exchanging: "Exchanging",

  @doc("The secret set holds the minted key as OPENROUTER_API_KEY.")
  Completed: "Completed",

  @doc("The authorization stopped; the secret set is unchanged.")
  Failed: "Failed",
}

model OpenRouterAuthorizationAwaitingCallback {
  state: OpenRouterAuthorizationState.AwaitingCallback;

  @doc("OpenRouter's authorization page, with the control plane's callback_url, this authorization's PKCE S256 challenge and its signed state.")
  authorizeUrl: url;

  @doc("When the callback must arrive by, or the authorization fails AuthorizationTimedOut.")
  callbackDueAt: offsetDateTime;
}

model OpenRouterAuthorizationExchanging {
  state: OpenRouterAuthorizationState.Exchanging;

  @doc("When the exchange must have stored a key by, or the authorization fails ExchangeFailed.")
  exchangeDueAt: offsetDateTime;
}

model OpenRouterAuthorizationCompleted {
  state: OpenRouterAuthorizationState.Completed;

  @doc("The label the key carries on OpenRouter, where its owner deletes it.")
  keyLabel: DisplayName;

  completedAt: offsetDateTime;
}

model OpenRouterAuthorizationFailed {
  state: OpenRouterAuthorizationState.Failed;
  reason: OpenRouterAuthorizationFailureReason;

  @doc("What failed and what fixes it.")
  detail: string;

  failedAt: offsetDateTime;
}

@doc("Where an OpenRouter authorization is: the authorization URL while it waits for the callback, the exchange time limit while it spends the code, the key label once Completed, the reason once Failed.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union OpenRouterAuthorizationStatus {
  AwaitingCallback: OpenRouterAuthorizationAwaitingCallback,
  Exchanging: OpenRouterAuthorizationExchanging,
  Completed: OpenRouterAuthorizationCompleted,
  Failed: OpenRouterAuthorizationFailed,
}

@doc("""
  One OAuth PKCE S256 flow at OpenRouter that mints an API key and stores it in a secret set as the
  ApiKey member OPENROUTER_API_KEY for OpenRouter. OpenRouter sends the browser back to the control
  plane, which spends the code with the verifier it holds sealed and then sends the browser to
  the secret set's page with openRouterAuthorizationId added. The code, the verifier and the key never appear in
  a response.
  """)
model OpenRouterAuthorization {
  @key openRouterAuthorizationId: EntityId;
  tenantId: EntityId;
  principalId: EntityId;
  secretSetId: EntityId;

  status: OpenRouterAuthorizationStatus;
  createdAt: int64;
  updatedAt: int64;
}

@doc("Starts an OpenRouter authorization for one secret set of the tenant.")
model OpenRouterAuthorizationStart {
  secretSetId: EntityId;
}

@doc("The OpenRouter authorization a request names.")
model OpenRouterAuthorizationPath {
  @path openRouterAuthorizationId: EntityId;
}

namespace V1 {
  @route("/openrouter-connection")
  interface OpenRouterConnections {
    @doc("""
      Starts an authorization that mints an OpenRouter API key for one secret set through
      OpenRouter's PKCE flow. Answers it AwaitingCallback with authorizeUrl; open it in a browser,
      where OpenRouter sends the browser back to the control plane at /openrouter/callback. The
      callback spends the code and stores the key as the ApiKey member OPENROUTER_API_KEY for
      OpenRouter, replacing that member and keeping every other one. Refused NotFound for a secret
      set the tenant does not own and Conflict when the set holds an OpenRouter credential under
      another name.
      """)
    @route("/authorize")
    @post
    authorize(@body body: OpenRouterAuthorizationStart): OpenRouterAuthorization | ProblemResponse;

    @doc("Reads one OpenRouter authorization the caller started: AwaitingCallback until the callback, Exchanging while the control plane spends the code, Completed with the key label, or Failed with its reason. Never carries the key.")
    @route("/authorizations/{openRouterAuthorizationId}")
    @get
    getAuthorization(...OpenRouterAuthorizationPath): OpenRouterAuthorization | ProblemResponse;
  }
}
