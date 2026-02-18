---
allowed-tools: Bash, Read, Write, Glob, Grep, Task
description: Synthesize collected evidence into findings
user-invocable: true
---

# /synthesize

Condense all collected evidence into FINDINGS.md and update the investigation status.

## Steps

1. Find the active investigation: look for PROJECTS/*/STATUS.md where .tags contains "status:investigating" or "status:root-cause-identified"
2. Read the project's BRIEF.md, STATUS.md, and all evidence files in EVIDENCE/
3. Read schemas/findings.template.md for the output format
4. Analyze the evidence:
   - Identify which evidence items support/contradict the current hypothesis
   - Look for patterns across evidence items
   - Determine if the root cause is clear or if more evidence is needed
5. If root cause is identified:
   - Write FINDINGS.md using the template
   - Update .tags: change status to "status:root-cause-identified" and add appropriate root-cause and area tags
   - Update STATUS.md: record synthesis in history, clear open questions that are answered
6. If root cause is NOT clear:
   - Write a partial FINDINGS.md noting what is known so far
   - Update STATUS.md: refine hypothesis, list specific open questions, suggest next data to collect
   - Tell the human what gaps remain and what evidence would help
7. If code paths are mentioned in BRIEF.md, read relevant files in REPOS/ to correlate evidence to code

## Rules
- FINDINGS.md uses structured blocks, not narrative
- Reference evidence by number (e.g., "Evidence 003 shows...")
- Keep customer/org names, sanitize patient PHI
- This is analysis, not data collection -- do not ask the human for new data here
