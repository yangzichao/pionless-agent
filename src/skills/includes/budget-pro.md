### No hard budget

This tier has **no hard limits** on queries, page reads, or iterations. Go as deep as the evidence requires.

However, maintain efficiency discipline:

- Do not repeat searches that have already been exhausted.
- Track diminishing returns: if 3 consecutive searches on the same subquestion yield no new evidence, mark it as saturated and move on.
- Prefer depth on high-value questions over breadth on low-value ones.

### Termination triggers

Stop the Ralph loop and produce a final report when ANY of the following is true:

- The completion gate passes.
- All subquestions are either answered with high confidence or marked as genuinely unanswerable with current sources.
- The user explicitly requests completion.
- The user's time sensitivity constraint is about to be exceeded.

When terminating, the report must include a "Limitations" section for any gaps that remain.
