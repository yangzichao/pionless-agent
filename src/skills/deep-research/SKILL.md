---
name: deep-research
description: Run a deep research workflow using orchestrator-worker task decomposition, Ralph-loop iteration, workspace reconstruction, evidence verification, and answer-first report synthesis.
model: claude-opus-4-6
allowed-tools: Read, Write, Bash, WebSearch, WebFetch, Agent
---

# Deep Research

Use this skill when the user asks for deep research, a literature review, a market or technical landscape scan, a source-backed report, or a long-horizon investigation.

This is the **standard** tier of the research system. It balances depth with efficiency through budgeted iterations and workspace reconstruction. For exhaustive, unbounded research, see `deep-research-pro`. For fast, focused lookups (or to use as a subagent worker), see `quick-research`.

<!-- include: includes/output-rules-orchestrator.md -->

## Objective

Produce a high-confidence report without letting the working context bloat. Operate as a bounded deep-research agent built on three rules:

1. **Orchestrator-worker**: one lead thread manages the plan and delegates each investigation thread as an isolated task.
2. **Ralph loop**: repeat research, synthesis, and verification until the quality gate passes or a real blocker remains.
3. **Workspace reconstruction**: after every meaningful step, throw away noisy history and rebuild only the minimal working state.

## Tool usage guide

Each allowed tool serves a distinct role in the research workflow:

- **WebSearch**: discover sources. Use for broad queries, finding primary documents, and contradiction-seeking searches. Generate 2-3 query variants per subquestion (exact-match, semantic, negation).
- **WebFetch**: deep-read a specific URL. Use after WebSearch identifies a promising source. Extract key facts, data, and quotes with provenance.
- **Write**: persist state to files. Use to save the workspace file and final report under `deep-research/`. This is critical—without writing state to a file, workspace reconstruction is only conceptual.
- **Read**: reload persisted state. Use at the start of each new iteration to read the current workspace file from `deep-research/` back into context, replacing stale conversation history.
- **Bash**: data processing, format conversion, or computation (e.g., calculating statistics, converting units, sorting tables).
- **Agent** (if available): spawn isolated subagent workers for parallel investigation tracks. Each subagent receives only its task objective, relevant workspace context, and allowed tools. Budget: up to 10 subagent spawns per research job; prefer batching independent subquestions into parallel subagents over spawning one per query.

<!-- include: includes/subagent-delegation.md -->

<!-- include: includes/workspace-reconstruction.md -->

## Operating model

<!-- include: includes/operating-model.md {SUBQUESTION_RANGE=3-7} {COMPLETION_STANDARD=substantively supported} -->

## Budget and termination

<!-- include: includes/budget-standard.md -->

## Research rules

<!-- include: includes/research-rules-standard.md -->

## Writing rules

<!-- include: includes/writing-guidelines.md -->

<!-- include: includes/report-template-standard.md -->

<!-- include: includes/math-notation-rules.md -->

## Default working template

<!-- include: includes/workspace-template-standard.md -->

## Completion gate

<!-- include: includes/completion-gate-standard.md -->
