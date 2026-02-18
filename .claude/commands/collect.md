---
allowed-tools: Bash, Read, Write, Glob, Grep, Task
description: Collect one piece of evidence for the active investigation
user-invocable: true
---

# /collect $ARGUMENTS

Collect one piece of structured evidence. The argument is the data source or a description of what was found.

## Steps

1. Find the active investigation: look for PROJECTS/*/STATUS.md where .tags contains "status:investigating"
2. Read the project's BRIEF.md and STATUS.md to understand context and current hypothesis
3. Determine the next evidence number by counting existing files in EVIDENCE/
4. Read schemas/evidence.template.md for the template
5. If $ARGUMENTS names a data source (e.g., "datadog", "mongodb"):
   - Read schemas/toolkit.md for the source's capabilities
   - Based on STATUS.md's open questions, suggest a specific query or action for the human to run
   - Wait for the human to provide the results
6. If $ARGUMENTS contains pasted data or observations:
   - Parse the provided data into the evidence template format
   - Write the evidence file to EVIDENCE/NNN-<slug>.md
7. After writing evidence:
   - Update STATUS.md: add a history entry, update open questions if the evidence changes them
   - If the evidence significantly changes the picture, note it in STATUS.md's hypothesis section
8. Tell the human what was recorded and suggest the next data point to collect

## Rules
- One evidence file per invocation
- Observation is 3 lines max
- Tags must come from schemas/tags.allowed
- Never free-explore REPOS/ -- only look at paths mentioned in BRIEF.md
