# Findings: TEST-1234

## Root Cause
`bulk-import.js` uses a non-atomic find-then-insert pattern (`Contact.findOne` + `Contact.create`) instead of a single `findOneAndUpdate` with `upsert: true`. When the API splits a 5,000-record batch into 25 parallel chunks of 200, concurrent workers race on overlapping email addresses and each inserts the same contact independently. The MongoDB `(email, orgId)` index is non-unique, so the database accepts all duplicates silently. Failed batches are retried by re-enqueuing the full original chunk, causing already-inserted records to be re-processed through the same non-atomic path, which multiplies the duplication count with each retry.

## Evidence Summary
1. `bulk-import.js:9-32` -- find-then-insert pattern with a developer comment explicitly flagging the bug. No atomic upsert used. (evidence 001)
2. `queue.js:13-20` -- failed jobs re-enqueue `job.data` (the full original batch) verbatim, with no record of which rows already succeeded. Up to 3 retries at 5 s intervals. (evidence 002)
3. `contact.js:12-13` -- `(email, orgId)` compound index declared without `unique: true`. Database enforces no deduplication constraint. (evidence 003)
4. `import-controller.js:23-26` -- 5,000-record import is split into 25 chunks of 200 and enqueued independently with no cross-chunk dedup guard, maximising concurrency and therefore the window for races.

## Impact Assessment
Acme Corp, Enterprise tier, production environment. Approximately 800 duplicate records created across 3 import batches. Affected records are contacts whose email addresses appeared in overlapping chunks or in batches that triggered retries. Sales team is sending duplicate outreach to affected contacts. No other customers confirmed affected; however, any org that has run a bulk import of more than one chunk (>200 records) is potentially at risk.

## Resolution
1. Replace `Contact.findOne` + `Contact.create` in `bulk-import.js` with `Contact.findOneAndUpdate({ email, orgId }, { $set: {...} }, { upsert: true, new: true })`. This makes each record operation atomic.
2. Add `{ unique: true }` to the `(email, orgId)` index in `contact.js` as a database-level safety net. Run a dedup migration before applying the index.
3. Fix retry logic in `queue.js`: either track per-record success state (e.g., write succeeded record IDs to Redis) and skip on retry, or switch to idempotent per-record queue jobs so retrying a job is safe.
4. De-duplicate the ~800 existing records for Acme Corp (retain the oldest `createdAt` per `(email, orgId)` pair, discard the rest).

## Prevention
- Enforce `unique: true` on all natural-key indexes as a schema convention -- non-unique compound indexes that serve as logical keys are a latent data-integrity risk.
- Require upsert patterns (not find-then-insert) in the import layer; add a lint rule or PR checklist item.
- Queue job retry handlers must be idempotent by design: either per-record jobs or explicit idempotency keys checked before processing.
- Add an integration test that runs two concurrent workers against the same batch and asserts no duplicates are created.
