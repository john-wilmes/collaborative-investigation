# Collaborative Investigation Framework

## Project Overview

Git-based framework for SaaS technical teams to run structured investigations assisted by lightweight AI agents (Sonnet, Haiku). Investigations can be anything: incident root-cause analysis, understanding how a system works, mapping an integration, or answering a technical question. The SaaS is an adjunct to many EHRs. Zero runtime dependencies beyond Presidio for PHI sanitization.

## Core Principle

State in files, not in conversations. Agents are stateless workers. They read structured files, do one thing, write structured output, and exit. No long conversations, no multi-phase sessions.

## Commands

| Command | Purpose |
|---------|---------|
| `scripts/new-project.sh <ticket>` | Create investigation from template |
| `/investigate <ticket>` | Start new investigation (runs new-project.sh) |
| `/collect <ticket> <source>` | Structured evidence gathering (one item per invocation) |
| `/synthesize <ticket>` | Condense evidence into findings |
| `/close <ticket>` | Classify, sanitize, push branch |
| `/reopen <ticket>` | Resume a closed investigation |

## Token Discipline

- CLAUDE.md must stay under 50 lines of rules
- `.claude/rules/` files use glob patterns to load only when relevant
- BRIEF.md is 10 lines max (human distills the question)
- STATUS.md is the investigation log and handoff mechanism
- Evidence files use templates with 3-line observation max
- One slash command = one phase = one session
- Agents never free-explore REPOS/ -- BRIEF.md scopes them to specific paths

## Classification

At `/close` time, a Haiku classifier reads all project files and writes a natural language classification into FINDINGS.md. No fixed taxonomy -- the classifier describes what kind of investigation it was, what was learned, which systems were involved, the significance, and open threads. Investigator approves or overrides. Prior art search is done by agents reading FINDINGS.md across branches.

## PHI Sanitization

Auto-sanitize on commit, never reject. Pre-commit hook runs Presidio on BRIEF.md, FINDINGS.md, and STATUS.md. Replaces patient PHI with typed placeholders (`[PATIENT_NAME]`, `[DATE]`, `[DOB]`, `[SSN]`), re-stages, commit proceeds. Customer/org info is kept -- only patient data is scrubbed. Pre-commit rejects EVIDENCE/ files from staging.

## What Gets Pushed

`inv/<ticket-id>` branches containing BRIEF.md, FINDINGS.md, and STATUS.md. EVIDENCE/ stays local (gitignored). Closed investigations can be reopened with `/reopen`.

## Commit Rules

- Work on `inv/<ticket-id>` branches for investigations
- Never commit to main directly except for framework changes
