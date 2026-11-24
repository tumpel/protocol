# tumpel-api

Types and a typed [progenitor](https://github.com/oxidecomputer/progenitor) client for the tumpel API and the host channel, generated from the TypeSpec in [tumpel/protocol](https://github.com/tumpel/protocol).

`tumpel_api::frozen` holds the types of every older channel protocol version the current release still speaks.

Each release is a `0.N.0` minor version, because an added field breaks callers that build the structs with literals. Pin it exactly: `tumpel-api = "=0.N.0"`.

Import `tumpel_api::ContainsUnrecognised` to call `is_unrecognised()` on a response or typed refusal. It checks the decoded value for an `Unrecognised` enum or union variant, including inside nested objects and collections. Clients can report an update once and still use the preserved value.
