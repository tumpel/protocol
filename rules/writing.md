# Writing

## Text a user reads

This covers the dashboard, CLI output, error messages, emails and docs pages.

1. Say what happened and what to do next, in plain words a newcomer understands on first read.
2. Never show internal references: no requirement, gap, EDD, ADR or RFC ids, no issue numbers, no migration or operation names.
3. Never turn a limit of the implementation into an instruction for the user. Fix the product instead.
4. Write short sentences, with no hedging and no jargon the user did not bring.

## Docs, issues and PR bodies

1. Write short declarative sentences in the active voice. Name the actor.
2. Use `must`, `never` or `always` for an obligation. Never write `should` or `could`.
3. No em dashes, en dashes, emoji or decorative bold.
4. Describe what the system does now. History belongs in the changelog.
5. Repo docs describe the design on its own terms. They never reference the projects it came from.
6. Never hard-wrap a paragraph.
