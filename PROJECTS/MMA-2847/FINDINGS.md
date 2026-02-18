# Findings: MMA-2847

## Question

1. Why does the fault model produce 0 findings on Windows when the same repo produces 34 on macOS?
2. Is any data silently lost or corrupted during indexing on Windows?

## Answer

1. The fault model produces 0 findings on Windows because `localPath` from `mma.config.json` is prepended to file paths during log extraction, producing absolute Windows-style FQNs (e.g., `D:\azdo\agent\_work\3\s\healthcare-platform\packages\auth\src\service.ts:42`). The backward trace step then tries to extract the file path from the FQN using `fqn.split(":")[0]` at `packages/models/fault/src/backward-trace.ts` line 44. On Windows, the drive letter colon (`D:`) is the first colon encountered, so `split(":")[0]` returns `"D"` instead of the file path. The subsequent CFG lookup uses `key.startsWith("D#")`, which matches nothing. Every one of the 34 backward traces returns zero steps, so zero fault tree roots are written.

   The complete failure path is:

   - `mma.config.json` on the Azure DevOps runner sets `"localPath": "D:\\azdo\\agent\\_work\\3\\s\\healthcare-platform"` (Evidence 009).
   - `extractLogStatements` in `packages/heuristics/src/logs.ts` (lines 40-41, 96-99) uses `filePath` as both `loc.module` and the FQN file-path segment. When localPath is joined to the relative path for template deduplication, the absolute Windows path leaks into the FQN (Evidence 002, 009).
   - Tree map keys remain POSIX-relative (e.g., `packages/auth/src/service.ts`) because they originate from `git ls-tree` output, which always emits forward-slash relative paths regardless of OS (Evidence 003).
   - Phase 7b in `apps/cli/src/commands/index-cmd.ts` (lines 388-407) builds CFG keys as `${loc.module}#${fnNode.name}` (Evidence 005) and then calls `traceBackwardFromLog`, which applies `split(":")[0]` to the absolute-path FQN and extracts `"D"`.
   - The `startsWith("D#")` check matches no CFG key; the trace returns empty with no error or warning (Evidence 001, 010).
   - This happens for all 34 roots uniformly, confirmed by the CI log showing "0/34 traces produced steps" (Evidence 008).

   A secondary contributor is that `findLogNode` in `backward-trace.ts` lines 104-106 uses `lastIndexOf(":")` (Evidence 006), which would correctly handle Windows absolute paths -- but control never reaches it because the outer `startsWith` check fails first. The inconsistency between the two colon-split strategies within the same file is what allows macOS to work while Windows fails.

2. No data is corrupted during indexing. Log extraction completes correctly: 142 log templates are extracted from 34 files and 34 log roots are identified identically on both platforms (Evidence 008). The tree map is populated correctly with POSIX-relative keys on both platforms (Evidence 003, 009). What is lost is the backward trace output -- 34 trace results that would have been produced are silently discarded when the `trees.get(filePath)` lookup misses and the code executes `continue` with no log output at `index-cmd.ts` line ~399 (Evidence 004). The SARIF output is structurally valid but empty. No index file is written incorrectly; there is simply nothing to write.

## Evidence Summary

1. Evidence 001 -- `backward-trace.ts` line 44 uses `fqn.split(":")[0]` to extract the file path from the FQN. On a Windows absolute path, this returns the drive letter instead of the path, breaking CFG lookup for every trace.
2. Evidence 002 -- FQN file-path segment is set directly from the tree map key in `logs.ts`, meaning the two values should agree -- unless localPath is prepended separately at a different code site.
3. Evidence 003 -- `git ls-tree` and `git diff` always emit POSIX forward-slash relative paths, ruling out git ingestion as the source of absolute paths in tree map keys.
4. Evidence 004 -- `index-cmd.ts` phase 7b silently skips any file whose `loc.module` does not match a tree map key, producing no log output and building no CFG -- making the failure invisible in CI.
5. Evidence 005 -- CFG keys and FQN prefixes are constructed from the same `loc.module` value, so the mismatch is not between CFG key format and FQN format -- it is in the value of `loc.module` itself on Windows.
6. Evidence 006 -- `findLogNode` in the same file uses `lastIndexOf(":")` (correct for Windows absolute paths), inconsistent with `traceBackwardFromLog`'s `split(":")[0]` (incorrect for Windows absolute paths). This inconsistency pins the bug to line 44.
7. Evidence 007 -- `findFunctionNodes` does not cover `function_expression` nodes, limiting CFG coverage. Platform-independent; not a cause of the Windows-specific failure but reduces overall finding yield on both platforms.
8. Evidence 008 -- Azure DevOps CI log confirms 34 log roots identified, 0/34 traces produced steps, and 34 empty traces on Windows. Mac run on the same commit: 34/34 traces succeeded. Failure is in backward tracing only.
9. Evidence 009 -- `mma.config.json` on the CI runner has `"localPath": "D:\\azdo\\agent\\_work\\3\\s\\healthcare-platform"`. Debug log confirms tree map keys are POSIX-relative but log FQNs are absolute Windows paths. Root cause confirmed.
10. Evidence 010 -- Console.log comparison: Mac FQN `packages/auth/src/service.ts:42` yields correct `split(":")[0]` result; Windows FQN `D:\azdo\...\service.ts:42` yields `"D"`. CFG keys on both platforms use relative paths. Directly demonstrates the collision.

## Implications

**Immediate fix -- `backward-trace.ts` line 44.** Replace `fqn.split(":")[0]` with `fqn.slice(0, fqn.lastIndexOf(":"))`. This mirrors the strategy already used correctly in `findLogNode` at line 105 and handles absolute paths on any OS. One-line change, no API surface change, no schema migration.

**Secondary fix -- path normalization at FQN construction.** The localPath should not leak into FQNs. In `logs.ts`, the file path used to build FQNs and `loc.module` should be the POSIX-relative path from the tree map key, not any absolute resolution. Auditing the template-deduplication code path that causes localPath to be joined in (Evidence 009) and stripping the localPath prefix before storing `loc.module` would make the system robust regardless of how paths are used internally. This also ensures the log index is portable (not machine-specific) if it is ever persisted.

**Diagnostic improvement -- `index-cmd.ts` phase 7b.** Add a warning log at the `if (!tree) continue` branch (Evidence 004) reporting the unmatched `loc.module` value. This would have surfaced the bug immediately on the first CI run and would catch similar regressions in the future.

**Scope of impact.** The bug affects any Windows environment where `localPath` is set to an absolute path in `mma.config.json`. The migration from Ubuntu GitHub Actions (where `localPath` was presumably a relative or POSIX path) to Azure DevOps Windows Server 2022 (where it is an absolute Windows path) is what exposed the pre-existing fragility. macOS developer machines are unaffected. The `findFunctionNodes` gap (Evidence 007) is a separate, pre-existing coverage limitation affecting all platforms.

## Classification

This was a root cause analysis investigation that identified a cross-platform path-handling bug in the fault model indexing pipeline. The core finding was that on Windows, absolute paths with drive letters (e.g., `D:\...`) were incorrectly parsed when extracting file paths from FQNs, causing `split(":")` to extract the drive letter instead of the full path, which broke all 34 CFG lookups and produced zero fault tree findings. The fix is a one-line change to use `lastIndexOf(":")` instead of `split(":")[0]` in backward-trace.ts, plus secondary fixes for path normalization to prevent localPath from leaking into FQNs and diagnostic improvements to surface such failures in CI. The scope is specifically Windows environments with absolute paths in mma.config.json, though the underlying fragility in the path-handling logic affects the system on all platforms.
