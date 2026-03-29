# gluon-agent

`gluon-agent` is a universal plugin scaffold for Claude Code and OpenAI Codex.
This repository now contains:

- shared plugin assets in `shared/`
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
  .claude-plugin/plugin.json
codex/
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

2. Or open the cloned repo in Codex and use the repo marketplace at `.agents/plugins/marketplace.json`, which exposes `gluon-agent` from `./plugins/gluon-agent`.

## Test

Claude Code:

```bash
claude --plugin-dir dist/claude-plugin
```

Codex:

1. Run `bash scripts/install-codex.sh`, or
2. Open this repo in Codex and use the repo marketplace.

## Source Notes

- Claude GitHub marketplace install is documented by Anthropic via `/plugin marketplace add owner/repo`.
- Codex currently documents repo and personal local marketplaces, while official public plugin publishing is still marked "coming soon".

## Local Commands

```bash
make build
make install-claude
make install-codex
```

## Reference

The detailed design and platform comparison live in:

- `gluon-agent-开发完全指南.md`
