---
name: deep-research-pro
description: Use this skill for exhaustive, unbounded research workflows where completeness matters more than speed — comprehensive literature reviews, full competitive landscape scans, regulatory deep-dives, and high-stakes decisions requiring 3+ source corroboration and a dedicated contradiction-seeking pass.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: research
  pionless.tier: pro
  pionless.suggests-delegation: "subquestion-investigation contradiction-seeking verification methodology-audit"
---

# Deep Research Pro

Use this skill when the user asks for exhaustive research, a comprehensive literature review, a full competitive landscape, a regulatory deep-dive, or any investigation where completeness matters more than speed.

This is the **unbounded** tier. There are no soft caps on queries, fetches, or iterations — the workflow goes as deep as the evidence requires. For bounded research see `deep-research`. For fast lookups see `quick-research`.

## When to activate

Activate when the host needs:

- 5–12 subquestions investigated thoroughly,
- 3+ independent sources per major claim,
- a dedicated contradiction-seeking pass before finalization,
- a citation-dense report with explicit methodology and contradictions sections,
- no soft termination on query or iteration count.

Do not activate for tasks where a bounded budget is acceptable (use `deep-research`) or for one-shot lookups (use `quick-research`).

## Operating principles

This skill rests on three principles. Apply all three throughout the workflow.

1. **Orchestrator-worker.** One lead thread manages the plan and delegates each investigation thread as an isolated task. See `references/delegation-patterns.md`.
2. **Ralph loop.** Repeat research → synthesis → verification → contradiction-seeking until the completion gate passes or every subquestion is genuinely saturated. See `references/ralph-loop.md`.
3. **Workspace reconstruction.** After every meaningful step, rebuild only the minimal working state from a persisted file. See `references/workspace-reconstruction.md`.

## Workflow

Guide the host agent through these six steps.

1. **Initialize the research contract.** Pin down the question, decision, output format, time sensitivity, and constraints. State assumptions explicitly when the user did not specify.
2. **Build the plan board.** 5–12 subquestions with priority, expected evidence type, dependencies, and depth target. See `references/plan-board.md`.
3. **Run worker-style investigations.** Apply `references/source-policy.md`, `references/verification-policy.md`, `references/retrieval-policy.md`, `references/depth-policy.md`. Verification requires **3 independent sources** for major claims at this tier.
4. **Reconstruct the workspace after each step.** Use `assets/workspace-template.md`; persist per `references/workspace-reconstruction.md`.
5. **Run a dedicated contradiction-seeking pass before finalization.** This is mandatory at the pro tier. See `references/contradiction-seeking-pass.md`.
6. **Execute the Ralph loop until the completion gate passes.** Gate criteria in `references/completion-gate.md`.

## Output convention

Write workspace and final report to the project's `deep-research/` directory using the prefix `YYYY-MM-DD-HHMM-<topic>`. See `references/output-conventions.md`.

## Resources

- `references/output-conventions.md` — `deep-research/` directory and filename rules.
- `references/plan-board.md` — 5–12 subquestion board with depth targets.
- `references/ralph-loop.md` — the iteration loop with a mandatory contradiction-seeking pass.
- `references/workspace-reconstruction.md` — file-backed state protocol.
- `references/source-policy.md` — primary, secondary, weak tiers; active disagreement-seeking.
- `references/verification-policy.md` — 3-source rule, dedicated contradiction pass, third-source resolution.
- `references/retrieval-policy.md` — 5 query angles per major subquestion.
- `references/depth-policy.md` — uncapped iterative deepening.
- `references/contradiction-seeking-pass.md` — the mandatory pre-finalization pass.
- `references/efficiency-discipline.md` — saturation handling without hard caps.
- `references/completion-gate.md` — pro-tier gate criteria.
- `references/delegation-patterns.md` — parallel investigation, verifier split, methodology audit.
- `references/writing-guidelines.md` — citation density, methodology section, contradictions section.
- `references/math-notation-rules.md` — preserve formulas and code through Markdown.
- `assets/report-template.md` — pro-tier report skeleton with Methodology and Contradictions sections.
- `assets/workspace-template.md` — workspace skeleton with the pro-tier gate checklist.

## Tool usage

Skills do not grant tools. The host runtime decides what is permitted. Apply the rules below conditionally on what the host actually exposes.

- If a web-search tool is available, use it liberally; generate **3–5 query variants** per major subquestion (exact-match, semantic, contradiction-seeking, site-specific, temporal).
- If a web-fetch tool is available, deep-read promising sources without artificial caps.
- If a file-write tool is available, persist the workspace to `deep-research/<prefix>.workspace.md` and the report to `deep-research/<prefix>.md`.
- If a file-read tool is available, reload the workspace at the start of each iteration rather than relying on prior conversation turns.
- If a shell tool is available, use it for data processing, format conversion, computation, or table generation.
- If the host supports spawning worker agents, follow `references/delegation-patterns.md` to parallelize independent tracks. If not, run the same passes sequentially.

## Efficiency discipline

There are no hard budgets at this tier, but discipline still applies:

- Do not repeat searches that have already been exhausted.
- Track diminishing returns: if 3 consecutive searches on the same subquestion yield no new evidence, mark `saturated` and move on.
- Prefer depth on high-value questions over breadth on low-value ones.

See `references/efficiency-discipline.md`.

## What this skill does not do

- No fast one-shot answers (use `quick-research`).
- No bounded research (use `deep-research` if a soft budget is acceptable).
- No code edits, deploys, or external side effects beyond file writes into `deep-research/`.
