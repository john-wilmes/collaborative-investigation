# Collaborative Investigation Framework

## Project Overview

Git-based framework for SaaS technical teams to run structured investigations of customer-reported issues, assisted by lightweight AI agents (Sonnet, Composer 1.5). The SaaS is an adjunct to many EHRs. Zero runtime dependencies beyond Presidio for PHI sanitization.

## Core Principle

State in files, not in conversations. Agents are stateless workers. They read structured files, do one thing, write structured output, and exit. No long conversations, no multi-phase sessions.

## Key Commands

```
scripts/new-project.sh <ticket-id>    # Create investigation from template
git commit                             # Auto-sanitizes PHI via pre-commit hook
```

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/investigate <ticket>` | Start new investigation, create project from template |
| `/collect <ticket> <source>` | Structured evidence gathering (one item per invocation) |
| `/synthesize <ticket>` | Condense evidence into findings, update hypothesis |
| `/close <ticket>` | Classify, sanitize, push branch |

## Token Discipline

- CLAUDE.md must stay under 50 lines of rules
- `.claude/rules/` files use glob patterns to load only when relevant
- BRIEF.md is 10 lines max (human distills the ticket)
- STATUS.md is the investigation log and handoff mechanism
- Evidence files use templates with 3-line observation max
- One slash command = one phase = one session
- Agents never free-explore REPOS/ -- BRIEF.md scopes them to specific paths

## Classification

At `/close` time, a Haiku classifier agent reads all project files and writes a natural language classification into the Classification section of FINDINGS.md. No fixed taxonomy -- the classifier describes root cause category, affected systems, failure pattern, severity, and contributing factors in plain English. Investigator approves or overrides. Prior art search across investigations is done by agents reading FINDINGS.md, not by filtering tags.

## PHI Sanitization

Auto-sanitize on commit, never reject. Pre-commit hook runs Presidio, replaces patient PHI with typed placeholders (`[PATIENT_NAME]`, `[DATE]`, `[DOB]`, `[SSN]`), re-stages, commit proceeds. `[DOB]` only fires near birth-related keywords; general dates become `[DATE]`. Customer/org info is kept -- only patient data is scrubbed. MRNs scrubbed only when labeled in context (e.g., "MRN: 12345"), not bare IDs. Pre-commit also rejects STATUS.md and EVIDENCE/ files from staging.

## What Gets Pushed

`inv/<ticket-id>` branches containing BRIEF.md and FINDINGS.md. EVIDENCE/ stays local (gitignored).

## Commit Rules

- Work on `inv/<ticket-id>` branches for investigations
- Never commit to main directly except for framework changes
