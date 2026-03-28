# gluon-agent

`gluon-agent` is a universal plugin scaffold for Claude Code and OpenAI Codex.
This repository now contains:

- shared plugin assets in `shared/`
- Claude-specific manifest in `claude/.claude-plugin/`
- Codex-specific manifest in `codex/.codex-plugin/`
- `build.sh` to assemble runnable distributions under `dist/`

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
build.sh
```

## Build

```bash
./build.sh
```

This generates:

- `dist/claude-plugin/`
- `dist/codex-plugin/`

## Test

Claude Code:

```bash
claude --plugin-dir dist/claude-plugin
```

Codex:

1. Copy `dist/codex-plugin` into your local plugins directory, or
2. Reference it from a marketplace file.

## Reference

The detailed design and platform comparison live in:

- `gluon-agent-开发完全指南.md`
