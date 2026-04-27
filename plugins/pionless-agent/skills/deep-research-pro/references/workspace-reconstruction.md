# Workspace Reconstruction

Workspace reconstruction works only if the workspace lives in a **file**, not just in conversation context.

## Protocol

1. At project start, create or reuse a `deep-research/` directory in the current workspace.
2. Derive a topic slug and run prefix in the form `YYYY-MM-DD-HHMM-<topic>` (`references/output-conventions.md`).
3. Write the initial workspace state to `deep-research/<prefix>.workspace.md` using `assets/workspace-template.md`.
4. After each meaningful step (search, fetch, synthesis, worker return, contradiction-seeking pass), overwrite that same file.
5. Before each new iteration, read **only** that workspace file. Do not rely on earlier conversation turns for research state.
6. Write the final report to `deep-research/<prefix>.md`.

## What to keep in the workspace

The workspace holds these blocks:

- `Research question` — the exact objective and constraints.
- `Evolving report` — the best current draft, already cleaned and deduplicated.
- `Immediate context` — only the facts, tensions, and next-step cues needed right now.
- `Open tasks` — the remaining frontier on the plan board.
- `Contradictions log` — disagreements found, resolution status, and which side the evidence currently favors.

Plus mandatory header sections from `assets/workspace-template.md`:

- `Loop State` — iteration counter, gate status, stale-rounds counter, search/fetch/worker counters, contradiction-pass status.
- `Gate Checklist` — the pro-tier completion-gate criteria as checkboxes (3+ sources, contradiction pass completed, methodology present, etc.).

## What to discard

- Full raw page content from prior fetches.
- Full prior search-result lists.
- Long worker transcripts.
- Earlier draft revisions of the report.

These can exist externally for audit, but the active reasoning context should stay compact.

## Why

Without file-backed reconstruction, the loop slowly poisons itself with stale context. At pro tier, where iterations can run long, this is even more important than at the standard tier.
