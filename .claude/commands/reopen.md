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
2. Fetch the branch: `git fetch origin inv/$TICKET_ID`
   - If the branch does not exist on origin, tell the human and stop
3. Check out the branch: `git checkout inv/$TICKET_ID`
   - If there are local changes that would be overwritten, tell the human and stop
4. Verify PROJECTS/$TICKET_ID/ exists with BRIEF.md, FINDINGS.md, and STATUS.md
   - If STATUS.md is missing (older investigation closed before STATUS.md was pushed), create one from the FINDINGS.md and BRIEF.md context
5. Create PROJECTS/$TICKET_ID/EVIDENCE/ directory if it does not exist (was gitignored)
6. Update STATUS.md:
   - Add a history entry: current date, "reopen" phase, "Investigation reopened"
   - Clear the "Next Action" section or set it to "Review prior findings and collect new evidence"
7. Read BRIEF.md, FINDINGS.md, and STATUS.md. Summarize for the investigator:
   - What the original investigation was about
   - What was found (from FINDINGS.md Answer section)
   - The full investigation history (from STATUS.md)
   - What evidence is NOT available (EVIDENCE/ was local-only and not preserved)
8. Ask the investigator: what prompted reopening? Update the STATUS.md Current Understanding and Open Questions based on their answer.

## Rules
- Do not modify FINDINGS.md or BRIEF.md during reopen -- those reflect the prior conclusion
- New evidence goes into EVIDENCE/ as usual, numbering continues from where it left off (or starts at 001 if evidence was lost)
- The investigator can run /synthesize again to update FINDINGS.md with new evidence
- A reopened investigation follows the same /collect -> /synthesize -> /close cycle
