# Brief: VNSE-4821

## Context
Customer: Bar Double J Ranch. Support ticket filed 2026-02-17. Ranch manager uploaded their spring bull catalog via CSV import. Expected 100 bulls with EPD profiles. Only 47 listings appeared.

## Question
Why did the CSV bulk import create only 47 of 100 listings, and where did the EPD data go for the ones that were created?

## Scope
Affects any customer using CSV import for breeding stock with EPD data (BULL and REGISTERED_HEIFER types). Potential data integrity issue -- orphaned EPD profiles or missing genetic records could lead to incorrect breeding decisions.

## Relevant Code Paths
- REPOS/vnse/src/utils/csv-import.ts (import pipeline, EPD profile creation)
- REPOS/vnse/src/pages/ImportListingsPage.tsx (UI that drives the import)

## Starting Point
The import uses parallel batches (concurrency=5). EPD profiles are created via raw GraphQL mutation as a workaround for an Amplify serialization bug. Initial hypothesis was that error handling in the GraphQL path was swallowing failures. Confirmed cause: `allow.group("admins")` authorization rule on EPDProfile blocks creation by regular authenticated users.
