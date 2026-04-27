# Delegation Patterns

Read this only if a **parent orchestrator** is composing multiple instances of `quick-research`. This skill itself does not spawn subagents.

## Parent-side patterns

These are shapes a parent orchestrator can adopt. The parent — not this skill — owns the spawn topology, model choice, and tool permissions.

### Parallel sub-questions

If the parent's research question decomposes cleanly into N independent sub-questions, the parent may spawn N workers, each running `quick-research` on one sub-question, then synthesize across worker outputs.

Use when sub-questions share no shared evidence and order does not matter.

### Searcher / verifier split

The parent may run one `quick-research` worker to gather evidence and a second `quick-research` worker to independently verify load-bearing claims against fresh searches.

Use when the question is contentious, recency matters, or a single-source result must be hardened.

## Worker-side responsibilities

Each `quick-research` worker:

- runs in subagent mode,
- returns the structured format from `assets/report-template-subagent.md`,
- does **not** spawn further subagents,
- does **not** write report files unless the task card explicitly requests one.

## Fallback

If the parent does not support spawning workers, it can apply this skill sequentially to each sub-question within a single thread.
