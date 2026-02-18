---
allowed-tools: Bash, Read, Write, Glob, Grep, Task
description: Finalize investigation and push to GitHub
user-invocable: true
---

# /close $ARGUMENTS

Finalize the investigation, classify it, ensure PHI is sanitized, and push the branch.

$ARGUMENTS is the ticket-id.

## Steps

1. Set TICKET_ID to $ARGUMENTS. Read PROJECTS/$TICKET_ID/BRIEF.md, PROJECTS/$TICKET_ID/FINDINGS.md, and PROJECTS/$TICKET_ID/STATUS.md. If they do not exist, tell the human and stop.
2. Validate completeness:
   - FINDINGS.md must have Question, Answer, and Evidence Summary filled in (not just template placeholders)
   - If incomplete, tell the human what is missing and stop
3. Run the classifier: use the Task tool to spawn a Haiku subagent with this prompt:

   "You are a classification agent. Read the investigation files and write a natural language classification for the Classification section of FINDINGS.md.

   Read these files:
   - PROJECTS/$TICKET_ID/BRIEF.md
   - PROJECTS/$TICKET_ID/FINDINGS.md
   - All files in PROJECTS/$TICKET_ID/EVIDENCE/
   - PROJECTS/$TICKET_ID/STATUS.md

   Write exactly 3-5 sentences covering:
   - What type of investigation this was (incident root-cause analysis, system behavior exploration, integration mapping, performance analysis, security review, etc.)
   - What was learned and its significance
   - Which systems, components, or interfaces were involved
   - The practical impact or importance of the findings (could be a bug severity, a knowledge gap closed, a design constraint discovered, or a confirmation that something works as expected)
   - Any open threads, caveats, or areas that warrant follow-up

   Write in plain English for a teammate reading this cold. Be specific, not generic. This is not always a bug -- it might be exploratory research, system documentation, or confirming expected behavior. Return ONLY the 3-5 sentences, nothing else."

4. Take the classifier's output and write it into the Classification section of PROJECTS/$TICKET_ID/FINDINGS.md
5. Present the classification to the investigator. Ask: does this look right, or do you want to edit it?
6. After investigator approves (or edits):
   - Update STATUS.md: add final history entry with "Closed" phase
   - Stage PROJECTS/$TICKET_ID/BRIEF.md, PROJECTS/$TICKET_ID/FINDINGS.md, and PROJECTS/$TICKET_ID/STATUS.md
   - Do NOT stage EVIDENCE/ (gitignored, enforced by pre-commit hook)
7. Get the ticket-id from the branch name: `git rev-parse --abbrev-ref HEAD`, strip the "inv/" prefix. If it does not match $TICKET_ID, warn the human.
8. Commit with message: "investigation: $TICKET_ID - <one-line summary of the answer from FINDINGS.md>"
   - The pre-commit hook will run PHI sanitization and re-stage automatically
9. Post-commit verification: read the committed FINDINGS.md via `git show HEAD:PROJECTS/$TICKET_ID/FINDINGS.md`. Confirm that Question, Answer, and Classification sections each contain at least one non-placeholder sentence. If sanitization degraded the content, warn the human.
10. Push the inv/$TICKET_ID branch to origin
    - If push fails, report the exact error to the human and stop
    - The human can push manually with: git push -u origin inv/$TICKET_ID
11. Report the branch name and suggest creating a PR or /reopen later if needed

## Rules
- Never push without the pre-commit hook running (no --no-verify)
- The commit includes BRIEF.md, FINDINGS.md, and STATUS.md
- EVIDENCE/ stays local (gitignored)
- The classifier's output can be overridden by the investigator -- they have final say
