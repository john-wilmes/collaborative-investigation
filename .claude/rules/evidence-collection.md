---
globs: PROJECTS/*/EVIDENCE/*.md
---

# Evidence Collection Rules

When creating or editing evidence files:

1. Use the template from schemas/evidence.template.md exactly
2. Number evidence files sequentially: 001-<slug>.md, 002-<slug>.md, etc.
3. The slug should be 2-3 lowercase words separated by hyphens describing the evidence
4. Observation section is 3 lines MAX -- be precise, not narrative
5. Relevance must state whether evidence supports, contradicts, or is neutral to the current hypothesis
6. Tags must come from schemas/tags.allowed
7. Never include raw patient PHI -- use placeholders if referencing patient data
8. Source must be specific: include exact query, URL, file:line, or dashboard name
9. One evidence file per data point -- do not combine multiple observations
