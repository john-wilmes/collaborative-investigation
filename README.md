# Collaborative Investigation Framework

Git-based framework for SaaS technical teams to run structured investigations assisted by lightweight AI agents (Sonnet, Haiku). Investigations can be anything: incident root-cause analysis, understanding how a system works, mapping an integration, or answering a technical question.

## How It Works

State lives in files, not in conversations. Agents are stateless workers that read structured files, do one thing, write structured output, and exit. Each investigation gets a branch (`inv/<ticket-id>`) with three pushed artifacts:

- **BRIEF.md** -- Human-written, 10 lines max. Context, question, scope, starting point.
- **FINDINGS.md** -- Agent-synthesized answer with evidence references, implications, and a natural language classification.
- **STATUS.md** -- Investigation log and handoff mechanism.

Evidence files stay local (gitignored). Only sanitized summaries get pushed.

## Commands

| Command | Purpose |
|---------|---------|
| `/investigate <ticket>` | Start a new investigation |
| `/collect <ticket> <source>` | Gather one piece of evidence |
| `/synthesize <ticket>` | Condense evidence into findings |
| `/close <ticket>` | Classify, sanitize, push branch |
| `/reopen <ticket>` | Resume a closed investigation |

One command = one phase = one session. Token discipline is enforced through templates with strict length limits.

## PHI Sanitization

Pre-commit hook auto-sanitizes BRIEF.md, FINDINGS.md, and STATUS.md using Presidio. Patient PHI is replaced with typed placeholders (`[PATIENT_NAME]`, `[DATE]`, etc.). Customer and organization names are kept. EVIDENCE/ files are blocked from staging entirely.

## Inter-Agent Communication

This project uses a custom MCP server (`agent-comm`) for communication between independent Claude Code sessions. This section compares that approach with Claude Code's built-in [Agent Teams](https://code.claude.com/docs/en/agent-teams) feature.

### Two Different Problems

Agent Teams solves "how do I parallelize work on a single task" -- running 3 code reviewers on one PR, or 5 hypothesis-testers on one bug. It is a task decomposition and parallel execution framework within a single session.

agent-comm solves "how do independent agents working on different things stay aware of each other" -- reporting investigation findings to the team that owns the code, or coordinating across projects that happen to run on the same machine. It is closer to a shared message board than a task runner.

### Architecture

| Dimension | Agent Teams (built-in) | agent-comm (this project) |
|---|---|---|
| Topology | Hub-and-spoke: one lead, N teammates | Peer-to-peer: any session registers and talks to any other |
| Lifecycle | Lead creates team, spawns teammates, cleans up | Sessions self-register on start, deregister on end via hooks |
| Scope | Single task within one session | Cross-project, cross-session, persists across restarts |
| State storage | Separate dirs per team under `~/.claude/teams/` and `~/.claude/tasks/` | Single `~/.claude/agent-comm/state.json` |
| Concurrency control | File locking for task claims | Atomic write-then-rename |

### Communication

| Dimension | Agent Teams | agent-comm |
|---|---|---|
| Message delivery | Automatic -- injected as new conversation turns | Store-and-forward -- read on session start or by polling state.json |
| Direct messages | Built-in `SendMessage` tool | `send_message` MCP tool with `to` field |
| Broadcast | Sends N separate messages (one per teammate) | Single write with `to: null`, all readers see it |
| Protocols | Shutdown request/response, plan approval | None built in |

### Task Coordination

| Dimension | Agent Teams | agent-comm |
|---|---|---|
| Task model | Dependencies (blocks/blockedBy), owner assignment, file-locked claiming | Basic CRUD with assignedTo, no dependency graph, no locking |
| Quality gates | Hooks (`TeammateIdle`, `TaskCompleted`) can reject completion | None |
| Display | In-process cycling or tmux/iTerm2 split panes | Each session independent |

### What Agent Teams Has That agent-comm Does Not

- **Real-time message delivery.** Messages inject into the recipient's conversation as new turns. agent-comm messages are only seen when a session starts or explicitly reads state.json.
- **Display modes.** In-process teammate cycling (Shift+Down) and split-pane views for watching all agents at once.
- **Structured protocols.** Shutdown request/approve/reject. Plan approval with lead review.
- **Task dependencies.** `blocks`/`blockedBy` with automatic unblocking on completion.
- **Permission inheritance.** Teammates automatically get the lead's permissions and project context.

### What agent-comm Has That Agent Teams Does Not

- **Cross-session persistence.** A message sent today is readable by an agent that starts tomorrow. Agent Teams die when the lead session ends, and `/resume` does not restore teammates.
- **Cross-project communication.** Separate projects in separate directories can exchange messages. Agent Teams only coordinates within one project and one session.
- **No hierarchy.** Any agent can talk to any other without a lead. The topology is whatever emerges from who is running.
- **Cheaper broadcast.** One write to state.json versus N separate message deliveries.

### They Are Complementary

You can use Agent Teams within a session to parallelize an investigation's evidence collection, then use agent-comm to report findings to the owning team afterward. In this project's validation testing, the MMA-2847 investigation findings were sent via agent-comm to the `multi-model-analyzer` agent in a separate session, which read the report, fixed 3 of 4 bugs, disputed one finding as a false positive (correctly), and reported back -- all without ever being in the same session or team.
