import "@typespec/http";
import "./models.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("A build provider that runs prebuilds on the tenant's own account and bills it.")
enum BuildProvider {
  @doc("Tumpel dispatches the caller workflow in the repository, which calls Tumpel's reusable prebuild workflow.")
  GitHubActions: "GitHubActions",

  @doc("Tumpel runs the pipeline definition the repository's CircleCI project binding names, whose config imports the orb tumpel/prebuild.")
  CircleCI: "CircleCI",

  @doc("Tumpel sends the build recipe to Namespace's hosted BuildKit, which trusts the stage issuer's tokens.")
  Namespace: "Namespace",
}

@doc("An outside service the tenant links: the GitHub App, one build provider, or OpenRouter as a model provider.")
enum ConnectionKind {
  GitHub: "GitHub",
  GitHubActions: "GitHubActions",
  CircleCI: "CircleCI",
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
  account: string;
}

@doc("A Connected connection whose credential stops working within the renewal window.")
model ExpiringConnection {
  kind: ConnectionKind;
  state: ConnectionState.Expiring;
  account: string;

  @doc("When the credential stops working.")
  expiresAt: offsetDateTime;
}

@doc("A connection whose credential stopped working; prebuilds on it fail until the tenant connects again.")
model ExpiredConnection {
  kind: ConnectionKind;
  state: ConnectionState.Expired;
  account: string;

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

@doc("A workflow file of the tenant's repositories, such as .github/workflows/tumpel-prebuild.yml.")
@pattern("^\\.github/workflows/[A-Za-z0-9._-]+\\.ya?ml$")
@maxLength(200)
scalar WorkflowPath extends string;

@doc("A Namespace workspace id, such as tenant_123456789ab.")
@pattern("^tenant_[A-Za-z0-9]+$")
@maxLength(100)
scalar NamespaceWorkspaceId extends string;

@doc("The aud claim a provider requires on Tumpel's tokens, such as federation.namespaceapis.com.")
@minLength(1)
@maxLength(500)
scalar OidcAudience extends string;

@doc("""
  The tenant's GitHub Actions build provider. A prebuild dispatches the caller workflow in the
  repository, which calls Tumpel's reusable prebuild workflow; the job's upload is accepted only
  from a run of that workflow.
  """)
model GitHubActionsConnection {
  @key gitHubActionsConnectionId: EntityId;
  tenantId: EntityId;

  @doc("The account GitHub Actions bills, as the tenant names it.")
  accountLabel: DisplayName;

  @doc("The caller workflow each repository holds; the start commits or dispatches it and the job token must name it.")
  callerWorkflow: WorkflowPath;

  createdAt: int64;
  updatedAt: int64;
}

model GitHubActionsConnectionStart {
  accountLabel: DisplayName;
  callerWorkflow: WorkflowPath;
}

model GitHubActionsConnected {
  state: ConnectionState.Connected;
  connection: GitHubActionsConnection;
}

model GitHubActionsNotConnected {
  state: ConnectionState.NotConnected;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union GitHubActionsLink {
  Connected: GitHubActionsConnected,
  NotConnected: GitHubActionsNotConnected,
}

@doc("The tenant's GitHub Actions build provider connection.")
model GitHubActionsConnectionLink {
  tenantId: EntityId;
  link: GitHubActionsLink;

  @doc("The reusable workflow a caller workflow calls: tumpel/workflows/.github/workflows/prebuild.yml@v2.")
  reusableWorkflow: string;

  @doc("The caller workflow a prebuild start commits in each repository at the connection's callerWorkflow path, or at .github/workflows/tumpel-prebuild.yml while not connected, as YAML text.")
  callerWorkflowExample: string;
}

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
  issuer: url;

  @doc("The sub of a prebuild token: tenant:<tenantId>:persona:<personaName>:job:prebuild, with the prebuild's persona name.")
  subjectPattern: string;

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
  issuer: url;
  subjectPattern: string;

  @doc("The aud Tumpel defines for Namespace: federation.namespaceapis.com.")
  audience: OidcAudience;
}

@doc("The stage has no issuer hostname yet, so Namespace cannot trust its tokens; `fix` says how to deploy it.")
model NamespaceNotConfigured {
  state: ConnectionState.NotConfigured;
  detail: string;
  fix: string;
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

@doc("A CircleCI id: an organization, a project or a pipeline definition, as a lower-case UUID.")
@pattern("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
scalar CircleCIUuid extends string;

@doc("""
  A CircleCI project slug: gh/<owner>/<name> in a GitHub OAuth organization, or
  circleci/<organization id>/<project id> in a GitHub App organization.
  """)
@pattern("^(gh|github|circleci)/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
@maxLength(200)
scalar CircleCIProjectSlug extends string;

@doc("""
  The tenant's CircleCI build provider. A prebuild runs the pipeline definition of the
  repository's project binding with the tenant's personal API token, which Tumpel holds sealed and
  never answers; the job's upload is accepted only from a token of the organization's issuer.
  """)
model CircleCIConnection {
  @key circleCIConnectionId: EntityId;
  tenantId: EntityId;

  @doc("The CircleCI organization that bills the builds, as the tenant names it.")
  accountLabel: DisplayName;

  @doc("The CircleCI organization id, from Organization Settings > Overview.")
  organizationId: CircleCIUuid;

  @doc("The organization's OIDC issuer, https://oidc.circleci.com/org/<organizationId>, whose job tokens upload the layers.")
  issuer: url;

  credential: CircleCICredential;
  createdAt: int64;
  updatedAt: int64;
}

@doc("How the connection's personal API token reached Tumpel.")
enum CircleCICredentialKind {
  @doc("CircleCI issued it through its OAuth authorization with PKCE; it stops working 90 days after it was issued.")
  Authorized: "Authorized",

  @doc("A person pasted it; CircleCI does not tell Tumpel when it stops working.")
  Pasted: "Pasted",
}

model CircleCIAuthorizedCredential {
  kind: CircleCICredentialKind.Authorized;

  @doc("When the token stops working; the connection reads Expiring from 14 days before it and Expired from it.")
  expiresAt: offsetDateTime;
}

model CircleCIPastedCredential {
  kind: CircleCICredentialKind.Pasted;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union CircleCICredential {
  Authorized: CircleCIAuthorizedCredential,
  Pasted: CircleCIPastedCredential,
}

@doc("Connects CircleCI with a pasted token, the fallback to an authorization. The control plane checks the token with GET /api/v2/me and seals it; no operation answers it.")
model CircleCIConnectionStart {
  accountLabel: DisplayName;
  organizationId: CircleCIUuid;

  @doc("A personal API token of a member of the organization; CircleCI's API v2 refuses project tokens.")
  apiToken: SecretText;
}

model CircleCIConnected {
  state: ConnectionState.Connected;
  connection: CircleCIConnection;
}

model CircleCINotConnected {
  state: ConnectionState.NotConnected;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union CircleCILink {
  Connected: CircleCIConnected,
  NotConnected: CircleCINotConnected,
}

@doc("A CircleCI organization the authorized token reads, from GET /api/v2/me/collaborations.")
model CircleCIOrganization {
  organizationId: CircleCIUuid;
  name: DisplayName;

  @doc("The organization's slug, such as gh/acme or circleci/<id>.")
  slug: string;
}

@doc("Why a CircleCI authorization ended Failed. Each reason names the phase it stopped in.")
enum CircleCIAuthorizationFailureReason {
  @doc("No redirect address arrived within 10 minutes of the authorization, or no organization was chosen within 10 minutes of the token.")
  AuthorizationTimedOut: "AuthorizationTimedOut",

  @doc("CircleCI sent the person back with an error instead of a code, such as access_denied when they chose Deny.")
  AccessDenied: "AccessDenied",

  @doc("CircleCI's token endpoint refused the code: it was spent, it expired, or the verifier does not match.")
  CodeRefused: "CodeRefused",

  @doc("The token reads no CircleCI organization; in an SSO organization, the person did not authorize it at the consent screen.")
  NoOrganization: "NoOrganization",

  @doc("CircleCI answered the token exchange or the organization read with another error, or not within 10 seconds.")
  ExchangeFailed: "ExchangeFailed",
}

@doc("The phase a CircleCI authorization is in.")
enum CircleCIAuthorizationState {
  @doc("The person approves at authorizeUrl; the browser then lands on redirectUri, whose address carries the code.")
  AwaitingRedirect: "AwaitingRedirect",

  @doc("The token reads several organizations and the person picks the one that bills the builds; the token is held sealed until then.")
  ChoosingOrganization: "ChoosingOrganization",

  @doc("The CircleCI connection holds the token.")
  Completed: "Completed",

  @doc("The authorization stopped; the CircleCI connection is unchanged.")
  Failed: "Failed",
}

model CircleCIAuthorizationAwaitingRedirect {
  state: CircleCIAuthorizationState.AwaitingRedirect;

  @doc("CircleCI's consent page, with this authorization's client_id, PKCE S256 challenge and state.")
  authorizeUrl: url;

  @doc("The loopback address CircleCI sends the browser to, http://127.0.0.1:47151/circleci/callback; nothing listens there unless the tumpel CLI does.")
  redirectUri: url;

  @doc("When the redirect address must arrive by, or the authorization fails AuthorizationTimedOut.")
  redirectDueAt: offsetDateTime;
}

model CircleCIAuthorizationChoosingOrganization {
  state: CircleCIAuthorizationState.ChoosingOrganization;
  organizations: CircleCIOrganization[];

  @doc("When the organization must be chosen by, or the authorization fails AuthorizationTimedOut and the token is discarded.")
  chooseDueAt: offsetDateTime;
}

model CircleCIAuthorizationCompleted {
  state: CircleCIAuthorizationState.Completed;
  organizationId: CircleCIUuid;
  accountLabel: DisplayName;

  @doc("When the token stops working.")
  expiresAt: offsetDateTime;

  completedAt: offsetDateTime;
}

model CircleCIAuthorizationFailed {
  state: CircleCIAuthorizationState.Failed;
  reason: CircleCIAuthorizationFailureReason;

  @doc("What failed and what fixes it.")
  detail: string;

  failedAt: offsetDateTime;
}

@doc("Where a CircleCI authorization is: the consent URL while it waits for the redirect, the organizations while it waits for a choice, the organization once Completed, the reason once Failed.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union CircleCIAuthorizationStatus {
  AwaitingRedirect: CircleCIAuthorizationAwaitingRedirect,
  ChoosingOrganization: CircleCIAuthorizationChoosingOrganization,
  Completed: CircleCIAuthorizationCompleted,
  Failed: CircleCIAuthorizationFailed,
}

@doc("""
  One OAuth 2.0 authorization code flow with PKCE S256 that connects the tenant's CircleCI
  organization. The tenant's own client, registered once through CircleCI's dynamic client
  registration, sends the person to CircleCI's consent page; CircleCI sends the browser back to a
  loopback address. The verifier and the token are held sealed and never answered.
  """)
model CircleCIAuthorization {
  @key circleCIAuthorizationId: EntityId;
  tenantId: EntityId;
  principalId: EntityId;
  status: CircleCIAuthorizationStatus;
  createdAt: int64;
  updatedAt: int64;
}

@doc("The address the browser landed on after CircleCI's consent page, such as http://127.0.0.1:47151/circleci/callback?code=...&state=....")
@minLength(1)
@maxLength(4000)
scalar CircleCIRedirectedUrl extends string;

@doc("The redirect address of an authorization. Its code is spent once at CircleCI's token endpoint and never stored.")
model CircleCIAuthorizationComplete {
  circleCIAuthorizationId: EntityId;
  redirectedUrl: CircleCIRedirectedUrl;
}

@doc("The organization a ChoosingOrganization authorization connects; one its organizations lists.")
model CircleCIAuthorizationChoose {
  circleCIAuthorizationId: EntityId;
  organizationId: CircleCIUuid;
}

@doc("The tenant's CircleCI build provider connection.")
model CircleCIConnectionLink {
  tenantId: EntityId;
  link: CircleCILink;

  @doc("The orb a repository's prebuild config imports: tumpel/prebuild@1.")
  orb: string;

  @doc("The prebuild config to commit, such as .circleci/tumpel-prebuild.yml, as YAML text to copy; its pipeline definition gets no trigger.")
  configExample: string;
}

@doc("""
  Binds one repository to the CircleCI project and pipeline definition its prebuilds run. The
  pipeline definition must check out the repository.
  """)
model CircleCIProject {
  @key circleCIProjectId: EntityId;
  tenantId: EntityId;

  @doc("The repository as https://github.com/<owner>/<name> in lower case.")
  repository: RepositoryUrl;

  projectSlug: CircleCIProjectSlug;

  @doc("The CircleCI project id, read from the project at the binding.")
  projectId: CircleCIUuid;

  @doc("The pipeline definition the prebuilds run, from Project Settings > Project Setup.")
  pipelineDefinitionId: CircleCIUuid;

  createdAt: int64;
  updatedAt: int64;
}

model CircleCIProjectAdd {
  @doc("A GitHub repository, such as https://github.com/acme/app.git.")
  repository: RepositoryUrl;

  projectSlug: CircleCIProjectSlug;
  pipelineDefinitionId: CircleCIUuid;
}

model CircleCIProjectPath {
  @path circleCIProjectId: EntityId;
}
