# gluon-agent

This repository maintains a shared plugin codebase for Claude Code and OpenAI Codex.

## Working Rules

- put reusable skills under `shared/skills/`
- put reusable MCP configuration in `shared/.mcp.json`
- keep Claude-only files under `claude/`
- keep Codex-only files under `codex/`
- run `bash build.sh` to assemble `dist/claude-plugin` and `dist/codex-plugin`

## Research Output

All research skills (deep-research, deep-research-pro, quick-research) must write output to `deep-research/` using the naming template `YYYY-MM-DD-HHSS-topic.md`. Never write reports to the project root.

## Goal

Keep the shared layer as large as possible and platform-specific differences as thin as possible.
