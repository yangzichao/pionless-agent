## 2. Agent Anatomy

This chapter is finalized and should not be revised unless the underlying definition of a Claude Code agent changes.

A Claude Code agent definition describes a model, tool set, and system prompt that can run either as a delegated subagent or as a specialized main session.

Two independent axes describe any agent definition:

- **Platform** — which runtime the definition targets. Everything in this chapter is Claude Code.
- **Invocation role** — how the definition is launched at runtime. The same `.md` file can run as either:
    - a *subagent*, spawned by a parent Claude Code session via the `Agent` tool (isolated context, returns a summary to the parent); or
    - a *specialized main session*, started directly by the user with `claude --agent <name>` (becomes the top-level session, owns the user conversation; often used for heavy bespoke work that starts in this mode rather than being delegated).

These two axes are orthogonal: "Claude Code-specific" and "subagent" describe different things and do not exclude each other. A file authored for Claude Code can still be a subagent — operationally — whenever a parent Claude Code session delegates to it.

This chapter focuses on the subagent role: the definition is invoked by a parent Claude Code session via the `Agent` tool, runs in an isolated context, returns only a summary to its parent, and is typically narrow (one job, one output shape). Body-level adjustments for the specialized-main-session role (host-facing identity statement, conversation etiquette, `CLAUDE.md` / memory handling) are out of scope here.

### Always a single markdown file

A Claude Code subagent is a single `.md` file with frontmatter and a prompt body. There is no folder form. The agent file contains only the prompt and configuration.

### Canonical tree

```
agents/
  research-orchestrator.md
  research-worker.md
  research-verifier.md
  code-reviewer.md
```

The filename should match the `name` field.

### First-class, second-class, and Claude-Code-specific surfaces

Treating the agent as a runtime means recognizing it as the composition of several configurable surfaces. They are not all equal in weight.

**First-class surfaces** are the agent's core. Every agent has these — even when a field is omitted, the surface is still present (omitting `model` inherits the caller's; omitting `tools` inherits the caller's tool set). They define **what the agent is** and **what it can do**.

| Surface | Frontmatter fields | What it controls |
|---|---|---|
| Identity & behavior | body; `name`, `description` | Who the agent is, how it works, when the host should invoke it |
| Tool surface | `tools`, `disallowedTools` | Which actions the agent can take |
| Compute substrate | `model` | The model the agent runs on |

These exist on every comparable platform under different names. Removing any of them removes something fundamental.

**Second-class surfaces** are cross-platform capability extensions. They exist on most agent platforms, are **optional**, and a given agent may engage some, all, or none. When present they materially expand what the agent can do — when absent the agent is still complete.

| Surface | Frontmatter fields | What it controls |
|---|---|---|
| Knowledge surface | `skills` | Workflow knowledge packs injected at startup |
| External tool surface | `mcpServers` | MCP servers connected for the agent's lifetime |
| State surface | `memory` | Persistent storage across conversations |

A subagent that behaves like a pure function leaves all three unset; one that needs persistent context, external tools, and pre-loaded workflows may engage all three. Either is a complete subagent.

Delegation — which subagents an agent may spawn — is **not** a surface of the subagent role. Per Claude Code's model, subagents are leaf nodes: they are spawned by a parent and return a summary, but do not themselves spawn further subagents. Spawning topology is a property of the *specialized main session* role (`claude --agent <name>`) and is covered in [chapter 05 — Agent-Orchestrates-Agent](05-agent-orchestrates-agent.md).

**Claude-Code-specific surfaces** are unique to this runtime. Treat them as opt-in extras, not load-bearing parts of the agent's design — definitions that lean on these will not port to other platforms.

| Surface | Frontmatter fields | What it controls |
|---|---|---|
| Lifecycle hooks | `hooks` | PreToolUse / lifecycle event validators that can block, transform, or audit tool calls |

**Tuning knobs.** Everything else in frontmatter is operational tuning with sensible defaults: `maxTurns`, `effort`, `permissionMode`, `background`, `isolation`, `initialPrompt`, `color`. They adjust **how** the agent runs but do not change **what** it is or **what** it can do. Omitting any of them does not break the agent definition; most agents leave them unset.

### Frontmatter

Frontmatter configures the surfaces above plus a handful of tuning knobs. Only `name` and `description` are required; everything else is optional. Example:

```yaml
---
name: research-worker
description: Worker for a narrow research subquestion. Use when an orchestrator needs evidence gathered for one focused query.
model: sonnet
maxTurns: 18
disallowedTools: Agent
skills:
  - quick-research
---
```

Field-level notes for the most-used keys:

- **`name`** — unique identifier, lowercase-hyphenated; the filename must match.
- **`description`** — phrase as a routing hint ("Use when …") so a host can decide whether to delegate.
- **`model`** — `sonnet`, `opus`, `haiku`, a full model id, or `inherit`.
- **`tools`** — allowlist. Omit to inherit the caller's full tool set.
- **`disallowedTools`** — denylist subtracted from the inherited or specified tool set. Leaf workers commonly set `disallowedTools: Agent` as a hardening measure to ensure they never spawn subagents.

### What does NOT go in an agent

- Scripts, references, fixtures, or templates — agents output text or structured JSON, not template-filled artifacts.
- Configuration that varies per invocation — the caller supplies that at spawn time.
- Per-platform variants of the same prompt — one agent file per agent.
