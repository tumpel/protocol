import "@typespec/http";
import "./models.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("The secret set member a Claude setup writes: the variable its harness reads a subscription token from.")
enum ClaudeSetupMember {
  ClaudeCodeOauthToken: "CLAUDE_CODE_OAUTH_TOKEN",
  CodexAuthJson: "CODEX_AUTH_JSON",
}

@doc("The harness a Claude setup signs in to: Claude Code with claude setup-token, or Codex with codex login --device-auth.")
enum ClaudeSetupHarness {
  ClaudeCode: "ClaudeCode",
  Codex: "Codex",
}

@doc("The one-time code Codex prints for the person to enter at the sign-in URL.")
@minLength(1)
@maxLength(64)
scalar ClaudeSetupUserCode extends string;

@doc("The sign-in code a person pastes after signing in at a Claude setup's signInUrl.")
@minLength(1)
@maxLength(2000)
scalar ClaudeSetupCodeText extends string;

@doc("Why a Claude setup ended Failed. Each reason names the phase it stopped in.")
enum ClaudeSetupFailureReason {
  @doc("The box did not print a sign-in URL within claudeSetupUrlBudgetSeconds: it did not boot, its image could not be fetched, or claude setup-token printed none.")
  SetupUrlMissing: "SetupUrlMissing",

  @doc("Claude Code printed an OAuth error for the pasted code, as it does for a code from another sign-in.")
  CodeRejected: "CodeRejected",

  @doc("Claude Code exited after the code without printing a token, or Codex exited without signing in; the box console in the detail shows why.")
  ClaudeCodeExited: "ClaudeCodeExited",

  @doc("No code arrived within claudeSetupCodeBudgetSeconds of the URL, or no token within claudeSetupMintBudgetSeconds of the code; past the mint budget the detail quotes the last lines Claude Code printed after the code, or says the box did not report within claudeSetupMintGraceSeconds more.")
  SetupTimedOut: "SetupTimedOut",

  @doc("Claude Code printed a token and the box could not store it in the secret set; the token is discarded with the box.")
  TokenNotStored: "TokenNotStored",

  @doc("The host the setup was offered to had no free box slot.")
  NoHostOnline: "NoHostOnline",

  @doc("A newer setup of the same secret set started; a secret set runs one setup at a time, and its box is discarded.")
  Superseded: "Superseded",
}

@doc("The phase a Claude setup is in.")
enum ClaudeSetupState {
  @doc("The box is offered to its host and has not printed a sign-in URL yet.")
  Starting: "Starting",

  @doc("The box printed the sign-in URL and waits for the code.")
  AwaitingCode: "AwaitingCode",

  @doc("The code reached the box, which waits for Claude Code to mint the token and stores it.")
  Minting: "Minting",

  @doc("The secret set holds the minted token; the box is gone.")
  Completed: "Completed",

  @doc("The setup stopped; the box is gone and the secret set is unchanged.")
  Failed: "Failed",
}

@doc("The box is booting on its host.")
model ClaudeSetupStarting {
  state: ClaudeSetupState.Starting;

  @doc("When the box must print its sign-in URL by, or the setup fails SetupUrlMissing.")
  urlDueAt: offsetDateTime;
}

@doc("The box printed its sign-in URL and waits for the code the sign-in page shows.")
model ClaudeSetupAwaitingCode {
  state: ClaudeSetupState.AwaitingCode;

  @doc("Where the person signs in; for Claude Code the page shows the code to submit.")
  signInUrl: HttpUrl;

  @doc("The one-time code a Codex setup shows, for the person to enter at signInUrl. A Codex setup takes no submitted code: its box stores the token once the person signs in.")
  userCode?: ClaudeSetupUserCode;

  @doc("When the code must arrive by, or for Codex the sign-in must finish by, or the setup fails SetupTimedOut.")
  codeDueAt: offsetDateTime;
}

@doc("The box has the code and waits for Claude Code to mint and store the token.")
model ClaudeSetupMinting {
  state: ClaudeSetupState.Minting;

  @doc("When the setup fails SetupTimedOut unless the box stored the token or reported why not: claudeSetupMintBudgetSeconds plus claudeSetupMintGraceSeconds after the code.")
  tokenDueAt: offsetDateTime;
}

@doc("The secret set holds the minted token.")
model ClaudeSetupCompleted {
  state: ClaudeSetupState.Completed;

  @doc("The member the setup wrote: the SubscriptionToken CLAUDE_CODE_OAUTH_TOKEN for Anthropic, or the CredentialFile CODEX_AUTH_JSON for OpenAi.")
  memberName: ClaudeSetupMember;

  @doc("When the stored token stops working; for Codex, when the access token in the file does, which Codex refreshes itself.")
  expiresAt: offsetDateTime;

  completedAt: offsetDateTime;
}

@doc("The setup stopped without storing a token; the secret set is unchanged.")
model ClaudeSetupFailed {
  state: ClaudeSetupState.Failed;
  reason: ClaudeSetupFailureReason;

  @doc("What failed and what fixes it.")
  detail: Detail;

  failedAt: offsetDateTime;
}

@doc("Where a Claude setup is, with the facts of its state: the time each live phase ends by, the sign-in URL while it waits for the code, the member once Completed, the reason once Failed. A setup read past the end of its phase reads Failed.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union ClaudeSetupStatus {
  Starting: ClaudeSetupStarting,
  AwaitingCode: ClaudeSetupAwaitingCode,
  Minting: ClaudeSetupMinting,
  Completed: ClaudeSetupCompleted,
  Failed: ClaudeSetupFailed,
}

@doc("""
  A short-lived box that signs in to the setup's harness and stores the token in a secret set: it
  runs `claude setup-token` from the tenant's pinned Claude Code and stores the SubscriptionToken
  member CLAUDE_CODE_OAUTH_TOKEN for Anthropic, or `codex login --device-auth` from the pinned Codex
  and stores the auth.json it writes as the CredentialFile member CODEX_AUTH_JSON for OpenAi. The box gets no secret set member and no GitHub token,
  and the token never appears in any response.
  """)
model ClaudeSetup {
  @key claudeSetupId: EntityId;
  tenantId: EntityId;
  principalId: EntityId;
  secretSetId: EntityId;
  hostId: EntityId;
  boxId: EntityId;
  harness: ClaudeSetupHarness;
  harnessVersion: HarnessVersion;
  status: ClaudeSetupStatus;
  createdAt: int64;
  updatedAt: int64;
}

@doc("The Claude setup a request names.")
model ClaudeSetupPath {
  @path claudeSetupId: EntityId;
}

@doc("The secret set whose Claude setups a list reads.")
model ClaudeSetupListQuery {
  @query
  secretSetId: EntityId;
}

@doc("Starts a Claude setup for one secret set of the tenant.")
model ClaudeSetupStart {
  secretSetId: EntityId;

  @doc("The harness to sign in to; ClaudeCode when absent.")
  harness?: ClaudeSetupHarness;
}

@doc("The code the sign-in page showed. It is stored sealed until it goes to the box once, and is never returned.")
model ClaudeSetupCodeSubmit {
  code: ClaudeSetupCodeText;
}

@doc("The token a setup box minted, or for Codex the whole auth.json, for the secret set its setup names.")
model ClaudeSetupTokenWrite {
  tenantId: EntityId;
  value: SecretText;

  @doc("When the token stops working, from the exp claim of the access token in a Codex auth.json. A Codex setup refuses a write without it; a Claude Code token expires one year after it is stored, the lifetime Claude Code gives it.")
  expiresAt?: offsetDateTime;
}

@doc("""
  The single-use credential of one setup box, handed to it in its ClaudeSetupBoxOffer: it writes the
  setup's token once, while the setup is Minting, and nothing else.
  """)
model ClaudeSetupBoxToken is BearerAuth;
