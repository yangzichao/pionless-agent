---
name: quick-research
description: Use this skill when the user needs a fast, sourced answer to a focused factual or comparative question, or when a larger research workflow needs a single-pass research worker.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: research
  pionless.tier: quick
  pionless.suggests-delegation: ""
---

# Quick Research

Use this skill for one focused research question that needs a sourced answer in a single pass. Examples: fact-check a claim, look up the current state of a technology, answer a specific technical question, or produce findings for a larger research workflow.

This skill is intentionally narrow: one pass, one focused loop, no subagent decomposition. If the question turns out to be broad or open-ended, escalate to the `deep-research` or `deep-research-pro` workflow instead.

## When to activate

Activate when the host needs to:

- answer one focused question,
- with sourced citations,
- within a tight budget,
- in a single pass.

Do not activate for open-ended exploration, full literature reviews, or multi-track investigations.

## Modes

This skill has two output modes. The host chooses which one fits.

- **Standalone mode** — the user invoked this skill directly. Write a concise human-readable report using `assets/report-template-standalone.md`.
- **Subagent mode** — a parent orchestrator invoked this skill as a worker. Return findings in the structured format defined by `assets/report-template-subagent.md` so the parent can ingest them.

## Workflow

Guide the host agent through these four steps.

1. **Frame** the question. Pin down the exact ask and what "good enough" looks like. If the prompt is ambiguous, apply `references/framing-checklist.md` before searching.
2. **Search** from 2–3 angles. Apply the source-tier rules in `references/source-policy.md` to triage results.
3. **Verify** load-bearing claims. Apply `references/verification-policy.md` to decide when one source is enough and when a second is required.
4. **Synthesize** using the right template for the active mode. Math and notation: see `references/math-notation-rules.md` if the answer involves formulas.

Stop after one pass plus at most one verification pass. See `references/budget.md`.

## Output convention

If the host supports file writes and the project follows the `deep-research/` convention, write standalone reports to `deep-research/YYYY-MM-DD-HHMM-<topic>.md`. Otherwise return the report inline. Full convention in `references/output-conventions.md`.

## Resources

- `references/framing-checklist.md` — turn an ambiguous prompt into a tight question.
- `references/source-policy.md` — primary, authoritative-secondary, and weak source tiers.
- `references/verification-policy.md` — required support per claim type and how to surface conflicts.
- `references/budget.md` — search/fetch/iteration limits and termination triggers.
- `references/output-conventions.md` — `deep-research/` directory and filename rules.
- `references/math-notation-rules.md` — preserve math/code notation through Markdown.
- `references/delegation-patterns.md` — read only if a parent orchestrator is composing multiple instances of this skill in parallel.
- `assets/report-template-standalone.md` — final output for standalone mode.
- `assets/report-template-subagent.md` — structured findings for subagent mode.
- `assets/citation.schema.json` — machine-readable citation schema.
- `scripts/triage_sources.py` — optional helper that ranks candidate URLs by source tier.

## Tool usage

Skills do not grant tools. The host runtime decides what is permitted. Apply the rules below conditionally on what the host actually exposes.

- If a web-search tool is available, use it for discovery; generate 2–3 query variants per question (exact-match, semantic, one alternative angle).
- If a web-fetch tool is available, deep-read 2–4 high-value pages rather than skimming many.
- If shell access is available and Python is installed, run `python scripts/triage_sources.py urls.txt` to rank candidate sources before deep-reading. If shell access is unavailable, apply the same heuristics manually using `references/source-policy.md`.
- If a file-write tool is available and the project follows the `deep-research/` convention, write the standalone report there. Otherwise return the report inline.

This skill does not spawn subagents. It is designed to **be** a subagent.

## What this skill does not do

- No plan-board construction (orchestrator territory).
- No Ralph loop (one pass, optionally one verification pass).
- No subagent spawning.
- No exhaustive verification (use `deep-research-pro` if 3+ source corroboration is required).
