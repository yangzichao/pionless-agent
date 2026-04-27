# Subagent Output Format

Return the following structured block to the parent orchestrator. This format is designed to be directly ingestible by the evolving report of a parent deep-research orchestrator.

```text
Task: <the subquestion assigned>
Status: answered | partially-answered | unanswerable
Confidence: high | medium | low

Findings:
- <claim>: <evidence summary> | source: <url> | tier: <primary|secondary|weak> | confidence: <high|medium|low>
- <claim>: <evidence summary> | source: <url> | tier: <primary|secondary|weak> | confidence: <high|medium|low>

Contradictions:
- <if any sources disagreed, note the disagreement and which side seems closer to primary>

Unresolved:
- <what could not be answered and why>

Recommended follow-up:
- <if partially answered, what the parent should investigate next>
```

Rules:

- One claim per `Findings` line; do not collapse multiple facts into one line.
- `tier` and `confidence` are required on every finding.
- If `Contradictions` is empty, write `Contradictions: none`.
- If `Unresolved` is empty, write `Unresolved: none`.
- Do not write a Markdown report file in subagent mode unless the parent's task card explicitly asks for one.
