## 6. Agent-Orchestrates-Agent

When an orchestrator agent spawns worker agents, three structural options exist:

| Option | Layout | Verdict |
|---|---|---|
| **Worker as child of orchestrator** | `agents/orchestrator/workers/worker.md` | Reject. Couples the worker to one orchestrator; if a second orchestrator wants to use it, you either duplicate or hoist. |
| **Worker as sibling of orchestrator** | `agents/orchestrator.md`, `agents/worker.md` | Accept. Both are agents; both live in `agents/`. |
| **Workers in a separate pool** | `agents/orchestrators/`, `agents/workers/` | Reject. The orchestrator/worker distinction is a relationship, not a type — an agent can be both depending on context. |

### Recommendation: sibling

All agents live as siblings under `src/agents/`. Orchestration topology is expressed in the orchestrator's frontmatter, not in folder structure.

### Where orchestration lives

Per Claude Code's subagent model, subagents are leaf nodes: they are spawned by a parent, return a summary, and do not themselves spawn further subagents. Orchestration therefore happens when an agent definition is launched as a *specialized main session* via `claude --agent <name>` — in that role the agent owns the user conversation and may spawn subagents to do work.

Topology is captured by the `Agent(...)` allowlist syntax inside the orchestrator's `tools` field:

```yaml
---
name: research-orchestrator
description: Coordinates parallel research workers and merges their outputs into a single report.
model: opus
maxTurns: 40
tools: Agent(research-worker, research-verifier), Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch
---
```

Read this as: when launched as a main session, this agent may spawn `research-worker` or `research-verifier` as subagents, and no other agent types. There is no separate `spawns-agents` field — the same `tools` field that gates ordinary tool access also gates subagent spawning, via the `Agent(...)` constructor.

### Worker hardening

A definition that should always behave as a leaf — never spawn anything regardless of how it is invoked — uses the denylist:

```yaml
disallowedTools: Agent
```

This is the recommended posture for any agent designed exclusively as a worker. It also makes the relationship explicit: the orchestrator's `Agent(...)` allowlist names workers, and each worker's `disallowedTools: Agent` confirms it terminates the spawn chain.

### Validation invariants

A build step over `src/agents/` should:

1. Verify every agent named inside `Agent(...)` exists.
2. Detect cycles (orchestrator A's allowlist names B, B's allowlist names A).
3. Warn when an agent listed in some orchestrator's `Agent(...)` allowlist does not declare `disallowedTools: Agent` — that worker could in principle be invoked as a main session itself and create unbounded spawn topologies.
