## 2. Agent Anatomy

A Claude Code agent is a runtime: a model, tool set, and system prompt that can be invoked as a subagent. It is typically narrow (one job, one output shape) and is intended to be called by another agent rather than by the end user.

Two independent axes describe any agent definition:

- **Platform** — which runtime the definition targets. Everything in this chapter is Claude Code.
- **Invocation role** — how the definition is launched at runtime. The same `.md` file can run as either:
    - a *subagent*, spawned by a parent Claude Code session via the `Agent` tool (isolated context, returns a summary to the parent); or
    - a *specialized main session*, started directly by the user with `claude --agent <name>` (becomes the top-level session, owns the user conversation; often used for heavy bespoke work that starts in this mode rather than being delegated).

These two axes are orthogonal: "Claude Code-specific" and "subagent" describe different things and do not exclude each other. A file authored for Claude Code can still be a subagent — operationally — whenever a parent Claude Code session delegates to it.

This chapter assumes the subagent role unless stated otherwise. Body-level adjustments for the specialized-main-session role (host-facing identity statement, conversation etiquette, `CLAUDE.md` / memory handling) are out of scope here.

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

### Frontmatter

Use the official Claude Code subagent frontmatter. `name` and `description` are required; everything else is optional.

```yaml
---
name: research-orchestrator
description: Coordinates parallel research workers and merges their outputs. Use when the question requires decomposition into independent tracks.
model: opus
maxTurns: 40
tools: Agent(research-worker, research-verifier), Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch
color: cyan
---
```

Field reference for the keys most agents use:

| Key | Purpose |
|---|---|
| `name` | Unique identifier (lowercase, hyphenated). Required. |
| `description` | When the host should delegate to this agent. Required; phrase it as a routing hint. |
| `model` | `sonnet`, `opus`, `haiku`, a full model id, or `inherit`. |
| `maxTurns` | Hard cap on agentic turns. |
| `tools` | Allowlist. Use `Agent(child-a, child-b)` inside this list to restrict which subagents can be spawned. Omit `tools` to inherit the caller's full tool set. |
| `disallowedTools` | Denylist. Subtracts from the inherited or specified tool set (e.g., `disallowedTools: Agent` forbids further delegation). |
| `color` | Display color in the UI. |

Other supported fields, when an agent genuinely needs that knob: `permissionMode`, `mcpServers`, `hooks`, `memory`, `background`, `effort`, `isolation`, `initialPrompt`, `skills`.

### Restricting subagent spawn topology

There is no separate `spawns-agents` field. To say "this orchestrator may only spawn `research-worker` and `research-verifier`," put it in the tool allowlist:

```yaml
tools: Agent(research-worker, research-verifier), Read, Write, Bash
```

Workers that must never delegate further use the denylist:

```yaml
disallowedTools: Agent
```

### What does NOT go in an agent

- Scripts, references, fixtures, or templates — agents output text or structured JSON, not template-filled artifacts.
- Configuration that varies per invocation — the caller supplies that at spawn time.
- Per-platform variants of the same prompt — one agent file per agent.
