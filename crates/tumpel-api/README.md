# tumpel-api

Types and a typed [progenitor](https://github.com/oxidecomputer/progenitor) client for the tumpel API and the host channel, generated from the TypeSpec in [tumpel/protocol](https://github.com/tumpel/protocol).

`tumpel_api::frozen` holds the types of every older channel protocol version the current release still speaks.

Each release is a `0.N.0` minor version, because an added field breaks callers that build the structs with literals. Pin it exactly: `tumpel-api = "=0.N.0"`.

Successful responses expose `ResponseValue::is_unrecognised()`. It reports whether decoding retained an `Unrecognised` enum or union variant anywhere in the response, including nested objects and collections. Clients can report an update once and still print the preserved value. Failed attempts to decode an untagged variant do not set the bit.
