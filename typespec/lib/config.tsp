import "@typespec/json-schema";
import "./models.tsp";
import "./operations.tsp";

using TypeSpec.JsonSchema;

namespace Tumpel;

@doc("The name of an environment variable, such as ANTHROPIC_API_KEY.")
@pattern("^[A-Z_][A-Z0-9_]*$")
@maxLength(200)
scalar EnvironmentVariableName extends string;

@doc("Where a secret value comes from when the file is applied. The value itself is never in the file.")
@extension("additionalProperties", false)
model SecretValueSource {
  env: EnvironmentVariableName;
}

@extension("additionalProperties", false)
model ConfigSecretVariable {
  ...SecretVariableMember;
  valueFrom: SecretValueSource;
}

@extension("additionalProperties", false)
model ConfigApiKey {
  ...ApiKeyMember;
  valueFrom: SecretValueSource;
}

@doc("When a subscription token stops working: an offset date-time, or the environment variable that holds one when the file is read.")
union ConfigExpiry {
  offsetDateTime,
  SecretValueSource,
}

@extension("additionalProperties", false)
model ConfigSubscriptionToken {
  ...OmitProperties<SubscriptionTokenMember, "expiresAt">;
  expiresAt: ConfigExpiry;
  valueFrom: SecretValueSource;
}

@doc("One member of a secret set: its kind, name and provider, and the variable its value is read from.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "kind" })
union ConfigSecret {
  Variable: ConfigSecretVariable,
  ApiKey: ConfigApiKey,
  SubscriptionToken: ConfigSubscriptionToken,
}

@extension("additionalProperties", false)
model ConfigSecretSet {
  ...OmitProperties<SecretSetCreate, "secrets">;
  secrets: ConfigSecret[];
}

@doc("A path on the machine that applies the file, relative to the tenant config file.")
@minLength(1)
@maxLength(1000)
scalar LocalFilePath extends string;

@doc("""
  One persona file: `path` is where the harness reads it, relative to its home in the box, and
  `from` the local file whose bytes it holds. The config file never holds the bytes; apply reads
  them and uploads the files whose digest changed.
  """)
@extension("additionalProperties", false)
model ConfigPersonaFile {
  path: PersonaFilePath;
  from: LocalFilePath;
}

@doc("A persona of the file. It names its harness, its secret set by the set's name in the same file, and its files.")
@extension("additionalProperties", false)
model ConfigPersona {
  ...OmitProperties<PersonaCreate, "secretSetId" | "files">;
  secretSetName: DisplayName;
  files: ConfigPersonaFile[];
}
@@extension(HarnessPinCreate, "additionalProperties", false);

@doc("The labels of one enrolled host, named by the hostId `tumpel host list` prints.")
@extension("additionalProperties", false)
model ConfigHost {
  hostId: EntityId;
  ...HostLabels;
}

@doc("""
  A tenant's whole configuration, kept in one JSON file under version control. `tumpel config
  plan` and `apply` make the tenant match it: a persona, secret set or pin the file leaves out is
  deleted, and an enrolled host the file leaves out loses its labels. Personas and secret sets are
  matched by name, pins by harness and hosts by hostId; a persona names its secret set by name.
  """)
@jsonSchema
@extension("additionalProperties", false)
model TenantConfig {
  @doc("The address of a copy of this schema, so an editor validates the file.")
  `$schema`?: url;

  personas: ConfigPersona[];
  secretSets: ConfigSecretSet[];
  harnessPins: HarnessPinCreate[];
  hosts: ConfigHost[];
}

@doc("The value of one environment variable a secret of the config names in valueFrom, entered where the config is applied.")
model ConfigSecretValue {
  env: EnvironmentVariableName;
  value: SecretText;
}

@doc("The value of one environment variable a subscription token's expiresAt names, entered where the config is read.")
model ConfigExpiryValue {
  env: EnvironmentVariableName;
  expiresAt: offsetDateTime;
}

@doc("A persona file of the config named by its `from` path, with the digest and size of its bytes.")
model ConfigFileDigest {
  from: LocalFilePath;
  digest: Sha256Digest;
  sizeBytes: PersonaFileSize;
}

model InlineConfigFile {
  source: PersonaFileSource.Inline;
  from: LocalFilePath;
  content: PersonaFileContent;
}

model StoredConfigFile {
  source: PersonaFileSource.Stored;
  ...ConfigFileDigest;
}

@doc("""
  The bytes of a persona file the config names in `from`: Inline (base64, up to
  PersonaFileLimit.InlineFileBytes), or Stored by the digest and size of a file uploaded with
  Personas_uploadFile.
  """)
@discriminated(#{ envelope: "none", discriminatorPropertyName: "source" })
union ConfigFileWrite {
  Inline: InlineConfigFile,
  Stored: StoredConfigFile,
}

@doc("A tenant config to plan, with the digest of each persona file it names and the value of each expiry variable.")
model TenantConfigPlanRequest {
  config: TenantConfig;
  files: ConfigFileDigest[];
  expiryValues: ConfigExpiryValue[];

  @doc("""
    The environment variables apply will send in secretValues, by name and never with a value. An
    empty list keeps the stored values of every secret set the config keeps; any other list must
    name every variable the config names, and plans a Rewrite of every kept set.
    """)
  secretValues: SecretValueSource[];
}

@doc("""
  A tenant config to apply, with what the file itself never holds: each persona file it names,
  the value of each environment variable its secret sets name, and the value of each expiry
  variable. An empty secretValues keeps the stored values of every secret set the config keeps,
  and refuses a set the plan creates or updates; any other secretValues must cover every variable
  the config names, and every kept set is written again with it.
  """)
model TenantConfigApply {
  config: TenantConfig;
  files: ConfigFileWrite[];
  secretValues: ConfigSecretValue[];
  expiryValues: ConfigExpiryValue[];
}

enum ConfigChangeAction {
  Create: "Create",
  Update: "Update",
  Delete: "Delete",

  @doc("The secret set keeps its member names and gets its values written again, because every value it names was sent.")
  Rewrite: "Rewrite",
}

enum ConfigResource {
  Persona: "Persona",
  SecretSet: "SecretSet",
  HarnessPin: "HarnessPin",
  Host: "Host",
}

@doc("One change of a plan: what it does to which persona, secret set, pin or host, and the line tumpel config plan prints for it.")
model ConfigChange {
  action: ConfigChangeAction;
  resource: ConfigResource;

  @doc("The persona or secret set name, the harness of a pin, or the hostId of a host.")
  name: string;

  description: string;
}

@doc("The changes that make the tenant match a config, in the order apply makes them.")
model ConfigPlan {
  changes: ConfigChange[];
}
