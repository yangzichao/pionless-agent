# Efficiency Discipline

The pro tier has **no hard budgets** on queries, fetches, or iterations. Discipline still applies.

## Saturation

If 3 consecutive searches on the same subquestion yield no new evidence, mark the subquestion `saturated` on the plan board and move on. Record the angles tried so a later pass can revisit if needed.

## Diminishing returns

If two consecutive Ralph iterations produced no new evidence and changed no claims, this is a signal to:

- promote different subquestions on the plan board,
- shift to the contradiction-seeking pass,
- or finalize.

## Depth vs breadth

Prefer depth on high-value questions over breadth on low-value ones. A 3-source resolution of a decision-critical claim beats a single-source touch on five peripheral claims.

## Termination triggers (despite no hard budget)

Stop the Ralph loop and finalize when **any** of the following is true.

- The completion gate passes.
- Every subquestion is either answered with the required confidence or marked as genuinely unanswerable with current sources.
- The user explicitly requests completion.
- The user's time-sensitivity constraint is about to be exceeded.

When terminating before the gate passes, the report **must** include a `Limitations` section explaining what was not resolved and why.
