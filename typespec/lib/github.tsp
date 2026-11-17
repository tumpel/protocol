import "./models.tsp";

namespace Tumpel;

@doc("A GitHub id: of an App, an installation or an account. GitHub issues them as positive integers.")
@minValue(1)
scalar GitHubId extends safeint;

@doc("A GitHub user or organization login.")
@pattern("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$")
scalar GitHubLogin extends string;

@doc("Where the GITHUB_TOKEN of a turn offer came from.")
enum RepositoryCredentialSource {
  @doc("An installation access token of the stage's GitHub App, minted for the session's repository when the turn was offered.")
  GitHubApp: "GitHubApp",

  @doc("The Variable member GITHUB_TOKEN of the persona's secret set; no installation of the tenant covers the session's repository.")
  SecretSet: "SecretSet",

  @doc("Neither: the tenant has no installation and the secret set no GITHUB_TOKEN, so the box clones without a credential.")
  None: "None",
}

@doc("The installation's state as GitHub's last installation webhook reported it.")
enum GitHubInstallationStatus {
  @doc("GitHub mints tokens for it.")
  Active: "Active",

  @doc("A person suspended the installation on GitHub; no turn gets a token of it until they unsuspend it.")
  Suspended: "Suspended",
}

@doc("The kind of GitHub account an installation is on, as GitHub reports it.")
enum GitHubAccountType {
  User: "User",
  Organization: "Organization",
}

@doc("Why the control plane did not link an installation a person brought back from GitHub; GitHubConnections_start sends it to the dashboard as refused=<GitHubInstallRefusal>.")
enum GitHubInstallRefusal {
  @doc("Another tenant holds the installation; disconnect it there, then add the account again with Add new.")
  OtherTenant: "OtherTenant",

  @doc("The person who came back from GitHub did not install the App on this account; only the person who installed it links it.")
  NotInstaller: "NotInstaller",

  @doc("GitHub has not named who installed the App on this organization, sometimes for a moment after the install, always for an install made before the control plane recorded installers; add the account again in a moment, and if it stays, uninstall the App on GitHub and install it again.")
  InstallerUnknown: "InstallerUnknown",
}

@doc("An installation of the stage's GitHub App on one GitHub account, linked to the tenant when GitHub sent the installer back. A tenant holds one per connected account or organization.")
model GitHubInstallation {
  @key installationId: GitHubId;
  tenantId: EntityId;

  @doc("The GitHub account the App is installed on; the installation covers repositories of this account only.")
  accountLogin: GitHubLogin;

  @doc("Whether the account is a user or an organization; the installation's settings page on GitHub is https://github.com/settings/installations/<installationId> for a User and https://github.com/organizations/<accountLogin>/settings/installations/<installationId> for an Organization.")
  accountType: GitHubAccountType;

  status: GitHubInstallationStatus;
  createdAt: int64;

  @doc("When the setup callback or a webhook last changed the installation.")
  updatedAt: int64;
}

@doc("The stage has a GitHub App; a tenant installs it on each account or organization it connects.")
model GitHubAppReady {
  state: "Ready";
  appSlug: string;
}

@doc("The stage has no GitHub App yet; a person creates it once at `setupUrl`.")
model GitHubAppMissing {
  state: "AppMissing";
  setupUrl: url;
}

@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union GitHubAppState {
  Ready: GitHubAppReady,
  AppMissing: GitHubAppMissing,
}

@doc("The stage's GitHub App as the caller's tenant sees it. The tenant's installations are listed by GitHubConnections_list.")
model GitHubConnection {
  tenantId: EntityId;
  app: GitHubAppState;
}

@doc("""
  Where a person installs the stage's GitHub App on one more account or organization for the
  caller's tenant. `installUrl` carries a state signed for the tenant, valid until `expiresAt`;
  GitHub sends the installer back to the control plane, which adds the installation to the
  tenant's installations once GitHub confirms the person who installed it owns the account.
  """)
model GitHubInstallStart {
  installUrl: url;
  expiresAt: offsetDateTime;
}

@doc("The name of a GitHub repository, without its owner.")
@pattern("^[A-Za-z0-9._-]{1,100}$")
scalar GitHubRepositoryName extends string;

@doc("The number of an issue in its repository.")
@minValue(1)
scalar GitHubIssueNumber extends safeint;

@doc("A repository one of the tenant's GitHub App installations covers.")
model GitHubRepository {
  owner: GitHubLogin;
  name: GitHubRepositoryName;
  defaultBranch: string;
  `private`: boolean;
  htmlUrl: url;
}

@doc("An open issue of a repository. Pull requests are left out.")
model GitHubIssue {
  issueNumber: GitHubIssueNumber;
  title: string;
  htmlUrl: url;

  @doc("The names of the issue's labels.")
  labels: string[];

  @doc("When the issue last changed on GitHub.")
  updatedAt: offsetDateTime;
}