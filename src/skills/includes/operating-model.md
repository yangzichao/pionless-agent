### 1. Initialize the research contract

Before searching deeply, pin down:

- the exact research question
- the decision the user is trying to make
- required output format
- time sensitivity
- constraints such as geography, budget, stack, or audience

If the user did not specify these, infer the smallest sensible contract and state the assumption briefly.

### 2. Build a Plan Board

Turn the problem into a compact task board with:

- the main question
- {SUBQUESTION_RANGE} subquestions
- priority for each subquestion
- expected evidence type for each subquestion
- blocking dependencies
- execution mode (parallel via subagent when available, otherwise sequential in the orchestrator)

Pick the next task by expected information gain, not by convenience. Prefer tasks that:

- close a major knowledge gap
- test a risky assumption
- add a new primary-source angle
- resolve a contradiction

### 3. Run worker-style investigations

Treat every subtask as a focused worker assignment with a narrow objective and explicit deliverable.

Each worker pass should return:

- findings
- evidence with provenance
- unresolved questions
- confidence level
- whether the result changes the overall thesis

Keep worker contexts isolated. Use the Agent tool to spawn subagents for independent tracks when available; otherwise run the same worker-style passes sequentially in the orchestrator. Do not drag the entire prior transcript into each subtask.

### 4. Reconstruct the workspace after each step

After each search, read, or synthesis step, rewrite the working state into only four blocks:

- `Research question`
- `Evolving report`
- `Immediate context`
- `Open tasks`

Definitions:

- `Research question`: the exact objective and constraints
- `Evolving report`: the best current draft, already cleaned and deduplicated
- `Immediate context`: only the facts, tensions, and next-step cues needed right now
- `Open tasks`: the remaining frontier on the Plan Board

Do not keep full raw history in the reasoning workspace. Full history can exist externally for audit, but the active context should stay compact.

### 5. Execute the Ralph loop

Repeat this loop until done:

1. Inspect the current workspace.
2. Choose the highest-value open task (or batch independent tasks for parallel subagents when available).
3. Gather or verify evidence (directly, or via subagent workers when supported).
4. Update the evolving report.
5. Run quality checks.
6. Reconstruct the workspace.

Do not stop just because there is enough text. Stop when the report is {COMPLETION_STANDARD}.
