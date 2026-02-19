# Findings: VNSE-4821

## Question

1. Why did the CSV bulk import create only 47 of 100 listings for Bar Double J Ranch?
2. Where did the EPD data go for the listings that were created -- are EPD profiles orphaned?

## Answer

**1. The 53 missing listings are all BULL rows. Every one failed at the `createEPDProfile` AppSync mutation with "Not Authorized to access createEPDProfile on type Mutation."**

The customer's CSV contained 53 BULL rows and 47 non-BULL rows (12 HEIFER, 18 STEER, 11 COW, 6 REGISTERED_HEIFER). Only the 47 non-BULL rows were created successfully. The ticket's framing of "100 bulls" was inaccurate -- the full catalog had mixed animal types.

The authorization failure has a precise cause in the code. `EPDProfile` is defined in `amplify/data/resource.ts` (lines 120-123) with `allow.group("admins")` for create/update/delete and `allow.publicApiKey()` for read only. Regular authenticated users have no create permission on this type. The import runs via `client.graphql()` with `authMode: "userPool"`, meaning it executes as the logged-in ranch manager -- a non-admin user -- and AppSync correctly rejects every mutation.

The raw GraphQL workaround in `csv-import.ts` (lines 290-335) was introduced to bypass an Amplify `a.json()` serialization bug. It routes around the Amplify client's automatic permission handling but does not add the `owner` field or arrange for admin-level execution. Every BULL row hits this path and fails before a Listing record is ever written, so there are no orphaned half-created listings for the 53 failures: the Listing create at line 337 is never reached.

**2. The 47 created listings have no EPD data at all -- but they are not "missing" EPD profiles. They are non-BULL types that never went through the EPD path.**

Evidence 005 identified a secondary risk: if `createEPDProfile` returned a success response with a null `id`, the Listing would be created without `epdProfileId` and an orphaned EPDProfile would exist in DynamoDB. This risk does not apply to the 53 failed rows (they never got past EPD creation). For the 47 created non-BULL listings, the EPD code block was never entered (condition at line 290 gates on BULL or REGISTERED_HEIFER type plus non-empty `epdValues`). The 6 REGISTERED_HEIFER rows succeeded because their EPD columns were empty after CSV parsing, bypassing the EPD path entirely. Evidence 006 confirms 53 error traces and 47 success traces, with no successful `createEPDProfile` traces in the window -- meaning no EPDProfiles were created at all and no orphan risk exists for this import.

## Evidence Summary

1. Evidence 001: `importListings` uses `Promise.allSettled` in sequential batches of 5. Resilient design -- one row failure cannot kill its batch-mates.
2. Evidence 002: BULL rows use a raw `client.graphql()` mutation to create EPDProfiles before creating the Listing. If EPD creation throws, the Listing is never written.
3. Evidence 003: The error-handling logic in the raw GraphQL path is structurally correct -- AppSync error arrays are caught and re-thrown, propagating to `allSettled`.
4. Evidence 004: `Promise.allSettled` failure accounting ensures 53 failures would surface in `result.failed` and be visible in the UI's "Failed Rows" table. Error messages were available to the customer on the import completion screen.
5. Evidence 005: Silent `epdProfileId` omission (lines 332-334) is a real secondary risk for future imports, but did not affect this event because no EPDProfile was successfully created.
6. Evidence 006 (Datadog APM): 53 error traces for `createEPDProfile`, all returning "Not Authorized to access createEPDProfile on type Mutation." 47 successful `createListing` traces for non-EPD rows. Timestamps 14:12-14:14 UTC, 2026-02-17. No successful EPD traces in this window.
7. Evidence 007: Initial inspection suggested the authorization rule was `allow.owner()`. Code review of `REPOS/vnse/amplify/data/resource.ts` lines 120-123 confirmed the create operation uses `allow.group("admins")`, not owner. Regular authenticated users cannot create EPDProfiles under any circumstances.
8. Evidence 008: CSV breakdown -- 53 BULL, 47 non-BULL (12 HEIFER, 18 STEER, 11 COW, 6 REGISTERED_HEIFER). The 6 REGISTERED_HEIFERs succeeded because their EPD columns were empty, bypassing the EPD mutation path. This reconciles the 53/47 split exactly.

## Implications

**Root cause is confirmed and actionable.** The EPDProfile authorization model (`allow.group("admins")`) prohibits creation by regular users, including ranch managers performing CSV imports. This is almost certainly an unintentional authorization rule -- the Listing model uses `allow.owner()` for create, and EPDProfiles are a dependent record. The rule likely should be `allow.owner()` or `allow.authenticated()` for create, consistent with how Listings are handled.

**Immediate fix:** Change the EPDProfile authorization in `amplify/data/resource.ts` to permit owner-based or authenticated creation, then redeploy the Amplify backend. No frontend code changes are required; the existing raw GraphQL workaround will succeed once authorization is correct. The Amplify serialization bug that necessitated the workaround should be re-evaluated separately.

**Data recovery for this customer:** The 53 BULL rows need to be re-imported after the fix is deployed. No DynamoDB cleanup is needed -- no EPDProfiles or Listings were written for the failed rows.

**Secondary code defect (non-blocking):** The silent `epdProfileId` omission at `csv-import.ts` lines 332-334 should be converted to a thrown error so that a null-id response from AppSync does not silently create a Listing without its EPD link. This is a defensive code change, not required for this customer's recovery.

**Scope:** Any customer using CSV import for BULL or REGISTERED_HEIFER rows with EPD data is affected. This feature may have never worked in production if the authorization rule was set this way from initial deployment.

## Classification

This was a root-cause analysis of a CSV bulk import data integrity issue affecting a livestock breeding management feature. Investigation revealed that the customer's report of "100 missing bull listings" was inaccurate: the CSV contained 53 BULL rows and 47 non-BULL rows, with only the BULL rows failing due to a strict AppSync authorization rule (`allow.group("admins")`) on the EPDProfile model that prevents regular authenticated users from creating EPD records. The failure point was a raw GraphQL workaround (introduced to bypass an Amplify serialization bug) that bypassed automatic owner-field injection, causing every BULL row to fail authorization before any Listing record was written -- ensuring no orphaned EPDProfiles or half-created listings exist. The fix is a targeted authorization rule change to `allow.owner()` on the EPDProfile model to match the Listing pattern, with a secondary defensive code change to catch silent `epdProfileId` omission in future imports. This feature appears to have never worked in production for any customer importing BULL or REGISTERED_HEIFER rows with EPD data if the authorization rule was set this way at deployment.
