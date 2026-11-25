# API

1. Define every operation in TypeSpec first (`rules/typespec.md`).
2. Never add an operation when an existing one already serves the need, or serves it with an added optional field, filter or query parameter. Use or extend the existing one.
3. A small additive change ships without sign-off: a new optional field or parameter on an existing operation, a new response field, or a small new operation that follows the conventions around it.
4. Every other change needs the owner's written approval before implementation. That covers a breaking change, a large addition, and any change to an existing field, path, status code or auth rule. Renaming a field, tightening a validation, changing a status code and making a parameter required are all breaking.
5. Secret values never travel over MCP. They arrive through the dashboard, an OAuth connection or the CLI's `--stdin`. A CLI command never takes a secret as a flag value.
6. CLI commands are plain and explicit: every value comes from a flag or a file. The CLI never auto-detects local state.
7. A host channel change stays compatible with every protocol version still in use. Every wire change but a new optional field needs `npm run channel:bump`; the channel-wire guard refuses one without it.
8. The back end parses requests with the strict named `XSchema` exports, so it refuses unknown values. Clients read responses with `decode`, keep the known fields, and tell users to update when the result lists unrecognised wire values, naming those values. An extra field alone gives no update signal.
