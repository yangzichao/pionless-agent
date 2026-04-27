# Output Conventions

## Directory

All research output goes into a `deep-research/` directory at the project root. Create it if it does not exist.

## Filename prefix

Derive a single run prefix per research job:

```
YYYY-MM-DD-HHMM-<topic>
```

Where:

- `YYYY-MM-DD` is the current date.
- `HHMM` is the current hour and minute (24h, no separator).
- `<topic>` is a short lowercase hyphenated slug derived from the research question.

Example: `2026-04-26-1530-eu-ai-act-deep-dive`

## Files

Use the same prefix for both files of a run:

- `deep-research/<prefix>.workspace.md` — workspace state, overwritten after every meaningful step.
- `deep-research/<prefix>.md` — final report.

## Forbidden

- Writing to the project root.
- Arbitrary names like `report.md` or `workspace.md`.
- Paths outside `deep-research/`.

## Subagent workers

If the host spawns workers, the orchestrator should pass the run prefix to each worker so all artifacts share the same `<prefix>` and stay grouped. The host owns whether subagents write files at all.

## Host without write access

If the host has no file-write tool, the workflow degrades sharply — the Ralph loop and workspace reconstruction depend on file-backed state. Surface this immediately and fall back to a tighter in-memory variant or to `deep-research` (standard tier) with explicit warnings.
