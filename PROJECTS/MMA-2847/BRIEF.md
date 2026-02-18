# Brief: MMA-2847

## Context

Internal tooling team reports that `mma index` produces fault trees with findings on macOS developer machines but zero findings on the Windows CI runner. The same monorepo (healthcare-platform, ~120 packages) is indexed in both environments. Mac developers see 34 fault tree roots; the Windows CI SARIF report shows 0. Log extraction works correctly on both platforms (verified by checking the log index output). The issue appeared after the team migrated CI from GitHub Actions (Ubuntu) to Azure DevOps (Windows Server 2022).

## Question

1. Why does the fault model produce 0 findings on Windows when the same repo produces 34 on macOS?
2. Is any data silently lost or corrupted during indexing on Windows?

## Scope

Focus on the fault model pipeline: log extraction (packages/heuristics), CFG construction (packages/structural), backward trace (packages/models/fault), and the CLI orchestration in index-cmd.ts. The feature model and functional model are not affected.

## Starting Point

- `apps/cli/src/commands/index-cmd.ts` -- orchestration, phase 6 (fault model)
- `packages/models/fault/src/backward-trace.ts` -- backward tracing from log roots
- `packages/structural/src/cfg.ts` -- control flow graph construction
- `packages/heuristics/src/logs.ts` -- log statement extraction
