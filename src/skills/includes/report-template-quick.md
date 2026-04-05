### Standalone mode (invoked directly by user)

When invoked directly, create or reuse a `deep-research/` directory in the current workspace, derive a short lowercase topic slug, and write a concise answer to `deep-research/YYYY-MM-DD-HHSS-topic.md`:

```markdown
# [Question as Title]

## Answer
[2-5 sentences: direct answer with inline citations as [Source Title](url).]

## Supporting Evidence
- **[Claim 1]**: [evidence summary] — [Source](url)
- **[Claim 2]**: [evidence summary] — [Source](url)

## Confidence & Caveats
[One-liner on confidence level and any important caveats.]

## Sources
- [Source Title](url)
```

### Subagent mode (invoked by a parent orchestrator)

When invoked as a worker by another skill (deep-research, deep-research-pro, or any other workflow), return findings in this structured format so the parent can consume them:

```text
Task: [the subquestion assigned]
Status: answered | partially-answered | unanswerable
Confidence: high | medium | low

Findings:
- [claim]: [evidence summary] | source: [url] | confidence: [high/medium/low]
- ...

Contradictions:
- [if any sources disagreed, note it here]

Unresolved:
- [what couldn't be answered and why]

Recommended follow-up:
- [if partially answered, what the parent should investigate next]
```

This format is designed to be directly ingestible by the evolving report of a parent deep-research orchestrator.
