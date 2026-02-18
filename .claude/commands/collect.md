---
allowed-tools: Bash, Read, Write, Glob, Grep, Task
description: Collect one piece of evidence for an investigation
user-invocable: true
---

# /collect $ARGUMENTS

Collect one piece of structured evidence. First argument is the ticket-id. Remaining arguments are the data source or a description of what was found.

Parse $ARGUMENTS: the first word is the ticket-id, everything after is the source/data.

## Steps

1. Set TICKET_ID to the first word of $ARGUMENTS. Read PROJECTS/$TICKET_ID/STATUS.md and PROJECTS/$TICKET_ID/BRIEF.md. If they do not exist, tell the human and stop.
2. Read PROJECTS/$TICKET_ID/.tags. Confirm status is "status:investigating". If not, warn the human that this investigation is in a different state.
3. Determine the next evidence number by counting existing files in PROJECTS/$TICKET_ID/EVIDENCE/
4. Read schemas/evidence.template.md for the template
5. If the remaining arguments name a data source (e.g., "datadog", "mongodb"):
   - Read schemas/toolkit.md for the source's capabilities
   - Based on STATUS.md's open questions, suggest a specific query or action for the human to run
   - Wait for the human to provide the results
6. If the remaining arguments contain pasted data or observations:
   - Parse the provided data into the evidence template format
   - Write the evidence file to PROJECTS/$TICKET_ID/EVIDENCE/NNN-<slug>.md
7. After writing evidence:
   - Update STATUS.md: add a history entry, update open questions if the evidence changes them
   - If the evidence significantly changes the picture, note it in STATUS.md's hypothesis section
8. Tell the human what was recorded and suggest the next data point to collect

## Rules
- One evidence file per invocation
- Observation is 3 lines max
- Tags must come from schemas/tags.allowed
- Never free-explore REPOS/ -- only look at paths mentioned in BRIEF.md
