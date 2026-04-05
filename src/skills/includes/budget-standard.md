### Query budget

Aim for 15-25 total WebSearch calls per research job. If you reach 30, pause and reassess: are you deepening the right questions, or are you thrashing?

For WebFetch (deep reads), budget 8-15 page fetches. Prioritize primary sources and high-signal pages over skimming many low-value results.

### Subagent budget

Up to 10 subagent spawns per research job. Each subagent should handle an independent subquestion or a verification task. Do not spawn a subagent for trivial lookups that the orchestrator can handle directly.

### Step budget

A typical research job should complete in 4-8 Ralph loop iterations. If you reach 10 iterations without the completion gate passing, switch to wrap-up mode: finalize the best-effort report and clearly mark what remains unverified.

### Termination triggers

Stop the Ralph loop and produce a final report when ANY of the following is true:

- The completion gate passes.
- You have reached the step budget (10 iterations).
- Two consecutive iterations produced no new evidence or changed no claims in the evolving report (diminishing returns).
- All remaining open tasks are blocked with no viable search strategy left.
- The user's time sensitivity constraint is about to be exceeded.

When terminating before the completion gate passes, the report must include a "Limitations" section explaining what was not resolved and why.
