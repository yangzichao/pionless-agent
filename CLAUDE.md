# gluon-agent

This repository is a universal plugin scaffold.

## Expected Layout

- `shared/` for cross-platform plugin assets
- `claude/` for Claude Code specific manifests and optional agents/hooks/LSP files
- `codex/` for Codex specific manifests and optional app integrations

## Research Output Convention

All research output **must** be written to the `deep-research/` directory at the project root. Never write research reports to the repository root or any other location.

Filename format: `YYYY-MM-DD-HHSS-topic.md` where:
- `YYYY-MM-DD` is the current date
- `HHSS` is the current hour and second (24h format, no separator)
- `topic` is a short lowercase slug derived from the research question (e.g. `ai-agent-frameworks`, `react-vs-vue`)

Workspace files follow the same prefix: `YYYY-MM-DD-HHSS-topic.workspace.md`

Examples:
- `deep-research/2026-03-30-1423-ai-agent-frameworks.md`
- `deep-research/2026-03-30-1423-ai-agent-frameworks.workspace.md`

## Development Flow

1. edit shared capabilities first
2. add platform-specific adapters only when required
3. run `bash build.sh`
4. test `dist/claude-plugin` and `dist/codex-plugin` separately
