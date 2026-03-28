# gluon-agent

This repository is a universal plugin scaffold.

## Expected Layout

- `shared/` for cross-platform plugin assets
- `claude/` for Claude Code specific manifests and optional agents/hooks/LSP files
- `codex/` for Codex specific manifests and optional app integrations

## Development Flow

1. edit shared capabilities first
2. add platform-specific adapters only when required
3. run `bash build.sh`
4. test `dist/claude-plugin` and `dist/codex-plugin` separately
