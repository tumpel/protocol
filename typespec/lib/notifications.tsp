import "@typespec/http";
import "./models.tsp";
import "./events.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("""
  The HTTPS address a webhook endpoint receives events at. It carries no user info and no
  fragment, so it never holds a credential.
  """)
@pattern("^https://[^/@?#\\s]+(/[^#\\s]*)?$")
@maxLength(2048)
scalar WebhookUrl extends url;

@doc("Whether the control plane delivers a webhook endpoint's events.")
enum WebhookDelivery {
  @doc("The endpoint answered its last request with a 2xx status, or has had no event yet.")
  Delivering: "Delivering",

  @doc("""
    The endpoint failed every request for 3 days. Delivery stopped; delete the endpoint and create
    it again once it answers.
    """)
  Failing: "Failing",
}

model WebhookDelivering {
  delivery: WebhookDelivery.Delivering;
}

model WebhookFailing {
  delivery: WebhookDelivery.Failing;

  @doc("How the last request failed: the status the endpoint answered, or that it did not answer within 10 seconds.")
  detail: string;

  failingSince: offsetDateTime;
}

@doc("Whether a webhook endpoint receives its events, with how it fails when it does not.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "delivery" })
union WebhookDeliveryStatus {
  Delivering: WebhookDelivering,
  Failing: WebhookFailing,
}

@doc("""
  An HTTPS endpoint that receives the tenant's events of the listed types, in eventId order, at
  least once. Each request is a POST of one event as JSON. Its `Tumpel-Signature` header is the
  base64url Ed25519 signature, under the tenant's webhook signing key, over the request body;
  `Tumpel-Event-Id` repeats the eventId so a receiver drops a repeat. A failed request is retried
  after 1 minute, doubling to 1 hour. The URL and types are fixed at create.
  """)
model WebhookEndpoint {
  @key @visibility(Lifecycle.Read) webhookEndpointId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @visibility(Lifecycle.Read, Lifecycle.Create) url: WebhookUrl;

  @minItems(1)
  @visibility(Lifecycle.Read, Lifecycle.Create)
  events: TenantEventType[];

  @visibility(Lifecycle.Read) status: WebhookDeliveryStatus;
  @visibility(Lifecycle.Read) createdAt: int64;
}

model WebhookEndpointCreate is Create<WebhookEndpoint>;

model WebhookEndpointPath {
  @path webhookEndpointId: EntityId;
}

@doc("The public half of the tenant's webhook signing key, raw 32 bytes in base64url.")
model WebhookSigningKey {
  algorithm: "Ed25519";

  @pattern("^[A-Za-z0-9_-]{43}$")
  publicKey: string;
}

@doc("The HTTPS push service address a browser's push subscription names.")
@pattern("^https://[^/@?#\\s]+(/[^#\\s]*)?$")
@maxLength(2048)
scalar PushEndpointUrl extends url;

@doc("The keys a browser's push subscription carries, in base64url, as the Push API reports them.")
model PushSubscriptionKeys {
  @doc("The browser's P-256 public key, uncompressed.")
  @pattern("^[A-Za-z0-9_-]{87}$")
  p256dh: string;

  @doc("The 16-byte authentication secret.")
  @pattern("^[A-Za-z0-9_-]{22}$")
  auth: string;
}

@doc("""
  One browser of the caller that receives a Web Push notification for each of the tenant's events
  of the listed types. A push service that answers 404 or 410 deletes the
  subscription.
  """)
model PushSubscription {
  @key @visibility(Lifecycle.Read) pushSubscriptionId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  @visibility(Lifecycle.Read) principalId: EntityId;
  @visibility(Lifecycle.Read, Lifecycle.Create) endpoint: PushEndpointUrl;

  @minItems(1)
  @visibility(Lifecycle.Read, Lifecycle.Create)
  events: TenantEventType[];

  @visibility(Lifecycle.Read) createdAt: int64;
}

@doc("What a browser sends to subscribe: its push endpoint, its keys and the event types to notify. The keys are write-only.")
model PushSubscriptionCreate {
  ...Create<PushSubscription>;
  keys: PushSubscriptionKeys;
}

model PushSubscriptionPath {
  @path pushSubscriptionId: EntityId;
}

@doc("The control plane's VAPID public key, an uncompressed P-256 point in base64url, which a browser passes as applicationServerKey.")
model PushKey {
  @pattern("^[A-Za-z0-9_-]{87}$")
  applicationServerKey: string;
}

namespace V1 {
  @route("/webhook-endpoints")
  interface WebhookEndpoints {
    @doc("Lists the tenant's webhook endpoints with their delivery status.")
    @get
    list(): WebhookEndpoint[] | ProblemResponse;

    @doc("Creates a webhook endpoint; it receives the listed event types from the next event on. Owner only.")
    @post
    create(@body body: WebhookEndpointCreate): WebhookEndpoint | ProblemResponse;

    @doc("Reads one webhook endpoint with its delivery status.")
    @route("/{webhookEndpointId}")
    @get
    get(...WebhookEndpointPath): WebhookEndpoint | ProblemResponse;

    @doc("Deletes a webhook endpoint; no request reaches it after the one in flight. Owner only.")
    @route("/{webhookEndpointId}")
    @delete
    delete(...WebhookEndpointPath): NoContentResponse | ProblemResponse;
  }

  @route("/webhook-signing-key")
  interface WebhookSigningKeys {
    @doc("Reads the public key that verifies the Tumpel-Signature header of the tenant's webhook requests.")
    @get
    get(): WebhookSigningKey | ProblemResponse;
  }

  @route("/push-subscriptions")
  interface PushSubscriptions {
    @doc("Lists the caller's push subscriptions in the tenant.")
    @get
    list(): PushSubscription[] | ProblemResponse;

    @doc("Subscribes one of the caller's browsers to Web Push notifications of the listed event types. The browser sends it; its keys never travel over MCP.")
    @post
    create(@body body: PushSubscriptionCreate): PushSubscription | ProblemResponse;

    @doc("Deletes one of the caller's push subscriptions; that browser gets no further notification.")
    @route("/{pushSubscriptionId}")
    @delete
    delete(...PushSubscriptionPath): NoContentResponse | ProblemResponse;
  }

  @route("/push-key")
  interface PushKeys {
    @doc("Reads the VAPID public key a browser needs to subscribe to Web Push.")
    @get
    get(): PushKey | ProblemResponse;
  }
}
