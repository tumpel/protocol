import "@typespec/http";
import "./models.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("""
  The HTTPS address of a remote MCP server that speaks Streamable HTTP. It carries no user info, no
  query and no fragment, so it never holds a credential.
  """)
@pattern("^https://[^/@?#\\s]+(/[^?#\\s]*)?$")
@maxLength(2048)
scalar ConnectorUrl extends url;

@doc("How a connector's upstream credential is held: one static token, or an OAuth grant.")
enum ConnectorAuth {
  @doc("One token the forwarder sends as Authorization: Bearer, written through StaticConnectors_setToken.")
  Static: "Static",

  @doc("An OAuth authorization-code grant the control plane obtains through dynamic client registration and refreshes.")
  OAuth: "OAuth",
}

@doc("Whether a connector can serve a new turn.")
enum ConnectorState {
  @doc("The connector holds no credential: set a token, or authorize an OAuth connector.")
  NotConnected: "NotConnected",

  @doc("The connector holds a credential, and new turns get it.")
  Connected: "Connected",

  @doc("An Owner cleared the credential. New turns are refused ConnectorDisconnected; running turns keep it until they end, and the last one to end deletes it.")
  Disconnected: "Disconnected",

  @doc("The last OAuth authorization or refresh failed; authorize again.")
  AuthorizationFailed: "AuthorizationFailed",
}

@doc("Why an OAuth connector's authorization or refresh failed after authorize answered. Each reason names the phase it stopped in.")
enum ConnectorAuthorizationFailureReason {
  @doc("The provider sent the browser back with an error, as it does when the person declines, or the person who authorized is no longer an Owner.")
  AuthorizationDenied: "AuthorizationDenied",

  @doc("No callback arrived within 10 minutes of the authorization, or its state was already spent.")
  AuthorizationExpired: "AuthorizationExpired",

  @doc("The token endpoint refused the code, answered without a token, or did not answer within 10 seconds.")
  TokenExchangeFailed: "TokenExchangeFailed",

  @doc("The token endpoint refused the refresh token with invalid_grant: the grant was revoked, expired or rotated by a refresh the control plane lost.")
  RefreshRefused: "RefreshRefused",
}

model ConnectorNotConnected {
  state: ConnectorState.NotConnected;
}

model ConnectorConnected {
  state: ConnectorState.Connected;
  connectedAt: offsetDateTime;
}

model ConnectorDisconnected {
  state: ConnectorState.Disconnected;
  disconnectedAt: offsetDateTime;
}

model ConnectorAuthorizationFailed {
  state: ConnectorState.AuthorizationFailed;
  reason: ConnectorAuthorizationFailureReason;

  @doc("What failed and what fixes it, with the provider's answer sanitized; it never quotes a token response.")
  detail: Detail;

  failedAt: offsetDateTime;
}

@doc("Whether a connector serves new turns, with when it connected, when it was disconnected, or why its authorization failed.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union ConnectorStatus {
  NotConnected: ConnectorNotConnected,
  Connected: ConnectorConnected,
  Disconnected: ConnectorDisconnected,
  AuthorizationFailed: ConnectorAuthorizationFailed,
}

@doc("The fields every connector has, whatever holds its credential.")
model ConnectorFields {
  @key @visibility(Lifecycle.Read) connectorId: EntityId;
  @visibility(Lifecycle.Read) tenantId: EntityId;
  name: DisplayName;
  @visibility(Lifecycle.Read, Lifecycle.Create) url: ConnectorUrl;
  @visibility(Lifecycle.Read) status: ConnectorStatus;
  @visibility(Lifecycle.Read) createdAt: int64;
  @visibility(Lifecycle.Read) updatedAt: int64;
}

@doc("""
  A remote MCP server the tenant connects once with one static token. Every session in the tenant
  whose persona lists it reaches it through the box's loopback forwarder, which sends the token as
  Authorization: Bearer. The URL is fixed at create; the token is write-only.
  """)
model StaticConnector {
  @visibility(Lifecycle.Read) auth: ConnectorAuth.Static;
  ...ConnectorFields;
}

@doc("""
  A remote MCP server the tenant connects once through OAuth. An Owner authorizes it in a browser,
  the control plane holds the grant sealed and refreshes it, and every session in the tenant whose
  persona lists it reaches it through the box's loopback forwarder. The URL is fixed at create.
  """)
model OAuthConnector {
  @visibility(Lifecycle.Read) auth: ConnectorAuth.OAuth;
  ...ConnectorFields;
}

@doc("A connector of either credential kind.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "auth" })
union Connector {
  Static: StaticConnector,
  OAuth: OAuthConnector,
}

model StaticConnectorCreate is Create<StaticConnector>;

model OAuthConnectorCreate is Create<OAuthConnector>;

@doc("Renames a connector. Its URL and credential kind are fixed at create; a new endpoint is a new connector.")
model ConnectorUpdate is Update<StaticConnector>;

@doc("The token a static connector sends upstream as Authorization: Bearer. It is stored sealed and never returned.")
model StaticConnectorTokenWrite {
  value: SecretText;
}

@doc("""
  One OAuth authorization of a connector. Open authorizeUrl in a browser; the provider sends the
  browser back to the control plane's callback, which stores the grant. Connectors_get reads the
  outcome. A newer authorization of the same connector replaces this one.
  """)
model ConnectorAuthorization {
  connectorAuthorizationId: EntityId;
  connectorId: EntityId;

  @doc("The provider's authorization page, with the control plane's callback, this authorization's PKCE S256 challenge, its signed state and the resource.")
  authorizeUrl: HttpUrl;

  @doc("When the callback must arrive by, or the connector reads AuthorizationFailed AuthorizationExpired.")
  callbackDueAt: offsetDateTime;
}

@doc("""
  An access token for one connector of one running turn. The forwarder sends it upstream until
  fewer than 30 seconds remain before expiresAt, then fetches another. A token without expiresAt is
  fetched once.
  """)
model ConnectorAccessToken {
  accessToken: SecretText;
  expiresAt?: offsetDateTime;
}

@doc("""
  The credential of one connector of one turn, handed to the box in its DispatchGrant: an HMAC of
  the tenant, the turn and the connector. It fetches that connector's access token while the turn
  is Running, and nothing else.
  """)
model ConnectorTurnToken is BearerAuth;

@doc("The connector a request names.")
model ConnectorPath {
  @path connectorId: EntityId;
}

@doc("The connector of a turn whose access token a box fetches.")
model ConnectorTokenPath {
  @path turnId: EntityId;
  @path connectorId: EntityId;
}

@doc("""
  The connector a write names, with the updatedAt of the caller's last read of it. The write is
  refused ConnectorChanged (409) when the stored updatedAt differs, and changes nothing.
  """)
model ConnectorWritePath {
  ...ConnectorPath;
  @query updatedAt: int64;
}

namespace V1 {
  @route("/connectors")
  interface Connectors {
    @doc("Lists the tenant's connectors of both kinds with their status; credentials are write-only and never returned.")
    @get
    list(): Connector[] | ProblemResponse;

    @doc("Reads one connector with its status, which shows whether an OAuth authorization completed.")
    @route("/{connectorId}")
    @get
    get(...ConnectorPath): Connector | ProblemResponse;

    @doc("Renames a connector. Refused Conflict when another connector has the name.")
    @route("/{connectorId}")
    @put
    update(...ConnectorWritePath, @body body: ConnectorUpdate): Connector | ProblemResponse;

    @doc("""
      Deletes a connector and its credential. Refused ConnectorInUse (409) while a persona lists it
      or a Running turn uses it. Sessions that copied it run later turns without it. The upstream
      grant stays in place; revoke it on the provider's site.
      """)
    @route("/{connectorId}")
    @delete
    delete(...ConnectorWritePath): NoContentResponse | ProblemResponse;

    @doc("""
      Disconnects a connector for new turns: it reads Disconnected, pending authorizations are
      cancelled and new turns are refused ConnectorDisconnected. Running turns keep fetching and
      refreshing its token until they end; stopping them is the only way to cut it off sooner. The
      credential is deleted when no Running turn uses it. The upstream grant stays in place; revoke
      it on the provider's site.
      """)
    @route("/{connectorId}/credential")
    @delete
    clearCredential(...ConnectorWritePath): Connector | ProblemResponse;
  }

  @route("/static-connectors")
  interface StaticConnectors {
    @doc("Creates a static connector without a token; it reads NotConnected until setToken. Refused Conflict when another connector has the name.")
    @post
    create(@body body: StaticConnectorCreate): StaticConnector | ProblemResponse;

    @doc("Stores the connector's token sealed, replacing any earlier one, and connects it; running turns get the new token at their next fetch. Over MCP the value is never taken: use the CLI's --stdin.")
    @route("/{connectorId}/token")
    @put
    setToken(...ConnectorWritePath, @body body: StaticConnectorTokenWrite): StaticConnector | ProblemResponse;
  }

  @route("/oauth-connectors")
  interface OAuthConnectors {
    @doc("Creates an OAuth connector without a grant; it reads NotConnected until an authorization completes. Refused Conflict when another connector has the name.")
    @post
    create(@body body: OAuthConnectorCreate): OAuthConnector | ProblemResponse;

    @doc("""
      Starts an OAuth authorization: discovers the server's authorization server, registers a public
      client through dynamic client registration and answers the authorize URL to open in a browser
      within 10 minutes. The callback stores the grant, replacing any earlier one; running turns get
      the new token at their next fetch. Refused ConnectorDiscoveryFailed or
      ConnectorRegistrationUnsupported, each naming the server and the fix.
      """)
    @route("/{connectorId}/authorize")
    @post
    authorize(...ConnectorWritePath): ConnectorAuthorization | ProblemResponse;
  }

  @doc("""
    The forwarder's side of a connector. No principal signs in: the box presents the turn's
    ConnectorTurnToken from its DispatchGrant.
    """)
  @route("/turns/{turnId}/connectors/{connectorId}/token")
  interface ConnectorTokens {
    @doc("""
      Answers the connector's current access token, refreshing an OAuth grant first when fewer than
      30 seconds remain, within 15 seconds. Admits the token while the turn is Running and its
      session lists the connector, a Disconnected one included. Refused ConnectorTurnTokenRefused
      (401) for a missing or foreign token, ConnectorTurnNotRunning (409) once the turn ended, and
      ConnectorRefreshFailed (503) when the provider refused or did not answer the refresh within 10
      seconds.
      """)
    @useAuth(ConnectorTurnToken)
    @post
    fetch(...ConnectorTokenPath): ConnectorAccessToken | ProblemResponse;
  }
}
