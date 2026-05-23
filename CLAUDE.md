# pionless-matrix

This repository is a cross-platform agent monorepo. A single source tree (`src/`) is partitioned into multiple publishable plugins via `src/plugins.json`. Each plugin ships to both Claude Code and Codex.

## Plugins

- **`pionless-agent`** — coding-workflow agents: `hoah-coder` (focused coder + reviewer loop), `parallel-fix` (batch fixer with worktree workers), `socratic-tutor`, `freshwater-doctor`.
- **`pionless-deep-research`** — research agents: `deep-research` orchestrator + 4 leaf agents (worker, verifier, drafter, writer), 6 report-style skills, and `markdown-to-pdf` pipeline.

## Expected Layout

- `src/agents/` — canonical agent definitions (.md); single source of truth
- `src/skills/<skill>/` — self-contained skill packages (SKILL.md + optional references/, assets/, scripts/)
- `src/plugins.json` — plugin membership manifest (which agents and skills belong to which plugin); enforced by build.sh
- `platforms/claude-code/<plugin>/.claude-plugin/plugin.json` — per-plugin Claude manifests
- `platforms/codex/<plugin>/.codex-plugin/plugin.json` — per-plugin Codex manifests
- `platforms/claude-code/agents/`, `platforms/codex/agents/` — GENERATED per-agent files (all plugins, partitioned at assembly time)
- `shared/skills/` — GENERATED expanded skill bodies (all plugins)
- `plugins/<plugin>/` — GENERATED committed repo plugins (serve both platforms)
- `dist/<plugin>/{claude-plugin,codex-plugin}/` — GENERATED publish-ready packages

## Development Flow

1. Edit agent definitions in `src/agents/` (system prompts, turn protocol)
2. Edit skill packages in `src/skills/<skill>/`
3. If adding a new agent or skill, register it in `src/plugins.json` under the owning plugin
4. Edit per-plugin platform manifests under `platforms/<platform>/<plugin>/`
5. Run `bash build.sh` — generates platform agents, expands skills, and assembles every plugin output
6. Test each plugin under `dist/<plugin>/claude-plugin/` and `dist/<plugin>/codex-plugin/` separately

Never hand-edit files in `platforms/claude-code/agents/`, `platforms/codex/agents/`, `shared/skills/`, `plugins/<plugin>/`, or `dist/` — they are build outputs. build.sh enforces that every `src/agents/*.md` and `src/skills/<skill>/` is claimed by exactly one plugin in `src/plugins.json`.

## Research Output Convention

All research output **must** be written to the `deep-research/` directory at the project root. Never write research reports to the repository root or any other location.

Filename format: `YYYY-MM-DD-HHMM-topic.md` where:
- `YYYY-MM-DD` is the current date
- `HHMM` is the current hour and minute (24h format, no separator)
- `topic` is a short lowercase slug derived from the research question (e.g. `ai-agent-frameworks`, `react-vs-vue`)

Workspace files follow the same prefix: `YYYY-MM-DD-HHMM-topic.workspace.md`

Examples:
- `deep-research/2026-03-30-1423-ai-agent-frameworks.md`
- `deep-research/2026-03-30-1423-ai-agent-frameworks.workspace.md`
