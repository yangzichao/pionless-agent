## 5. Agent-Orchestrates-Agent

This chapter is finalized and should not be revised unless Claude Code's underlying runtime model for agents and subagents changes (per chapter 02), or the skill/agent boundary established in chapter 01 changes.

**Decision: all agents are siblings under `src/agents/`.** No nesting, no separate pools.

The orchestrator/worker distinction is a *relationship*, not a *type* — both ends are the same kind of file (an agent definition), and the relationship is established at runtime by the orchestrator's `Agent(...)` allowlist, not by where files live. Encoding that relationship in folder structure (e.g. `agents/orchestrator/workers/worker.md`, or split pools `agents/orchestrators/` vs `agents/workers/`) bakes a transient role into a permanent layout and forces duplication the moment a second orchestrator wants to reuse a worker.

Orchestration topology is therefore expressed in the orchestrator's frontmatter, not in folder structure.

### Naming convention

Two shapes of subagent exist in this layout, distinguished by intent at creation time and by filename pattern.

**Bonded subagent.** Created for one specific *originating context* — its prompt assumes that context's task shape, input format, or output contract. The originating context is either an **orchestrator agent** in `src/agents/` or an **orchestrating skill** in `src/skills/` (skill case detailed in *Orchestration via skills* below). Filename takes the form `<originating-context>-worker` or `<originating-context>-verifier`.

**Utility subagent.** Created as a self-contained capability — its prompt does not depend on which orchestrator invokes it. Filename is the capability itself (e.g. `code-reviewer`, `web-fetcher`, `claim-checker`); it does not carry the `-worker` or `-verifier` suffix.

| Role | Naming pattern | Example |
|---|---|---|
| Orchestrator agent | `<domain>` | `deep-research` |
| Bonded worker (agent-driven) | `<originating-agent>-worker` | `deep-research-worker` |
| Bonded verifier (agent-driven) | `<originating-agent>-verifier` | `deep-research-verifier` |
| Bonded worker (skill-driven) | `<originating-skill>-worker` | `parallel-fix-worker` |
| Utility subagent | `<capability>` | `code-reviewer` |

**The prefix declares provenance, not exclusivity.** `deep-research-worker` reads as "originally built for the `deep-research` flow", not "only `deep-research` may invoke it." A second orchestrator may legitimately reuse it; if the prompt no longer fits, fork rather than rename or hoist. The same signal works the other way for maintainers: changes to `deep-research-worker` should honor the originating context's contract first; other callers reuse at their own cost.

Two further rules round out the convention:

- Reject generic names like `worker.md` or `verifier.md` with no prefix at all. The `-worker` / `-verifier` suffixes are reserved for the bonded shape and require a `<originating-context>-` prefix that points to a real orchestrator agent or orchestrating skill.
- Do not append `-orchestrator` to the orchestrator filename. The domain name is already its identity; the children's `-worker` / `-verifier` suffixes are what mark the relationship.

### Orchestrators are main-session-only

An orchestrator definition — any agent whose `tools` allowlist contains `Agent(...)` — is launched directly as a specialized main session via `claude --agent <name>`. It must never appear inside another agent's `Agent(...)` allowlist.

The reason is structural: per chapter 02, Claude Code subagents are leaf nodes that cannot spawn further subagents. If an orchestrator were invoked via the `Agent` tool, the spawning capability it depends on would be unavailable in that role — its `Agent(...)` allowlist would silently degrade to a no-op. Orchestration therefore happens only when an agent definition is entered as the top of a session, never as someone else's subagent.

The two postures that together make every agent's role unambiguous:

- An orchestrator declares its allowed children via `tools: Agent(...)` and never appears inside another `Agent(...)` allowlist.
- A leaf declares `disallowedTools: Agent` (see *Leaf hardening* below).

### Topology in frontmatter

When the orchestrator is a dedicated agent file, its frontmatter is the single source of truth for the spawn graph; the file is interpreted in its main-session role. (The skill-driven variant — where the playbook lives in a skill and the host enforces the allowlist — is covered separately below.)

```yaml
---
name: deep-research
description: Use when a research task needs parallel decomposition into focused subquestions and synthesis of worker outputs into a unified report.
model: opus
tools: Agent(deep-research-worker, deep-research-verifier), Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch
---
```

Read this as: when launched as a main session, this agent may spawn `deep-research-worker` or `deep-research-verifier` as subagents, and no other agent types. There is no separate `spawns-agents` field — the same `tools` field that gates ordinary tool access also gates subagent spawning, via the `Agent(...)` constructor. The `description` is phrased as a routing hint per chapter 02, so a host deciding whether to launch this orchestrator can match on the "Use when …" form. The worker and verifier filenames follow the naming convention above (`<originating-context>-worker`, `<originating-context>-verifier`, where the originating context here is an orchestrator agent), so the spawn graph is legible without opening any file.

### Leaf hardening

The leaf side of the topology is encoded with a denylist:

```yaml
disallowedTools: Agent
```

Any leaf definition should declare this so that, even if the file is ever launched as a main session itself, it still cannot spawn anything. The field is what the validation rules below check for.

### Orchestration via skills

The orchestrator can also be a skill loaded into the host's main agent rather than a dedicated agent file. The host plays the orchestrator role at runtime; the skill provides the playbook — which subagents to spawn, in what order, with what task cards. This case is still "agent-orchestrates-agent" — the host *is* an agent — but the entry point is the skill, not a `<domain>.md` file.

Per chapter 01, the skill carries no runtime authority: no `tools`, no `Agent(...)`, no `model`, no `disallowedTools`. Spawn permissions live on the host agent's frontmatter. The skill body must phrase its workflow as guidance ("the host should spawn ...", "if delegation is available ..."), and may flag the dependency with the optional `pionless.suggests-delegation` metadata defined in chapter 01 (its value is a short string naming the delegation pattern, e.g. `"source-collection verification synthesis"`).

All other rules in this chapter apply unchanged. The only generalization is that a bonded prefix may name a skill instead of an agent — already covered by the naming table and validation rule (4) below.

### Validation invariants

A build step over `src/agents/` should:

1. Verify every agent named inside `Agent(...)` exists.
2. Warn when an agent listed in some orchestrator's `Agent(...)` allowlist does not declare `disallowedTools: Agent` — that leaf could in principle be invoked as a main session itself and create unbounded spawn topologies.
3. **Refuse if an orchestrator (any agent whose `tools` contains `Agent(...)`) is referenced inside another agent's `Agent(...)` allowlist.** Orchestrators are main-session-only; appearing as a subagent silently disables their spawn capability.
4. **Refuse if a filename of the form `<X>-worker` or `<X>-verifier` exists where `<X>` is neither an orchestrator agent in `src/agents/` nor a skill in `src/skills/`.** This is a *provenance* check, not an *exclusivity* check: a bonded subagent may legitimately appear in multiple `Agent(...)` allowlists, but its filename must always trace back to the originating context it was first built for.
5. **Refuse if a filename ends in `-worker` or `-verifier` without any prefix** (i.e. a bare `worker.md` or `verifier.md`, or names where the `<X>` segment is empty). Bonded subagents must declare provenance.
6. **Defense-in-depth cycle detection.** Walk the directed graph induced by `Agent(...)` allowlists and refuse any cycle. Under rule (3) this graph cannot contain another orchestrator at all, so it is acyclic by construction; this rule exists as a guard in case rule (3) is ever relaxed or bypassed.
