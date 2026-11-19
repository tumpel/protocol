import type { HarnessCatalogEntrySchema, ProblemSchema, SecretSetCreateSchema, SecretSetSchema } from "@tumpel/schemas";
import type { z } from "zod";

type CatalogEntry = Pick<z.infer<typeof HarnessCatalogEntrySchema>, "credentials" | "credentialChoice">;
export type AcceptedCredential = CatalogEntry["credentials"][number];
type Provider = AcceptedCredential["provider"];
export type SecretMember = z.infer<typeof SecretSetCreateSchema>["secrets"][number];
export type SecretKey = z.infer<typeof SecretSetSchema>["keys"][number];
type Credential<T extends SecretKey | SecretMember> = Exclude<T, { kind: "Variable" }>;

export interface DispatchVariable {
  name: string;
  value: string;
}

export interface DispatchFile {
  path: string;
  value: string;
}

export type CredentialRefusal =
  | { kind: "NoCredential"; accepted: AcceptedCredential[] }
  | { kind: "NoModelCredential"; model: string; provider: Provider; accepted: AcceptedCredential[] }
  | { kind: "Unsupported"; name: string; credentialKind: string; supported: string[] }
  | { kind: "ModelUnsupported"; model: string; name: string; credentialKind: string; allowed: string[] }
  | { kind: "Expired"; name: string; expiresAt: string };

export type CredentialCheck<T extends SecretKey | SecretMember> =
  | {
      kind: "Usable";
      credential: Credential<T>;
      variable: string;
      fixed: DispatchVariable[];
      arguments: string[];
      costBasis: AcceptedCredential["costBasis"];
    }
  | CredentialRefusal;

export type CredentialProblem = z.infer<typeof ProblemSchema>;

const isCredential = <T extends SecretKey | SecretMember>(member: T): member is Credential<T> =>
  member.kind !== "Variable";

const accepts = (accepted: AcceptedCredential, member: { provider: string; kind: string }): boolean =>
  accepted.provider === member.provider && accepted.kind === member.kind;

const pick = <T extends SecretKey | SecretMember>(
  accepted: AcceptedCredential[],
  members: readonly T[],
  model: string | null,
  now: number,
): CredentialCheck<T> => {
  const credentials = members.filter(isCredential);
  const [held] = accepted.flatMap((each) =>
    credentials.filter((member) => accepts(each, member)).map((credential) => ({ each, credential })),
  );
  if (held === undefined) {
    const unsupported = credentials.find((member) => accepted.some((each) => each.provider === member.provider));
    if (unsupported === undefined) return { kind: "NoCredential", accepted };
    return {
      kind: "Unsupported",
      name: unsupported.name,
      credentialKind: unsupported.kind,
      supported: accepted.filter((each) => each.provider === unsupported.provider).map((each) => each.kind),
    };
  }
  const { each, credential } = held;
  if (model !== null && each.models !== undefined && !each.models.includes(model)) {
    return {
      kind: "ModelUnsupported",
      model,
      name: credential.name,
      credentialKind: credential.kind,
      allowed: each.models,
    };
  }
  if (credential.kind === "SubscriptionToken" && Date.parse(credential.expiresAt) <= now) {
    return { kind: "Expired", name: credential.name, expiresAt: credential.expiresAt };
  }
  return {
    kind: "Usable",
    credential,
    variable: each.variable,
    fixed: each.fixed,
    arguments: each.arguments,
    costBasis: each.costBasis,
  };
};

export const modelProvider = (model: string): Provider => {
  if (model.startsWith("anthropic/")) return "Anthropic";
  if (model.startsWith("openai/")) return "OpenAi";
  return "OpenRouter";
};

export const checkCredential = <T extends SecretKey | SecretMember>(
  entry: CatalogEntry,
  members: readonly T[],
  now: number,
): CredentialCheck<T> => pick(entry.credentials, members, null, now);

export const checkModelCredential = <T extends SecretKey | SecretMember>(
  entry: CatalogEntry,
  members: readonly T[],
  model: string,
  now: number,
): CredentialCheck<T> => {
  if (entry.credentialChoice === "CatalogOrder") return pick(entry.credentials, members, model, now);
  const provider = modelProvider(model);
  const accepted = entry.credentials.filter((each) => each.provider === provider);
  const checked = pick(accepted, members, model, now);
  if (checked.kind !== "NoCredential") return checked;
  return { kind: "NoModelCredential", model, provider, accepted };
};

export const credentialProblem = (
  refusal: CredentialRefusal,
  owner: string,
  harness: string,
  retry: string,
): CredentialProblem => {
  if (refusal.kind === "NoCredential") {
    return {
      code: "NoCredential",
      title: "No provider credential",
      detail: `${owner} holds no credential ${harness} reads: ${refusal.accepted.map(({ kind, provider }) => `a ${kind} for ${provider}`).join(", or ")}`,
      fix: `Add one of those to that secret set, then ${retry}`,
    };
  }
  if (refusal.kind === "NoModelCredential") {
    const wanted =
      refusal.accepted.length === 0
        ? `${harness} reads no credential for ${refusal.provider}`
        : `it holds no ${refusal.accepted.map(({ kind }) => kind).join(" or ")} for ${refusal.provider}`;
    return {
      code: "NoCredential",
      title: "No credential for the model's provider",
      detail: `model ${refusal.model} runs on ${refusal.provider}, and ${owner} cannot reach it: ${wanted}`,
      fix: `Add a credential for ${refusal.provider} to that secret set, or name a model of a provider it holds a credential for, then ${retry}`,
    };
  }
  if (refusal.kind === "Unsupported") {
    return {
      code: "CredentialKindUnsupported",
      title: "Credential kind not accepted by the harness",
      detail: `${owner} holds ${refusal.name}, a ${refusal.credentialKind}, and ${harness} accepts only ${refusal.supported.join(", ")}`,
      fix: `Replace ${refusal.name} with a ${refusal.supported.join(" or ")} in that secret set, then ${retry}`,
    };
  }
  if (refusal.kind === "ModelUnsupported") {
    return {
      code: "ModelUnsupported",
      title: "Model not supported by the harness",
      detail: `${harness} does not run model ${refusal.model} with ${refusal.credentialKind} ${refusal.name} of ${owner}; it runs ${refusal.allowed.join(", ")}`,
      fix: `Name one of those models, then ${retry}`,
    };
  }
  return {
    code: "CredentialExpired",
    title: "Subscription token expired",
    detail: `subscription token ${refusal.name} of ${owner} expired at ${refusal.expiresAt}`,
    fix: `Write a fresh token and its expiresAt to that secret set, then ${retry}`,
  };
};

export const dispatchVariables = (
  entry: CatalogEntry,
  members: readonly SecretMember[],
  model: string,
  now: number,
):
  | { kind: "Ready"; variables: DispatchVariable[]; arguments: string[]; credentialFile?: DispatchFile }
  | CredentialRefusal => {
  const checked = checkModelCredential(entry, members, model, now);
  if (checked.kind !== "Usable") return checked;
  const { credential, variable, fixed, arguments: harnessArguments } = checked;
  const path = entry.credentials.find((each) => each.kind === "CredentialFile" && each.variable === variable)?.path;
  const taken = new Set(entry.credentials.flatMap((each) => [each.variable, ...each.fixed.map(({ name }) => name)]));
  const others = members
    .filter((member) => member !== credential && !taken.has(member.name))
    .map((member) => ({ name: member.name, value: member.value }));
  if (credential.kind === "CredentialFile") {
    if (path === undefined) throw new Error(`the catalog maps the CredentialFile ${variable} to no path`);
    return {
      kind: "Ready",
      variables: [...fixed, ...others],
      arguments: harnessArguments,
      credentialFile: { path, value: credential.value },
    };
  }
  return {
    kind: "Ready",
    variables: [{ name: variable, value: credential.value }, ...fixed, ...others],
    arguments: harnessArguments,
  };
};
