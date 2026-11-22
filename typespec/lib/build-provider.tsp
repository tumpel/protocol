import "@typespec/http";
import "./models.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("An outside service the tenant links: the GitHub App, one build provider, or OpenRouter as a model provider.")
enum ConnectionKind {
  GitHub: "GitHub",
  Namespace: "Namespace",
  OpenRouter: "OpenRouter",
}

enum ConnectionState {
  @doc("The stage lacks what the connection needs, such as the GitHub App or an issuer hostname; the get operation of the kind names the fix.")
  NotConfigured: "NotConfigured",

  @doc("The stage is ready and the tenant has not connected its account.")
  NotConnected: "NotConnected",

  @doc("The tenant connected its account.")
  Connected: "Connected",

  @doc("The tenant connected its account and its credential stops working within the renewal window; connecting again before expiresAt replaces it.")
  Expiring: "Expiring",

  @doc("The tenant connected its account and its credential stopped working at its expiry; connecting again restores it.")
  Expired: "Expired",
}

model ConnectedConnection {
  kind: ConnectionKind;
  state: ConnectionState.Connected;

  @doc("What the connection is connected as: the GitHub logins of the tenant's installations, comma-separated, the account label the tenant gave a build provider, or for OpenRouter the names of the secret sets that hold an OpenRouter key, comma-separated, since OpenRouter's key exchange names no account.")
  account: Summary;
}

@doc("A Connected connection whose credential stops working within the renewal window.")
model ExpiringConnection {
  kind: ConnectionKind;
  state: ConnectionState.Expiring;
  account: Summary;

  @doc("When the credential stops working.")
  expiresAt: offsetDateTime;
}

@doc("A connection whose credential stopped working; prebuilds on it fail until the tenant connects again.")
model ExpiredConnection {
  kind: ConnectionKind;
  state: ConnectionState.Expired;
  account: Summary;

  @doc("When the credential stopped working.")
  expiredAt: offsetDateTime;
}

model NotConnectedConnection {
  kind: ConnectionKind;
  state: ConnectionState.NotConnected;
}

model NotConfiguredConnection {
  kind: ConnectionKind;
  state: ConnectionState.NotConfigured;
}

@doc("One connection kind of the tenant with its state, its account once connected, and the expiry of a credential that is Expiring or Expired.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union ConnectionSummary {
  Connected: ConnectedConnection,
  Expiring: ExpiringConnection,
  Expired: ExpiredConnection,
  NotConnected: NotConnectedConnection,
  NotConfigured: NotConfiguredConnection,
}

@doc("A Namespace workspace id, such as tenant_123456789ab.")
@pattern("^tenant_[A-Za-z0-9]+$")
@maxLength(100)
scalar NamespaceWorkspaceId extends string;

@doc("The aud claim a provider requires on Tumpel's tokens, such as federation.namespaceapis.com.")
@minLength(1)
@maxLength(500)
scalar OidcAudience extends string;

@doc("""
  The tenant's Namespace build provider. Namespace trusts tokens of the stage's issuer whose sub
  matches `subjectPattern` and whose aud is `audience`.
  """)
model NamespaceConnection {
  @key namespaceConnectionId: EntityId;
  tenantId: EntityId;

  @doc("The Namespace workspace that bills the builds, as the tenant names it.")
  accountLabel: DisplayName;

  @doc("The Namespace workspace the builds run in, such as tenant_123456789ab.")
  workspaceId: NamespaceWorkspaceId;

  @doc("The stage's OIDC issuer Namespace registers.")
  issuer: HttpUrl;

  @doc("The sub of a prebuild token: tenant:<tenantId>:persona:<personaName>:job:prebuild, with the prebuild's persona name.")
  subjectPattern: ShortText;

  @doc("The aud Tumpel defines for Namespace: federation.namespaceapis.com.")
  audience: OidcAudience;

  createdAt: int64;
  updatedAt: int64;
}

model NamespaceConnectionStart {
  accountLabel: DisplayName;
  workspaceId: NamespaceWorkspaceId;
}

model NamespaceConnected {
  state: ConnectionState.Connected;
  connection: NamespaceConnection;
}

@doc("The trust material to register at Namespace before connecting.")
model NamespaceNotConnected {
  state: ConnectionState.NotConnected;
  issuer: HttpUrl;
  subjectPattern: ShortText;

  @doc("The aud Tumpel defines for Namespace: federation.namespaceapis.com.")
  audience: OidcAudience;
}

@doc("The stage has no issuer hostname yet, so Namespace cannot trust its tokens; `fix` says how to deploy it.")
model NamespaceNotConfigured {
  state: ConnectionState.NotConfigured;
  detail: Detail;
  fix: Detail;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union NamespaceLink {
  Connected: NamespaceConnected,
  NotConnected: NamespaceNotConnected,
  NotConfigured: NamespaceNotConfigured,
}

@doc("The tenant's Namespace build provider connection.")
model NamespaceConnectionLink {
  tenantId: EntityId;
  link: NamespaceLink;
}
