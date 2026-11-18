import "./models.tsp";
import "./operations.tsp";
import "./channel.tsp";

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
}
