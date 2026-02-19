# Status: VNSE-4821

## Current Understanding
Root cause confirmed. The CSV had 53 BULL rows and 47 non-BULL rows (not 100 bulls as reported). All 53 BULL rows failed at `createEPDProfile` with "Not Authorized" because the EPDProfile model uses `allow.group("admins")` for create -- regular authenticated users including ranch managers cannot create EPDProfiles. The raw GraphQL workaround (introduced for an Amplify serialization bug) bypasses owner injection but still executes as the calling user, who lacks admin group membership. No EPDProfiles and no Listings were written for the 53 failed rows. The 47 created listings are non-BULL types that never entered the EPD path. No orphaned EPDProfiles exist from this import event.

## Open Questions
- None blocking recovery. The authorization rule defect is confirmed and the fix is known.
- Follow-up: was the EPDProfile `allow.group("admins")` rule intentional? If so, the CSV import feature has never worked for any customer with BULL/REGISTERED_HEIFER rows.
- Follow-up: re-evaluate the Amplify serialization bug that necessitated the raw GraphQL workaround -- may be fixed in a newer Amplify Gen2 version.

## Next Action
Engineering: change EPDProfile authorization in `amplify/data/resource.ts` to `allow.owner()` for create (matching Listing model pattern), redeploy Amplify backend, then advise Bar Double J Ranch to re-run their CSV import. No DynamoDB cleanup needed.
Run /close to finalize, sanitize, and push the `inv/VNSE-4821` branch.

## History
| Date | Phase | Summary |
|------|-------|---------|
| 2026-02-18 | init | Project created from template |
| 2026-02-18 | collect | Code review of csv-import.ts and ImportListingsPage.tsx. 5 evidence files written. EPD GraphQL workaround identified as primary failure vector; silent epdProfileId omission identified as secondary data integrity risk. |
| 2026-02-18 | collect | Datadog APM (Evidence 006): 53 auth-error traces for createEPDProfile, 47 success traces for non-EPD rows. CSV breakdown (Evidence 008): 53 BULL + 47 non-BULL. AppSync schema auth rule confirmed (Evidence 007). 3 evidence files written. |
| 2026-02-18 | synthesize | Root cause confirmed. EPDProfile model requires admin group for create; ranch manager (regular user) fails authorization on every BULL row. 53 failures are all BULL rows. 47 successes are all non-EPD types. No orphaned EPDProfiles. Fix: change EPDProfile auth rule to allow.owner() for create. FINDINGS.md written. |
| 2026-02-18 | close | Investigation closed. Haiku classifier wrote Classification section. FINDINGS.md, BRIEF.md, STATUS.md committed and pushed to inv/VNSE-4821. |
