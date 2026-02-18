---
allowed-tools: Bash, Read, Write, Glob, Grep, Task
description: Synthesize collected evidence into findings
user-invocable: true
---

# /synthesize $ARGUMENTS

Condense all collected evidence into FINDINGS.md and update the investigation status.

$ARGUMENTS is the ticket-id.

## Steps

1. Set TICKET_ID to $ARGUMENTS. Read PROJECTS/$TICKET_ID/STATUS.md, PROJECTS/$TICKET_ID/BRIEF.md. If they do not exist, tell the human and stop.
2. Read all evidence files in PROJECTS/$TICKET_ID/EVIDENCE/
3. Read schemas/findings.template.md for the output format
4. Analyze the evidence:
   - What question was the investigation trying to answer? (from BRIEF.md)
   - What does the evidence show? Identify patterns, confirmations, contradictions
   - Is there a clear answer, or are there gaps?
5. If the answer is clear:
   - Overwrite the entire PROJECTS/$TICKET_ID/FINDINGS.md using the template. Any prior Classification text will be cleared -- it gets rewritten at /close time.
   - Update STATUS.md: record synthesis in history, note what was answered
6. If the answer is NOT clear:
   - Write a partial FINDINGS.md noting what is known so far
   - Update STATUS.md: refine the question, list specific gaps, suggest next data to collect
   - Tell the human what is missing and what evidence would help
7. If code paths are mentioned in BRIEF.md, read relevant files in REPOS/ to correlate evidence to code

## Rules
- FINDINGS.md uses structured blocks, not narrative
- Reference evidence by number (e.g., "Evidence 003 shows...")
- Keep customer/org names, sanitize patient PHI
- This is analysis, not data collection -- do not ask the human for new data here
- Do NOT write the Classification section -- that happens at /close time
