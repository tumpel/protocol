import "@typespec/http";
import "./models.tsp";
import "./github.tsp";
import "./release.tsp";
import "./issuer.tsp";
import "./prebuild.tsp";
import "./prebuild-template.tsp";
import "./build-provider.tsp";
import "./config.tsp";
import "./claude-setup.tsp";

using TypeSpec.Http;

namespace Tumpel;

enum ProblemCode {
  InvalidRequest: "InvalidRequest",
  SignedOut: "SignedOut",
  Forbidden: "Forbidden",
  NotFound: "NotFound",
  Conflict: "Conflict",
  NotInvited: "NotInvited",
  EnrolmentTokenSpent: "EnrolmentTokenSpent",
  EnrolmentTokenExpired: "EnrolmentTokenExpired",
  HostRevoked: "HostRevoked",
  NoHostAvailable: "NoHostAvailable",
  PoolExhausted: "PoolExhausted",
  HostOffline: "HostOffline",
  HarnessNotInCatalog: "HarnessNotInCatalog",
  NoCredential: "NoCredential",
  CredentialExpired: "CredentialExpired",
  CredentialKindUnsupported: "CredentialKindUnsupported",
  TurnInFlight: "TurnInFlight",
  SessionStopping: "SessionStopping",
  SessionNotStopped: "SessionNotStopped",
  SessionArchived: "SessionArchived",
  SessionFailed: "SessionFailed",
  GitHubAppMissing: "GitHubAppMissing",

  @doc("The stage has a GitHub App and no installation of the tenant covers what was asked: the tenant holds none, or none on the repository's owner.")
  GitHubNotConnected: "GitHubNotConnected",

  @doc("The GitHub issue is closed, or the number names a pull request.")
  IssueNotOpen: "IssueNotOpen",

  @doc("The GitHub issue does not exist or was deleted.")
  IssueNotFound: "IssueNotFound",

  NoRelease: "NoRelease",

  @doc("The current.json in the release bucket is not JSON, does not match ReleaseManifest, or repeats an architecture or image; the detail names the problem.")
  ReleaseUnreadable: "ReleaseUnreadable",
  TranscriptLineUnreadable: "TranscriptLineUnreadable",

  @doc("The current release carries no guest image of the harness version for any architecture of the tenant's hosts, or the published release is unreadable; the detail names which.")
  ImageNotReleased: "ImageNotReleased",
  NoBuildProvider: "NoBuildProvider",

  @doc("The named build provider is connected, and this control plane cannot dispatch to it yet.")
  BuildProviderUnavailable: "BuildProviderUnavailable",

  @doc("The build provider refused the job: GitHub refused the installation token or the workflow dispatch, Actions are disabled in the repository, or CircleCI refused the pipeline; the title names the cause and the detail names the answer.")
  DispatchRefused: "DispatchRefused",

  @doc("The GitHub App installation lacks a write permission the operation needs; the detail names it and the fix says how to accept it on GitHub.")
  GitHubAppPermissionMissing: "GitHubAppPermissionMissing",

  @doc("GitHub refused to add or update the caller workflow on the default branch.")
  CallerWorkflowRefused: "CallerWorkflowRefused",

  RepositoryUnreadable: "RepositoryUnreadable",

  @doc("GitHub did not answer the one-time read of the account type of an installation linked before the control plane stored account types; the detail quotes GitHub.")
  GitHubInstallationUnreadable: "GitHubInstallationUnreadable",

  IssuerMissing: "IssuerMissing",

  @doc("The build job token is missing, malformed, unsigned by GitHub Actions, meant for another audience, expired or not yet valid; the title names the check.")
  JobTokenRefused: "JobTokenRefused",

  @doc("The build job token is genuine and names another repository, workflow, ref or event than the prebuild and its connection; the title names the check.")
  JobTokenMismatch: "JobTokenMismatch",

  @doc("The prebuild is not Building: its build has not started, or it is past its upload.")
  PrebuildNotUploading: "PrebuildNotUploading",

  @doc("CircleCI refused the personal API token: it is mistyped, expired or revoked, or a project token.")
  CircleCITokenRefused: "CircleCITokenRefused",

  @doc("The repository has no CircleCI project binding, or the project slug names no project the token reads in the connected organization.")
  CircleCIProjectMissing: "CircleCIProjectMissing",

  @doc("The pipeline definition does not exist in the project or checks out another repository than the binding names.")
  CircleCIDefinitionMismatch: "CircleCIDefinitionMismatch",

  @doc("CircleCI answered a call the operation makes, such as registering or deleting a webhook, with an error; the detail names the call and the answer.")
  CircleCIRefused: "CircleCIRefused",

  @doc("The CircleCI authorization is not in the phase the operation needs, such as a redirect address sent twice or after the authorization ended.")
  CircleCIAuthorizationNotWaiting: "CircleCIAuthorizationNotWaiting",

  @doc("The completion finds no layer at the key its upload exchange signed.")
  LayerNotUploaded: "LayerNotUploaded",

  @doc("Only an Owner of the tenant runs this operation.")
  OwnerRequired: "OwnerRequired",

  @doc("The operation would leave the tenant without an Owner.")
  LastOwner: "LastOwner",

  InvitationExpired: "InvitationExpired",

  @doc("The afterEventId of an events read is older than the oldest event the log keeps.")
  EventCursorExpired: "EventCursorExpired",

  @doc("No host of the tenant is Online with a free box slot and a guest image of the pinned Claude Code for its architecture.")
  NoHostOnline: "NoHostOnline",

  @doc("The Claude setup is not in the state the operation needs, such as a code sent twice or after the setup ended.")
  ClaudeSetupNotWaiting: "ClaudeSetupNotWaiting",

  @doc("The setup box token is missing, unknown, spent or meant for another setup.")
  ClaudeSetupBoxTokenRefused: "ClaudeSetupBoxTokenRefused",

  @doc("A control plane deploy is draining running turns, so no new session or turn starts until it ends.")
  DeployInProgress: "DeployInProgress",

  @doc("The bearer is not the drainToken of the deploy drain in place.")
  DeployDrainTokenRefused: "DeployDrainTokenRefused",

  @doc("The metric query covers more than 500 buckets, or Minute buckets older than 8 days; the fix names a range that fits.")
  MetricRangeTooLarge: "MetricRangeTooLarge",

  @doc("The tenant's metrics store has no metric of that name.")
  MetricNotFound: "MetricNotFound",

  @doc("No shipped template has that id, or the template has no such version; the detail lists the valid ones.")
  PrebuildTemplateNotFound: "PrebuildTemplateNotFound",

  @doc("The repository's default branch holds neither .devcontainer/devcontainer.json nor .devcontainer.json; the fix names the templates.")
  DevcontainerMissing: "DevcontainerMissing",

  @doc("The repository's default branch already holds a devcontainer.json and the request does not ask to replace it; the detail names the file.")
  DevcontainerExists: "DevcontainerExists",

  @doc("GitHub refused a call the operation makes, such as creating a branch or a pull request; the detail quotes GitHub's message.")
  GitHubRefused: "GitHubRefused",

  @doc("A persona lists the connector or a Running turn uses it; the detail names them.")
  ConnectorInUse: "ConnectorInUse",

  @doc("The connector changed after the caller read it: the request's updatedAt is not the stored one. Read the connector again and send the write with its updatedAt.")
  ConnectorChanged: "ConnectorChanged",

  @doc("The connector's protected-resource or authorization-server metadata could not be read within 10 seconds, or named a non-HTTPS, private or loopback address, or no S256 support; the detail names the server.")
  ConnectorDiscoveryFailed: "ConnectorDiscoveryFailed",

  @doc("The connector's authorization server advertises no dynamic client registration endpoint, or refused the registration; connect it with a static token if the server takes one.")
  ConnectorRegistrationUnsupported: "ConnectorRegistrationUnsupported",

  @doc("The session's persona lists a connector that is Disconnected, NotConnected or AuthorizationFailed; reconnect it, or choose a persona without it.")
  ConnectorDisconnected: "ConnectorDisconnected",

  @doc("The connector's provider refused the refresh or did not answer within 10 seconds; the tool call failed and the turn goes on. On invalid_grant the connector reads AuthorizationFailed until an Owner authorizes it again.")
  ConnectorRefreshFailed: "ConnectorRefreshFailed",

  @doc("The box asked for a connector while its turn is not Running.")
  ConnectorTurnNotRunning: "ConnectorTurnNotRunning",

  @doc("The ConnectorTurnToken is missing, or does not name this tenant, turn and connector.")
  ConnectorTurnTokenRefused: "ConnectorTurnTokenRefused",

  @doc("The connector's server answered 401 or 403, or its token expired with no refresh token; the tool call failed and the turn goes on. Reconnect the connector.")
  ConnectorAuthRefused: "ConnectorAuthRefused",

  @doc("The connector's server could not be reached, or sent no first byte within 10 seconds; the tool call failed and the turn goes on.")
  ConnectorUnreachable: "ConnectorUnreachable",
}

@doc("Every refusal: what failed and what fixes it.")
model Problem {
  code: ProblemCode;
  title: string;
  detail: string;
  fix: string;
}

@error
model ProblemResponse {
  @statusCode statusCode: 400 | 401 | 403 | 404 | 409 | 410 | 422 | 429 | 503;
  @body body: Problem;
}

model SessionPath {
  @path sessionId: EntityId;
}

model TurnPath {
  @path turnId: EntityId;
}

model HostPath {
  @path hostId: EntityId;
}

model DevicePath {
  @path deviceId: EntityId;
}

model EnrolmentTokenPath {
  @path enrolmentTokenId: EntityId;
}

model OAuthGrantPath {
  @path grantId: EntityId;
}

model SnapshotPath {
  @path snapshotId: EntityId;
}

model PersonaPath {
  @path personaId: EntityId;
}

model MemberPath {
  @path principalId: EntityId;
}

model InvitationPath {
  @path invitationId: EntityId;
}

model SecretSetPath {
  @path secretSetId: EntityId;
}

model SecretMemberPath {
  ...SecretSetPath;
  @path name: SecretName;
}

model GitHubInstallationPath {
  @path installationId: GitHubId;
}

model GitHubRepositoryPath {
  @path owner: GitHubLogin;
  @path name: GitHubRepositoryName;
}

model HarnessPath {
  @path harness: Harness;
}

model GitHubInstallStartQuery {
  @doc("A page on the dashboard's origin the browser returns to once GitHub sends the installer back.")
  @query
  returnUrl?: url;

  @doc("The GitHub account to install on; GitHub then opens on that account instead of asking which one.")
  @query
  gitHubAccountId?: GitHubId;
}

model SignUp is Create<Tenant> {}

model Whoami {
  tenant: Tenant;
  principal: Principal;
}

@doc("The tenant and principal the caller acts as, and the origin of the API that answered, which every path of the API is relative to.")
model WhoamiWithEndpoint {
  ...Whoami;
  endpoint: url;
}

@doc("The OAuth error codes of RFC 6749, RFC 7591, RFC 8628 and RFC 8707 the control plane answers with.")
enum OAuthErrorCode {
  InvalidRequest: "invalid_request",
  InvalidClient: "invalid_client",
  InvalidGrant: "invalid_grant",
  UnsupportedGrantType: "unsupported_grant_type",
  UnsupportedResponseType: "unsupported_response_type",
  InvalidTarget: "invalid_target",
  InvalidClientMetadata: "invalid_client_metadata",
  InvalidRedirectUri: "invalid_redirect_uri",
  AuthorizationPending: "authorization_pending",
  SlowDown: "slow_down",
  AccessDenied: "access_denied",
  ExpiredToken: "expired_token",
}

@doc("An OAuth refusal, in the wire shape RFC 6749 gives it, so stock OAuth and device-flow clients read it.")
model OAuthError {
  error: OAuthErrorCode;
  error_description: string;
}

@error
model OAuthErrorResponse {
  @statusCode statusCode: 400 | 405 | 429;
  @body body: OAuthError;
}

model DeviceCodeRequest {
  device_name: DisplayName;
}

@doc("RFC 8628 device authorization, in its snake_case wire shape.")
model DeviceAuthorization {
  device_code: string;
  user_code: string;
  verification_uri: url;
  verification_uri_complete: url;
  @minValue(1) expires_in: int32;
  @minValue(1) interval: int32;
}

@doc("A user code the signed-in principal approves or denies, as the terminal printed it.")
model DeviceDecision {
  userCode: string;
}

@doc("A user code the signed-in principal approves, and the tenant of theirs the device acts in.")
model DeviceApproval {
  userCode: string;
  tenantId: EntityId;
}

model InvitationCreate is Create<Invitation>;

@doc("""
  A new invitation. `acceptUrl` carries the signed, single-use token and is shown here once: the
  control plane sends no email, so pass the link to the invitee yourself.
  """)
model InvitationCreated {
  invitation: Invitation;
  acceptUrl: url;
}

@doc("The token of an invitation's accept link.")
model InvitationAccept {
  @minLength(1) token: string;
}

model DeviceTokenRequest {
  grant_type: "urn:ietf:params:oauth:grant-type:device_code";
  device_code: string;
}

model DeviceToken {
  access_token: string;
  token_type: "Bearer";
}

@doc("RFC 9728 metadata for the hosted MCP endpoint.")
model ProtectedResourceMetadata {
  resource: url;
  authorization_servers: url[];
  scopes_supported: string[];
  bearer_methods_supported: string[];
  resource_name: string;
}

@doc("RFC 8414 metadata for the control plane's OAuth authorization server.")
model AuthorizationServerMetadata {
  issuer: url;
  authorization_endpoint: url;
  token_endpoint: url;
  revocation_endpoint: url;
  registration_endpoint: url;
  scopes_supported: string[];
  response_types_supported: string[];
  response_modes_supported: string[];
  grant_types_supported: string[];
  token_endpoint_auth_methods_supported: string[];
  code_challenge_methods_supported: string[];
  authorization_response_iss_parameter_supported: boolean;
  resource_indicators_supported: boolean;
}

@doc("RFC 7591 dynamic client registration. Only the redirect addresses and the name are read.")
model OAuthClientRegistration {
  @minItems(1) @maxItems(10) redirect_uris: url[];
  client_name?: string;
}

model OAuthClient {
  client_id: string;
  client_id_issued_at: int64;
  client_name: string;
  redirect_uris: url[];
  grant_types: string[];
  response_types: string[];
  token_endpoint_auth_method: "none";
  scope: string;
}

model OAuthClientRegistered {
  @statusCode statusCode: 201;
  @body body: OAuthClient;
}

model OAuthAuthorizeQuery {
  @query response_type: string;
  @query client_id: string;
  @query redirect_uri?: string;
  @query state?: string;
  @query code_challenge: string;
  @query code_challenge_method: string;
  @query resource?: string;
}

@doc("Where the browser goes next: the consent page, or the client's callback carrying an error.")
model SeeOther {
  @statusCode statusCode: 303;
  @header location: string;
}

@doc("An RFC 6749 authorization code redemption, with the PKCE verifier and the RFC 8707 resource.")
model OAuthAuthorizationCodeRequest {
  grant_type: "authorization_code";
  client_id: string;
  code: string;
  code_verifier: string;
  redirect_uri: string;
  resource?: string;
}

@doc("An RFC 6749 refresh, which spends the refresh token and issues a new pair.")
model OAuthRefreshTokenRequest {
  grant_type: "refresh_token";
  client_id: string;
  refresh_token: string;
  resource?: string;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "grant_type" })
union OAuthTokenRequest {
  authorization_code: OAuthAuthorizationCodeRequest,
  refresh_token: OAuthRefreshTokenRequest,
}

model OAuthToken {
  access_token: string;
  token_type: "Bearer";
  expires_in: int32;
  refresh_token: string;
  scope: string;
}

@doc("An RFC 7009 revocation by a public client: the token and every token of its grant stop working. An unknown token is answered as revoked.")
model OAuthRevocationRequest {
  token: string;
  client_id: string;
  token_type_hint?: string;
}

model OAuthRevoked {
  @statusCode statusCode: 200;
}

model EnrolmentTokenMint {
  @minValue(60) @maxValue(86400) expiresInSeconds: int32;
}

@doc("A freshly minted enrolment token. `token` is shown here once and never again.")
model MintedEnrolmentToken {
  enrolmentToken: EnrolmentToken;
  token: string;

  @doc("Downloads, installs and enrols the supervisor on a new host. It holds no token: it reads `token` from stdin.")
  installCommand: string;
}

model HostEnrol is Create<Host> {
  @minLength(1) enrolmentToken: string;
}

@doc("Replaces every label of a host.")
model HostLabels {
  labels: HostLabel[];
}

model SessionStart is Create<Session> {
  prompt: Prompt;
  @doc("What happens to the box after each turn; left out, the session takes its persona's boxRetention.")
  boxRetention?: BoxRetention;
}

@doc("A start from an open GitHub issue: the control plane reads the issue and writes the first prompt, which asks for the branch ticket/<issueNumber>-<slug of the title> and a draft pull request that closes the issue.")
model SessionStartFromIssue {
  personaId: EntityId;
  owner: GitHubLogin;
  name: GitHubRepositoryName;
  issueNumber: GitHubIssueNumber;
  `model`: ModelName;
  @doc("What happens to the box after each turn; left out, the session takes its persona's boxRetention.")
  boxRetention?: BoxRetention;
}

@doc("The answer to a start, sent before the harness writes anything.")
model StartedSession {
  session: Session;
  turn: Turn;
}

@doc("The answer to a start from an issue: the start's answer and the issue the session works.")
model StartedSessionFromIssue {
  ...StartedSession;
  issue: SessionIssue;
}

model SessionListQuery {
  @query state?: SessionState;
  @query hostId?: EntityId;

  @doc("Keep only the sessions whose latest turn last changed state at or before this time.")
  @query
  lastTurnBefore?: offsetDateTime;
}

model SessionStopQuery {
  @doc("""
    Also end the turn in flight at once: it fails Cancelled, the host stops its harness, then
    snapshots and frees the box as a plain stop does. Left out, a stop is refused while a turn is in flight.
    """)
  @query
  cancelTurn?: boolean;
}

model TurnSend is Create<TurnBase>;

model MetricWindow {
  @doc("The start of the window; Day buckets start at midnight in its offset, and every answered time is in its offset.")
  @query
  from: offsetDateTime;

  @doc("The end of the window, after `from`.")
  @query
  to: offsetDateTime;

  @doc("dimension:value; one key repeated is OR, different keys AND")
  @query(#{ explode: true })
  filter?: string[];
}

model MetricPath {
  @path metric: MetricName;
}

model MetricSeriesQuery {
  ...MetricWindow;
  @query bucket: MetricBucket;

  @doc("Up to two dimensions to group the series by; left out, every series merges into one.")
  @query(#{ explode: true })
  @maxItems(2)
  groupBy?: string[];
}

model MetricTurnQuery {
  ...MetricWindow;

  @doc("Read the points of this session alone.")
  @query
  sessionId?: EntityId;

  @doc("The cursor of the previous page; leave it out to read from `from`.")
  @query
  cursor?: string;
}

model TurnWaitQuery {
  @doc("A turn to wait on; repeat it to wait on several turns of any of the tenant's sessions.")
  @query(#{ explode: true })
  @minItems(1)
  @maxItems(50)
  turnId: EntityId[];

  @doc("The most seconds to wait for one of the turns to end.")
  @query
  @minValue(0)
  @maxValue(50)
  timeoutSeconds: int32;
}

model TranscriptQuery {
  @doc("The cursor of an earlier page: the lineSeq after which this page starts. Leave it out to read from the first line.")
  @query
  after?: Sequence;

  @doc("Read the lines of this turn alone.")
  @query
  turnId?: EntityId;

  @doc("The most lines the page holds, counting kept lines on a compact page. Left out, a raw page holds up to the transcript chunk size and a compact page has no line cap. A page reads on across stored chunks until it holds `limit` lines, reaches `maxBytes` or reaches the last line.")
  @query
  @minValue(1)
  @maxValue(1000)
  limit?: int32;

  @doc("The most bytes the page holds, cut on a line boundary; 32768 when left out. A raw page counts the stored JSONL lines it reads, a compact page the text it returns. A page always holds at least one line.")
  @query
  @minValue(1)
  @maxValue(1048576)
  maxBytes?: int32;

  @doc("Keep the text the assistant wrote, shorten each tool call to one line naming the tool and its first argument, keep one line per token, cost or error report Codex, OpenCode and PiDev write, and drop tool results and every other line. Only a session whose harness has compactTranscript in the harness catalog accepts it, and a line that is not JSON refuses the read with TranscriptLineUnreadable. Dropped lines still advance the cursor, and a compact page reads on past them, up to 8 reads of transcriptChunkLines lines each, until it holds `limit` lines, reaches `maxBytes` or reaches the last line; a page that reaches 8 reads answers with the lines it holds, none when every line it read was dropped, and moves the cursor on.")
  @query
  compact?: boolean;
}

@doc("""
  A page of a session's transcript: Raw holds the stored lines, Compact (a read with compact) the
  kept text grouped by turn. `cursor` is the lineSeq the page read up to, dropped lines included,
  or the `after` the read passed when nothing was read; pass it as `after` to read on.
  `finished` is true when no turn is in flight and no line follows `cursor`.
  """)
@discriminated(#{ envelope: "none", discriminatorPropertyName: "form" })
union TranscriptPage {
  Raw: RawTranscriptPage,
  Compact: CompactTranscriptPage,
}

@doc("A page of a session's harness-native JSONL lines.")
model RawTranscriptPage {
  form: "Raw";
  sessionState: SessionState;
  lines: TranscriptLine[];
  cursor: Sequence;
  finished: boolean;
}

@doc("A page of a session's compact transcript: the session named once, and each turn once above its kept lines.")
model CompactTranscriptPage {
  form: "Compact";
  sessionId: EntityId;
  sessionState: SessionState;
  turns: CompactTranscriptTurn[];
  cursor: Sequence;
  finished: boolean;
}

@doc("The kept lines of one turn on a compact page, in order.")
model CompactTranscriptTurn {
  turnId: EntityId;
  lines: CompactTranscriptLine[];
}

@doc("One kept line of a compact page: assistant text, or a tool call shortened to one line.")
model CompactTranscriptLine {
  lineSeq: Sequence;
  text: string;
}

@doc("A new persona with its whole file set: at most PersonaFileLimit.PersonaBytes together, each at a path its harness accepts.")
model PersonaCreate is Create<Persona> {
  @doc("The persona's files; none when left out.")
  files?: PersonaFileWrite[];

  @doc("What happens to the box after each turn; left out, the persona's sessions get Auto.")
  boxRetention?: BoxRetention;
}

@doc("Replaces the persona's name, secret set, connectors, box memory, box retention and whole file set: a file the update leaves out is deleted, a box memory it leaves out goes back to BoxMemoryLimit.DefaultMib, and a box retention it leaves out goes back to Auto. The harness is fixed at create.")
model PersonaUpdate is Update<Persona> {
  files: PersonaFileWrite[];
  @doc("What happens to the box after each turn; left out, the persona's sessions get Auto.")
  boxRetention?: BoxRetention;
}

enum PersonaFilePatchKind {
  @doc("Adds the file, or replaces the file at its path.")
  Put: "Put",

  @doc("Deletes the file at the path.")
  Remove: "Remove",

  @doc("Replaces the one occurrence of oldText in the file at the path with newText.")
  Edit: "Edit",
}

model PutPersonaFilePatch {
  kind: PersonaFilePatchKind.Put;
  file: PersonaFileWrite;
}

model RemovePersonaFilePatch {
  kind: PersonaFilePatchKind.Remove;
  path: PersonaFilePath;
}

model EditPersonaFilePatch {
  kind: PersonaFilePatchKind.Edit;
  path: PersonaFilePath;
  @minLength(1) oldText: string;
  newText: string;
}

@doc("One change to one file of a persona; every other file is left as it is.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union PersonaFilePatch {
  Put: PutPersonaFilePatch,
  Remove: RemovePersonaFilePatch,
  Edit: EditPersonaFilePatch,
}

@doc("Asks for a presigned upload of one persona file larger than PersonaFileLimit.InlineFileBytes, named by the sha256 of its bytes.")
model PersonaFileUploadRequest {
  digest: Sha256Digest;
  sizeBytes: PersonaFileSize;
}

@doc("""
  Where to PUT the file's bytes: `uploadUrl` is a presigned PUT of the blob stored under `digest`
  alone, valid until `uploadExpiresAt`. Once uploaded, name the file in a persona write as a
  Stored file with this digest and size; the control plane checks the stored object before it
  accepts the write.
  """)
model PersonaFileUpload {
  digest: Sha256Digest;
  sizeBytes: PersonaFileSize;
  uploadUrl: url;
  uploadExpiresAt: offsetDateTime;
}

model HarnessPinCreate is Create<HarnessPin>;

model SecretSetCreate is Create<SecretSet> {
  secrets: SecretValue[];
}

@doc("""
  Sets the set's name and its list of members. A member the update leaves out is deleted with its
  value. A member sent without a value keeps the value stored under its previousName, or under its
  name when it is not renamed.
  """)
model SecretSetUpdate is Update<SecretSet> {
  secrets: SecretMemberUpdate[];
}

@route("/healthz")
@useAuth(NoAuth)
@get
op health(): Health;

@route("/.well-known")
namespace WellKnown {
  @route("/oauth-protected-resource")
  @useAuth(NoAuth)
  @get
  op protectedResource(): ProtectedResourceMetadata;

  @route("/oauth-protected-resource/mcp")
  @useAuth(NoAuth)
  @get
  op protectedResourceForMcp(): ProtectedResourceMetadata;

  @route("/oauth-authorization-server")
  @useAuth(NoAuth)
  @get
  op authorizationServer(): AuthorizationServerMetadata;

  @route("/oauth-authorization-server/mcp")
  @useAuth(NoAuth)
  @get
  op authorizationServerForMcp(): AuthorizationServerMetadata;

  @doc("The issuer discovery document; answers on the issuer hostname only.")
  @route("/openid-configuration")
  @useAuth(NoAuth)
  @get
  op openIdConfiguration(): OpenIdConfiguration;

  @doc("The issuer public keys; answers on the issuer hostname only.")
  @route("/jwks.json")
  @useAuth(NoAuth)
  @get
  op jwks(): IssuerJwks;
}

@doc("The OAuth 2.1 surface a web MCP client walks to reach the hosted MCP endpoint, copied from an earlier hosted MCP service.")
@route("/oauth")
namespace OAuth {
  @route("/register")
  @useAuth(NoAuth)
  @post
  op register(@body body: OAuthClientRegistration): OAuthClientRegistered | OAuthErrorResponse;

  @doc("Judges the authorization request and sends the browser on to the consent page behind the identity proxy.")
  @route("/authorize")
  @useAuth(NoAuth)
  @get
  op authorize(...OAuthAuthorizeQuery): SeeOther | ProblemResponse;

  @route("/token")
  @useAuth(NoAuth)
  @post
  op token(
    @header contentType: "application/x-www-form-urlencoded",
    @body body: OAuthTokenRequest,
  ): OAuthToken | OAuthErrorResponse;

  @route("/revoke")
  @useAuth(NoAuth)
  @post
  op revoke(
    @header contentType: "application/x-www-form-urlencoded",
    @body body: OAuthRevocationRequest,
  ): OAuthRevoked | OAuthErrorResponse;
}

@route("/v1")
namespace V1 {
  @route("/tenants")
  interface Tenants {
    @doc("""
      Creates a tenant with the signed-in identity as its Owner, and its default persona. A person
      who already owns a tenant with that name gets that tenant back, so a repeated or concurrent
      sign-up of one name creates one tenant; another name creates another tenant.
      """)
    @useAuth(IdentityAssertion)
    @post
    signUp(@body body: SignUp): Whoami | ProblemResponse;
  }

  @route("/whoami")
  interface Identity {
    @doc("Names the tenant and principal the caller acts as, and the API origin that answered.")
    @get
    whoami(): WhoamiWithEndpoint | ProblemResponse;

    @doc("""
      Lists every tenant the caller's principal belongs to, with its role there. A token acts in
      one tenant; to act in another, sign in again and choose it on the device or consent page.
      """)
    @route("/tenants")
    @get
    listTenants(): Membership[] | ProblemResponse;
  }

  @route("/members")
  interface Members {
    @doc("Lists the principals of the tenant with their roles there.")
    @get
    list(): Principal[] | ProblemResponse;

    @doc("""
      Removes a principal from the tenant and signs out its devices and tokens there. Owner only;
      refused LastOwner when it would leave the tenant without an Owner.
      """)
    @route("/{principalId}")
    @delete
    remove(...MemberPath): NoContentResponse | ProblemResponse;
  }

  @route("/invitations")
  interface Invitations {
    @doc("""
      Invites an email to the tenant in a role for seven days. Owner only. Answers the accept link
      once; no email is sent.
      """)
    @post
    create(@body body: InvitationCreate): InvitationCreated | ProblemResponse;

    @doc("Lists the tenant's open invitations.")
    @get
    list(): Invitation[] | ProblemResponse;

    @doc("Revokes an open invitation; its link stops working. Owner only.")
    @route("/{invitationId}")
    @delete
    revoke(...InvitationPath): NoContentResponse | ProblemResponse;

    @doc("""
      Accepts an invitation as the signed-in email, from the accept page: creates the principal
      when the email has none and its membership of the tenant, and spends the invitation.
      """)
    @useAuth(IdentityAssertion)
    @route("/accept")
    @post
    accept(@body body: InvitationAccept): Whoami | ProblemResponse;
  }

  @route("/device")
  interface DeviceFlow {
    @route("/code")
    @useAuth(NoAuth)
    @post
    start(@body body: DeviceCodeRequest): DeviceAuthorization | OAuthErrorResponse;

    @doc("Approves a user code for the signed-in principal in one of its tenants, from the browser; the device acts in that tenant.")
    @useAuth(IdentityAssertion)
    @route("/approve")
    @post
    approve(@body body: DeviceApproval): Device | ProblemResponse;

    @doc("Denies a user code for the signed-in principal, from the browser. The code is deleted and its terminal is refused.")
    @useAuth(IdentityAssertion)
    @route("/deny")
    @post
    deny(@body body: DeviceDecision): NoContentResponse | ProblemResponse;

    @route("/token")
    @useAuth(NoAuth)
    @post
    token(@body body: DeviceTokenRequest): DeviceToken | OAuthErrorResponse;
  }

  @route("/devices")
  interface Devices {
    @doc("Lists the devices signed in as the caller.")
    @get
    list(): Device[] | ProblemResponse;

    @doc("Signs a device out; its token stops working at once.")
    @route("/{deviceId}")
    @delete
    revoke(...DevicePath): NoContentResponse | ProblemResponse;
  }

  @route("/enrolment-tokens")
  interface EnrolmentTokens {
    @doc("""
      Mints a one-time enrolment token for a new host; expiresInSeconds is how long it enrols one.
      The token is shown once; save it on the host in the file the install command names.
      """)
    @post
    mint(@body body: EnrolmentTokenMint): MintedEnrolmentToken | ProblemResponse;

    @doc("Lists the tenant's enrolment tokens that are unused and unexpired, without their token values.")
    @get
    list(): EnrolmentToken[] | ProblemResponse;

    @doc("Revokes an unused enrolment token; no host can enrol with it.")
    @route("/{enrolmentTokenId}")
    @delete
    revoke(...EnrolmentTokenPath): NoContentResponse | ProblemResponse;
  }

  @route("/hosts")
  interface Hosts {
    @doc("Enrols a host with a one-time enrolment token, which this spends.")
    @route("/enrol")
    @useAuth(NoAuth)
    @post
    enrol(@body body: HostEnrol): Host | ProblemResponse;

    @doc("Lists the tenant's hosts with their presence: Enrolled, Online, Offline or Revoked.")
    @get
    list(): Host[] | ProblemResponse;

    @doc("Lists the box slots, running and warm boxes, load and available memory of each of the tenant's hosts that has connected since it enrolled and is not revoked.")
    @route("/usage")
    @get
    listUsage(): ReportedHostUsage[] | ProblemResponse;

    @doc("Reads one host with its presence and labels.")
    @route("/{hostId}")
    @get
    get(...HostPath): Host | ProblemResponse;

    @doc("Revokes a host: its channel closes and it cannot connect again.")
    @route("/{hostId}/revoke")
    @post
    revoke(...HostPath): Host | ProblemResponse;

    @doc("Replaces every label of a host.")
    @route("/{hostId}/labels")
    @put
    setLabels(...HostPath, @body body: HostLabels): Host | ProblemResponse;
  }

  @route("/releases")
  interface Releases {
    @doc("Reads the current release: its version, commit, channel protocol version, supervisor binaries, CLI binaries and guest images.")
    @route("/current")
    @useAuth(NoAuth)
    @get
    current(): ReleaseManifest | ProblemResponse;

    @doc("Redirects to the current release's supervisor binary for one architecture, so a fresh host downloads it with the endpoint alone.")
    @route("/supervisor/{architecture}")
    @useAuth(NoAuth)
    @get
    supervisor(...ReleaseSupervisorPath): SupervisorDownload | ProblemResponse;

    @doc("Redirects to the current release's tumpel CLI binary for one architecture, so a client downloads the CLI that matches the deployed release.")
    @route("/cli/{architecture}")
    @useAuth(NoAuth)
    @get
    cli(...ReleaseCliPath): CliDownload | ProblemResponse;

    @doc("Serves the script that installs the current release's tumpel CLI, so a person installs it with one command piped to sh.")
    @route("/install.sh")
    @useAuth(NoAuth)
    @get
    install(): CliInstallScript | ProblemResponse;

    @doc("""
      Reads the rollout while a deploy drains: the commit the control plane was deployed from and the
      hosts with turns Offered or Running. Refused NotFound (404) when no deploy drain is in place, and
      DeployDrainTokenRefused (401) when the bearer is not its drainToken.
      """)
    @route("/rollout")
    @useAuth(DeployDrainToken)
    @get
    rollout(): ReleaseRollout | ProblemResponse;
  }

  @route("/sessions")
  interface Sessions {
    @doc("Starts a session with its first prompt on the online host of the tenant with the most free box slots, then the most memory available. A slot is free when no running turn and no held box takes it; an Auto box that waits idle frees its slot for placement. When no host has a free slot, the start evicts the least recently used Auto box on one host until the new box fits there, and it refuses PoolExhausted when nothing frees room. The session runs its persona's harness at the pinned version, with the persona's files and secret set. Answers before the harness writes anything.")
    @post
    start(@body body: SessionStart): StartedSession | ProblemResponse;

    @doc("""
      Starts a session from an open issue of a GitHub repository, as start does, with the first prompt
      the control plane writes from the issue's number, title, URL and body. The answer names the
      issue and the branch the prompt asks for. Reads the issue with the token a turn on the
      repository gets; refused IssueNotFound when the issue is missing, IssueNotOpen when it is closed or
      a pull request, and RepositoryUnreadable when no token reads it.
      """)
    @route("/from-issue")
    @post
    startFromIssue(@body body: SessionStartFromIssue): StartedSessionFromIssue | ProblemResponse;

    @doc("Lists the tenant's sessions, optionally only those in one state, on one host or with no turn since a time.")
    @get
    list(...SessionListQuery): Session[] | ProblemResponse;

    @doc("Reads one session; its state is Starting, Idle, Running, Stopping, Stopped, Failed or Archived.")
    @route("/{sessionId}")
    @get
    get(...SessionPath): Session | ProblemResponse;

    @doc("""
      Stops a session: its host snapshots the session and tears its box down, and the next send boots
      a fresh box from the snapshots. Answers Stopping before the box is gone; refused TurnInFlight
      while a turn is in flight unless cancelTurn is true, which fails that turn Cancelled first, and
      refused while the session's host is offline.
      """)
    @route("/{sessionId}/stop")
    @post
    stop(...SessionPath, ...SessionStopQuery): Session | ProblemResponse;

    @doc("""
      Archives an idle, stopped or failed session: discards an idle session's box without a snapshot,
      deletes its snapshots, keeps its transcript readable and refuses every later send. An archive is
      final, and archiving an archived session answers it as it is. Refused SessionNotStopped while a
      turn runs or the session stops, and HostOffline when an idle session's host is offline.
      """)
    @route("/{sessionId}/archive")
    @post
    archive(...SessionPath): Session | ProblemResponse;

    @doc("Lists the credential handovers of a session, oldest first: which variables each turn offer carried, never their values.")
    @route("/{sessionId}/credential-handovers")
    @get
    listCredentialHandovers(...SessionPath): CredentialHandover[] | ProblemResponse;

    @doc("Lists the stops of a session that failed, oldest first; each returned the session to Idle with its box kept.")
    @route("/{sessionId}/stop-failures")
    @get
    listStopFailures(...SessionPath): StopFailure[] | ProblemResponse;
  }

  interface Turns {
    @doc("Sends a session its next prompt; answers before any output, and refuses while another turn of the session is in flight. When the session's host is offline, the turn boots on another online host of the tenant if the snapshots hold the last completed turn, and is refused HostOffline, naming the turns they miss, if not.")
    @route("/sessions/{sessionId}/turns")
    @post
    send(...SessionPath, @body body: TurnSend): Turn | ProblemResponse;

    @doc("Lists a session's turns, oldest first.")
    @route("/sessions/{sessionId}/turns")
    @get
    list(...SessionPath): Turn[] | ProblemResponse;

    @doc("""
      Waits until one of the turns is Completed or Failed, or until timeoutSeconds pass, then reads
      every turn in the order asked; answers at once when one has already ended. Refused NotFound,
      naming the turn, when a turnId names no turn of the tenant.
      """)
    @route("/turns/wait")
    @get
    wait(...TurnWaitQuery): Turn[] | ProblemResponse;

    @doc("Reads one turn; its state is Offered, Running, Completed or Failed.")
    @route("/turns/{turnId}")
    @get
    get(...TurnPath): Turn | ProblemResponse;

    @doc("Reads why a Failed turn failed.")
    @route("/turns/{turnId}/failure")
    @get
    getFailure(...TurnPath): TurnFailure | ProblemResponse;
  }

  interface Transcripts {
    @doc("""
      Reads a page of a session's harness-native JSONL transcript; turnId keeps one turn's lines.
      Pass the cursor of the previous page as after to read on; an empty page means nothing new.
      """)
    @route("/sessions/{sessionId}/transcript")
    @get
    read(...SessionPath, ...TranscriptQuery): TranscriptPage | ProblemResponse;
  }

  interface Snapshots {
    @doc("Lists a session's snapshots in order, each stored or failed with its reason.")
    @route("/sessions/{sessionId}/snapshots")
    @get
    list(...SessionPath): Snapshot[] | ProblemResponse;

    @doc("Reads one snapshot: its stored size, or why it was not stored.")
    @route("/snapshots/{snapshotId}")
    @get
    get(...SnapshotPath): Snapshot | ProblemResponse;
  }

  @route("/metrics")
  interface Metrics {
    @doc("Lists every metric with series seen in the window, with its dimensions and their values; filter narrows the series counted.")
    @get
    catalog(...MetricWindow): MetricCatalog | ProblemResponse;

    @doc("""
      Reads a metric's buckets in the window, grouped by up to two dimensions. Refused
      MetricRangeTooLarge past 500 buckets or for Minute buckets older than 8 days, and
      MetricNotFound for a metric the store lacks.
      """)
    @route("/{metric}/series")
    @get
    query(...MetricPath, ...MetricSeriesQuery): MetricSeriesSet | ProblemResponse;

    @doc("Lists the turn points behind a metric in the window, oldest first, a page at a time; sessionId keeps one session's points.")
    @route("/{metric}/turns")
    @get
    turns(...MetricPath, ...MetricTurnQuery): MetricTurnPage | ProblemResponse;
  }

  @route("/harnesses")
  interface HarnessCatalog {
    @doc("Lists the harness catalog: every harness and version a tenant can pin.")
    @get
    list(): HarnessCatalogEntry[] | ProblemResponse;

    @doc("Lists every harness of the catalog with the version new sessions of it run and whether the tenant pins that version.")
    @route("/pins")
    @get
    listPins(): EffectiveHarnessVersion[] | ProblemResponse;

    @doc("Pins the harness to a version of the catalog, replacing its pin.")
    @route("/pins")
    @put
    pin(@body body: HarnessPinCreate): HarnessPin | ProblemResponse;

    @doc("Removes the tenant's pin for a harness.")
    @route("/pins/{harness}")
    @delete
    unpin(...HarnessPath): NoContentResponse | ProblemResponse;
  }

  @route("/personas")
  interface Personas {
    @doc("Creates a persona: its harness, the secret set its sessions run on and the harness's config files, each inline or stored by digest.")
    @post
    create(@body body: PersonaCreate): Persona | ProblemResponse;

    @doc("Presigns the upload of one persona file larger than PersonaFileLimit.InlineFileBytes; name it by digest in a persona write afterwards.")
    @route("/file-uploads")
    @post
    uploadFile(@body body: PersonaFileUploadRequest): PersonaFileUpload | ProblemResponse;

    @doc("Lists the tenant's personas.")
    @get
    list(): Persona[] | ProblemResponse;

    @doc("Reads one persona.")
    @route("/{personaId}")
    @get
    get(...PersonaPath): Persona | ProblemResponse;

    @doc("Replaces a persona's name, secret set, connectors and whole file set; its harness is fixed at create. Sessions already started keep the connectors they copied.")
    @route("/{personaId}")
    @put
    update(...PersonaPath, @body body: PersonaUpdate): Persona | ProblemResponse;

    @doc("""
      Changes one file of a persona and leaves every other file, and its digest, as it is: Put adds
      or replaces the file at its path, Remove deletes the file at the path, and Edit replaces the one
      occurrence of oldText in the UTF-8 file at the path with newText. Refused NotFound when Remove
      or Edit names no file of the persona, and InvalidRequest when oldText occurs other than once,
      or the result breaks the limits and paths a create checks.
      """)
    @route("/{personaId}/file-patches")
    @post
    patchFile(...PersonaPath, @body body: PersonaFilePatch): Persona | ProblemResponse;

    @doc("Deletes a persona all of whose sessions are Failed; one with any session in another state is refused with 409 naming those sessions.")
    @route("/{personaId}")
    @delete
    delete(...PersonaPath): NoContentResponse | ProblemResponse;
  }

  @route("/github-connection")
  interface GitHubConnections {
    @doc("Reads the stage's GitHub App as the tenant sees it: Ready with the App's slug, or AppMissing while the stage has no GitHub App. The tenant's installations are listed by list.")
    @get
    get(): GitHubConnection | ProblemResponse;

    @doc("Lists every installation of the stage's GitHub App the tenant holds, one per connected account or organization, with its account type and its last reported status. Refused GitHubInstallationUnreadable when GitHub does not answer the one-time read of the account type of an installation linked before the control plane stored it.")
    @route("/installations")
    @get
    list(): GitHubInstallation[] | ProblemResponse;

    @doc("""
      Answers the URL where a person installs the stage's GitHub App on one more account or
      organization for the tenant. Once GitHub sends the installer back, the installation is added
      to the tenant's installations, and every turn on a repository of that account gets an
      installation token as GITHUB_TOKEN and GH_TOKEN in place of the secret set's. Each call
      answers a fresh state, so running it again adds another installation. Refused with
      GitHubAppMissing while the stage has no App. With `gitHubAccountId`, GitHub opens on that
      account. With `returnUrl`, a page on the dashboard's origin, GitHub sends the browser back
      through the control plane to that page with from=github, also when an organization owner must
      approve the installation first; a refused install adds refused=<GitHubInstallRefusal> and
      account=<login>, a failed GitHub call failed=<detail>.
      """)
    @route("/start")
    @post
    start(...GitHubInstallStartQuery): GitHubInstallStart | ProblemResponse;

    @doc("Removes one installation from the tenant, for an Owner; turns on repositories of its account then use the secret set's GITHUB_TOKEN. Refused NotFound when the tenant holds no installation with that id. The installation itself stays on GitHub until a person uninstalls the App there.")
    @route("/installations/{installationId}")
    @delete
    delete(...GitHubInstallationPath): NoContentResponse | ProblemResponse;

    @doc("Lists the repositories every installation of the tenant covers. Refused GitHubAppMissing while the stage has no App, GitHubNotConnected while the tenant holds no installation, and RepositoryUnreadable when GitHub refuses the listing of any of them.")
    @route("/repositories")
    @get
    listRepositories(): GitHubRepository[] | ProblemResponse;

    @doc("Lists the open issues of a repository, read with the installation on its owner, most recently updated first; pull requests are left out.")
    @route("/repositories/{owner}/{name}/issues")
    @get
    listIssues(...GitHubRepositoryPath): GitHubIssue[] | ProblemResponse;
  }

  @route("/prebuilds")
  interface Prebuilds {
    @doc("""
      Starts a prebuild of a repository's default branch on the named build provider. Answers the
      stored or running prebuild with the same key and starts no job, unless rebuild is true. Refused
      before anything is stored: NoBuildProvider when the named provider is not connected,
      HarnessNotInCatalog when the persona's harness has no version the tenant can run, NoRelease or
      ImageNotReleased when the current release carries no Amd64 guest image of that version,
      RepositoryUnreadable when GitHub refuses to show the inputs or no token reads them,
      GitHubNotConnected when a GitHub Actions start finds no installation of the tenant on the
      repository's owner, GitHubAppPermissionMissing when that installation cannot write Actions, or
      Contents and Workflows while the caller workflow needs adding, CallerWorkflowRefused when
      GitHub refuses that commit, CircleCIProjectMissing when a CircleCI start finds no project
      binding for the repository, DispatchRefused when GitHub refuses the installation token, Actions
      are disabled in the repository, the provider refuses the job or a CircleCI pipeline parameter
      would pass 512 characters, and BuildProviderUnavailable while this control plane cannot
      dispatch to the named provider. A GitHub Actions start reads the caller workflow on the
      default branch with the installation token, each GitHub call within 10 s. When it is missing
      or differs from the current example, the start commits the example, whose push trigger on its
      own path starts the run, and reads the inputs at that commit; otherwise it reads them at the
      branch's head and dispatches the caller workflow there with no inputs. The prebuild records
      the commit it read; the run is picked up by that commit, from its workflow_run events or from
      its call to prebuildInputs.read. Refused DevcontainerMissing, after the provider check, when the
      default branch holds neither .devcontainer/devcontainer.json nor .devcontainer.json. A CircleCI start runs the binding's pipeline
      definition with config and checkout on the default branch and the parameters
      tumpel_prebuild_id, tumpel_tenant_id, tumpel_api_origin, tumpel_rootfs_url and
      tumpel_image_digest, records the pipeline and answers it Building.
      """)
    @post
    start(@body body: PrebuildStart): Prebuild | ProblemResponse;

    @doc("Lists the prebuilds of one repository, or of every repository of the tenant when repository is left out, newest first.")
    @get
    list(...PrebuildListQuery): Prebuild[] | ProblemResponse;

    @doc("Lists the newest prebuild of each repository the tenant has prebuilt, ordered by repository.")
    @route("/latest")
    @get
    listLatest(): Prebuild[] | ProblemResponse;

    @doc("""
      Reads what a prebuild of a repository's default branch would run, without starting one or
      storing anything: the config source, the commands in run order, containerEnv, the input digest
      and the findings a build would refuse or fail on, each worded as the build words it. With
      source Supplied it reads the supplied text as the repository's .devcontainer/devcontainer.json.
      It compares rust-toolchain.toml, .nvmrc and .python-version with the guest image of the
      persona's harness version. Each GitHub call answers within 10 s. Refused DevcontainerMissing
      when the repository holds no devcontainer.json and none is supplied, RepositoryUnreadable when
      GitHub refuses to show the repository or no token reads it, HarnessNotInCatalog, NoRelease and
      ImageNotReleased as a start is.
      """)
    @route("/preview")
    @post
    preview(@body body: PrebuildPreviewRequest): PrebuildPreview | ProblemResponse;

    @doc("Reads one prebuild; its state is Dispatched, Building, Converting, Done or Failed.")
    @route("/{prebuildId}")
    @get
    get(...PrebuildPath): Prebuild | ProblemResponse;

    @doc("Reads why a Failed prebuild failed: the phase and its fix.")
    @route("/{prebuildId}/failure")
    @get
    getFailure(...PrebuildPath): PrebuildFailure | ProblemResponse;
  }

  @route("/prebuild-templates")
  interface PrebuildTemplates {
    @doc("Lists every devcontainer.json template the control plane ships, by id, each with its versions newest first and the toolchains each version pins.")
    @get
    list(): PrebuildTemplate[] | ProblemResponse;

    @doc("Reads one template version with its devcontainer.json text. Refused PrebuildTemplateNotFound, listing the valid ids or versions, for an unknown template or version.")
    @route("/{prebuildTemplateId}/versions/{prebuildTemplateVersion}")
    @get
    get(...PrebuildTemplateVersionPath): PrebuildTemplateVersion | ProblemResponse;

    @doc("""
      Commits a template version's devcontainer.json as .devcontainer/devcontainer.json on the
      branch tumpel/prebuild-template, cut from the default branch's head, and opens a pull request
      to the default branch with the installation of the tenant's GitHub App on the repository's
      owner. When that branch already has an open pull request, the branch moves to the new commit
      and the answer is that pull request. With replace true, an existing devcontainer.json is
      replaced and the pull request says so. Each GitHub call answers within 10 s. Refused
      PrebuildTemplateNotFound for an unknown template or version, GitHubAppMissing while the stage
      has no App, GitHubNotConnected when no installation of the tenant is on the owner,
      DevcontainerExists naming the file when the default branch holds a devcontainer.json and
      replace is false, and GitHubRefused quoting GitHub when it refuses a read, the branch, the file
      or the pull request.
      """)
    @route("/pull-request")
    @post
    openPullRequest(@body body: PrebuildTemplatePullRequestOpen): PrebuildTemplatePullRequest | ProblemResponse;

    @doc("""
      Reads the newest pull request from the repository's branch tumpel/prebuild-template, with the
      installation of the tenant's GitHub App on the repository's owner: Open, Merged or Closed.
      Refused NotFound when the branch has no pull request, GitHubAppMissing, GitHubNotConnected and
      GitHubRefused as openPullRequest is.
      """)
    @route("/pull-request")
    @get
    getPullRequest(...PrebuildTemplatePullRequestQuery): PrebuildTemplatePullRequest | ProblemResponse;
  }

  @doc("""
    The run's side of a GitHub Actions prebuild. No principal signs in: the run presents its job's
    GitHub Actions OIDC token, which must carry the API origin with no trailing slash as aud, be
    unexpired and be signed by a key GitHub publishes. The tenant is the one whose GitHub App
    installation is on the token's repository owner.
    """)
  @route("/prebuild-inputs")
  interface PrebuildInputs {
    @doc("""
      Answers the inputs of the prebuild that waits for this run: the newest Dispatched GitHub
      Actions prebuild of the token's repository whose start read the token's sha, or the prebuild
      this run already took. The token must name the connection's caller workflow, the default
      branch as ref, push or workflow_dispatch as event_name, and a job of
      tumpel/workflows/.github/workflows/prebuild.yml at tag v2 or v2.x.y. The first call records
      the token's run_id as the prebuild's run and moves it to Building. Refused JobTokenRefused
      (401) naming the failed check, NotFound when no prebuild waits for a run at that commit,
      JobTokenMismatch (403) naming the failed claim, and PrebuildNotUploading when the prebuild
      is past Building.
      """)
    @useAuth(ProviderJobToken)
    @post
    read(): PrebuildJobInputs | ProblemResponse;
  }

  @doc("""
    The upload job's side of a prebuild. No principal signs in: the job presents its provider's OIDC
    token, which must carry the API origin with no trailing slash as aud and be unexpired. A GitHub
    Actions token must be signed by a key GitHub publishes and name the prebuild's repository, the
    connection's caller workflow, the repository's default branch as ref, push or workflow_dispatch
    as event_name, a job of the reusable workflow at tag v2 or v2.x.y, and the run id and commit
    sha the prebuild recorded as run_id and sha. A CircleCI
    token must be issued by https://oidc.circleci.com/org/<organization id> and signed by a key at
    its /.well-known/jwks-pub.json, name the connection's organization, the prebuild's repository
    as vcs-origin, the binding's project, the recorded pipeline, the default branch as vcs-ref and
    no SSH rerun; the first upload start records its job, and every later start and complete must
    name the same job. That first start also reads the pipeline's revision from CircleCI, and a
    revision other than the commit the start read fails the prebuild in phase Dispatch. A missing
    tenant, a missing prebuild, another organization and another repository each answer the same
    NotFound.
    """)
  @route("/prebuilds/{prebuildId}/uploads")
  interface PrebuildUploads {
    @doc("""
      Records the layer's digest and size and exchanges the job token for one presigned PUT of the
      layer to <tenantId>/prebuilds/<prebuildId>/layers/<digest> in the snapshot bucket, bound to
      its sha256 and its size. Refused JobTokenRefused (401) naming the failed check, NotFound,
      JobTokenMismatch (403) naming the failed claim, PrebuildNotUploading unless the prebuild
      is Building, and Conflict when an earlier start of the same prebuild recorded another digest
      or size; a repeat with the same digest and size answers a fresh grant.
      """)
    @useAuth(ProviderJobToken)
    @post
    start(...PrebuildPath, @body body: PrebuildUploadStart): PrebuildUploadGrant | ProblemResponse;

    @doc("""
      Moves the prebuild to Converting once the bucket holds the layer its start recorded. Refused
      as start is, and LayerNotUploaded when the bucket lacks it.
      """)
    @route("/complete")
    @useAuth(ProviderJobToken)
    @post
    complete(...PrebuildPath, @body body: PrebuildUploadComplete): Prebuild | ProblemResponse;
  }

  @route("/connections")
  interface Connections {
    @doc("Lists one row per connection kind, the GitHub App and each build provider, with its state and, once Connected, the account it bills.")
    @get
    list(): ConnectionSummary[] | ProblemResponse;
  }

  @route("/tenant-config")
  interface TenantConfigs {
    @doc("""
      Plans the changes that make the tenant match a tenant config, as tumpel config plan prints
      them, and changes nothing. A persona, secret set or pin the config leaves out is deleted, and
      an enrolled host it leaves out loses its labels. Refused InvalidRequest when the plan stops: a
      name repeats, a persona with a session that is not Failed is left out, a persona's harness differs, a host
      is not enrolled, a file digest or expiry value the config names is missing, or secretValues
      is not empty and leaves out a variable the config names.
      """)
    @route("/plan")
    @post
    plan(@body body: TenantConfigPlanRequest): ConfigPlan | ProblemResponse;

    @doc("""
      Replaces the tenant config with the one sent, all of it or nothing, as tumpel config apply
      does: writes everything the config describes and deletes what it leaves out. Every change is
      checked first, then personas, secret sets, secret values and pins are written in one
      transaction, so a refused change leaves the tenant as it was. Every host is checked before
      that commit and its labels are written after it; a host revoked while the apply runs keeps
      the commit and is refused HostRevoked for its labels. An empty secretValues keeps the stored values of every kept secret set; any other
      must cover every variable the config names and writes every kept set again. Refused
      InvalidRequest, changing nothing, when the plan stops, secretValues is not empty and leaves out
      a variable, or it is empty and a set the plan creates or updates needs values.
      """)
    @route("/apply")
    @post
    apply(@body body: TenantConfigApply): ConfigPlan | ProblemResponse;
  }

  @route("/oauth-grants")
  interface OAuthGrants {
    @doc("Lists the OAuth clients, such as an MCP connector or the dashboard, that hold a live token for the caller in this tenant.")
    @get
    list(): OAuthGrant[] | ProblemResponse;

    @doc("Revokes one of the caller's OAuth grants: every access and refresh token of the grant stops working at once.")
    @route("/{grantId}")
    @delete
    revoke(...OAuthGrantPath): NoContentResponse | ProblemResponse;
  }

  @route("/github-actions-connection")
  interface GitHubActionsConnections {
    @doc("Reads the tenant's GitHub Actions build provider connection: Connected with its caller workflow, or NotConnected.")
    @get
    get(): GitHubActionsConnectionLink | ProblemResponse;

    @doc("Connects the tenant's own GitHub Actions account, replacing an earlier GitHub Actions connection.")
    @route("/start")
    @post
    start(@body body: GitHubActionsConnectionStart): GitHubActionsConnectionLink | ProblemResponse;

    @doc("Disconnects the tenant's GitHub Actions account; prebuilds already stored stay.")
    @delete
    delete(): NoContentResponse | ProblemResponse;
  }

  @route("/namespace-connection")
  interface NamespaceConnections {
    @doc("Reads the tenant's Namespace build provider connection: the issuer, the subject pattern and the audience Tumpel defines for Namespace, to register there, or NotConfigured while the stage has no issuer; start is refused IssuerMissing then.")
    @get
    get(): NamespaceConnectionLink | ProblemResponse;

    @doc("Connects the tenant's own Namespace workspace, replacing an earlier Namespace connection.")
    @route("/start")
    @post
    start(@body body: NamespaceConnectionStart): NamespaceConnectionLink | ProblemResponse;

    @doc("Disconnects the tenant's Namespace workspace; prebuilds already stored stay.")
    @delete
    delete(): NoContentResponse | ProblemResponse;
  }

  @route("/circleci-connection")
  interface CircleCIConnections {
    @doc("Reads the tenant's CircleCI build provider connection, the orb and the config to commit; the API token is never answered.")
    @get
    get(): CircleCIConnectionLink | ProblemResponse;

    @doc("""
      Connects the tenant's CircleCI organization with a pasted personal API token, the fallback to
      authorize, replacing an earlier CircleCI connection; project bindings stay. Refused
      CircleCITokenRefused when GET /api/v2/me refuses the token.
      """)
    @route("/start")
    @post
    start(@body body: CircleCIConnectionStart): CircleCIConnectionLink | ProblemResponse;

    @doc("""
      Starts an authorization that connects the tenant's CircleCI organization through CircleCI's
      OAuth consent page, registering the tenant's CircleCI client first when it has none. Answers it
      AwaitingRedirect with the consent URL. Refused CircleCIRefused when CircleCI refuses the client
      registration.
      """)
    @route("/authorize")
    @post
    authorize(): CircleCIAuthorization | ProblemResponse;

    @doc("""
      Takes the address the browser landed on, spends its code with the authorization's verifier at
      CircleCI's token endpoint and reads the organizations the token reads. The connection takes
      the token at once when it already names one of them, or when there is one; otherwise the
      authorization is ChoosingOrganization. A denied consent, a refused code or no organization
      ends it Failed. Refused NotFound for another principal's authorization, InvalidRequest when
      the address is not the redirect address with a code or an error or carries another state,
      leaving the authorization AwaitingRedirect, and CircleCIAuthorizationNotWaiting unless the
      authorization is AwaitingRedirect.
      """)
    @route("/complete")
    @post
    complete(@body body: CircleCIAuthorizationComplete): CircleCIAuthorization | ProblemResponse;

    @doc("""
      Connects the organization a ChoosingOrganization authorization lists, with the token it holds,
      replacing an earlier CircleCI connection; project bindings stay. Refused NotFound for another
      principal's authorization, InvalidRequest when the organization is not listed, and
      CircleCIAuthorizationNotWaiting unless the authorization is ChoosingOrganization.
      """)
    @route("/choose")
    @post
    choose(@body body: CircleCIAuthorizationChoose): CircleCIAuthorization | ProblemResponse;

    @doc("Disconnects the tenant's CircleCI organization and deletes its project bindings and their webhooks; prebuilds already stored stay.")
    @delete
    delete(): NoContentResponse | ProblemResponse;
  }

  @route("/circleci-projects")
  interface CircleCIProjects {
    @doc("Lists the repositories bound to a CircleCI project, by repository.")
    @get
    list(): CircleCIProject[] | ProblemResponse;

    @doc("""
      Binds a repository to its CircleCI project and pipeline definition, once per repository, and
      registers a workflow-completed webhook on the project with a signing secret the control plane
      generates and seals.
      Refused NoBuildProvider while CircleCI is not connected, CircleCIProjectMissing when the slug
      names no project of the connected organization, CircleCIDefinitionMismatch when the pipeline
      definition is missing or checks out another repository, and Conflict when the repository is
      already bound. CircleCITokenRefused or CircleCIRefused when CircleCI refuses the webhook.
      """)
    @post
    add(@body body: CircleCIProjectAdd): CircleCIProject | ProblemResponse;

    @doc("Deletes a repository's CircleCI project binding and its webhook at CircleCI.")
    @route("/{circleCIProjectId}")
    @delete
    delete(...CircleCIProjectPath): NoContentResponse | ProblemResponse;
  }

  @doc("""
    CircleCI's side of a prebuild. No principal signs in: CircleCI posts each workflow-completed
    event of a bound project, signed with the binding's secret as v1=<hex HMAC-SHA256 of the body>
    in circleci-signature. A failed tumpel-prebuild workflow fails its prebuild in phase Build, a
    successful one without a completed upload in phase Upload; an event of a pipeline no prebuild
    recorded is ignored.
    """)
  @route("/circleci-events/{tenantId}")
  interface CircleCIEvents {
    @doc("Takes one workflow-completed event. Refused NotFound for an unknown tenant or project and Forbidden when the signature does not match.")
    @post
    receive(
      @path tenantId: EntityId,
      @header("circleci-signature") signature: string,
      @body body: Record<unknown>,
    ): NoContentResponse | ProblemResponse;
  }

  @route("/secret-sets")
  interface SecretSets {
    @doc("Creates a secret set of variables and provider credentials with their values.")
    @post
    create(@body body: SecretSetCreate): SecretSet | ProblemResponse;

    @doc("Lists the tenant's secret sets with their member names and kinds; values are write-only and never returned.")
    @get
    list(): SecretSet[] | ProblemResponse;

    @doc("Reads one secret set with its member names and kinds; values are write-only and never returned.")
    @route("/{secretSetId}")
    @get
    get(...SecretSetPath): SecretSet | ProblemResponse;

    @doc("Sets a secret set's name and members. A member sent without a value keeps its stored value; a member left out is deleted.")
    @route("/{secretSetId}")
    @put
    update(...SecretSetPath, @body body: SecretSetUpdate): SecretSet | ProblemResponse;

    @doc("Writes one member of a secret set with its value, replacing a member of the same name; every other member keeps its value.")
    @route("/{secretSetId}/members")
    @put
    setMember(...SecretSetPath, @body body: SecretValue): SecretSet | ProblemResponse;

    @doc("Deletes one member of a secret set and its stored value; every other member keeps its value.")
    @route("/{secretSetId}/members/{name}")
    @delete
    removeMember(...SecretMemberPath): SecretSet | ProblemResponse;

    @doc("Deletes a secret set and its stored values; refused while a persona names it.")
    @route("/{secretSetId}")
    @delete
    delete(...SecretSetPath): NoContentResponse | ProblemResponse;
  }

  @route("/claude-setups")
  interface ClaudeSetups {
    @doc("""
      Starts a short-lived box on an Online host of the tenant, placed as a session is, that runs
      claude setup-token from the tenant's pinned Claude Code with no secret set member and no
      GitHub token. Answers Starting before the box prints anything; read it with get until it is
      AwaitingCode with its signInUrl, then submit the code the sign-in page shows. Once Claude Code
      mints the token, the box stores it in the secret set as the SubscriptionToken member
      CLAUDE_CODE_OAUTH_TOKEN for Anthropic, replacing that member and keeping every other one.
      With harness Codex the box runs codex login --device-auth from the pinned Codex instead:
      AwaitingCode carries the userCode to enter at signInUrl, no code is submitted, and once the
      person signs in the box stores its auth.json as the CredentialFile CODEX_AUTH_JSON for OpenAi.
      Refused NotFound for a secret set the tenant does not own, Conflict when the set holds a
      credential of the harness's provider under another name, HarnessNotInCatalog, NoRelease, and NoHostOnline when
      no Online host has a free slot and the guest image for its architecture. A set runs one
      setup at a time: a start fails the set's running setup Superseded and discards its box.
      """)
    @post
    start(@body body: ClaudeSetupStart): ClaudeSetup | ProblemResponse;

    @doc("Lists the running Claude setups of one secret set, each read as get reads it: at most one, still Starting, AwaitingCode or Minting, for a client to resume.")
    @get
    list(...ClaudeSetupListQuery): ClaudeSetup[] | ProblemResponse;

    @doc("Reads one Claude setup: Starting until urlDueAt, AwaitingCode with the sign-in URL until codeDueAt, Minting until tokenDueAt, Completed with the member it wrote, or Failed with its reason. A setup read past the end of its phase fails with that phase's reason before it answers. Never carries the token.")
    @route("/{claudeSetupId}")
    @get
    get(...ClaudeSetupPath): ClaudeSetup | ProblemResponse;

    @doc("""
      Sends the code the sign-in page showed to the setup's box once; the setup reads Minting.
      Refused ClaudeSetupNotWaiting unless the setup is AwaitingCode. The code is a secret value, so
      the MCP server offers no tool for this operation.
      """)
    @route("/{claudeSetupId}/code")
    @post
    submitCode(...ClaudeSetupPath, @body body: ClaudeSetupCodeSubmit): ClaudeSetup | ProblemResponse;
  }

  @doc("""
    The setup box's side of a Claude setup. No principal signs in: the box presents the single-use
    token its ClaudeSetupBoxOffer carried, which writes this setup's member once while it is Minting.
    """)
  @route("/claude-setups/{claudeSetupId}/token")
  interface ClaudeSetupBoxes {
    @doc("""
      Stores the minted token in the setup's secret set as the SubscriptionToken member
      CLAUDE_CODE_OAUTH_TOKEN for Anthropic, expiring one year after it is stored, or for a Codex
      setup the auth.json as the CredentialFile CODEX_AUTH_JSON for OpenAi, expiring at expiresAt, sealed as every member is, and
      completes the setup. Refused ClaudeSetupBoxTokenRefused (401) for a missing, unknown or spent
      token, and ClaudeSetupNotWaiting unless the setup is Minting, or AwaitingCode for Codex. The answer never echoes the token.
      """)
    @useAuth(ClaudeSetupBoxToken)
    @post
    writeToken(...ClaudeSetupPath, @body body: ClaudeSetupTokenWrite): NoContentResponse | ProblemResponse;
  }
}
