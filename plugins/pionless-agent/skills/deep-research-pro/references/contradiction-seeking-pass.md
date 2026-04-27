# Contradiction-Seeking Pass

Mandatory at the pro tier. The completion gate cannot pass without it.

## When

After the evolving report has reached completeness on every subquestion **but before** declaring the gate passed.

## Procedure

For each major claim in the evolving report:

1. Generate a query that explicitly tries to **disprove** the claim. Examples:
   - "limitations of <approach>"
   - "criticism of <author> <claim>"
   - "<claim> is wrong"
   - "evidence against <conclusion>"
   - "<minority position> on <topic>"
2. Run the query and read the top results, including those that disagree with the current thesis.
3. For each piece of counter-evidence found:
   - Add it to the `Contradictions` log in the workspace.
   - Decide whether it changes the claim, weakens it, or can be rebutted with the existing evidence.
   - If it changes the claim, return to the Ralph loop to update the evolving report.
4. If no counter-evidence is found for a claim, record this in the workspace too — the absence of disagreement is itself a finding worth noting.

## Worker delegation

If the host supports spawning workers, this pass is a strong candidate for delegation: spawn a "verifier" worker tasked specifically with disproving the thesis. The verifier returns counter-evidence; the orchestrator decides what to do with it. See `references/delegation-patterns.md`.

## Output

The contradiction-seeking pass produces:

- updates to the workspace `Contradictions` log,
- updates to the report's `Contradictions & Contested Claims` section (mandatory at pro tier),
- possibly a new Ralph loop iteration if claims must change.

## Gate impact

After the pass, mark `Dedicated contradiction-seeking pass completed` on the gate checklist. Without this checkbox, the report is not done.
