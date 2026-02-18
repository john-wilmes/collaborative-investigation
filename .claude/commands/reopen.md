---
allowed-tools: Bash, Read, Write, Glob, Grep
description: Resume a previously closed investigation
user-invocable: true
---

# /reopen $ARGUMENTS

Resume a closed investigation from its pushed branch.

$ARGUMENTS is the ticket-id.

## Steps

1. Set TICKET_ID to $ARGUMENTS.
2. Check the current branch: `git rev-parse --abbrev-ref HEAD`. If it is an inv/* branch different from inv/$TICKET_ID, warn the human. Check for unpushed commits on the current branch (`git log @{u}..HEAD`) and mention them if any exist.
3. Fetch the branch: `git fetch origin inv/$TICKET_ID`
   - If the branch does not exist on origin, tell the human and stop
4. Check out the branch: `git checkout inv/$TICKET_ID`
   - If there are local changes that would be overwritten, tell the human and stop. Suggest: commit or stash current changes first (`git stash`), then rerun /reopen.
5. Verify PROJECTS/$TICKET_ID/ exists with BRIEF.md, FINDINGS.md, and STATUS.md
   - If STATUS.md is missing (older investigation closed before STATUS.md was pushed), create one using the format from scripts/new-project.sh. Set Current Understanding from FINDINGS.md Answer section. Leave Open Questions empty. In History, add two rows: one with date "unknown" and phase "init" and summary "Original investigation (pre-STATUS.md era)", and one with today's date and phase "reopen".
6. Create PROJECTS/$TICKET_ID/EVIDENCE/ directory if it does not exist (was gitignored)
7. Update STATUS.md:
   - Add a history entry: current date, "reopen" phase, "Investigation reopened"
   - Clear the "Next Action" section or set it to "Review prior findings and collect new evidence"
8. Read BRIEF.md, FINDINGS.md, and STATUS.md. Summarize for the investigator:
   - What the original investigation was about
   - What was found (from FINDINGS.md Answer section)
   - The full investigation history (from STATUS.md)
   - What evidence is NOT available (EVIDENCE/ was local-only and not preserved)
9. Ask the investigator: what prompted reopening? Update the STATUS.md Current Understanding and Open Questions based on their answer. If the reopening changes the original question, advise the investigator to update BRIEF.md before proceeding with /collect.

## Rules
- Do not modify FINDINGS.md or BRIEF.md during reopen -- those reflect the prior conclusion
- New evidence goes into EVIDENCE/ as usual; numbering is determined by /collect (checks FINDINGS.md for highest referenced number)
- The investigator can run /synthesize again to update FINDINGS.md with new evidence
- A reopened investigation follows the same /collect -> /synthesize -> /close cycle
