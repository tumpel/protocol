# RFC: Host channel and tenant operations as sequences

| Field   | Value                                                                                                                                     |
| ------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Status  | Draft (2026-11-23)                                                                                                                        |
| Scope   | Review only; the code as built at control-plane bdd61a1 plus control-plane PR 149 (open), supervisor 8d051d3, channel protocol version 37 |
| Related | [channel.tsp](../../typespec/lib/channel.tsp), [tenant-api.tsp](../../typespec/lib/tenant-api.tsp)                                        |

## Summary

This document draws every host operation of the control plane as one sequence diagram. Each diagram shows who writes which row or object, and in what order. The host keeps every frame it sends in `channel.json` until the control plane acks it. The control plane acks a host frame only after the frame's effect is stored. Each diagram makes that order visible, and the text under it names every place where the code differs from the design.

The diagrams describe the code as built. Where it differs from the design, one sentence under the diagram says so. The appendix lists the rows each operation writes, with the measured figure next to the row budget.

## Reading the diagrams

Every diagram has the same participants in the same order: the supervisor on the host, the HostChannel Durable Object, the Tenant Durable Object, R2 and D1. TenantMetrics appears where telemetry is written. The Worker appears last when a client request starts the operation.

The HostChannel keeps two kinds of state. Its socket attachment holds the connection phase, the cursor (the last host `seq` applied on this connection), `boxCapacity` and the frame-rate window. A `Note over H` shows an attachment change. The `ledger` row holds the outbound frames the host has not acked. A self-arrow `H->>H: ledger row` shows a write to that row.

A shaded box around Tenant self-arrows is one SQL transaction. A Tenant self-arrow outside a box commits on its own. An arrow to R2 or D1 is a write or read of the object or row it names. An arrow that carries a credential, a presigned URL or a token names it in the label.

## 1. Hello and Welcome

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  opt reconnect after a Tenant restart
    S->>H: Frame seq k (any host message)
    H->>T: hostMessage
    T--xH: retryable error, Tenant restarted
    H->>S: close 1011, frame k not stored
    Note over S: frame k stays in channel.json
  end
  S->>H: WebSocket upgrade
  Note over H: attachment: AwaitingHello, nonce, empty frame window of hostFramesPerMinute
  H->>S: Challenge(nonce)
  S->>H: Hello(signature, resendFrom k, heldTurnIds, usage, boxCapacity)
  Note over H: reads host table: public_key, revoked. Reads ledger row.
  loop each unacked TurnOffer in the ledger row
    H->>T: prepareOffer(turnId)
    alt turn still Offered
      rect rgba(120, 140, 255, 0.15)
        T->>T: INSERT credential_handovers, turn_full_images
      end
      T->>H: credential: secret variables, turn tokens, GitHub token, presigned GET URLs
    else turn no longer Offered
      T->>H: Withdrawn
    end
  end
  H->>S: Welcome(ack k-1)
  H->>S: resent ledger frames: TurnOffer with credential, or TurnWithdrawn
  Note over H: attachment: Open, cursor k-1, boxCapacity
  H->>D: UPDATE hosts.supervisor_version, UPSERT host_channel_protocols and host_guest_protocols (on change only)
  Note over D: a protocol the Hello leaves out DELETEs its row
  H->>T: hostHello(heldTurnIds, usage, boxCapacity)
  rect rgba(120, 140, 255, 0.15)
    T->>T: INSERT events HostOnline (no host_reports row, or heard_at past 90 s)
    T->>T: UPSERT host_reports (first connect, a change of box capacity, channel protocol, memory budget or memory held, or heard_at older than 30 s)
    T->>T: DELETE superseded supervisor_update_latest_failures
  end
  T->>T: each Running turn not in heldTurnIds fails HostDropped
  T-->>H: done
  H->>S: close older sockets of this host (Replaced)
  S->>H: resent host frames from seq k, each acked after its write
```

On a first connect the Tenant inserts the `host_reports` row and appends HostOnline, and Welcome goes out alone. The cursor comes from `resendFrom` alone. Hello judges only Running turns; Offered turns wait for the Heartbeat grace in section 2.

The supervisor resends its withheld frames at most half the frame limit per tick, so a long backlog stays under the rate limit on reconnect.

Code and design differ in three places. Welcome and the resent frames go out before the D1 and Tenant writes of Hello. Welcome still carries `ack`, which the protocol text says version 37 leaves out; the supervisor ignores it at 37. Each resent offer mints fresh credentials and writes one more `credential_handovers` row.

## 2. Heartbeat and reconcile

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  participant M as TenantMetrics
  S->>H: Heartbeat(ack n, heldTurnIds, heldSessionIds, heldClaudeSetupIds, usage, health, telemetry)
  H->>H: ledger row: drop frames up to n (written only when a frame drops)
  H->>D: read hosts.tenant_id (first message after a start, then cached)
  H->>M: record(telemetry points)
  Note over M: writes Analytics Engine, no row
  H->>T: hostHeartbeat(usage, health, held lists)
  rect rgba(120, 140, 255, 0.15)
    T->>T: UPDATE host_reports (memory budget, memory held or health changed, or heard_at older than 30 s)
    T->>T: UPDATE turns.unheld_heartbeats 1 to 0 for each held turn
    T->>T: UPDATE turns.unheld_heartbeats 0 to 1 for an omitted Offered turn with offer_sent 1
  end
  T->>T: fail HostDropped: an omitted Running turn, or an omitted Offered turn already at 1
  T->>H: BoxDiscard, or SnapshotRequest then teardown, for a held box no session needs
  H->>H: ledger row: unacked += BoxDiscard
  T->>T: UPDATE sessions Idle to Stopped for each box not held, INSERT events SessionStopped
  T->>T: move snapshot_requests of boxes not held to snapshot_failures, fail their turns
  T->>T: fail each live Claude setup not in heldClaudeSetupIds
  T-->>H: done
  H->>S: Heartbeat
```

The host sends a Heartbeat at the interval set in its runtime configuration. The reply Heartbeat leaves the HostChannel after every write above. A report that matches the stored one writes no row. One row lands in `host_reports` about every 40 seconds, when `heard_at` passes 30 seconds.

`heldTurnIds` names the turns the host runs, every turn named by an unacked host frame, and every offer received and not yet started. An offer the host never took fails HostDropped on the second Heartbeat that omits it. Turns that wait on a `snapshot_requests` row are left out of reconcile.

Code and design differ in four places. Only the Heartbeat `ack` drops outbound frames; the `ack` on a host frame is ignored. A Heartbeat updates `host_reports` but never creates it, so only Hello inserts the row. A telemetry batch TenantMetrics refuses is logged and dropped. The protocol text says an omitted session fails its Running turn BoxLost; the code stops only Idle sessions and leaves Running turns to `heldTurnIds`.

## 3. TurnOffer, TurnClaim and TurnClaimed

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  T->>T: UPDATE turns offer_sent 1, unheld_heartbeats 0
  Note over T: reads host_reports: RateLimited or past 90 s fails the turn here
  T->>H: send(TurnOffer, no credential)
  H->>T: prepareOffer(turnId)
  T->>T: unseal secret set members from secret_values
  rect rgba(120, 140, 255, 0.15)
    T->>T: INSERT credential_handovers, turn_full_images or turn_layered_images
  end
  T->>H: credential: secret variables, turn tokens, GitHub token, presigned GET URLs
  H->>H: ledger row: unacked += TurnOffer (stored without the credential)
  H->>S: Frame TurnOffer with credential
  H-->>T: Sent
  Note over S: offer joins the in-memory offered set and heldTurnIds
  S->>S: channel.json: append TurnClaim seq c
  S->>H: Frame TurnClaim(seq c, boxId)
  H->>T: hostMessage TurnClaim
  rect rgba(120, 140, 255, 0.15)
    T->>T: UPDATE turns Running, sessions Running, prebuilds Building
    T->>T: INSERT events TurnStarted
  end
  T->>H: reply TurnClaimed
  H->>H: ledger row: unacked += TurnClaimed
  H->>S: Frame TurnClaimed
  H->>S: Ack(c)
  Note over H: attachment: cursor c
  opt the Ack is lost with the socket
    S->>H: Hello(resendFrom c), then Welcome
    S->>H: Frame TurnClaim(seq c) again
    H->>T: hostMessage TurnClaim
    Note over T: turn Running on the same box: no write
    T->>H: reply TurnClaimed
    H->>H: ledger row: unacked += TurnClaimed
    H->>S: Frame TurnClaimed (the host gets it twice)
    H->>S: Ack(c)
  end
```

With no open socket the HostChannel answers Offline, and the Tenant fails the turn Undelivered at once. A TurnClaim from another host for this turn gets TurnWithdrawn. A TurnClaim for a turn that already ended gets TurnWithdrawn, plus BoxDiscard when its session is Stopped.

The ledger row stores the offer without the credential. Every send to the host, including a resend at Welcome, calls `prepareOffer` again and mints a fresh credential.

Code and design differ in one place: the Tenant's offer awaits `prepareOffer` before the ledger append, where the design appends before any await. A HostChannel restart in that window rejects the send, and the turn fails Undelivered.

## 4. TurnLines to an R2 chunk

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  S->>S: channel.json: append line to the open TurnLines batch
  S->>H: Frame TurnLines(seq f, firstLineSeq a, lines a to b)
  Note over H: attachment: frame window count + 1
  H->>T: hostMessage TurnLines
  T->>R: read the last stored lineSeq (cached after the first read)
  alt b at or below the stored last: a resend
    Note over T: no write
  else a past the stored last + 1
    T->>T: fail TranscriptGap
  else new lines
    T->>T: UPDATE turns.result_printed 1, once, when a new line is the success result
    T->>R: PUT chunk object of the new lines only, keyed last-first-turnId.jsonl
    alt R2 refuses the PUT
      T->>T: fail TranscriptGap (TranscriptNotStored)
    end
  end
  T-->>H: no reply
  H->>S: Ack(f)
  S->>S: channel.json: drop frames up to f
```

A TurnLines frame writes no Durable Object row, except `result_printed` once per turn. A resend that overlaps stored lines writes only the lines past the stored last, so a chunk key never holds a line twice. A turn that is not Running ignores the frame and the frame is still acked.

`result_printed` commits before the R2 PUT. A PUT that fails after it leaves the flag set on a turn that then fails TranscriptGap, and the turn ends Failed either way.

## 5. TurnComplete and TurnFailed

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  S->>H: Frame TurnComplete or TurnFailed(seq e, credentialFile when the login refreshed)
  H->>T: hostMessage
  opt credentialFile present
    rect rgba(120, 140, 255, 0.15)
      T->>T: seal credentialFile, DELETE and INSERT secret_values, secret_credentials
    end
  end
  alt TurnComplete
    T->>R: read the last stored lineSeq
    Note over T: lastLineSeq mismatch fails TranscriptGap, no result fails HarnessExitedWithoutResult
    Note over T: a snapshot already asked for this turn: no write (a resend)
    T->>T: INSERT turn_warnings (when warned), INSERT snapshot_requests
    T->>H: send SnapshotRequest(presigned PUT URL for the root)
    H->>H: ledger row: unacked += SnapshotRequest
    H->>S: Frame SnapshotRequest with presigned PUT URL
  else TurnFailed NotClaimed
    T->>T: UPDATE turns Offered, offer_sent 1
    T->>H: reply TurnOffer, prepared with a fresh credential as in section 3
    H->>H: ledger row: unacked += TurnOffer
    H->>S: Frame TurnOffer with credential
  else TurnFailed, any other reason
    T->>R: read the transcript end
    rect rgba(120, 140, 255, 0.15)
      T->>T: UPDATE turns Failed, sessions Idle, INSERT turn_failures, events TurnFailed and SessionIdle
      T->>T: DELETE released connector tokens
    end
    T->>T: INSERT snapshot_requests
    T->>H: send SnapshotRequest(presigned PUT URL)
    H->>H: ledger row: unacked += SnapshotRequest
    H->>S: Frame SnapshotRequest with presigned PUT URL
  end
  H->>S: Ack(e)
```

TurnComplete does not complete the turn. It asks for a snapshot, and the turn turns Completed only when SnapshotDone stores it (section 6). A failed turn also asks for a snapshot, so its session keeps the work done so far. TurnFailed HostUpdating moves an Offered turn, or a Running turn with no lines, to another host.

Every write above lands before the Ack. A resent TurnComplete finds its `snapshot_requests` row and writes nothing. A resent TurnFailed finds the turn already Failed and writes nothing.

## 6. Snapshot upload

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  loop each part p
    S->>H: Frame SnapshotChunks(part p, digests)
    H->>T: hostMessage
    T->>R: read the index of the restorable snapshot (cached)
    T->>H: reply SnapshotChunksHeld(part p, held digests)
    H->>H: ledger row: unacked += SnapshotChunksHeld
    H->>S: Frame SnapshotChunksHeld
    H->>S: Ack
    S->>H: Frame SnapshotPacks(part p, packs, chunks)
    H->>T: hostMessage
    T->>R: PUT live-packs.json (the session holds its new packs)
    T->>H: reply SnapshotPackUploads(part p, presigned PUT URL per missing pack)
    H->>H: ledger row: unacked += SnapshotPackUploads
    H->>S: Frame SnapshotPackUploads with presigned PUT URLs
    H->>S: Ack
    S->>R: PUT each missing pack with its presigned URL
  end
  S->>R: PUT the snapshot root with the presigned URL from SnapshotRequest
  S->>H: Frame SnapshotDone(uploadedBytes)
  H->>T: hostMessage
  T->>R: read the root and every manifest object, PUT the pack list object
  T->>R: PUT live-packs.json (the snapshot claims its packs)
  rect rgba(120, 140, 255, 0.15)
    T->>T: DELETE snapshot_requests, INSERT snapshots
    T->>T: UPDATE turns Completed, sessions Idle, INSERT events TurnCompleted and SessionIdle
    T->>T: DELETE released connector tokens
  end
  opt box retention Off
    T->>T: UPDATE sessions Stopping
  end
  opt a queued turn picked by the transaction
    T->>T: UPDATE turns offer_sent 1
    T->>H: send TurnOffer, prepared with a fresh credential as in section 3
    H->>H: ledger row: unacked += TurnOffer
    H->>S: Frame TurnOffer with credential
  end
  opt session Stopping
    T->>H: send BoxTeardown
    H->>H: ledger row: unacked += BoxTeardown
    H->>S: Frame BoxTeardown
  end
  T->>R: PUT live-packs.json (older snapshots release), DELETE older roots and pack lists
  T->>T: DELETE older snapshots rows
  T-->>H: no reply
  H->>S: Ack
```

Each part writes the `ledger` row twice, once per reply, and the next Heartbeat `ack` writes it once more. A stored snapshot writes the same Tenant rows for one chunk or 100000, because chunks and packs live in R2 objects. A resent SnapshotChunks or SnapshotPacks returns the same answer; a resent SnapshotDone finds no `snapshot_requests` row and writes nothing.

SnapshotFailed, or a SnapshotDone whose root, manifest or packs fail the checks, moves the request to `snapshot_failures` and fails the turn SnapshotNotStored.

Code and design differ in one place: `live-packs.json` is written with a plain PUT, where the design asks for an etag-conditional PUT.

## 7. BoxGone and eviction to make room

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  Note over T: placement found no free memory and picked Idle Auto boxes, least recently used first
  T->>T: new turn stays Offered with offer_sent 0 (offer composed, not sent)
  loop each evicted Idle session
    T->>T: UPDATE sessions Stopping
    alt the latest turn has a stored snapshot
      T->>H: send BoxTeardown
      H->>H: ledger row: unacked += BoxTeardown
      H->>S: Frame BoxTeardown
    else no snapshot yet
      T->>T: INSERT snapshot_requests, then section 6, then BoxTeardown
    end
  end
  S->>S: stop the box, free its memory and disk
  S->>H: Frame BoxGone(seq g, sessionId, boxId)
  H->>T: hostMessage BoxGone
  T->>T: UPDATE sessions Stopped, INSERT events SessionStopped
  loop each Offered turn on this host with offer_sent 0, oldest first
    Note over T: held memory and disk from host_reports and session rows
    alt held memory and disk within the host budget
      T->>T: UPDATE turns offer_sent 1, unheld_heartbeats 0
      T->>H: send TurnOffer, prepared with a fresh credential as in section 3
      H->>H: ledger row: unacked += TurnOffer
      H->>S: Frame TurnOffer with credential
    else over budget, a session on the host is Stopping
      Note over T: the turn keeps waiting
    else over budget, no session Stopping
      T->>T: fail PoolExhausted: turns, turn_failures, events
    end
  end
  T-->>H: no reply to BoxGone
  H->>S: Ack(g)
```

The offer of the waiting turn is stored and sent before the Ack of the BoxGone that made room for it. The same loop runs after every Heartbeat reconcile, so a waiting turn is offered as soon as the session rows and the host report leave room.

BoxTeardownFailed inserts `stop_failures` and returns the session to Idle. Its box still holds memory and no session is Stopping, so the next Heartbeat fails the waiting turn PoolExhausted. A teardown that never answers keeps its session Stopping, and the waiting turn waits for its BoxGone.

Code and design differ on main: without PR 149, BoxGone re-runs only the evicted session's own queue, so the waiting turn's offer is never sent.

## 8. Frame-rate limit

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  Note over H: attachment frames: framesPerMinute (600 on dev), windowStart, count
  S->>H: Frame seq f
  Note over H: attachment: count + 1 for this minute (a duplicate seq is not counted)
  alt count past framesPerMinute
    H->>S: FrameRateLimited(seq f, retryAfter = start of the next minute)
    Note over H: cursor stays f-1, nothing stored
    S->>H: frames after f already in flight: each answered FrameRateLimited, each counted
    Note over S: withholds from f until retryAfter plus up to 50 percent jitter
    S->>H: Heartbeat(health RateLimited)
    H->>T: hostHeartbeat
    T->>T: UPDATE host_reports.reported_health RateLimited
    Note over T: placement skips the host, a new offer to it fails RateLimited
    S->>H: from retryAfter: resend from f, at most half the limit per tick
    H->>T: hostMessage
    H->>S: Ack(f)
  else within the limit
    H->>T: hostMessage
    H->>S: Ack(f)
  end
```

The window lives in the socket attachment. It survives hibernation; a new socket starts a fresh window. Running turns keep running through a refusal. The host reports RateLimited for one minute after its last FrameRateLimited, and that `host_reports` update is the one row a refusal writes.

The rate check runs before the gap check. A frame past a gap that arrives after `retryAfter` closes the connection, and the next Hello resends from the oldest unacked frame.

Code and design differ in two places. A refused frame counts against the minute it arrives in, where the protocol text says it counts nothing. A new offer to a host that reports RateLimited fails the new turn RateLimited, where the design pauses offers without failing them.

## 9. Host revoke

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  participant W as Worker
  W->>D: UPDATE hosts state Revoked
  W->>T: forgetHostUsage(hostId)
  T->>T: DELETE host_reports, supervisor update rows of the host
  loop each Offered or Running turn on the host
    T->>T: fail HostRevoked: turns, turn_failures, events, sessions Idle
    T->>T: INSERT snapshot_requests for a session left Idle
    T->>H: send SnapshotRequest(presigned PUT URL)
    H->>H: ledger row: unacked += SnapshotRequest
    H->>S: Frame SnapshotRequest with presigned PUT URL
  end
  T->>T: each snapshot_requests row of the host moves to snapshot_failures NotAnswered
  T-->>W: done
  W->>H: revoke
  H->>H: UPDATE host SET revoked 1
  H->>S: close Revoked
  S->>H: reconnect, Hello
  H->>S: close Revoked
```

Revoke runs from the Worker in three steps: D1, then the Tenant, then the HostChannel. The host learns of it only from the close. No TurnCancel is sent, and credentials already handed over stay valid until they expire.

Code and design differ in one place: failing a Running turn asks its box for a snapshot, so a SnapshotRequest reaches the ledger row and the open socket before the close, and stays unacked in the ledger row.

## 10. Session start and placement

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  participant W as Worker
  W->>D: read the tenant's hosts: state, health, architecture, CPU, memory
  W->>T: startSession(hosts)
  T->>R: read the current release (image architectures) and the deploy drain marker
  Note over T: reads host_reports joined with sessions per host
  Note over T: memory held = max(reported memory_held_mib, sum of live box_memory_mib)
  Note over T: disk held = max(reported disk_held_mib, sum of live box_disk_mib)
  Note over T: admits a host that is Online (heard_at within 90 s), Healthy, has the image, and fits memory and disk
  alt no host fits and no Idle Auto box frees enough
    T->>W: Unplaced, with a reason per host
  else placed
    rect rgba(120, 140, 255, 0.15)
      T->>T: INSERT sessions Starting with host_id and box_id, session_connectors, session_box_memory
      T->>T: INSERT session_box_retention, session_tags, session_origins, session_issues
      T->>T: INSERT turns Offered, turn_goals
    end
    T->>T: UPDATE turns offer_sent 1
    T->>H: send TurnOffer
    H->>T: prepareOffer, answered with the credential as in section 3
    H->>H: ledger row: unacked += TurnOffer
    H->>S: Frame TurnOffer with credential
    H-->>T: Sent
    T->>W: Started(session, turn)
  end
```

A live box belongs to a Starting, Running, Idle or Stopping session. The session row gets its `host_id` and `box_id` in the same transaction as the turn, before the offer, so the next placement in the same Tenant already counts the box. A host with no `host_reports` row reads NotOnline. When eviction is needed, the offer waits for BoxGone as in section 7.

Placement admits on memory and disk only. Free box slots (`box_capacity` less Starting, Running, Idle and Stopping boxes) and load rank the admitted hosts but never refuse one. The disk check applies only when the host reports disk held above zero.

## 11. Turn sent to an existing session

```mermaid
sequenceDiagram
  participant S as Supervisor (host)
  participant H as HostChannel DO
  participant T as Tenant DO
  participant R as R2
  participant D as D1
  participant W as Worker
  W->>T: sendTurn(sessionId, prompt, hosts)
  Note over T: refuses Archived, Stopping, Failed, a refused credential, a disconnected connector, a deploy drain
  alt a turn of the session is Offered or Running
    T->>T: INSERT turns Offered with offer_sent 0, turn_goals
    T->>W: Sent (queued behind the earlier turn)
  else the box is live on an Online host
    rect rgba(120, 140, 255, 0.15)
      T->>T: UPDATE sessions Running, INSERT turns Offered, turn_goals
    end
    T->>T: UPDATE turns offer_sent 1
    T->>H: send TurnOffer, prepared as in section 3
    H->>H: ledger row: unacked += TurnOffer
    H->>S: Frame TurnOffer with credential
    T->>W: Sent
  else the box is Stopped, or its host is not Online
    Note over T: places as in section 10, never evicting the session's own box
    T->>T: move the old host's snapshot_requests to snapshot_failures
    rect rgba(120, 140, 255, 0.15)
      T->>T: UPDATE sessions Running with the new host_id and box_id, INSERT turns, turn_goals
    end
    T->>H: send TurnOffer to the new host, or evict first as in section 7
    T->>H: send BoxDiscard to the old host when its box was not Stopped
    T->>W: Sent
  end
```

A queued turn is offered when the turn before it ends: the transaction that ends that turn picks it, and the offer goes out after the commit. A session whose completed turns have no stored snapshot is refused as Stranded when it has to move host, because the new box cannot restore their work.

Excluding the session's own box from eviction comes from PR 149; on main a send picks the session's own Idle box as the box to evict.

## FAQ

**Why does the host get TurnClaimed twice after a lost Ack?**
The control plane cannot tell a resent TurnClaim from a lost reply, so it answers again with no write.

**Can a turn wait forever for room?**
Yes, while a teardown never answers. Its session stays Stopping, and the waiting turn waits for a BoxGone that never comes.

**Where do credentials live after an offer?**
In box memory on the host. The `ledger` row stores the offer without them, and each resend mints new ones.

## Appendix: rows per operation

Rows count Durable Object SQL rows and index entries, as the scenario tests and the dev metrics count them. "Idle" is one host with no turn for 10 minutes. Measured figures come from the `test/scenarios` row tests at bdd61a1 and from the dev row counts recorded with them.

| Operation                          | Rows written per store                                                                                                                | Idle 10 min                      | Measured                                                                             | Row budget                |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------ | ------------------------- |
| Hello                              | D1: 0 unchanged. HostChannel: 0. Tenant: `host_reports` 0 or 1, `events` 0 or 1, plus one `credential_handovers` row per resent offer | 0                                | not measured                                                                         | at most 1                 |
| Heartbeat                          | HostChannel: `ledger` 0, or 1 when `ack` drops a frame. Tenant: `host_reports` 0 or 1. TenantMetrics: 0                               | Tenant at most 20, HostChannel 0 | test: at most 20 Tenant, 0 HostChannel; dev: 46 for two hosts                        | 20 Tenant, 0 HostChannel  |
| TurnOffer to TurnClaimed           | HostChannel: `ledger` 2. Tenant: `turns`, `credential_handovers`, image row, then `turns`, `sessions`, `events` at claim              | 0                                | within the turn below                                                                | within the turn below     |
| TurnLines                          | Tenant: 0, plus `result_printed` once per turn. R2: one PUT per frame. HostChannel: 0                                                 | 0                                | test: rows do not grow with lines or chunks                                          | 0 rows, one PUT per frame |
| TurnComplete                       | Tenant: `snapshot_requests` 1. HostChannel: `ledger` 1                                                                                | 0                                | within the turn below                                                                | within the turn below     |
| Stored snapshot                    | HostChannel: `ledger` 2 per part. Tenant: fixed per snapshot. R2: `live-packs.json`, pack list, packs, root                           | 0                                | test: at most 20 Tenant, the same for 1 or 100000 chunks; failed snapshot at most 25 | no separate budget        |
| One turn, offer to stored snapshot | sum of the rows above                                                                                                                 | 0                                | test and dev: 53 Tenant, 5 HostChannel                                               | 24 Tenant, 10 HostChannel |
| BoxGone after eviction             | Tenant: `sessions` 2, `events` 1, then the offer rows. HostChannel: `ledger` 2                                                        | 0                                | not measured                                                                         | no separate budget        |
| Frame-rate limit                   | HostChannel: 0 (attachment only). Tenant: `host_reports` 1 when the reported health turns RateLimited                                 | 0                                | test: no row per refused frame                                                       | 0                         |
| Host revoke                        | D1: `hosts` 1. Tenant: `host_reports` 1 and the failure rows per turn. HostChannel: `host` 1                                          | 0                                | not measured                                                                         | no separate budget        |
| Session start                      | Tenant: `sessions` and its side tables, `turns`, then the offer rows. HostChannel: `ledger` 1                                         | 0                                | within the turn above                                                                | within the turn above     |
| Turn to an existing session        | Tenant: `sessions`, `turns`, then the offer rows. HostChannel: `ledger` 1                                                             | 0                                | within the turn above                                                                | within the turn above     |

The idle figure is inside the row budget of 100 rows per 10 minutes, and the Tenant's 30-second `host_reports` refresh makes up all of it. One turn writes 53 Tenant rows against a row budget of 24; session creation, credential handovers, layered image rows and snapshot request rows make up the difference.
