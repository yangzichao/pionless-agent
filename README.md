# gluon-agent

`gluon-agent` is a cross-platform research agent package for Claude Code and OpenAI Codex.
This repository now contains:

- shared workflow skills in `shared/`
- Claude plugin subagents in `claude/agents/`
- Codex custom-agent templates in `codex/agents/`
- Claude-specific manifest in `claude/.claude-plugin/`
- Codex-specific manifest in `codex/.codex-plugin/`
- a committed universal plugin package in `plugins/gluon-agent/`
- a Claude marketplace in `.claude-plugin/marketplace.json`
- `build.sh` to assemble runnable distributions under `dist/`
- `.agents/plugins/marketplace.json` so Codex can discover the plugin from this repo
- install scripts under `scripts/`

## Structure

```text
shared/
  skills/
  scripts/
  .mcp.json
claude/
  agents/
  .claude-plugin/plugin.json
codex/
  agents/
  .codex-plugin/plugin.json
plugins/
  gluon-agent/
.claude-plugin/
  marketplace.json
.agents/plugins/marketplace.json
scripts/
build.sh
```

## Build

```bash
bash build.sh
```

This generates:

- `dist/claude-plugin/`
- `dist/codex-plugin/`
- `plugins/gluon-agent/` as the committed repo plugin package for both platforms

Agent packaging differs by platform:

- Claude Code can load plugin-shipped subagents from `agents/`.
- Codex custom agents live under `.codex/agents/` or `~/.codex/agents/`, so this repo ships templates in `codex/agents/` and the installer copies them into `~/.codex/agents/`.

## Install From GitHub

Repository:

- [https://github.com/yangzichao/gluon-agent](https://github.com/yangzichao/gluon-agent)

### Claude Code

True GitHub marketplace install is supported.

```bash
/plugin marketplace add yangzichao/gluon-agent
/plugin install gluon-agent@gluon-agent-marketplace
```

This works because the repo publishes a marketplace at `.claude-plugin/marketplace.json` that points at `./plugins/gluon-agent`.

### Codex

Direct GitHub marketplace install is not documented in current Codex plugin docs. The supported paths today are:

1. Clone the repo and run the installer:

```bash
git clone https://github.com/yangzichao/gluon-agent.git
cd gluon-agent
bash scripts/install-codex.sh
```

This installs:

- the Codex plugin under `~/.codex/plugins/gluon-agent`
- custom research agents under `~/.codex/agents/`

2. Or open the cloned repo in Codex and use the repo marketplace at `.agents/plugins/marketplace.json`, which exposes `gluon-agent` from `./plugins/gluon-agent`. In that mode you still need to copy `codex/agents/*.toml` into `.codex/agents/` or `~/.codex/agents/` if you want the named orchestrator agents.

## Test

Claude Code:

```bash
claude --plugin-dir dist/claude-plugin
```

Codex:

1. Run `bash scripts/install-codex.sh`, or
2. Open this repo in Codex and use the repo marketplace.

## Agent Model

The intended entrypoints are agents, not bare skills:

- `deep-research`: orchestrator agent for substantial research jobs
- `deep-research-pro`: orchestrator agent for exhaustive investigations
- `quick-research`: lightweight standalone fast-research agent
- `research-worker`: worker agent for focused subquestions
- `research-verifier`: worker agent for contradiction-seeking and claim verification

The shared `skills/` directory exists to keep the operating procedure reusable across Claude and Codex. It is not meant to be the only user-facing surface.

### Orchestrator fan-out requirements

Orchestrator agents (`deep-research`, `deep-research-pro`) spawn `research-worker` and `research-verifier` as named subagents. This requires the orchestrator to run as the **main session agent**, not as a delegated subagent, because subagents cannot spawn other subagents on either platform.

**Claude Code**: Launch the orchestrator as the session agent:

```bash
claude --agent gluon-agent:deep-research
# or
claude --agent gluon-agent:deep-research-pro
```

If you install the plugin and invoke the skill from a normal session (e.g. `/deep-research`), the skill runs inside the main Claude thread and can use the Agent tool to spawn workers — but only if Claude itself is the main agent. If `deep-research` is auto-delegated as a subagent, it will **not** be able to fan out.

**Codex**: Fan-out works in interactive CLI sessions where Codex resolves custom agent names from `~/.codex/agents/`. It does **not** work in tool-backed or API sessions — custom agent name resolution is not yet supported there (see [openai/codex#15250](https://github.com/openai/codex/issues/15250)). The `agents.max_depth` config (default 1) also prevents workers from spawning grandchildren.

## Source Notes

- Claude GitHub marketplace install is documented by Anthropic via `/plugin marketplace add owner/repo`.
- Claude also documents plugin-distributed subagents via plugin `agents/`.
- Codex currently documents plugins for skills/apps/MCP plus project or user custom agents under `.codex/agents/` and `~/.codex/agents/`; public plugin support for shipping custom agents as first-class plugin components is not documented.

## Local Commands

```bash
make build
make install-claude
make install-codex
```

## Reference

The detailed design and platform comparison live in:

- `gluon-agent-开发完全指南.md`
