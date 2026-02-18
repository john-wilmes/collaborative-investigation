# Brief: TEST-1234

## Customer
Acme Corp, production environment, Enterprise tier

## Problem
After running a bulk contact import of ~5,000 records, customer reports seeing duplicate contacts. Some contacts appear 2-3 times. Problem is worse when imports are retried after partial failures.

## Impact
~800 duplicate records created across 3 import batches. Customer's sales team is seeing duplicate entries in their pipeline and sending duplicate outreach emails.

## Relevant Code Paths
REPOS/acme-crm/src/sync/bulk-import.js
REPOS/acme-crm/src/sync/queue.js
REPOS/acme-crm/src/api/import-controller.js
REPOS/acme-crm/src/models/contact.js

## Initial Hypothesis
Bulk import may not be using atomic upserts, causing race conditions when concurrent workers process overlapping records.
