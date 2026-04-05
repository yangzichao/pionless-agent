### Subagent delegation

Use subagents to parallelize independent investigation tracks:

- Each subagent gets a narrow objective, a list of seed queries, and acceptance criteria.
- Subagents return structured findings: claims, evidence with provenance, confidence level, and unresolved questions (use the `quick-research` subagent output format).
- The orchestrator synthesizes subagent results, resolves contradictions, and updates the evolving report.
- Best uses for subagents: independent domain angles, contradiction-seeking verification, and data-heavy analysis.
- Do not spawn subagents for tasks that depend on each other—run those sequentially.

**Platform fallback**: if the Agent tool is not available on the current platform, fall back to sequential worker-style execution. Run each subtask in sequence within the orchestrator's own context, using workspace reconstruction between tasks to maintain isolation. The research quality should not degrade—only parallelism is lost.
