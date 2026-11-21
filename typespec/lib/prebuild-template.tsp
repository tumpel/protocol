import "@typespec/http";
import "./models.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("A template's id: lower-case letters, digits and dashes, such as npm, rust or python.")
@pattern("^[a-z][a-z0-9-]{0,39}$")
@maxLength(40)
scalar PrebuildTemplateId extends string;

@doc("A template version: an integer per template, starting at 1. A shipped version never changes.")
@minValue(1)
scalar PrebuildTemplateVersionNumber extends int32;

@doc("One sentence on what a template version sets up.")
@minLength(1)
@maxLength(500)
scalar PrebuildTemplateSummary extends string;

@doc("A toolchain the guest image carries.")
enum Toolchain {
  Node: "Node",
  Rust: "Rust",
  Python: "Python",
}

@doc("A toolchain a template version pins, at the version the guest image it targets carries.")
model PrebuildTemplateToolchain {
  toolchain: Toolchain;

  @doc("The toolchain's version, such as 26.13.1.")
  @minLength(1)
  toolchainVersion: ShortText;
}

@doc("The template.json beside a template version's devcontainer.json.")
model PrebuildTemplateManifest {
  summary: PrebuildTemplateSummary;

  @doc("What the template's commands install, one item each, such as the npm dependencies from package-lock.json.")
  @maxItems(100) installs: Summary[];

  @doc("The toolchains the version pins: the guest image it targets.")
  @maxItems(50) toolchains: PrebuildTemplateToolchain[];
}

@doc("One version of a template, without its devcontainer.json text.")
model PrebuildTemplateVersionSummary {
  prebuildTemplateVersion: PrebuildTemplateVersionNumber;
  ...PrebuildTemplateManifest;

  @doc("The sha256 of the version's devcontainer.json bytes.")
  digest: Sha256Digest;
}

@doc("A devcontainer.json the control plane ships, with every version newest first. Templates are global: every tenant sees the same set.")
model PrebuildTemplate {
  @key prebuildTemplateId: PrebuildTemplateId;

  @doc("Every shipped version, newest first.")
  @maxItems(1000) versions: PrebuildTemplateVersionSummary[];
}

@doc("One version of a template with its devcontainer.json text.")
model PrebuildTemplateVersion {
  prebuildTemplateId: PrebuildTemplateId;
  ...PrebuildTemplateVersionSummary;

  @doc("The devcontainer.json text the version commits, byte for byte the file whose sha256 is digest.")
  devcontainer: LongText;
}

model PrebuildTemplateVersionPath {
  @path prebuildTemplateId: PrebuildTemplateId;
  @path prebuildTemplateVersion: PrebuildTemplateVersionNumber;
}

@doc("Opens a pull request that adds a template version's devcontainer.json to a repository.")
model PrebuildTemplatePullRequestOpen {
  @doc("A GitHub repository, such as https://github.com/acme/app.git or acme/app.")
  repository: RepositoryUrl;

  prebuildTemplateId: PrebuildTemplateId;
  prebuildTemplateVersion: PrebuildTemplateVersionNumber;

  @doc("Replace the repository's devcontainer.json; false refuses a repository that holds one.")
  replace: boolean;
}

model PrebuildTemplatePullRequestQuery {
  @doc("A GitHub repository, in any form a start accepts.")
  @query
  repository: RepositoryUrl;
}

@doc("Where a pull request is on GitHub.")
enum PullRequestState {
  Open: "Open",
  Merged: "Merged",

  @doc("Closed without a merge.")
  Closed: "Closed",
}

@doc("The pull request on a repository's template branch, tumpel/prebuild-template.")
model PrebuildTemplatePullRequest {
  @doc("The repository as https://github.com/<owner>/<name> in lower case.")
  repository: RepositoryUrl;

  @doc("The branch the pull request merges from: tumpel/prebuild-template.")
  branch: ShortText;

  @minValue(1) pullRequestNumber: int64;

  @doc("The pull request's page on GitHub.")
  url: HttpUrl;

  state: PullRequestState;
}
