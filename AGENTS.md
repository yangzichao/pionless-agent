# gluon-agent

This repository maintains a shared plugin codebase for Claude Code and OpenAI Codex.

## Working Rules

- put reusable skills under `shared/skills/`
- put reusable MCP configuration in `shared/.mcp.json`
- keep Claude-only files under `claude/`
- keep Codex-only files under `codex/`
- run `bash build.sh` to assemble `dist/claude-plugin` and `dist/codex-plugin`

## Goal

Keep the shared layer as large as possible and platform-specific differences as thin as possible.
