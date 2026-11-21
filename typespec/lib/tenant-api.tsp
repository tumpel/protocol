import "./models.tsp";
import "./operations.tsp";
import "./channel.tsp";
import "./prebuild.tsp";
import "./build-provider.tsp";
import "./events.tsp";
import "./notifications.tsp";
import "./subscriptions.tsp";
import "./triggers.tsp";
import "./config.tsp";

namespace Tumpel;

@doc("""
  The Tenant API versions the tenant Durable Object serves, from Oldest to Version. A caller always
  sends Version. Within a version only a new operation lands; every other change to an operation's
  input or result raises Version, and the Durable Object keeps serving Version - 1 for one deploy.
  """)
@minValue(TenantApiOldest)
@maxValue(TenantApiVersion)
@TypeSpec.OpenAPI.extension("x-bound-names", #["Oldest", "Version"])
scalar TenantApiProtocol extends int32;

const TenantApiOldest = 1;
const TenantApiVersion = 9;

namespace TenantApi {

@doc("A persona file as the tenant Durable Object stores it: the bytes live in the store under `digest`.")
model StoredFile {
  path: PersonaFilePath;
  digest: Sha256Digest;
  sizeBytes: PersonaFileSize;
}

@doc("A stored persona file with its timestamps, as a persona read carries it.")
model StoredFileRead {
  ...StoredFile;
  createdAt: int64;
  updatedAt: int64;
}

@doc("A persona as the tenant Durable Object stores it, its files named by digest.")
model StoredPersona {
  turnTotalBudgetSeconds?: TurnTotalBudgetSeconds;
  personaId: EntityId;
  tenantId: EntityId;
  name: DisplayName;
  harness: Harness;
  secretSetId: EntityId;
  connectorIds: EntityId[];
  @minValue(512) @maxValue(65536) boxMemoryMib?: int32;
  @minValue(32768) @maxValue(262144) boxDiskMib?: int32;
  boxRetention: BoxRetention;
  tumpelMcp: boolean;
  files: StoredFileRead[];
  createdAt: int64;
  updatedAt: int64;
}

@doc("What a persona edit writes. The harness is fixed at create.")
model PersonaChange {
  turnTotalBudgetSeconds?: TurnTotalBudgetSeconds;
  name: DisplayName;
  secretSetId: EntityId;
  connectorIds: EntityId[];
  @minValue(512) @maxValue(65536) boxMemoryMib: int32;
  @minValue(32768) @maxValue(262144) boxDiskMib: int32;
  boxRetention: BoxRetention;
  tumpelMcp: boolean;
  files: StoredFile[];
}

@doc("What a persona create writes.")
model PersonaWrite {
  ...PersonaChange;
  harness: Harness;
}

model ListPersonasInput {
  tenantId: EntityId;
}

model GetPersonaInput {
  tenantId: EntityId;
  personaId: EntityId;
}

model CreatePersonaInput {
  tenantId: EntityId;
  persona: PersonaWrite;
  now: int64;
}

model UpdatePersonaInput {
  tenantId: EntityId;
  personaId: EntityId;
  persona: PersonaChange;
  now: int64;
}

@doc("What a persona patch writes: each field it names replaces the stored one, and every field it leaves out, and every file, stays as it is.")
model PersonaPatchChange is OptionalProperties<OmitProperties<PersonaChange, "files">>;

@doc("A persona patch, which the tenant Durable Object reads, merges and writes in one transaction, so a concurrent write never loses a field neither names.")
model PatchPersonaInput {
  tenantId: EntityId;
  personaId: EntityId;
  patch: PersonaPatchChange;
  now: int64;
}

model DeletePersonaInput {
  tenantId: EntityId;
  personaId: EntityId;
}

model OpenInput {
  tenantId: EntityId;
  now: int64;
}

model SupervisorUpdateInput {
  hostId: EntityId;
  message: Channel.SupervisorUpdateStep | Channel.SupervisorUpdateFailed;
}

model SupervisorUpdatesInput {
  hostIds: EntityId[];
}

model ListSecretSetsInput {
  tenantId: EntityId;
}

model GetSecretSetInput {
  tenantId: EntityId;
  secretSetId: EntityId;
}

@doc("The GitHub account a repository token secret acts as, when the set holds one.")
model GitHubUser {
  githubUserId: int64;
  login: string;
}

model CreateSecretSetInput {
  tenantId: EntityId;
  secretSet: SecretSetCreate;
  githubUser: GitHubUser | null;
  now: int64;
}

model UpdateSecretSetInput {
  tenantId: EntityId;
  secretSetId: EntityId;
  change: SecretSetUpdate;
  githubUser: GitHubUser | null;
  now: int64;
}

@doc("A secret set patch, which the tenant Durable Object reads, merges and writes in one transaction, so a concurrent write never loses a member neither names.")
model PatchSecretSetInput {
  tenantId: EntityId;
  secretSetId: EntityId;
  patch: SecretSetPatch;
  githubUser: GitHubUser | null;
  now: int64;
}

model SetSecretMemberInput {
  tenantId: EntityId;
  secretSetId: EntityId;
  member: SecretValue;
  githubUser: GitHubUser | null;
  now: int64;
}

model RemoveSecretMemberInput {
  tenantId: EntityId;
  secretSetId: EntityId;
  name: string;
  now: int64;
}

model DeleteSecretSetInput {
  secretSetId: EntityId;
}

model CreateSecretSetWrite {
  kind: "CreateSecretSet";
  secretSetId: EntityId;
  secretSet: SecretSetCreate;
  githubUser: GitHubUser | null;
}

model RewriteSecretSetWrite {
  kind: "RewriteSecretSet";
  secretSetId: EntityId;
  secretSet: SecretSetCreate;
  githubUser: GitHubUser | null;
}

model DeleteSecretSetWrite {
  kind: "DeleteSecretSet";
  secretSetId: EntityId;
}

model CreatePersonaWrite {
  kind: "CreatePersona";
  persona: PersonaWrite;
}

model UpdatePersonaWrite {
  kind: "UpdatePersona";
  personaId: EntityId;
  persona: PersonaChange;
}

model DeletePersonaWrite {
  kind: "DeletePersona";
  personaId: EntityId;
}

model PinWrite {
  kind: "Pin";
  pin: HarnessPinCreate;
}

model UnpinWrite {
  kind: "Unpin";
  harness: string;
}

@doc("Creates a trigger that names its persona by name, so it may name a persona the same apply creates.")
model CreateTriggerWrite {
  kind: "CreateTrigger";
  trigger: ConfigTrigger;
  principalId: EntityId;
}

model UpdateTriggerWrite {
  kind: "UpdateTrigger";
  triggerId: EntityId;
  trigger: ConfigTrigger;
  principalId: EntityId;
}

model DeleteTriggerWrite {
  kind: "DeleteTrigger";
  triggerId: EntityId;
}

@doc("One write of a config apply, which the tenant Durable Object commits with the others in one transaction.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union ConfigWrite {
  CreateSecretSet: CreateSecretSetWrite,
  RewriteSecretSet: RewriteSecretSetWrite,
  DeleteSecretSet: DeleteSecretSetWrite,
  CreatePersona: CreatePersonaWrite,
  UpdatePersona: UpdatePersonaWrite,
  DeletePersona: DeletePersonaWrite,
  Pin: PinWrite,
  Unpin: UnpinWrite,
  CreateTrigger: CreateTriggerWrite,
  UpdateTrigger: UpdateTriggerWrite,
  DeleteTrigger: DeleteTriggerWrite,
}

model ApplyConfigInput {
  tenantId: EntityId;
  writes: ConfigWrite[];
  now: int64;
}

model ListPinsInput {}

model PinInput {
  pin: HarnessPinCreate;
  now: int64;
}

model UnpinInput {
  harness: string;
}

model ListConnectorsInput {
  tenantId: EntityId;
  now: int64;
}

model GetConnectorInput {
  tenantId: EntityId;
  connectorId: EntityId;
  now: int64;
}

model CreateConnectorInput {
  tenantId: EntityId;
  auth: ConnectorAuth;
  name: string;
  url: string;
  now: int64;
}

model RenameConnectorInput {
  tenantId: EntityId;
  connectorId: EntityId;
  updatedAt: int64;
  name: string;
  now: int64;
}

model DeleteConnectorInput {
  connectorId: EntityId;
  updatedAt: int64;
}

model SetStaticTokenInput {
  tenantId: EntityId;
  connectorId: EntityId;
  updatedAt: int64;
  value: string;
  now: int64;
}

model ClearConnectorCredentialInput {
  tenantId: EntityId;
  connectorId: EntityId;
  updatedAt: int64;
  now: int64;
}

model StartConnectorAuthorizationInput {
  tenantId: EntityId;
  principalId: EntityId;
  connectorId: EntityId;
  updatedAt: int64;
  controlPlaneOrigin: string;
  now: int64;
}

@doc("The signed state of a connector authorization, as the callback reads it back.")
model ConnectorStateClaims {
  purpose: "ConnectorAuthorization";
  @minLength(1) tenantId: string;
  @minLength(1) connectorId: string;
  @minLength(1) connectorAuthorizationId: string;
  @minLength(1) principalId: string;
}

model ConnectorCallbackCode {
  kind: "Code";
  code: string;
  issuer: string | null;
}

model ConnectorCallbackError {
  kind: "Error";
  error: string;
}

model ConnectorCallbackInput {
  claims: ConnectorStateClaims;
  stateHash: string;
  callback: ConnectorCallbackCode | ConnectorCallbackError;
  initiatorIsOwner: boolean;
  now: int64;
}

model ServeConnectorTokenInput {
  turnId: EntityId;
  connectorId: EntityId;
  now: int64;
}

model UnknownConnectorsInput {
  connectorIds: EntityId[];
}

model NewOpenRouterAuthorization {
  secretSetId: EntityId;
  controlPlaneOrigin: string;
}

model StartOpenRouterAuthorizationInput {
  tenantId: EntityId;
  principalId: EntityId;
  input: NewOpenRouterAuthorization;
  now: int64;
}

model GetOpenRouterAuthorizationInput {
  tenantId: EntityId;
  principalId: EntityId;
  openRouterAuthorizationId: EntityId;
}

model OpenRouterCallbackCode {
  kind: "Code";
  code: string;
}

model OpenRouterCallbackNoCode {
  kind: "NoCode";
}

model OpenRouterCallbackInput {
  tenantId: EntityId;
  openRouterAuthorizationId: EntityId;
  callback: OpenRouterCallbackCode | OpenRouterCallbackNoCode;
  now: int64;
}

model OpenRouterAuthorizationDeadline {
  openRouterAuthorizationId: EntityId;
  at: int64;
}

model OpenRouterAuthorizationDeadlineReachedInput {
  deadline: OpenRouterAuthorizationDeadline;
}

model OpenRouterSecretSetsInput {}

model StartCircleCIAuthorizationInput {
  tenantId: EntityId;
  principalId: EntityId;
  now: int64;
}

model CompleteCircleCIAuthorizationInput {
  tenantId: EntityId;
  principalId: EntityId;
  circleCIAuthorizationId: EntityId;
  redirectedUrl: string;
  now: int64;
}

model ChooseCircleCIOrganizationInput {
  tenantId: EntityId;
  principalId: EntityId;
  circleCIAuthorizationId: EntityId;
  organizationId: string;
  now: int64;
}

model CircleCIAuthorizationDeadline {
  circleCIAuthorizationId: EntityId;
  at: int64;
}

model CircleCIAuthorizationDeadlineReachedInput {
  tenantId: EntityId;
  deadline: CircleCIAuthorizationDeadline;
}

@doc("A host as the control plane stores it, without its supervisor update reports and protocol ranges.")
model HostRecord {
  ...OmitProperties<Host, "supervisorUpdateStep" | "supervisorUpdateFailure" | "channelProtocol" | "guestProtocol">;
}

model NewClaudeSetup {
  principalId: EntityId;
  secretSetId: EntityId;
  harness: ClaudeSetupHarness;
  harnessVersion: string;
  hosts: HostRecord[];
  endpoint: string;
}

model StartClaudeSetupInput {
  tenantId: EntityId;
  input: NewClaudeSetup;
  now: int64;
}

model GetClaudeSetupInput {
  tenantId: EntityId;
  claudeSetupId: EntityId;
  now: int64;
}

model ListClaudeSetupsInput {
  tenantId: EntityId;
  secretSetId: EntityId;
  now: int64;
}

model SubmitClaudeSetupCodeInput {
  tenantId: EntityId;
  claudeSetupId: EntityId;
  code: string;
  now: int64;
}

model WriteClaudeSetupTokenInput {
  tenantId: EntityId;
  claudeSetupId: EntityId;
  credential: string;
  token: string;
  tokenExpiresAt?: string;
  now: int64;
}

model ClaudeSetupDeadline {
  claudeSetupId: EntityId;
  at: int64;
}

model ClaudeSetupDeadlineReachedInput {
  tenantId: EntityId;
  deadline: ClaudeSetupDeadline;
}

model StoredClaudeSetupOffer {
  type: "ClaudeSetupBoxOffer";
  claudeSetupId: EntityId;
  boxId: EntityId;
}

model StoredClaudeSetupCode {
  type: "ClaudeSetupBoxCode";
  claudeSetupId: EntityId;
  boxId: EntityId;
}

model PrepareClaudeSetupInput {
  tenantId: EntityId;
  stored: StoredClaudeSetupOffer | StoredClaudeSetupCode;
  hostId: EntityId;
  now: int64;
}

model ListPrebuildsInput {
  tenantId: EntityId;
  repository: string | null;
}

model ListLatestPrebuildsInput {
  tenantId: EntityId;
}

model GetPrebuildInput {
  tenantId: EntityId;
  prebuildId: EntityId;
}

model PrebuildKey {
  repository: string;
  inputDigest: string;
  guestImageDigest: string;
}

model HeldPrebuildInput {
  tenantId: EntityId;
  key: PrebuildKey;
}

model RecordPrebuildBuildingInput {
  tenantId: EntityId;
  prebuildId: EntityId;
  now: int64;
}

model JobInputsTargetInput {
  tenantId: EntityId;
  repository: string;
  headSha: string;
  runId: int64;
}

model BindJobRunInput {
  tenantId: EntityId;
  prebuildId: EntityId;
  runId: int64;
  now: int64;
}

@doc("A GitHub Actions workflow run event, as the webhook reports it.")
model RunEvent {
  action: string;
  runId: int64;
  repository: string;
  path: string;
  headSha: string;
  htmlUrl: string;
  conclusion: string | null;
}

model WorkflowRunReportedInput {
  tenantId: EntityId;
  event: RunEvent;
  now: int64;
}

model PrebuildDeadline {
  prebuildId: EntityId;
  at: int64;
}

model PrebuildDispatchDue {
  name: "PrebuildDispatch";
  deadline: PrebuildDeadline;
}

model PrebuildBuildDue {
  name: "PrebuildBuild";
  deadline: PrebuildDeadline;
}

model PrebuildDeadlineReachedInput {
  tenantId: EntityId;
  due: PrebuildDispatchDue | PrebuildBuildDue;
}

model RepositoryRef {
  owner: string;
  name: string;
}

model GitHubActionsStart {
  prebuildId: EntityId;
  personaId: EntityId;
  target: RepositoryRef;
  repository: string;
  guestImageDigest: string;
  rootfsKey: string;
  callerWorkflow: string;
  apiOrigin: string;
  rebuild: boolean;
}

model StartGitHubActionsPrebuildInput {
  tenantId: EntityId;
  start: GitHubActionsStart;
  now: int64;
}

model PrebuildCommitStart {
  prebuildId: EntityId;
  personaId: EntityId;
  key: PrebuildKey;
  configSource: PrebuildConfigSource;
  defaultBranch: string;
  headSha: string;
  rootfsKey: string;
}

model NewSession {
  principalId: EntityId;
  startedBy: SessionStartedBy;
  hosts: HostRecord[];
  harness: Harness;
  harnessVersion: string;
  endpoint: string;
  start: SessionStart;
}

model StartHostPrebuildInput {
  tenantId: EntityId;
  commit: PrebuildCommitStart;
  provider: BuildProvider;
  input: NewSession;
  apiOrigin: string;
  now: int64;
}

model UploadTargetInput {
  tenantId: EntityId;
  prebuildId: EntityId;
}

model CircleCIUploadJob {
  pipelineId: string;
  headSha: string;
  jobId: string;
}

model BindCircleCIUploadJobInput {
  tenantId: EntityId;
  prebuildId: EntityId;
  upload: CircleCIUploadJob;
  now: int64;
}

model PrebuildLayerUpload {
  layerDigest: string;
  layerSizeBytes: int64;
}

model StartPrebuildUploadInput {
  tenantId: EntityId;
  prebuildId: EntityId;
  upload: PrebuildLayerUpload;
  now: int64;
}

model CompletePrebuildUploadInput {
  tenantId: EntityId;
  prebuildId: EntityId;
  upload: PrebuildLayerUpload;
  now: int64;
}

model GetPrebuildFailureInput {
  tenantId: EntityId;
  prebuildId: EntityId;
}

model PrebuildStartRecord {
  prebuildId: EntityId;
  personaId: EntityId;
  key: PrebuildKey;
  configSource: PrebuildConfigSource;
  target: RepositoryRef;
  defaultBranch: string;
  headSha: string;
  rootfsKey: string;
}

model DispatchCircleCIPrebuildInput {
  tenantId: EntityId;
  start: PrebuildStartRecord;
  project: CircleCIProject;
  parameters: Record<string>;
  now: int64;
}

model CircleCIWorkflowCompletedEvent {
  type: string;
  workflow: {
    name: string;
    status: string;
    url: url;
  };
  pipelineId: string;
  projectId: string;
}

model CircleCIWorkflowCompletedInput {
  tenantId: EntityId;
  event: CircleCIWorkflowCompletedEvent;
  now: int64;
}

model RepositoryReadTokenInput {
  tenantId: EntityId;
  personaId: EntityId;
  repository: RepositoryRef;
  now: int64;
  permissions: Record<"read" | "write">;
}

model StartSessionInput {
  tenantId: EntityId;
  input: NewSession;
  now: int64;
}

model IssueOfSession {
  ...OmitProperties<SessionIssue, "sessionId">;
}

model StartSessionFromIssueInput {
  tenantId: EntityId;
  input: NewSession;
  issue: IssueOfSession;
  now: int64;
}

model SendTurnInput {
  tenantId: EntityId;
  sessionId: EntityId;
  send: TurnSend;
  hosts: HostRecord[];
  now: int64;
}

model StopSessionInput {
  tenantId: EntityId;
  sessionId: EntityId;
  cancelledBy: string | null;
  now: int64;
}

model ArchiveSessionInput {
  tenantId: EntityId;
  sessionId: EntityId;
  now: int64;
}

model SetSessionTagsInput {
  tenantId: EntityId;
  sessionId: EntityId;
  ...SessionTags;
  now: int64;
}

@doc("A tag patch, which the tenant Durable Object reads, merges and writes in one transaction.")
model PatchSessionTagsInput {
  tenantId: EntityId;
  sessionId: EntityId;
  patch: SessionTagsPatch;
  now: int64;
}

model DeleteSessionInput {
  tenantId: EntityId;
  sessionId: EntityId;
}

model GetSessionInput {
  tenantId: EntityId;
  sessionId: EntityId;
}

model SessionFilter {
  state?: SessionState;
  hostId?: EntityId;
  lastTurnBefore?: int64;
  @doc("Keep only the sessions that carry every tag named.")
  @maxItems(16)
  tags?: SessionTag[];

  @doc("Keep only the sessions this trigger started.")
  triggerId?: EntityId;
}

model ListSessionsInput {
  tenantId: EntityId;
  filter: SessionFilter;
}

model ListTurnsInput {
  tenantId: EntityId;
  sessionId: EntityId;
}

model GetTurnInput {
  tenantId: EntityId;
  turnId: EntityId;
}

model SteerTurnInput {
  tenantId: EntityId;
  turnId: EntityId;
  steer: SteerCreate;
  now: int64;
}

model ListSteersInput {
  tenantId: EntityId;
  turnId: EntityId;
}

model TakeSteersInput {
  turnId: EntityId;
  now: int64;
}

model CancelTurnInput {
  tenantId: EntityId;
  turnId: EntityId;
  cancelledBy: string;
  now: int64;
}

model WaitTurnsInput {
  tenantId: EntityId;
  turnIds: EntityId[];
  timeoutSeconds: int32;
}

model ListEventsInput {
  tenantId: EntityId;

  @doc("The id after which the page starts; null starts at the current end of the log.")
  afterEventId: Sequence | null;

  @doc("The event types to keep; an empty list keeps every type.")
  events: TenantEventType[];

  @doc("The session whose events to keep; null keeps every session's.")
  sessionId: EntityId | null;

  @doc("The trigger whose events to keep; null keeps every trigger's.")
  triggerId: EntityId | null;

  @minValue(0)
  @maxValue(50)
  waitSeconds: int32;
}

model ListWebhookEndpointsInput {
  tenantId: EntityId;
}

model CreateWebhookEndpointInput {
  tenantId: EntityId;
  endpoint: WebhookEndpointCreate;
  now: int64;
}

model GetWebhookEndpointInput {
  tenantId: EntityId;
  webhookEndpointId: EntityId;
}

model DeleteWebhookEndpointInput {
  tenantId: EntityId;
  webhookEndpointId: EntityId;
}

model SetWebhookEndpointStatusInput {
  tenantId: EntityId;
  webhookEndpointId: EntityId;
  status: WebhookDeliveryStatus;
}

model ListPushSubscriptionsInput {
  tenantId: EntityId;
  principalId: EntityId;
}

model CreatePushSubscriptionInput {
  tenantId: EntityId;
  principalId: EntityId;
  subscription: PushSubscriptionCreate;
  now: int64;
}

model DeletePushSubscriptionInput {
  tenantId: EntityId;
  principalId: EntityId;
  pushSubscriptionId: EntityId;
}

model ForgetPushSubscriptionInput {
  tenantId: EntityId;
  pushSubscriptionId: EntityId;
}

model PushTargetInput {
  tenantId: EntityId;
  pushSubscriptionId: EntityId;
}

model CreateSubscriptionInput {
  tenantId: EntityId;
  subscription: SubscriptionCreate;
  now: int64;
}

model SubscriptionFilter {
  sessionId?: EntityId;
  state?: SubscriptionState;
}

model ListSubscriptionsInput {
  tenantId: EntityId;
  filter: SubscriptionFilter;
}

model GetSubscriptionInput {
  tenantId: EntityId;
  subscriptionId: EntityId;
}

model PauseSubscriptionInput {
  tenantId: EntityId;
  subscriptionId: EntityId;
  ...SubscriptionPause;
  now: int64;
}

model ResumeSubscriptionInput {
  tenantId: EntityId;
  subscriptionId: EntityId;
  now: int64;
}

model DeleteSubscriptionInput {
  tenantId: EntityId;
  subscriptionId: EntityId;
  now: int64;
}

model CompleteSubscriptionInput {
  tenantId: EntityId;
  subscriptionId: EntityId;
  now: int64;
}

model CreateTriggerInput {
  tenantId: EntityId;
  trigger: TriggerCreate;

  @doc("The Owner who creates the trigger, whom its sessions run as.")
  principalId: EntityId;

  now: int64;
}

model ListTriggersInput {
  tenantId: EntityId;
}

model GetTriggerInput {
  tenantId: EntityId;
  triggerId: EntityId;
}

@doc("A trigger patch, which the tenant Durable Object reads, merges and writes in one transaction.")
model UpdateTriggerInput {
  tenantId: EntityId;
  triggerId: EntityId;
  patch: TriggerPatch;

  @doc("The Owner who changes the trigger, whom its sessions run as from now on.")
  principalId: EntityId;

  now: int64;
}

model DeleteTriggerInput {
  tenantId: EntityId;
  triggerId: EntityId;
  now: int64;
}

@doc("The source adapter matched the delivery and filled the prompt from its payload.")
model TriggerFiredMatched {
  kind: "Matched";

  @doc("The repository the event names, such as GitHub's repository.html_url; the session clones it.")
  repository: RepositoryUrl;

  @doc("The trigger's prompt with every placeholder filled from the payload.")
  prompt: Prompt;
}

@doc("The source adapter matched the delivery and refused the start itself, such as for a prompt field the event lacks.")
model TriggerFiredRefused {
  kind: "Refused";
  refusal: TriggerStartRefusal;
}

@doc("""
  One delivery a trigger matched. The tenant Durable Object reads the trigger's persona, model and
  principalId as they are now and starts the session through the path of Sessions_start, with a
  TriggerOrigin as its startedBy, at most once per triggerId and deliveryId. It appends
  TriggerStartRefused when the adapter or the start refuses the delivery.
  """)
model TriggerFiredInput {
  tenantId: EntityId;
  triggerId: EntityId;
  deliveryId: TriggerDeliveryId;
  fired: TriggerFiredMatched | TriggerFiredRefused;
  now: int64;
}

model GetTurnFailureInput {
  tenantId: EntityId;
  turnId: EntityId;
}

model ListStopFailuresInput {
  tenantId: EntityId;
  sessionId: EntityId;
}

model ListSnapshotsInput {
  tenantId: EntityId;
  sessionId: EntityId;
}

model ListCredentialHandoversInput {
  tenantId: EntityId;
  sessionId: EntityId;
}

model GetSnapshotInput {
  tenantId: EntityId;
  snapshotId: EntityId;
}

model TranscriptCursorInput {
  tenantId: EntityId;
  sessionId: EntityId;
  after: int64;
  turnId: EntityId | null;
  limit: int32;
  maxBytes?: int64;
}

model ConnectedAccountsInput {}

model DeleteBuildConnectionInput {
  provider: BuildProvider;
}

model CircleCIConnectionInput {}

model CircleCITokenInput {}

model ConnectCircleCIInput {
  start: CircleCIConnectionStart;
  now: int64;
}

model ListCircleCIProjectsInput {
  tenantId: EntityId;
}

model CircleCIProjectBoundToInput {
  tenantId: EntityId;
  projectId: string;
}

model CircleCIProjectOfInput {
  tenantId: EntityId;
  repository: string;
}

model CircleCIBinding {
  repository: string;
  projectSlug: string;
  projectId: string;
  pipelineDefinitionId: string;
  webhookId: string;
  signingSecret: string;
}

model AddCircleCIProjectInput {
  tenantId: EntityId;
  binding: CircleCIBinding;
  now: int64;
}

model CircleCIWebhooksInput {}

model CircleCIWebhookSecretInput {
  projectId: string;
}

model DeleteCircleCIProjectInput {
  circleCIProjectId: EntityId;
}

model GitHubActionsConnectionInput {
  tenantId: EntityId;
}

model ConnectGitHubActionsInput {
  tenantId: EntityId;
  start: GitHubActionsConnectionStart;
  now: int64;
}

model NamespaceConnectionInput {}

model ConnectNamespaceInput {
  start: NamespaceConnectionStart;
  now: int64;
}

model OfferSentInput {
  turnId: EntityId;
}

model HostHelloInput {
  hostId: EntityId;
  boxCapacity: int32;
  usage: HostUsage;
  now: int64;
  channelProtocol: int32;
}

model HostUsageInput {
  hostId: EntityId;
  usage: HostUsage;
  now: int64;
}

model ReconcileHeldBoxesInput {
  tenantId: EntityId;
  hostId: EntityId;
  heldSessionIds: EntityId[];
  now: int64;
}

model ForgetHostUsageInput {
  hostId: EntityId;
}

model RunningTurnsByHostInput {}

model ListHostUsageInput {
  tenantId: EntityId;
}

model DeferredOffersInput {
  tenantId: EntityId;
  hostId: EntityId;
}

model TurnMetricDimensionsInput {
  turnIds: EntityId[];
}

model PrepareOfferInput {
  tenantId: EntityId;
  turnId: EntityId;
  hostId: EntityId;
  now: int64;
}

enum HostPresence {
  Online: "Online",
  Offline: "Offline",
}

model HostPresenceInput {
  tenantId: EntityId;
  hostId: EntityId;
  presence: HostPresence;
  now: int64;
}

model HostMessageInput {
  tenantId: EntityId;
  hostId: EntityId;
  message: Channel.TurnImageFetching | Channel.TurnClaim | Channel.TurnRepositoryReady | Channel.TurnLine | Channel.TurnComplete | Channel.TurnRepositoryCloneFailed | Channel.TurnFailed | Channel.SnapshotChunks | Channel.SnapshotPacks | Channel.RestoreChunks | Channel.SnapshotDone | Channel.SnapshotFailed | Channel.BoxGone | Channel.BoxTeardownFailed | Channel.ClaudeSetupBoxUrl | Channel.ClaudeSetupBoxFailed;
}

model TurnDeadline {
  turnId: EntityId;
  at: int64;
}

enum SessionDeadlineName {
  FirstLine: "FirstLine",
  Total: "Total",
  Snapshot: "Snapshot",
  SnapshotAnswer: "SnapshotAnswer",
  Teardown: "Teardown",
  TeardownAnswer: "TeardownAnswer",
  HostOffline: "HostOffline",
}

model SessionDueDeadline {
  name: SessionDeadlineName;
  deadline: TurnDeadline;
}

model DeadlineReachedInput {
  tenantId: EntityId;
  due: SessionDueDeadline;
}

model ListPersonasRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listPersonas";
  input: ListPersonasInput;
}

model GetPersonaRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getPersona";
  input: GetPersonaInput;
}

model CreatePersonaRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "createPersona";
  input: CreatePersonaInput;
}

model UpdatePersonaRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "updatePersona";
  input: UpdatePersonaInput;
}

model PatchPersonaRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "patchPersona";
  input: PatchPersonaInput;
}

model DeletePersonaRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deletePersona";
  input: DeletePersonaInput;
}

model OpenRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "open";
  input: OpenInput;
}

model SupervisorUpdateRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "supervisorUpdate";
  input: SupervisorUpdateInput;
}

model SupervisorUpdatesRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "supervisorUpdates";
  input: SupervisorUpdatesInput;
}

model ListSecretSetsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listSecretSets";
  input: ListSecretSetsInput;
}

model GetSecretSetRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getSecretSet";
  input: GetSecretSetInput;
}

model CreateSecretSetRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "createSecretSet";
  input: CreateSecretSetInput;
}

model UpdateSecretSetRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "updateSecretSet";
  input: UpdateSecretSetInput;
}

model PatchSecretSetRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "patchSecretSet";
  input: PatchSecretSetInput;
}

model SetSecretMemberRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "setSecretMember";
  input: SetSecretMemberInput;
}

model RemoveSecretMemberRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "removeSecretMember";
  input: RemoveSecretMemberInput;
}

model DeleteSecretSetRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deleteSecretSet";
  input: DeleteSecretSetInput;
}

model ApplyConfigRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "applyConfig";
  input: ApplyConfigInput;
}

model ListPinsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listPins";
  input: ListPinsInput;
}

model PinRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "pin";
  input: PinInput;
}

model UnpinRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "unpin";
  input: UnpinInput;
}

model ListConnectorsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listConnectors";
  input: ListConnectorsInput;
}

model GetConnectorRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getConnector";
  input: GetConnectorInput;
}

model CreateConnectorRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "createConnector";
  input: CreateConnectorInput;
}

model RenameConnectorRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "renameConnector";
  input: RenameConnectorInput;
}

model DeleteConnectorRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deleteConnector";
  input: DeleteConnectorInput;
}

model SetStaticTokenRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "setStaticToken";
  input: SetStaticTokenInput;
}

model ClearConnectorCredentialRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "clearConnectorCredential";
  input: ClearConnectorCredentialInput;
}

model StartConnectorAuthorizationRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startConnectorAuthorization";
  input: StartConnectorAuthorizationInput;
}

model ConnectorCallbackRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "connectorCallback";
  input: ConnectorCallbackInput;
}

model ServeConnectorTokenRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "serveConnectorToken";
  input: ServeConnectorTokenInput;
}

model UnknownConnectorsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "unknownConnectors";
  input: UnknownConnectorsInput;
}

model StartOpenRouterAuthorizationRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startOpenRouterAuthorization";
  input: StartOpenRouterAuthorizationInput;
}

model GetOpenRouterAuthorizationRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getOpenRouterAuthorization";
  input: GetOpenRouterAuthorizationInput;
}

model OpenRouterCallbackRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "openRouterCallback";
  input: OpenRouterCallbackInput;
}

model OpenRouterAuthorizationDeadlineReachedRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "openRouterAuthorizationDeadlineReached";
  input: OpenRouterAuthorizationDeadlineReachedInput;
}

model OpenRouterSecretSetsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "openRouterSecretSets";
  input: OpenRouterSecretSetsInput;
}

model StartCircleCIAuthorizationRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startCircleCIAuthorization";
  input: StartCircleCIAuthorizationInput;
}

model CompleteCircleCIAuthorizationRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "completeCircleCIAuthorization";
  input: CompleteCircleCIAuthorizationInput;
}

model ChooseCircleCIOrganizationRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "chooseCircleCIOrganization";
  input: ChooseCircleCIOrganizationInput;
}

model CircleCIAuthorizationDeadlineReachedRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "circleCIAuthorizationDeadlineReached";
  input: CircleCIAuthorizationDeadlineReachedInput;
}

model StartClaudeSetupRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startClaudeSetup";
  input: StartClaudeSetupInput;
}

model GetClaudeSetupRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getClaudeSetup";
  input: GetClaudeSetupInput;
}

model ListClaudeSetupsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listClaudeSetups";
  input: ListClaudeSetupsInput;
}

model SubmitClaudeSetupCodeRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "submitClaudeSetupCode";
  input: SubmitClaudeSetupCodeInput;
}

model WriteClaudeSetupTokenRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "writeClaudeSetupToken";
  input: WriteClaudeSetupTokenInput;
}

model ClaudeSetupDeadlineReachedRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "claudeSetupDeadlineReached";
  input: ClaudeSetupDeadlineReachedInput;
}

model PrepareClaudeSetupRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "prepareClaudeSetup";
  input: PrepareClaudeSetupInput;
}

model ListPrebuildsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listPrebuilds";
  input: ListPrebuildsInput;
}

model ListLatestPrebuildsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listLatestPrebuilds";
  input: ListLatestPrebuildsInput;
}

model GetPrebuildRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getPrebuild";
  input: GetPrebuildInput;
}

model HeldPrebuildRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "heldPrebuild";
  input: HeldPrebuildInput;
}

model RecordPrebuildBuildingRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "recordPrebuildBuilding";
  input: RecordPrebuildBuildingInput;
}

model JobInputsTargetRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "jobInputsTarget";
  input: JobInputsTargetInput;
}

model BindJobRunRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "bindJobRun";
  input: BindJobRunInput;
}

model WorkflowRunReportedRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "workflowRunReported";
  input: WorkflowRunReportedInput;
}

model PrebuildDeadlineReachedRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "prebuildDeadlineReached";
  input: PrebuildDeadlineReachedInput;
}

model StartGitHubActionsPrebuildRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startGitHubActionsPrebuild";
  input: StartGitHubActionsPrebuildInput;
}

model StartHostPrebuildRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startHostPrebuild";
  input: StartHostPrebuildInput;
}

model UploadTargetRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "uploadTarget";
  input: UploadTargetInput;
}

model BindCircleCIUploadJobRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "bindCircleCIUploadJob";
  input: BindCircleCIUploadJobInput;
}

model StartPrebuildUploadRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startPrebuildUpload";
  input: StartPrebuildUploadInput;
}

model CompletePrebuildUploadRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "completePrebuildUpload";
  input: CompletePrebuildUploadInput;
}

model GetPrebuildFailureRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getPrebuildFailure";
  input: GetPrebuildFailureInput;
}

model DispatchCircleCIPrebuildRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "dispatchCircleCIPrebuild";
  input: DispatchCircleCIPrebuildInput;
}

model CircleCIWorkflowCompletedRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "circleCIWorkflowCompleted";
  input: CircleCIWorkflowCompletedInput;
}

model RepositoryReadTokenRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "repositoryReadToken";
  input: RepositoryReadTokenInput;
}

model StartSessionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startSession";
  input: StartSessionInput;
}

model StartSessionFromIssueRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "startSessionFromIssue";
  input: StartSessionFromIssueInput;
}

model SendTurnRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "sendTurn";
  input: SendTurnInput;
}

model StopSessionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "stopSession";
  input: StopSessionInput;
}

model ArchiveSessionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "archiveSession";
  input: ArchiveSessionInput;
}

model SetSessionTagsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "setSessionTags";
  input: SetSessionTagsInput;
}

model PatchSessionTagsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "patchSessionTags";
  input: PatchSessionTagsInput;
}

model DeleteSessionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deleteSession";
  input: DeleteSessionInput;
}

model GetSessionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getSession";
  input: GetSessionInput;
}

model ListSessionsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listSessions";
  input: ListSessionsInput;
}

model ListTurnsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listTurns";
  input: ListTurnsInput;
}

model GetTurnRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getTurn";
  input: GetTurnInput;
}

model CancelTurnRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "cancelTurn";
  input: CancelTurnInput;
}

model SteerTurnRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "steerTurn";
  input: SteerTurnInput;
}

model ListSteersRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listSteers";
  input: ListSteersInput;
}

model TakeSteersRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "takeSteers";
  input: TakeSteersInput;
}

model WaitTurnsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "waitTurns";
  input: WaitTurnsInput;
}

model ListEventsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listEvents";
  input: ListEventsInput;
}

model ListWebhookEndpointsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listWebhookEndpoints";
  input: ListWebhookEndpointsInput;
}

model CreateWebhookEndpointRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "createWebhookEndpoint";
  input: CreateWebhookEndpointInput;
}

model GetWebhookEndpointRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getWebhookEndpoint";
  input: GetWebhookEndpointInput;
}

model DeleteWebhookEndpointRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deleteWebhookEndpoint";
  input: DeleteWebhookEndpointInput;
}

model SetWebhookEndpointStatusRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "setWebhookEndpointStatus";
  input: SetWebhookEndpointStatusInput;
}

model ListPushSubscriptionsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listPushSubscriptions";
  input: ListPushSubscriptionsInput;
}

model CreatePushSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "createPushSubscription";
  input: CreatePushSubscriptionInput;
}

model DeletePushSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deletePushSubscription";
  input: DeletePushSubscriptionInput;
}

model ForgetPushSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "forgetPushSubscription";
  input: ForgetPushSubscriptionInput;
}

model PushTargetRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "pushTarget";
  input: PushTargetInput;
}

model CreateSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "createSubscription";
  input: CreateSubscriptionInput;
}

model ListSubscriptionsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listSubscriptions";
  input: ListSubscriptionsInput;
}

model GetSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getSubscription";
  input: GetSubscriptionInput;
}

model PauseSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "pauseSubscription";
  input: PauseSubscriptionInput;
}

model ResumeSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "resumeSubscription";
  input: ResumeSubscriptionInput;
}

model DeleteSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deleteSubscription";
  input: DeleteSubscriptionInput;
}

model CompleteSubscriptionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "completeSubscription";
  input: CompleteSubscriptionInput;
}

model CreateTriggerRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "createTrigger";
  input: CreateTriggerInput;
}

model ListTriggersRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listTriggers";
  input: ListTriggersInput;
}

model GetTriggerRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getTrigger";
  input: GetTriggerInput;
}

model UpdateTriggerRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "updateTrigger";
  input: UpdateTriggerInput;
}

model DeleteTriggerRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deleteTrigger";
  input: DeleteTriggerInput;
}

model TriggerFiredRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "triggerFired";
  input: TriggerFiredInput;
}

model GetTurnFailureRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getTurnFailure";
  input: GetTurnFailureInput;
}

model ListStopFailuresRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listStopFailures";
  input: ListStopFailuresInput;
}

model ListSnapshotsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listSnapshots";
  input: ListSnapshotsInput;
}

model ListCredentialHandoversRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listCredentialHandovers";
  input: ListCredentialHandoversInput;
}

model GetSnapshotRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "getSnapshot";
  input: GetSnapshotInput;
}

model TranscriptCursorRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "transcriptCursor";
  input: TranscriptCursorInput;
}

model ConnectedAccountsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "connectedAccounts";
  input: ConnectedAccountsInput;
}

model DeleteBuildConnectionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deleteBuildConnection";
  input: DeleteBuildConnectionInput;
}

model CircleCIConnectionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "circleCIConnection";
  input: CircleCIConnectionInput;
}

model CircleCITokenRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "circleCIToken";
  input: CircleCITokenInput;
}

model ConnectCircleCIRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "connectCircleCI";
  input: ConnectCircleCIInput;
}

model ListCircleCIProjectsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listCircleCIProjects";
  input: ListCircleCIProjectsInput;
}

model CircleCIProjectBoundToRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "circleCIProjectBoundTo";
  input: CircleCIProjectBoundToInput;
}

model CircleCIProjectOfRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "circleCIProjectOf";
  input: CircleCIProjectOfInput;
}

model AddCircleCIProjectRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "addCircleCIProject";
  input: AddCircleCIProjectInput;
}

model CircleCIWebhooksRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "circleCIWebhooks";
  input: CircleCIWebhooksInput;
}

model CircleCIWebhookSecretRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "circleCIWebhookSecret";
  input: CircleCIWebhookSecretInput;
}

model DeleteCircleCIProjectRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deleteCircleCIProject";
  input: DeleteCircleCIProjectInput;
}

model GitHubActionsConnectionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "gitHubActionsConnection";
  input: GitHubActionsConnectionInput;
}

model ConnectGitHubActionsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "connectGitHubActions";
  input: ConnectGitHubActionsInput;
}

model NamespaceConnectionRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "namespaceConnection";
  input: NamespaceConnectionInput;
}

model ConnectNamespaceRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "connectNamespace";
  input: ConnectNamespaceInput;
}

model OfferSentRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "offerSent";
  input: OfferSentInput;
}

model HostHelloRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "hostHello";
  input: HostHelloInput;
}

model HostUsageRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "hostUsage";
  input: HostUsageInput;
}

model ReconcileHeldBoxesRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "reconcileHeldBoxes";
  input: ReconcileHeldBoxesInput;
}

model ForgetHostUsageRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "forgetHostUsage";
  input: ForgetHostUsageInput;
}

model RunningTurnsByHostRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "runningTurnsByHost";
  input: RunningTurnsByHostInput;
}

model ListHostUsageRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "listHostUsage";
  input: ListHostUsageInput;
}

model DeferredOffersRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deferredOffers";
  input: DeferredOffersInput;
}

model TurnMetricDimensionsRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "turnMetricDimensions";
  input: TurnMetricDimensionsInput;
}

model PrepareOfferRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "prepareOffer";
  input: PrepareOfferInput;
}

model HostPresenceRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "hostPresence";
  input: HostPresenceInput;
}

model HostMessageRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "hostMessage";
  input: HostMessageInput;
}

model DeadlineReachedRequest {
  tenantApiVersion: TenantApiProtocol;
  operation: "deadlineReached";
  input: DeadlineReachedInput;
}

@doc("One request to the tenant Durable Object's single entry point. `operation` names the operation the way a path names a REST operation.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "operation" })
union TenantRequest {
  listPersonas: ListPersonasRequest,
  getPersona: GetPersonaRequest,
  createPersona: CreatePersonaRequest,
  updatePersona: UpdatePersonaRequest,
  patchPersona: PatchPersonaRequest,
  deletePersona: DeletePersonaRequest,
  open: OpenRequest,
  supervisorUpdate: SupervisorUpdateRequest,
  supervisorUpdates: SupervisorUpdatesRequest,
  listSecretSets: ListSecretSetsRequest,
  getSecretSet: GetSecretSetRequest,
  createSecretSet: CreateSecretSetRequest,
  updateSecretSet: UpdateSecretSetRequest,
  patchSecretSet: PatchSecretSetRequest,
  setSecretMember: SetSecretMemberRequest,
  removeSecretMember: RemoveSecretMemberRequest,
  deleteSecretSet: DeleteSecretSetRequest,
  applyConfig: ApplyConfigRequest,
  listPins: ListPinsRequest,
  pin: PinRequest,
  unpin: UnpinRequest,
  listConnectors: ListConnectorsRequest,
  getConnector: GetConnectorRequest,
  createConnector: CreateConnectorRequest,
  renameConnector: RenameConnectorRequest,
  deleteConnector: DeleteConnectorRequest,
  setStaticToken: SetStaticTokenRequest,
  clearConnectorCredential: ClearConnectorCredentialRequest,
  startConnectorAuthorization: StartConnectorAuthorizationRequest,
  connectorCallback: ConnectorCallbackRequest,
  serveConnectorToken: ServeConnectorTokenRequest,
  unknownConnectors: UnknownConnectorsRequest,
  startOpenRouterAuthorization: StartOpenRouterAuthorizationRequest,
  getOpenRouterAuthorization: GetOpenRouterAuthorizationRequest,
  openRouterCallback: OpenRouterCallbackRequest,
  openRouterAuthorizationDeadlineReached: OpenRouterAuthorizationDeadlineReachedRequest,
  openRouterSecretSets: OpenRouterSecretSetsRequest,
  startCircleCIAuthorization: StartCircleCIAuthorizationRequest,
  completeCircleCIAuthorization: CompleteCircleCIAuthorizationRequest,
  chooseCircleCIOrganization: ChooseCircleCIOrganizationRequest,
  circleCIAuthorizationDeadlineReached: CircleCIAuthorizationDeadlineReachedRequest,
  startClaudeSetup: StartClaudeSetupRequest,
  getClaudeSetup: GetClaudeSetupRequest,
  listClaudeSetups: ListClaudeSetupsRequest,
  submitClaudeSetupCode: SubmitClaudeSetupCodeRequest,
  writeClaudeSetupToken: WriteClaudeSetupTokenRequest,
  claudeSetupDeadlineReached: ClaudeSetupDeadlineReachedRequest,
  prepareClaudeSetup: PrepareClaudeSetupRequest,
  listPrebuilds: ListPrebuildsRequest,
  listLatestPrebuilds: ListLatestPrebuildsRequest,
  getPrebuild: GetPrebuildRequest,
  heldPrebuild: HeldPrebuildRequest,
  recordPrebuildBuilding: RecordPrebuildBuildingRequest,
  jobInputsTarget: JobInputsTargetRequest,
  bindJobRun: BindJobRunRequest,
  workflowRunReported: WorkflowRunReportedRequest,
  prebuildDeadlineReached: PrebuildDeadlineReachedRequest,
  startGitHubActionsPrebuild: StartGitHubActionsPrebuildRequest,
  startHostPrebuild: StartHostPrebuildRequest,
  uploadTarget: UploadTargetRequest,
  bindCircleCIUploadJob: BindCircleCIUploadJobRequest,
  startPrebuildUpload: StartPrebuildUploadRequest,
  completePrebuildUpload: CompletePrebuildUploadRequest,
  getPrebuildFailure: GetPrebuildFailureRequest,
  dispatchCircleCIPrebuild: DispatchCircleCIPrebuildRequest,
  circleCIWorkflowCompleted: CircleCIWorkflowCompletedRequest,
  repositoryReadToken: RepositoryReadTokenRequest,
  startSession: StartSessionRequest,
  startSessionFromIssue: StartSessionFromIssueRequest,
  sendTurn: SendTurnRequest,
  stopSession: StopSessionRequest,
  archiveSession: ArchiveSessionRequest,
  setSessionTags: SetSessionTagsRequest,
  patchSessionTags: PatchSessionTagsRequest,
  deleteSession: DeleteSessionRequest,
  getSession: GetSessionRequest,
  listSessions: ListSessionsRequest,
  listTurns: ListTurnsRequest,
  getTurn: GetTurnRequest,
  cancelTurn: CancelTurnRequest,
  steerTurn: SteerTurnRequest,
  listSteers: ListSteersRequest,
  takeSteers: TakeSteersRequest,
  waitTurns: WaitTurnsRequest,
  listEvents: ListEventsRequest,
  listWebhookEndpoints: ListWebhookEndpointsRequest,
  createWebhookEndpoint: CreateWebhookEndpointRequest,
  getWebhookEndpoint: GetWebhookEndpointRequest,
  deleteWebhookEndpoint: DeleteWebhookEndpointRequest,
  setWebhookEndpointStatus: SetWebhookEndpointStatusRequest,
  listPushSubscriptions: ListPushSubscriptionsRequest,
  createPushSubscription: CreatePushSubscriptionRequest,
  deletePushSubscription: DeletePushSubscriptionRequest,
  forgetPushSubscription: ForgetPushSubscriptionRequest,
  pushTarget: PushTargetRequest,
  createSubscription: CreateSubscriptionRequest,
  listSubscriptions: ListSubscriptionsRequest,
  getSubscription: GetSubscriptionRequest,
  pauseSubscription: PauseSubscriptionRequest,
  resumeSubscription: ResumeSubscriptionRequest,
  deleteSubscription: DeleteSubscriptionRequest,
  completeSubscription: CompleteSubscriptionRequest,
  createTrigger: CreateTriggerRequest,
  listTriggers: ListTriggersRequest,
  getTrigger: GetTriggerRequest,
  updateTrigger: UpdateTriggerRequest,
  deleteTrigger: DeleteTriggerRequest,
  triggerFired: TriggerFiredRequest,
  getTurnFailure: GetTurnFailureRequest,
  listStopFailures: ListStopFailuresRequest,
  listSnapshots: ListSnapshotsRequest,
  listCredentialHandovers: ListCredentialHandoversRequest,
  getSnapshot: GetSnapshotRequest,
  transcriptCursor: TranscriptCursorRequest,
  connectedAccounts: ConnectedAccountsRequest,
  deleteBuildConnection: DeleteBuildConnectionRequest,
  circleCIConnection: CircleCIConnectionRequest,
  circleCIToken: CircleCITokenRequest,
  connectCircleCI: ConnectCircleCIRequest,
  listCircleCIProjects: ListCircleCIProjectsRequest,
  circleCIProjectBoundTo: CircleCIProjectBoundToRequest,
  circleCIProjectOf: CircleCIProjectOfRequest,
  addCircleCIProject: AddCircleCIProjectRequest,
  circleCIWebhooks: CircleCIWebhooksRequest,
  circleCIWebhookSecret: CircleCIWebhookSecretRequest,
  deleteCircleCIProject: DeleteCircleCIProjectRequest,
  gitHubActionsConnection: GitHubActionsConnectionRequest,
  connectGitHubActions: ConnectGitHubActionsRequest,
  namespaceConnection: NamespaceConnectionRequest,
  connectNamespace: ConnectNamespaceRequest,
  offerSent: OfferSentRequest,
  hostHello: HostHelloRequest,
  hostUsage: HostUsageRequest,
  reconcileHeldBoxes: ReconcileHeldBoxesRequest,
  forgetHostUsage: ForgetHostUsageRequest,
  runningTurnsByHost: RunningTurnsByHostRequest,
  listHostUsage: ListHostUsageRequest,
  deferredOffers: DeferredOffersRequest,
  turnMetricDimensions: TurnMetricDimensionsRequest,
  prepareOffer: PrepareOfferRequest,
  hostPresence: HostPresenceRequest,
  hostMessage: HostMessageRequest,
  deadlineReached: DeadlineReachedRequest,
}

@doc("The request names a version outside the instance's window, or an older version an adapter cannot translate. The caller answers a retryable failure.")
model TenantApiVersionUnsupported {
  refusal: "TenantApiVersionUnsupported";
  oldestTenantApiVersion: int32;
  tenantApiVersion: int32;
}

@doc("The instance does not know the operation: it runs older code. The caller answers a retryable failure.")
model TenantOperationUnknown {
  refusal: "TenantOperationUnknown";
  operation: string;
}

@doc("The input fails the operation's schema: a caller bug, which the caller fails as a 500.")
model TenantRequestInvalid {
  refusal: "TenantRequestInvalid";
  operation: string;
  issues: string[];
}

@doc("Why the tenant Durable Object served no result.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "refusal" })
union TenantRefusal {
  TenantApiVersionUnsupported: TenantApiVersionUnsupported,
  TenantOperationUnknown: TenantOperationUnknown,
  TenantRequestInvalid: TenantRequestInvalid,
}

@doc("A unique constraint refused the write.")
model WriteConflict {
  ok: false;
  constraint: string;
}

model PersonaWritten {
  ok: true;
  value: StoredPersona;
}

model PersonaUpdated {
  ok: true;
  @doc("Null when no persona has the id.")
  value: StoredPersona | null;
}

model ListPersonasResult {
  personas: StoredPersona[];
}

model GetPersonaResult {
  persona: StoredPersona | null;
}

model CreatePersonaResult {
  written: PersonaWritten | WriteConflict;
}

model UpdatePersonaResult {
  written: PersonaUpdated | WriteConflict;
}

model PatchPersonaResult {
  written: PersonaUpdated | WriteConflict;
}

model PersonaDeleted {
  kind: "Deleted";
}

model PersonaNotFound {
  kind: "NotFound";
}

model PersonaInUse {
  kind: "InUse";
  sessions: EntityId[];
}

model DeletePersonaResult {
  deleted: PersonaDeleted | PersonaNotFound | PersonaInUse;
}

  model OpenResult {}

  model SupervisorUpdateResult {}

  @doc("The latest update step and failure a host reported.")
  model SupervisorUpdates {
    supervisorUpdateStep: SupervisorUpdateLatestStep;
    supervisorUpdateFailure: SupervisorUpdateLatestFailure;
  }

  model SupervisorUpdatesResult {
    byHost: Record<SupervisorUpdates>;
  }

  @doc("A stored member no longer matches its kind, so the set cannot be read.")
  model SecretSetUnreadable {
    kind: "Unreadable";
    secretSetId: EntityId;
    name: string;
    member: string;
    detail: string;
  }

  model SecretSetsRead {
    kind: "Read";
    secretSets: SecretSet[];
  }

  model ListSecretSetsResult {
    read: SecretSetsRead | SecretSetUnreadable;
  }

  model SecretSetFound {
    kind: "Found";
    secretSet: SecretSet;
  }

  model SecretSetNotFound {
    kind: "NotFound";
  }

  model GetSecretSetResult {
    read: SecretSetFound | SecretSetNotFound | SecretSetUnreadable;
  }

  model SecretSetWritten {
    ok: true;
    value: SecretSet;
  }

  model CreateSecretSetResult {
    written: SecretSetWritten | WriteConflict;
  }

  model SecretSetUpdated {
    kind: "Updated";
    secretSet: SecretSet;
  }

  model SecretSetMissing {
    kind: "SetNotFound";
  }

  model SecretSetConflict {
    kind: "Conflict";
    constraint: string;
  }

  model SecretSetNoStoredValue {
    kind: "NoStoredValue";
    name: string;
    source: string;
  }

  model SecretSetUncheckedToken {
    kind: "UncheckedToken";
    source: string;
  }

  model UpdateSecretSetResult {
    updated: SecretSetUpdated | SecretSetMissing | SecretSetConflict | SecretSetNoStoredValue | SecretSetUncheckedToken;
  }

  model PatchSecretSetResult {
    patched: SecretSetUpdated | SecretSetMissing | SecretSetConflict | SecretSetNoStoredValue | SecretSetUncheckedToken;
  }

  model SecretMemberWritten {
    kind: "Set";
    secretSet: SecretSet;
  }

  model SetSecretMemberResult {
    set: SecretMemberWritten | SecretSetMissing | SecretSetConflict | SecretSetUnreadable;
  }

  model SecretMemberRemoved {
    kind: "Removed";
    secretSet: SecretSet;
  }

  model SecretMemberNotFound {
    kind: "MemberNotFound";
  }

  model RemoveSecretMemberResult {
    removed: SecretMemberRemoved | SecretSetMissing | SecretMemberNotFound | SecretSetUnreadable;
  }

  model SecretSetDeleted {
    kind: "Deleted";
  }

  model SecretSetInUse {
    kind: "InUse";
    personas: string[];
  }

  model DeleteSecretSetResult {
    deleted: SecretSetDeleted | SecretSetNotFound | SecretSetInUse;
  }

  model ConfigApplied {
    kind: "Applied";
  }

  model ConfigConflict {
    kind: "Conflict";
    constraint: string;
  }

  model ConfigResourceDeleted {
    kind: "Deleted";
    resource: string;
  }

  model ApplyConfigResult {
    applied: ConfigApplied | ConfigConflict | ConfigResourceDeleted;
  }

  model ListPinsResult {
    pins: HarnessPin[];
  }

  model PinResult {
    pin: HarnessPin;
  }

  model UnpinResult {
    unpinned: boolean;
  }

model ListConnectorsResult {
  connectors: Connector[];
}

model GetConnectorResult {
  connector: Connector | null;
}

model ConnectorWrittenOk {
  kind: "Written";
  connector: Connector;
}

model ConnectorNotFound {
  kind: "NotFound";
}

model ConnectorNameTaken {
  kind: "NameTaken";
}

model ConnectorChanged {
  kind: "Changed";
}

model ConnectorWrittenResult {
  written: ConnectorWrittenOk | ConnectorNotFound | ConnectorNameTaken | ConnectorChanged;
}

model ConnectorDeletedOk {
  kind: "Deleted";
}

model ConnectorInUse {
  kind: "InUse";
  detail: string;
}

model DeleteConnectorResult {
  deleted: ConnectorDeletedOk | ConnectorNotFound | ConnectorChanged | ConnectorInUse;
}

model ConnectorAuthorizeStartedOk {
  kind: "Started";
  authorization: ConnectorAuthorization;
}

model ConnectorDiscoveryFailed {
  kind: "DiscoveryFailed";
  detail: string;
}

model ConnectorRegistrationUnsupported {
  kind: "RegistrationUnsupported";
  detail: string;
}

model StartConnectorAuthorizationResult {
  started: ConnectorAuthorizeStartedOk | ConnectorNotFound | ConnectorChanged | ConnectorDiscoveryFailed | ConnectorRegistrationUnsupported;
}

model ConnectorCallbackConnected {
  kind: "Connected";
  name: string;
}

model ConnectorCallbackNotConnected {
  kind: "NotConnected";
  detail: string;
}

model ConnectorCallbackResult {
  settled: ConnectorCallbackConnected | ConnectorCallbackNotConnected;
}

model ConnectorTokenServedOk {
  kind: "Served";
  token: ConnectorAccessToken;
}

model ConnectorTokenRefused {
  kind: "Refused";
}

model ConnectorTurnNotRunning {
  kind: "NotRunning";
}

model ConnectorNoCredential {
  kind: "NoCredential";
  name: string;
}

model ConnectorRefreshFailed {
  kind: "RefreshFailed";
  detail: string;
}

model ServeConnectorTokenResult {
  served: ConnectorTokenServedOk | ConnectorTokenRefused | ConnectorTurnNotRunning | ConnectorNoCredential | ConnectorRefreshFailed;
}

model UnknownConnectorsResult {
  unknownConnectorIds: EntityId[];
}

model CreateConnectorResult {
  ...ConnectorWrittenResult;
}

model RenameConnectorResult {
  ...ConnectorWrittenResult;
}

model SetStaticTokenResult {
  ...ConnectorWrittenResult;
}

model ClearConnectorCredentialResult {
  ...ConnectorWrittenResult;
}

model OpenRouterAuthorizationStartedOk {
  kind: "Started";
  authorization: OpenRouterAuthorization;
}

model AuthorizationNoSecretSet {
  kind: "NoSecretSet";
}

model AuthorizationOtherCredential {
  kind: "OtherCredential";
  name: string;
}

model StartOpenRouterAuthorizationResult {
  started: OpenRouterAuthorizationStartedOk | AuthorizationNoSecretSet | AuthorizationOtherCredential;
}

model OpenRouterAuthorizationFound {
  kind: "Found";
  authorization: OpenRouterAuthorization;
}

model AuthorizationNotFound {
  kind: "NotFound";
}

model GetOpenRouterAuthorizationResult {
  read: OpenRouterAuthorizationFound | AuthorizationNotFound;
}

model OpenRouterReturned {
  kind: "Returned";
  secretSetId: EntityId;
}

model OpenRouterCallbackResult {
  settled: OpenRouterReturned | AuthorizationNotFound;
}

model OpenRouterAuthorizationDeadlineReachedResult {}

model OpenRouterSecretSetsResult {
  names: string[];
}

model CircleCIAuthorizationStartedOk {
  kind: "Started";
  authorization: CircleCIAuthorization;
}

model CircleCIRegistrationRefused {
  kind: "RegistrationRefused";
  detail: string;
}

model StartCircleCIAuthorizationResult {
  started: CircleCIAuthorizationStartedOk | CircleCIRegistrationRefused;
}

model CircleCIAuthorizationSteppedOk {
  kind: "Stepped";
  authorization: CircleCIAuthorization;
}

model AuthorizationNotWaiting {
  kind: "NotWaiting";
  detail: string;
}

model AuthorizationInvalid {
  kind: "Invalid";
  detail: string;
}

model CircleCIAuthorizationStepped {
  stepped: CircleCIAuthorizationSteppedOk | AuthorizationNotFound | AuthorizationNotWaiting | AuthorizationInvalid;
}

model CompleteCircleCIAuthorizationResult {
  ...CircleCIAuthorizationStepped;
}

model ChooseCircleCIOrganizationResult {
  ...CircleCIAuthorizationStepped;
}

model CircleCIAuthorizationDeadlineReachedResult {}

model ImageAvailability {
  harness: string;
  harnessVersion: string;
  architectures: HostArchitecture[];
}

model UnplaceableNotOnline {
  kind: "Unplaceable";
  host: HostRecord;
  reason: "NotOnline";
}

model UnplaceableNoImage {
  kind: "Unplaceable";
  host: HostRecord;
  reason: "NoImage";
  image: ImageAvailability;
}

model UnplaceableFull {
  kind: "Unplaceable";
  host: HostRecord;
  reason: "Full";
  usage: ReportedHostUsage;
}

model UnplaceableMemoryFull {
  kind: "Unplaceable";
  host: HostRecord;
  reason: "MemoryFull";
  usage: ReportedHostUsage;
  boxMemoryMib: int32;
}

model UnplaceableNoMemory {
  kind: "Unplaceable";
  host: HostRecord;
  reason: "NoMemory";
  usage: ReportedHostUsage;
  boxMemoryMib: int32;
}

model UnplaceableNoDisk {
  kind: "Unplaceable";
  host: HostRecord;
  reason: "NoDisk";
  usage: ReportedHostUsage;
  boxDiskMib: int32;
}

model UnplaceableNoConnectors {
  kind: "Unplaceable";
  host: HostRecord;
  reason: "NoConnectors";
  usage: ReportedHostUsage;
}

@doc("Why placement passed over a host.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "reason" })
union Unplaceable {
  NotOnline: UnplaceableNotOnline,
  NoImage: UnplaceableNoImage,
  Full: UnplaceableFull,
  MemoryFull: UnplaceableMemoryFull,
  NoMemory: UnplaceableNoMemory,
  NoDisk: UnplaceableNoDisk,
  NoConnectors: UnplaceableNoConnectors,
}

model ClaudeSetupStartedOk {
  kind: "Started";
  setup: ClaudeSetup;
}

model ClaudeSetupUnplaced {
  kind: "Unplaced";
  hosts: Unplaceable[];
}

model ClaudeSetupReleaseUnreadable {
  kind: "ReleaseUnreadable";
  detail: string;
}

model StartClaudeSetupResult {
  started: ClaudeSetupStartedOk | ClaudeSetupUnplaced | ClaudeSetupReleaseUnreadable | AuthorizationNoSecretSet | AuthorizationOtherCredential;
}

model GetClaudeSetupResult {
  setup: ClaudeSetup | null;
}

model ListClaudeSetupsResult {
  setups: ClaudeSetup[];
}

model ClaudeSetupCodedOk {
  kind: "Coded";
  setup: ClaudeSetup;
}

model SubmitClaudeSetupCodeResult {
  coded: ClaudeSetupCodedOk | AuthorizationNotFound | AuthorizationNotWaiting;
}

model ClaudeSetupStoredOk {
  kind: "Stored";
}

model ClaudeSetupRefused {
  kind: "Refused";
}

model ClaudeSetupNotStored {
  kind: "NotStored";
  detail: string;
}

model WriteClaudeSetupTokenResult {
  stored: ClaudeSetupStoredOk | AuthorizationNotFound | ClaudeSetupRefused | AuthorizationNotWaiting | ClaudeSetupNotStored;
}

model ClaudeSetupDeadlineReachedResult {}

model ClaudeSetupReady {
  kind: "Ready";
  message: Channel.ClaudeSetupBoxOffer | Channel.ClaudeSetupBoxCode;
}

model ClaudeSetupWithdrawn {
  kind: "Withdrawn";
  message: Channel.ClaudeSetupBoxDiscard;
}

model PrepareClaudeSetupResult {
  prepared: ClaudeSetupReady | ClaudeSetupWithdrawn;
}

model ListPrebuildsResult {
  prebuilds: Prebuild[];
}

model ListLatestPrebuildsResult {
  prebuilds: Prebuild[];
}

model GetPrebuildResult {
  prebuild: Prebuild | null;
}

model HeldPrebuildResult {
  prebuild: Prebuild | null;
}

model RecordPrebuildBuildingResult {}

model CallerWorkflowConnected {
  kind: "Connected";
  callerWorkflow: string;
}

model CallerWorkflowNotConnected {
  kind: "NotConnected";
}

model JobInputsTarget {
  prebuild: Prebuild;
  defaultBranch: string;
  callerWorkflow: CallerWorkflowConnected | CallerWorkflowNotConnected;
  headSha: string;
  rootfsKey: string;
}

model JobInputsTargetResult {
  target: JobInputsTarget | null;
}

model JobRunBoundOk {
  kind: "Bound";
  prebuild: Prebuild;
}

model JobRunOther {
  kind: "OtherRun";
  runId: int64;
}

model BindJobRunResult {
  bound: JobRunBoundOk | JobRunOther;
}

model WorkflowRunReportedResult {}

model PrebuildDeadlineReachedResult {}

model PrebuildStarted {
  kind: "Started";
  prebuild: Prebuild;
}

model PrebuildNoInstallation {
  kind: "NoInstallation";
}

model PrebuildTokenRefused {
  kind: "TokenRefused";
  detail: string;
}

model PrebuildUnreadable {
  kind: "Unreadable";
  detail: string;
}

model PrebuildPermissionMissing {
  kind: "PermissionMissing";
  permissions: string[];
  appSlug: string;
}

model PrebuildAppPermissionMissing {
  kind: "AppPermissionMissing";
  permissions: string[];
  appSlug: string;
  appOwner: string;
}

model PrebuildCallerRefused {
  kind: "CallerRefused";
  detail: string;
}

model PrebuildActionsDisabled {
  kind: "ActionsDisabled";
  detail: string;
}

model PrebuildRefused {
  kind: "Refused";
  detail: string;
}

model StartGitHubActionsPrebuildResult {
  started: PrebuildStarted | PrebuildNoInstallation | PrebuildTokenRefused | PrebuildUnreadable | PrebuildPermissionMissing | PrebuildAppPermissionMissing | PrebuildCallerRefused | PrebuildActionsDisabled | PrebuildRefused;
}

model HostPrebuildStarted {
  kind: "Started";
  started: Prebuild;
}

model StartDraining {
  kind: "Draining";
}

model StartUnplaced {
  kind: "Unplaced";
  hosts: Unplaceable[];
}

model StartConnectorDisconnected {
  kind: "ConnectorDisconnected";
  names: string[];
}

model StartHostPrebuildResult {
  started: HostPrebuildStarted | StartDraining | StartUnplaced | StartConnectorDisconnected | ClaudeSetupReleaseUnreadable;
}

model PrebuildRun {
  runId: int64;
  headSha: string;
}

model UploadJobRecorded {
  kind: "Job";
  jobId: string;
}

model UploadJobAbsent {
  kind: "NoJob";
}

model RecordedPipeline {
  pipelineId: string;
  projectId: string;
  headSha: string;
  job: UploadJobRecorded | UploadJobAbsent;
}

model GitHubActionsUploadTarget {
  provider: "GitHubActions";
  prebuild: Prebuild;
  defaultBranch: string;
  upload: PrebuildLayerUpload | null;
  callerWorkflow: CallerWorkflowConnected | CallerWorkflowNotConnected;
  run: PrebuildRun;
}

model CircleCIUploadTarget {
  provider: "CircleCI";
  prebuild: Prebuild;
  defaultBranch: string;
  upload: PrebuildLayerUpload | null;
  organizationId: string;
  pipeline: RecordedPipeline;
}

model UploadTargetResult {
  target: GitHubActionsUploadTarget | CircleCIUploadTarget | null;
}

model CircleCIJobBoundOk {
  kind: "Bound";
}

model CircleCIJobOther {
  kind: "OtherJob";
  jobId: string;
}

model CircleCIRevisionMoved {
  kind: "RevisionMoved";
  prebuild: Prebuild;
}

model CircleCIJobRefused {
  kind: "Refused";
  status: int32;
  detail: string;
}

model BindCircleCIUploadJobResult {
  bound: CircleCIJobBoundOk | CircleCIJobOther | CircleCIRevisionMoved | CircleCIJobRefused;
}

model UploadRecordedOk {
  kind: "Recorded";
  prebuild: Prebuild;
}

model UploadNotUploading {
  kind: "NotUploading";
  prebuild: Prebuild;
}

model UploadOtherLayer {
  kind: "OtherLayer";
  prebuild: Prebuild;
  recorded: PrebuildLayerUpload;
}

model UploadRecorded {
  recorded: UploadRecordedOk | UploadNotUploading | UploadOtherLayer;
}

model StartPrebuildUploadResult {
  ...UploadRecorded;
}

model CompletePrebuildUploadResult {
  ...UploadRecorded;
}

model GetPrebuildFailureResult {
  failure: PrebuildFailure | null;
}

model CircleCIDispatched {
  kind: "Dispatched";
  prebuild: Prebuild;
}

model CircleCIDispatchNotConnected {
  kind: "NotConnected";
}

model DispatchCircleCIPrebuildResult {
  dispatched: CircleCIDispatched | CircleCIDispatchNotConnected | PrebuildRefused;
}

model CircleCIWorkflowCompletedResult {}

model ReadTokenOk {
  kind: "Token";
  token: string;
}

model RepositoryReadTokenResult {
  read: ReadTokenOk | PrebuildRefused;
}

model SessionStartedOk {
  kind: "Started";
  started: StartedSession;
}

model StartSessionResult {
  started: SessionStartedOk | StartDraining | StartUnplaced | StartConnectorDisconnected | ClaudeSetupReleaseUnreadable | SessionTagsOverLimit;
}

model SessionFromIssueStartedOk {
  kind: "Started";
  started: StartedSessionFromIssue;
}

model StartSessionFromIssueResult {
  started: SessionFromIssueStartedOk | StartDraining | StartUnplaced | StartConnectorDisconnected | ClaudeSetupReleaseUnreadable | SessionTagsOverLimit;
}

model TurnSentOk {
  kind: "Sent";
  turn: Turn;
}

model TurnStranded {
  kind: "Stranded";
  missingTurnIds: EntityId[];
}

model SessionNotFound {
  kind: "NotFound";
}

model TurnInFlight {
  kind: "InFlight";
  turnId: EntityId;
}

model SessionStopping {
  kind: "Stopping";
}

model SessionArchivedState {
  kind: "Archived";
}

model SessionFailedState {
  kind: "Failed";
}

model NoCredentialRefusal {
  kind: "NoCredential";
  accepted: HarnessCredential[];
}

model NoModelCredentialRefusal {
  kind: "NoModelCredential";
  `model`: string;
  provider: ModelProvider;
  accepted: HarnessCredential[];
}

model UnsupportedCredentialRefusal {
  kind: "Unsupported";
  name: string;
  credentialKind: string;
  supported: string[];
}

model ModelUnsupportedCredentialRefusal {
  kind: "ModelUnsupported";
  `model`: ModelName;
  name: string;
  credentialKind: string;
  allowed: ModelName[];
}

model ExpiredCredentialRefusal {
  kind: "Expired";
  name: string;
  expiresAt: string;
}

model TurnCredentialRefused {
  kind: "CredentialRefused";
  personaId: EntityId;
  refusal: NoCredentialRefusal | NoModelCredentialRefusal | UnsupportedCredentialRefusal | ModelUnsupportedCredentialRefusal | ExpiredCredentialRefusal;
}

model SendTurnResult {
  sent: TurnSentOk | StartDraining | TurnStranded | StartUnplaced | StartConnectorDisconnected | ClaudeSetupReleaseUnreadable | SessionNotFound | SessionStopping | SessionArchivedState | SessionFailedState | TurnCredentialRefused;
}

model SessionStoppingWith {
  kind: "Stopping";
  session: Session;
}

model CancelUnspoken {
  kind: "CancelUnspoken";
  turnId: EntityId;
  host: string;
}

model StopSessionResult {
  stopped: SessionStoppingWith | SessionNotFound | TurnInFlight | CancelUnspoken | SessionArchivedState;
}

model SessionArchivedOk {
  kind: "Archived";
  session: Session;
}

model SessionNotStopped {
  kind: "NotStopped";
  state: SessionState;
}

model ArchiveSessionResult {
  archived: SessionArchivedOk | SessionNotFound | SessionNotStopped;
}

model SessionTagged {
  kind: "Tagged";
  session: Session;
}

@doc("A patch or a start whose tags, with the crew tags a start inherits, would number more than 16; nothing changes.")
model SessionTagsOverLimit {
  kind: "TagsOverLimit";
  tags: SessionTag[];
}

model SetSessionTagsResult {
  tagged: SessionTagged | SessionNotFound;
}

model PatchSessionTagsResult {
  tagged: SessionTagged | SessionNotFound | SessionTagsOverLimit;
}

model SessionDeleted {
  kind: "Deleted";
}

model DeleteSessionResult {
  deleted: SessionDeleted | SessionNotFound | SessionNotStopped;
}

model GetSessionResult {
  session: Session | null;
}

model ListSessionsResult {
  sessions: Session[];
}

model ListTurnsResult {
  turns: Turn[] | null;
}

model GetTurnResult {
  turn: Turn | null;
}

model TurnCancelledOk {
  kind: "Cancelled";
  turn: Turn;
}

model TurnNotFound {
  kind: "NotFound";
}

model TurnNotWaiting {
  kind: "NotWaiting";
  state: TurnState;
}

model CancelTurnResult {
  cancelled: TurnCancelledOk | TurnNotFound | TurnNotWaiting;
}

model SteerSentOk {
  kind: "Sent";
  steer: Steer;
}

model TurnNotRunning {
  kind: "NotRunning";
  state: TurnState;
}

model SteerUnsupported {
  kind: "Unsupported";
}

model SteerTurnResult {
  sent: SteerSentOk | TurnNotFound | TurnNotRunning | SteerUnsupported;
}

model ListSteersResult {
  steers: Steer[] | null;
}

model SteersTaken {
  kind: "Taken";
  prompts: Prompt[];
}

model SteerInboxClosed {
  kind: "Closed";
}

model TakeSteersResult {
  taken: SteersTaken | SteerInboxClosed;
}

model TurnsRead {
  kind: "Read";
  turns: Turn[];
}

model WaitedTurnNotFound {
  kind: "NotFound";
  turnId: EntityId;
}

model WaitTurnsResult {
  waited: TurnsRead | WaitedTurnNotFound;
}

model EventsRead {
  kind: "Read";
  page: EventPage;
}

@doc("The afterEventId is older than the oldest event the log keeps.")
model EventCursorExpired {
  kind: "CursorExpired";
  oldestEventId: Sequence;
}

model ListEventsResult {
  listed: EventsRead | EventCursorExpired;
}

@doc("Where and how a push subscription receives its notifications.")
model PushDeliveryTarget {
  endpoint: PushEndpointUrl;
  keys: PushSubscriptionKeys;
  events: TenantEventType[];
}

model ListWebhookEndpointsResult {
  endpoints: WebhookEndpoint[];
}

model CreateWebhookEndpointResult {
  endpoint: WebhookEndpoint;
}

model GetWebhookEndpointResult {
  @doc("Null when the tenant has no webhook endpoint with the id.")
  endpoint: WebhookEndpoint | null;
}

model DeleteWebhookEndpointResult {
  @doc("False when the tenant has no webhook endpoint with the id.")
  deleted: boolean;
}

model SetWebhookEndpointStatusResult {}

model ListPushSubscriptionsResult {
  subscriptions: PushSubscription[];
}

model CreatePushSubscriptionResult {
  subscription: PushSubscription;
}

model DeletePushSubscriptionResult {
  @doc("False when the principal has no push subscription with the id.")
  deleted: boolean;
}

model ForgetPushSubscriptionResult {}

model PushTargetResult {
  @doc("Null when the subscription is gone.")
  target: PushDeliveryTarget | null;
}

model SubscriptionCreatedOk {
  kind: "Created";
  subscription: Subscription;
}

model CreateSubscriptionResult {
  created: SubscriptionCreatedOk | SessionNotFound | SessionArchivedState | SessionFailedState;
}

model ListSubscriptionsResult {
  subscriptions: Subscription[];
}

model GetSubscriptionResult {
  @doc("Null when the tenant has no subscription with the id.")
  subscription: Subscription | null;
}

model SubscriptionChangedOk {
  kind: "Changed";
  subscription: Subscription;
}

model SubscriptionNotFound {
  kind: "NotFound";
}

model SubscriptionEndedState {
  kind: "Ended";
  subscription: Subscription;
}

@doc("The subscription's cursor is older than the oldest event the log keeps; it stays Paused.")
model SubscriptionCursorExpired {
  kind: "CursorExpired";
  cursorEventId: Sequence;
  oldestEventId: Sequence;
}

model PauseSubscriptionResult {
  paused: SubscriptionChangedOk | SubscriptionNotFound | SubscriptionEndedState;
}

model ResumeSubscriptionResult {
  resumed: SubscriptionChangedOk | SubscriptionNotFound | SubscriptionEndedState | SubscriptionCursorExpired;
}

model DeleteSubscriptionResult {
  @doc("False when the tenant has no subscription with the id.")
  deleted: boolean;
}

model CompleteSubscriptionResult {
  completed: SubscriptionChangedOk | SubscriptionNotFound | SubscriptionEndedState;
}

model TriggerCreatedOk {
  kind: "Created";
  trigger: Trigger;
}

model TriggerUpdatedOk {
  kind: "Updated";
  trigger: Trigger;
}

model TriggerNotFound {
  kind: "NotFound";
}

@doc("The tenant has another trigger of the name.")
model TriggerNameTaken {
  kind: "NameTaken";
}

@doc("The tenant has no persona with the trigger's personaId.")
model TriggerPersonaNotFound {
  kind: "PersonaNotFound";
}

model CreateTriggerResult {
  created: TriggerCreatedOk | TriggerNameTaken | TriggerPersonaNotFound;
}

model ListTriggersResult {
  triggers: Trigger[];
}

model GetTriggerResult {
  @doc("Null when the tenant has no trigger with the id.")
  trigger: Trigger | null;
}

model UpdateTriggerResult {
  updated: TriggerUpdatedOk | TriggerNotFound | TriggerNameTaken | TriggerPersonaNotFound;
}

model DeleteTriggerResult {
  @doc("False when the tenant has no trigger with the id.")
  deleted: boolean;
}

@doc("An earlier delivery with the same id already started a session, so this one starts nothing.")
model TriggerDeliveryRepeated {
  kind: "Repeated";
  sessionId: EntityId;
}

@doc("The start was refused and TriggerStartRefused appended with the refusal.")
model TriggerStartRefusedOk {
  kind: "Refused";
  refusal: TriggerStartRefusal;
}

model TriggerFiredResult {
  fired: SessionStartedOk | TriggerDeliveryRepeated | TriggerNotFound | TriggerStartRefusedOk;
}

model GetTurnFailureResult {
  failure: TurnFailure | null;
}

model ListStopFailuresResult {
  failures: StopFailure[] | null;
}

model ListSnapshotsResult {
  snapshots: Snapshot[] | null;
}

model ListCredentialHandoversResult {
  handovers: CredentialHandover[] | null;
}

model GetSnapshotResult {
  snapshot: Snapshot | null;
}

model ByteRange {
  offset: int64;
  length: int64;
}

model TranscriptChunk {
  kind: "Chunk";
  sessionState: SessionState;
  harness: Harness;
  lastLineSeq: int64;
  inFlight: boolean;
  storageKey: string;
  range: ByteRange;
}

model TranscriptLines {
  kind: "Lines";
  sessionState: SessionState;
  harness: Harness;
  lastLineSeq: int64;
  inFlight: boolean;
  lines: TranscriptLine[];
}

model TranscriptCursorResult {
  cursor: TranscriptChunk | TranscriptLines | null;
}

model ConnectedAccounts {
  GitHubActions: string | null;
  CircleCI: string | null;
  Namespace: string | null;
}

model ConnectedAccountsResult {
  accounts: ConnectedAccounts;
}

model DeleteBuildConnectionResult {
  deleted: boolean;
}

model CircleCICredentialAuthorized {
  kind: "Authorized";
  @doc("When the OAuth token expires, in epoch milliseconds.")
  expiresAtMs: int64;
}

model CircleCICredentialPasted {
  kind: "Pasted";
}

@doc("The tenant's CircleCI connection as the tenant Durable Object stores it, without its secret.")
model CircleCIConnectionRecord {
  circleCIConnectionId: EntityId;
  accountLabel: string;
  organizationId: string;
  credential: CircleCICredentialAuthorized | CircleCICredentialPasted;
  createdAt: int64;
  updatedAt: int64;
}

model CircleCIConnectionResult {
  connection: CircleCIConnectionRecord | null;
}

model CircleCITokenResult {
  token: string | null;
}

model ConnectCircleCIResult {
  connection: CircleCIConnectionRecord;
}

model ListCircleCIProjectsResult {
  projects: CircleCIProject[];
}

model CircleCIProjectBoundToResult {
  project: CircleCIProject | null;
}

model CircleCIProjectOfResult {
  project: CircleCIProject | null;
}

model AddCircleCIProjectResult {
  project: CircleCIProject;
}

model CircleCIWebhook {
  circleCIProjectId: EntityId;
  webhookId: string;
}

model CircleCIWebhooksResult {
  webhooks: CircleCIWebhook[];
}

model CircleCIWebhookSecretResult {
  secret: string | null;
}

model DeleteCircleCIProjectResult {
  deleted: boolean;
}

model GitHubActionsConnectionResult {
  connection: GitHubActionsConnection | null;
}

model ConnectGitHubActionsResult {
  connection: GitHubActionsConnection;
}

@doc("The tenant's Namespace connection as the tenant Durable Object stores it.")
model NamespaceConnectionRecord {
  namespaceConnectionId: EntityId;
  accountLabel: string;
  workspaceId: string;
  createdAt: int64;
  updatedAt: int64;
}

model NamespaceConnectionResult {
  connection: NamespaceConnectionRecord | null;
}

model ConnectNamespaceResult {
  connection: NamespaceConnectionRecord;
}

model OfferSentResult {}

model HostHelloResult {}

model HostUsageResult {}

model ReconcileHeldBoxesResult {}

model ForgetHostUsageResult {}

model RunningTurns {
  hostId: EntityId;
  runningTurns: int32;
}

model RunningTurnsByHostResult {
  running: RunningTurns[];
}

model ListHostUsageResult {
  usage: ReportedHostUsage[];
}

@doc("A turn offer as the control plane stores it, before it adds the parts minted at each send.")
model StoredTurnOffer {
  ...OmitProperties<Channel.TurnOffer, "credential" | "lastLineSeq" | "snapshots" | "personaFiles" | "image" | "gitAuthorName" | "gitAuthorEmail">;
}

model TurnHandoff {
  type: "TurnHandoff";
  hostId: EntityId;
  offer: StoredTurnOffer;
}

model DeferredOffersResult {
  handoffs: TurnHandoff[];
}

model TurnMetricDimensionsResult {
  dimensions: Record<Record<string>>;
}

model OfferReady {
  kind: "Ready";
  ...PickProperties<Channel.TurnOffer, "credential" | "lastLineSeq" | "snapshots" | "personaFiles" | "image" | "gitAuthorName" | "gitAuthorEmail">;
}

model OfferWithdrawn {
  kind: "Withdrawn";
}

model PrepareOfferResult {
  prepared: OfferReady | OfferWithdrawn;
}

model HostPresenceResult {}

model HostFrameRefused {
  type: "Refused";
  reason: string;
}

model HostMessageResult {
  reply: HostFrameRefused | Channel.SnapshotChunksHeld | Channel.SnapshotPackUploads | Channel.RestoreDownloads | Channel.BoxDiscard | Channel.ClaudeSetupBoxDiscard | Channel.TurnClaimed | Channel.TurnWithdrawn | StoredTurnOffer | TurnHandoff | null;
}

model DeadlineReachedResult {}
}
