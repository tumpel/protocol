import "./models.tsp";

namespace Tumpel;

@doc("""
  The CLI's sign-in, kept in an env file of TUMPEL_ENDPOINT and
  TUMPEL_TOKEN lines, readable by the user alone. An environment variable of the same name overrides
  its line. The token answers only the endpoint it was issued by.
  """)
model CliCredentials {
  endpoint: url;
  @minLength(1) token: string;
}

@doc("""
  A non-interactive client credential for the identity-aware proxy, read from the environment.
  Neither value is printed or stored.
  """)
model CliProofCredentials {
  @minLength(1) clientId: string;
  @minLength(1) clientSecret: string;
}
