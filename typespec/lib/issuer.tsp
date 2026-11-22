import "./models.tsp";

namespace Tumpel;

@doc("The id of an issuer signing key: the RFC 7638 SHA-256 thumbprint of its public JWK, base64url.")
@pattern("^[A-Za-z0-9_-]{43}$")
@maxLength(43)
scalar IssuerKeyId extends string;

@doc("An RS256 public key of the stage's issuer, in the JWK form of RFC 7517.")
model IssuerJwk {
  kty: "RSA";
  use: "sig";
  alg: "RS256";
  kid: IssuerKeyId;

  @minLength(1)
  n: Token;

  @minLength(1)
  e: Token;
}

@doc("""
  The public keys of the stage's issuer, served at `/.well-known/jwks.json` on the issuer hostname:
  the one key that signs its tokens.
  """)
model IssuerJwks {
  @maxItems(100) keys: IssuerJwk[];
}

@doc("""
  The OpenID Connect discovery document of the stage's issuer, served at
  `/.well-known/openid-configuration` on the issuer hostname.
  """)
model OpenIdConfiguration {
  issuer: HttpUrl;
  jwks_uri: HttpUrl;
  @maxItems(20) response_types_supported: "id_token"[];
  @maxItems(20) subject_types_supported: "public"[];
  @maxItems(20) id_token_signing_alg_values_supported: "RS256"[];
  @maxItems(20) scopes_supported: "openid"[];
  @maxItems(20) claims_supported: ("iss" | "sub" | "aud" | "iat" | "nbf" | "exp" | "jti")[];
}
