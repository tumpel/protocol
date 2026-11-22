import "@typespec/json-schema";

namespace Tumpel;

@doc("A short value: a name, a kind, a status, a version, a branch, a commit or an id another system issued.")
@maxLength(256)
scalar ShortText extends string;

@doc("One line a person reads: a title, a client name, a cursor or an OAuth scope list.")
@maxLength(1024)
scalar Summary extends string;

@doc("""
  What failed and what fixes it, a warning, or a description. It may carry the tail of a
  harness's output, which the harness caps well below this.
  """)
@maxLength(16384)
scalar Detail extends string;

@doc("""
  A line of harness output or a document such as a script or a devcontainer.json. The guest
  protocol carries frames up to 4 MiB, but a single line past 1 MiB is refused instead of stored.
  """)
@maxLength(1048576)
scalar LongText extends string;

@doc("A token, a key, a code, a nonce or a signature, as its issuer encodes it.")
@maxLength(16384)
scalar Token extends string;

@doc("A credential file or a variable value a harness reads, such as an OAuth credentials JSON.")
@maxLength(65536)
scalar CredentialText extends string;

@doc("A URL held as text: an origin, an endpoint, a redirect or a presigned upload URL.")
@maxLength(4096)
scalar UrlText extends string;

@doc("A URL the API checks as one.")
@maxLength(4096)
scalar HttpUrl extends url;

@doc("A file system path, a socket or an object storage key; 4096 is the Linux PATH_MAX.")
@maxLength(4096)
scalar PathText extends string;
