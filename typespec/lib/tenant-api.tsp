import "./models.tsp";
import "./operations.tsp";
import "./channel.tsp";
import "./prebuild.tsp";
import "./build-provider.tsp";

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
const TenantApiVersion = 1;

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
  personaId: EntityId;
  tenantId: EntityId;
  name: DisplayName;
  harness: Harness;
  secretSetId: EntityId;
  connectorIds: EntityId[];
  @minValue(512) @maxValue(65536) boxMemoryMib?: int32;
  @minValue(32768) @maxValue(262144) boxDiskMib?: int32;
  boxRetention: BoxRetention;
  files: StoredFileRead[];
  createdAt: int64;
  updatedAt: int64;
}

@doc("What a persona edit writes. The harness is fixed at create.")
model PersonaChange {
  name: DisplayName;
  secretSetId: EntityId;
  connectorIds: EntityId[];
  @minValue(512) @maxValue(65536) boxMemoryMib: int32;
  @minValue(32768) @maxValue(262144) boxDiskMib: int32;
  boxRetention: BoxRetention;
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

@doc("A host as the control plane stores it, without its supervisor update reports.")
model HostRecord {
  ...OmitProperties<Host, "supervisorUpdateStep" | "supervisorUpdateFailure">;
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

@doc("One request to the tenant Durable Object's single entry point. `operation` names the operation the way a path names a REST operation.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "operation" })
union TenantRequest {
  listPersonas: ListPersonasRequest,
  getPersona: GetPersonaRequest,
  createPersona: CreatePersonaRequest,
  updatePersona: UpdatePersonaRequest,
  deletePersona: DeletePersonaRequest,
  open: OpenRequest,
  supervisorUpdate: SupervisorUpdateRequest,
  supervisorUpdates: SupervisorUpdatesRequest,
  listSecretSets: ListSecretSetsRequest,
  getSecretSet: GetSecretSetRequest,
  createSecretSet: CreateSecretSetRequest,
  updateSecretSet: UpdateSecretSetRequest,
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
}
