# Host Requirements

This skill leans hard on host-runtime capabilities. Without them, the workflow degrades or becomes inapplicable.

## Required

- **Worker-spawn with isolation.** The host must be able to spawn worker agents in isolated git worktrees. Each fix runs in its own worktree branched from the orchestrator's HEAD.
- **Shell access.** Required for git operations (`git worktree add`, `git merge`, `git status`, etc.) and for running the project's test suite.
- **File tools.** Read, Write, Edit, Glob, and Grep equivalents are needed for scanning and queue management.

## Strongly recommended

- **Parallel worker dispatch.** Without it, the skill still works but loses the parallelism that motivates it. Apply chains sequentially in that case.
- **Subagent for scanning.** Phase 1 spawns three subagents for the multi-angle scan. Without them, the orchestrator can run the three angles sequentially in a single thread.

## Inapplicable hosts

- Hosts without worker-spawn cannot run this skill meaningfully. Suggest the user run the fixes manually or a one-shot `/edit` workflow instead.
- Hosts without git or with read-only filesystems cannot run this skill at all.

## Authority boundary

The host owns:

- whether to spawn workers,
- which model each worker uses,
- which tools each worker is permitted,
- whether worktrees and merges happen at all.

This skill describes the workflow shape; the host enforces what is actually allowed.
