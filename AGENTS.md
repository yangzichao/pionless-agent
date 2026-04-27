# pionless-agent

This repository maintains a cross-platform research agent package for Claude Code and OpenAI Codex.

## Architecture

Agents are the brains (orchestration logic, turn protocol, Ralph loop enforcement). Skills are reference material (research rules, writing rules, report templates).

## Single Source of Truth

All agent definitions live in `src/agents/` as Claude-format .md files. Build.sh generates both platforms:

- `platforms/claude-code/agents/*.md` — Claude Code agents
- `platforms/codex/agents/*.toml` — Codex agents (converted format)

## Modular Skills

Skill content is decomposed into small modules in `src/skills/includes/`. Source SKILL.md files use `<!-- include: includes/filename.md -->` markers that build.sh expands at build time.

## Working Rules

- Edit agents in `src/agents/` — never hand-edit `platforms/claude-code/agents/` or `platforms/codex/agents/`
- Edit skill modules in `src/skills/includes/` — never hand-edit `shared/skills/`
- Run `bash build.sh` to assemble all outputs
- All research output goes to `deep-research/` using `YYYY-MM-DD-HHMM-topic.md` naming

## Agents

| Agent | Role | Claude Model |
|-------|------|--------------|
| deep-research | Orchestrator (standard) | opus |
| deep-research-pro | Orchestrator (exhaustive) | opus |
| quick-research | Standalone lightweight; also reusable as a worker | sonnet |
| deep-research-worker | Bonded evidence-gathering worker for deep-research | sonnet |
| deep-research-verifier | Bonded contradiction-seeking worker for deep-research | sonnet |
| parallel-fix-worker | Bonded single-fix worker for the parallel-fix skill | sonnet |
