---
allowed-tools: Bash, Read, Write, Glob, Grep
description: Finalize investigation and push to GitHub
user-invocable: true
---

# /close $ARGUMENTS

Finalize the investigation, ensure PHI is sanitized, and push the branch.

$ARGUMENTS is the ticket-id.

## Steps

1. Set TICKET_ID to $ARGUMENTS. Read PROJECTS/$TICKET_ID/BRIEF.md, PROJECTS/$TICKET_ID/FINDINGS.md, PROJECTS/$TICKET_ID/STATUS.md, and PROJECTS/$TICKET_ID/.tags. If they do not exist, tell the human and stop.
2. Validate completeness:
   - FINDINGS.md must have Root Cause, Evidence Summary, and Resolution filled in (not just template placeholders)
   - .tags must include at least one tag from each required category. Check with:
     - `grep "^root-cause:" PROJECTS/$TICKET_ID/.tags` -- must return at least one line
     - `grep "^area:" PROJECTS/$TICKET_ID/.tags` -- must return at least one line
     - `grep "^severity:" PROJECTS/$TICKET_ID/.tags` -- must return at least one line
   - If incomplete, tell the human what is missing and stop
3. Stage the files that get pushed: PROJECTS/$TICKET_ID/BRIEF.md, PROJECTS/$TICKET_ID/FINDINGS.md, PROJECTS/$TICKET_ID/.tags
   - Do NOT stage EVIDENCE/ (gitignored, but also enforced by pre-commit hook)
   - Do NOT stage STATUS.md (local working notes, enforced by pre-commit hook)
4. Get the ticket-id from the branch name: `git rev-parse --abbrev-ref HEAD`, strip the "inv/" prefix. If it does not match $TICKET_ID, warn the human.
5. Update .tags: set status to "status:resolved". Re-stage .tags.
6. Commit with message: "investigation: $TICKET_ID - <one-line root cause summary from FINDINGS.md>"
   - The pre-commit hook will run PHI sanitization and re-stage automatically
7. Post-commit verification: read the committed FINDINGS.md via `git show HEAD:PROJECTS/$TICKET_ID/FINDINGS.md`. Confirm that Root Cause, Evidence Summary, and Resolution sections each contain at least one non-placeholder sentence (not just [PATIENT_NAME], [DATE], etc.). If sanitization degraded the content, warn the human and provide the pre-sanitization text for them to rewrite.
8. Push the inv/$TICKET_ID branch to origin
   - If push fails, report the exact error to the human and stop
   - Do NOT proceed to step 9 until push succeeds
   - The human can push manually with: git push -u origin inv/$TICKET_ID
9. Update STATUS.md: add final history entry with resolution summary. This happens AFTER successful push so STATUS.md does not claim "resolved" if the branch never left the local machine.
10. Report the branch name and suggest creating a PR if the team uses that workflow

## Rules
- Never push without the pre-commit hook running (no --no-verify)
- The commit must include BRIEF.md, FINDINGS.md, and .tags only
- STATUS.md and EVIDENCE/ stay local
