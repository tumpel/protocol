import "@typespec/http";
import "./models.tsp";

using TypeSpec.Http;

namespace Tumpel;

@doc("An outside service the tenant links: the GitHub App or OpenRouter as a model provider.")
enum ConnectionKind {
  GitHub: "GitHub",
  OpenRouter: "OpenRouter",
}

enum ConnectionState {
  @doc("The stage lacks what the connection needs, such as the GitHub App; the get operation of the kind names the fix.")
  NotConfigured: "NotConfigured",

  @doc("The stage is ready and the tenant has not connected its account.")
  NotConnected: "NotConnected",

  @doc("The tenant connected its account.")
  Connected: "Connected",

}

model ConnectedConnection {
  kind: ConnectionKind;
  state: ConnectionState.Connected;

  @doc("What the connection is connected as: the GitHub logins of the tenant's installations, comma-separated, or for OpenRouter the names of the secret sets that hold an OpenRouter key, comma-separated, since OpenRouter's key exchange names no account.")
  account: Summary;
}

model NotConnectedConnection {
  kind: ConnectionKind;
  state: ConnectionState.NotConnected;
}

model NotConfiguredConnection {
  kind: ConnectionKind;
  state: ConnectionState.NotConfigured;
}

@doc("One connection kind of the tenant with its state and its account once connected.")
@discriminated(#{ envelope: "none", discriminatorPropertyName: "state" })
union ConnectionSummary {
  Connected: ConnectedConnection,
  NotConnected: NotConnectedConnection,
  NotConfigured: NotConfiguredConnection,
}
