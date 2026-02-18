---
allowed-tools: Bash, Read, Write, Glob, Grep, Task
description: Start a new investigation from a ticket ID
user-invocable: true
---

# /investigate $ARGUMENTS

Start a new investigation for the given ticket ID.

## Steps

1. Run `scripts/new-project.sh $ARGUMENTS` to create the project scaffold
2. Read `PROJECTS/$ARGUMENTS/BRIEF.md` and confirm it was created
3. Read `schemas/toolkit.md` to understand available data sources
4. Tell the human:
   - The project has been created at `PROJECTS/$ARGUMENTS/`
   - They need to fill in `BRIEF.md` with the ticket details (10 lines max)
   - List the available data sources from toolkit.md
   - Ask what they already know about the issue
5. Do NOT proceed to evidence collection -- that is a separate session with `/collect`

## Exit
After creating the project and briefing the human, stop. The human will fill in BRIEF.md and return later with `/collect`.
