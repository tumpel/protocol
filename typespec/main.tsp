import "@typespec/http";
import "@typespec/openapi3";
import "@kattebak/typespec-zod-emitter";
import "./lib/models.tsp";
import "./lib/operations.tsp";
import "./lib/channel.tsp";
import "./lib/cli.tsp";
import "./lib/supervisor.tsp";
import "./lib/config.tsp";
import "./lib/github.tsp";
import "./lib/release.tsp";
import "./lib/prebuild.tsp";
import "./lib/prebuild-template.tsp";
import "./lib/build-provider.tsp";
import "./lib/claude-setup.tsp";
import "./lib/openrouter.tsp";

using TypeSpec.Http;

@service(#{ title: "tumpel" })
@useAuth(BearerAuth)
namespace Tumpel;

@doc("""
  A signed assertion of the browser user's identity, set by the identity-aware proxy in front of
  the control plane (Cloudflare Access in the first backend). It names an email, never a device.
  """)
model IdentityAssertion is ApiKeyAuth<ApiKeyLocation.header, "Cf-Access-Jwt-Assertion">;
