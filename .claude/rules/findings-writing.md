---
globs: PROJECTS/*/FINDINGS.md
---

# Findings Writing Rules

When writing or updating FINDINGS.md:

1. Use structured blocks from schemas/findings.template.md, not narrative prose
2. Question should be a clear, specific statement of what the investigation set out to answer
3. Answer should be structured prose -- as detailed as the findings warrant
4. Evidence Summary must reference specific evidence file numbers (e.g., "Evidence 003")
5. Only include evidence that directly supports the answer
6. Implications should be actionable -- a fix, a design change, a decision, or "no action needed"
7. Patient PHI will be auto-sanitized on commit -- but avoid including it when possible
8. Customer/org names should be kept -- they are essential investigation context
9. This file gets pushed to GitHub on inv/* branches -- write for your teammates
10. Do NOT write the Classification section -- it is written by the classifier agent at /close time
