# Ralph Loop

Repeat this loop until the completion gate passes (`references/completion-gate.md`) or every subquestion is genuinely saturated.

## Iteration steps

1. **Inspect the current workspace.** Read the persisted `<prefix>.workspace.md` rather than relying on prior conversation turns.
2. **Choose the highest-value open task.** Select by expected information gain (`references/plan-board.md`). Batch independent tasks for parallel workers when the host supports spawning.
3. **Gather or verify evidence.** Apply `references/source-policy.md`, `references/verification-policy.md`, `references/retrieval-policy.md`, `references/depth-policy.md`. Run the work directly, or via worker spawn per `references/delegation-patterns.md`.
4. **Update the evolving report.** Synthesize new findings into the running draft. Keep it answer-first and citation-dense.
5. **Run quality checks.** Did the new evidence change any prior claim? Are contradictions surfaced? Does each major claim now have 3 independent sources or a documented reason for fewer?
6. **Reconstruct the workspace.** Overwrite the `.workspace.md` file with only the canonical blocks (`references/workspace-reconstruction.md`).

## Mandatory contradiction-seeking pass

Before declaring the gate passed, run a dedicated contradiction-seeking pass per `references/contradiction-seeking-pass.md`. The completion gate cannot pass without it.

## Stopping rule

Do not stop just because there is enough text. Stop when the report is **exhaustively supported** — see `references/completion-gate.md` for the precise criteria.

If terminating before the gate passes (e.g., user time-sensitivity exceeded), finalize a best-effort report with a clear `Limitations` section.
