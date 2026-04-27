# Delegation Patterns

This skill is built around an orchestrator-worker shape. Whether actual workers are spawned depends on the host runtime.

## Patterns

### Parallel subquestion workers

When the plan board contains independent subquestions, the host may spawn one worker per subquestion. Each worker runs a focused research pass (often the `quick-research` skill) and returns structured findings.

Use when subquestions share no shared evidence and order does not matter.

### Contradiction-seeking verifier

After the orchestrator drafts the evolving report, the host may spawn a **verifier** worker tasked with disproving the current thesis. The verifier returns counter-evidence (or confirms none was found) which feeds back into the next Ralph iteration. This is a strong fit for the mandatory pro-tier contradiction-seeking pass (`references/contradiction-seeking-pass.md`).

Use this pattern by default at the pro tier when worker spawning is available.

### Domain-specialist routing

If subquestions cross domains (e.g., legal + technical + financial), the host may route each subquestion to a worker primed on the relevant references and templates.

Use when domain conventions diverge enough that one prompt cannot serve all.

### Methodology auditor

For high-stakes decisions, the host may spawn a worker whose only job is to audit the orchestrator's methodology: did the search angles cover what they should have? Did verification meet the 3-source rule? Was contradiction-seeking genuine?

Use when the report will support a load-bearing external decision.

## Worker contract

Every worker should return:

- findings,
- evidence with provenance (URL, date, source tier),
- unresolved questions,
- confidence level,
- whether the result changes the overall thesis.

The `quick-research` skill's subagent template gives a concrete structured shape that this orchestrator can ingest directly.

## Host responsibilities

The host owns:

- whether to spawn workers at all,
- how many workers and at what concurrency,
- which model each worker uses,
- which tools each worker is permitted,
- the synthesis step that merges worker outputs.

This skill does not declare any of those.

## Sequential fallback

If the host runtime does not support spawning workers, run the same passes sequentially in this thread. Use workspace reconstruction between passes to keep context isolated. Quality should not degrade — only parallelism is lost.
