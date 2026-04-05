---
name: deep-research-pro
description: Run an unlimited deep research workflow with full orchestrator-worker decomposition, aggressive verification, and no budget constraints. Use for PhD-level investigations, comprehensive landscape scans, and high-stakes decisions requiring exhaustive evidence.
model: claude-opus-4-6
allowed-tools: Read, Write, Bash, WebSearch, WebFetch, Agent
---

# Deep Research Pro

Use this skill when the user asks for exhaustive research, a comprehensive literature review, a full competitive landscape, a regulatory deep-dive, or any investigation where completeness matters more than speed.

This is the **unbounded** tier of the research system. Unlike `deep-research`, there are no soft limits on queries, page reads, or iterations. The agent should go as deep as the evidence requires.

<!-- include: includes/output-rules-orchestrator.md -->

## Objective

Produce a high-confidence, citation-dense report by running an unbounded orchestrator-worker research loop with aggressive verification. Operate on three principles:

1. **Orchestrator-worker**: one lead thread manages the plan and delegates each investigation thread as an isolated subagent task.
2. **Ralph loop**: repeat research, synthesis, and verification until the quality gate passes or a real blocker remains.
3. **Workspace reconstruction**: after every meaningful step, throw away noisy history and rebuild only the minimal working state.

## Tool usage guide

Each allowed tool serves a distinct role:

- **WebSearch**: discover sources. Generate 3-5 query variants per subquestion (exact-match, semantic, negation, site-specific, temporal).
- **WebFetch**: deep-read a specific URL. Use liberally after WebSearch identifies promising sources. Extract key facts, data, and quotes with provenance.
- **Write**: persist state to files. Save workspace state and the final report under `deep-research/`.
- **Read**: reload persisted state. Read the current workspace file from `deep-research/` at the start of each iteration—do not rely on earlier conversation turns.
- **Bash**: data processing, format conversion, computation, or table generation.
- **Agent** (if available): spawn isolated subagent workers for parallel investigation tracks. Each subagent receives only its task objective, relevant workspace context, and allowed tools. Subagent results are collected and synthesized by the orchestrator.

<!-- include: includes/subagent-delegation.md -->

<!-- include: includes/workspace-reconstruction.md -->

## Operating model

<!-- include: includes/operating-model.md {SUBQUESTION_RANGE=5-12} {COMPLETION_STANDARD=exhaustively supported} -->

## Budget and termination

<!-- include: includes/budget-pro.md -->

## Research rules

<!-- include: includes/research-rules-pro.md -->

## Writing rules

<!-- include: includes/writing-guidelines.md -->

<!-- include: includes/report-template-pro.md -->

<!-- include: includes/math-notation-rules.md -->

## Default working template

<!-- include: includes/workspace-template-pro.md -->

## Completion gate

<!-- include: includes/completion-gate-pro.md -->
