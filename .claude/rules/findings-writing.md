---
globs: PROJECTS/*/FINDINGS.md
---

# Findings Writing Rules

When writing or updating FINDINGS.md:

1. Use structured blocks from schemas/findings.template.md, not narrative prose
2. Root Cause must be 2-3 sentences: what went wrong and why
3. Evidence Summary must reference specific evidence file numbers (e.g., "Evidence 003")
4. Only include evidence that directly supports the root cause conclusion
5. Resolution section must contain actionable steps, not vague recommendations
6. Prevention section should propose systemic changes, not one-off fixes
7. Patient PHI will be auto-sanitized on commit -- but avoid including it when possible
8. Customer/org names should be kept -- they are essential investigation context
9. This file gets pushed to GitHub on inv/* branches -- write for your teammates
10. Do NOT write the Classification section -- it is written by the classifier agent at /close time
