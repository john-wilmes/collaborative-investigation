# Status: MMA-2847

## Current Understanding
<!-- Updated after each session -->

Root cause confirmed. The fault model produces 0 findings on Windows because `localPath` from `mma.config.json` (`D:\azdo\agent\_work\3\s\healthcare-platform`) leaks into log FQNs during the template-deduplication step in `extractLogStatements`. This produces absolute Windows-style FQNs (e.g., `D:\azdo\...\service.ts:42`). The tree map keys remain POSIX-relative (from git output). At `backward-trace.ts` line 44, `fqn.split(":")[0]` extracts `"D"` (the drive letter) instead of the file path, so the CFG `startsWith` check matches nothing and every trace returns empty. This affects all 34 log roots uniformly, confirmed by the CI log (0/34 traces, Evidence 008, 009, 010).

Fix: replace `fqn.split(":")[0]` with `fqn.slice(0, fqn.lastIndexOf(":"))` at `backward-trace.ts` line 44. Secondary fix: strip `localPath` prefix before storing `loc.module` in `logs.ts`. Diagnostic: add a warning log at the `if (!tree) continue` branch in `index-cmd.ts` phase 7b.

## Open Questions

None. Root cause confirmed by Evidence 008, 009, and 010.

## Next Action

Run /close to finalize.

## History
| Date | Phase | Summary |
|------|-------|---------|
| 2026-02-18 | init | Project created from template |
| 2026-02-18 | collect | Code review of backward-trace.ts, index-cmd.ts, logs.ts, cfg.ts, log-roots.ts, parser.ts, git.ts. Found `split(":")[0]` bug in backward-trace.ts line 44 (Windows absolute path breaks CFG lookup). Confirmed log extraction and CFG key construction use same path origin. Silent `trees.get()` miss is the failure mode. 7 evidence files created. |
| 2026-02-18 | synthesize | Root cause confirmed by CI log (Evidence 008), CI config+debug log (Evidence 009), and FQN comparison (Evidence 010). localPath leaks into FQNs; split(":")[0] extracts drive letter "D" instead of file path; all 34 traces return empty. FINDINGS.md written. Three-part fix identified: line 44 patch, localPath strip in logs.ts, diagnostic log in index-cmd.ts. |
| 2026-02-18 | close | Investigation closed. Haiku classifier wrote Classification section. FINDINGS.md, BRIEF.md, STATUS.md committed and pushed to inv/MMA-2847. |
