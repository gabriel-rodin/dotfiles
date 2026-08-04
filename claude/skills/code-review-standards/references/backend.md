# Backend Review Checklist

Node.js/TS/Express/TypeORM: route/service/repository separation, explicit validation and error handling, transaction-safe writes, middleware-based auth/org/permission enforcement, query correctness and N+1 prevention, write-endpoint idempotency.

## Correctness

- **RFC-grammar headers**: when a request/response header is defined by an RFC with a value grammar beyond a single literal (conditional-request headers like `If-None-Match`/`If-Match`, `Accept*` families), does the implementation handle the full grammar (comma-list, `*`) or only the single-value case one client happens to send? `backend/src/routes/organizationLogo.ts` is the reference example done correctly.
- **In-memory/fake repository parity**: if this change adds a DB-backed repository next to an existing in-memory/fake one, do their not-found and soft-deleted edge cases match, **and** does the fake's sort/tie-break comparison actually match SQL's — plain lexicographic `<`/`>` on ISO-8601 UTC timestamps with the same tie-break columns (e.g. `created_at` then `id`), never `String.prototype.localeCompare()`, whose result is locale-sensitive and varies by runtime (dev/CI/prod)? `messageRepository.ts`'s `isNewer` is the reference.

## Security & Access Control

- **Org/tenant scoping**: does every repository method taking a bare entity id (`findById`, `softDelete`, `isMember`, etc.) filter by `org_id` in the query itself — not rely on the caller re-checking after an unscoped fetch?

## Data Integrity

- transaction boundaries and rollback safety
- concurrent update and partial update risks generally, not just the audit/snapshot case below
- **Idempotency for write/retry paths**: does a no-op call (delete-already-deleted, set-to-current-value) still write an audit entry, bump timestamps, or emit an event it shouldn't? Fix: check-then-short-circuit before any write, not write-then-reason. Re-check this after every subsequent edit to the same method — a later concurrency fix (below) can turn a conditional write into an unconditional one and silently reintroduce this.
- **Concurrency/audit accuracy**: for a value read before a transaction starts and later used in an audit log or response, could a concurrent write to a different part of the same aggregate land in the gap before commit? If returned/broadcast, re-read after commit; if it only feeds an audit log, document the staleness explicitly. Any invariant spanning a read-then-write (existence, non-empty, uniqueness) must be enforced under a lock (`SELECT ... FOR UPDATE`) inside the same transaction as the write — not against a snapshot read before the transaction started.
- **Schema migration safety**: for data-migrating migrations, does any `WHERE`/`JOIN` guard risk silently excluding a row instead of failing loudly? If a field's source of truth moves, is the old location cleared in the same migration (or the deferral explicitly justified)? Does `down()` restore data, not just schema?

## Performance

- **N+1 and unbounded queries**: is any per-row loop that issues a query per row (N+1) replaced with one batched `WHERE id IN (...)` query? Does every `list*`/`search*` method apply `LIMIT`/`OFFSET` in SQL rather than fetching everything and slicing in application code?
- realtime bottlenecks (socket/event fan-out)
- **Composite-index coverage for every branch of a multi-branch query**: when adding or relying on an index to keep a query index-only, does *every* branch use it — not just the first? A `UNION ALL` (or `OR`-expanded) query whose branches lead on different columns (e.g. `recipient_id`-first vs `sender_id`-first) needs a covering index per branch; one branch being index-only while its mirror falls back to per-row lookups silently halves the speedup and passes every test. For each branch, confirm the filter *and* the correlated-subquery (`NOT EXISTS`) columns form a leftmost prefix of some index in order — including the `type`/`deleted_at`/`created_at` tie-break columns, not just the join key. `messageRepository.ts`'s `findLatestPerDirectPeer` is the reference: the recipient branch is covered by `idx_messages_org_recipient`, but the sender branch needs a symmetric `(org_id, sender_id, recipient_id, type, deleted_at, created_at)` index that `idx_messages_org_sender_recipient` (stops at `recipient_id`) does not provide.

## Architecture & Consistency

- **Reuse before hand-rolling**: before hand-rolling a transaction lifecycle or an insert-then-read-back pattern, did the change grep for an existing helper (e.g. `db/sqlExecutor.ts`'s `withTransaction`) and either use it or state why it doesn't fit?
