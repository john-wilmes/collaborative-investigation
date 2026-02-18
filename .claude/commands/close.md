---
allowed-tools: Bash, Read, Write, Glob, Grep
description: Finalize investigation and push to GitHub
user-invocable: true
---

# /close

Finalize the investigation, ensure PHI is sanitized, and push the branch.

## Steps

1. Find the active investigation: look for PROJECTS/*/STATUS.md
2. Read BRIEF.md, FINDINGS.md, STATUS.md, and .tags
3. Validate completeness:
   - FINDINGS.md must have Root Cause, Evidence Summary, and Resolution filled in
   - .tags must include at least one root-cause, area, and severity tag
   - If incomplete, tell the human what is missing and stop
4. Update .tags: set status to "status:resolved"
5. Update STATUS.md: add final history entry with resolution summary
6. Stage the files that get pushed: BRIEF.md, FINDINGS.md, .tags
   - Do NOT stage EVIDENCE/ (it is gitignored)
   - Do NOT stage STATUS.md (local working notes)
7. Commit with message: "investigation: <ticket-id> - <one-line root cause summary>"
   - The pre-commit hook will run PHI sanitization automatically
8. Push the inv/<ticket-id> branch to origin
9. Report the branch name and suggest creating a PR if the team uses that workflow

## Rules
- Never push without the pre-commit hook running (no --no-verify)
- The commit must include BRIEF.md, FINDINGS.md, and .tags only
- STATUS.md and EVIDENCE/ stay local
