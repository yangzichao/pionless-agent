# Plan Board

Turn the research contract into a compact task board.

## Required fields

- The main question.
- 5–12 subquestions.
- Priority for each subquestion (high / med / low).
- Expected evidence type (primary doc, benchmark, market data, regulatory filing, etc.).
- Blocking dependencies between subquestions.
- Depth target per subquestion (see `references/depth-policy.md`).
- Execution mode (parallel via worker spawn when host supports it; sequential otherwise).

## Selecting the next task

Pick by **expected information gain**, not convenience. Prefer tasks that:

- close a major knowledge gap,
- test a risky assumption,
- add a new primary-source angle,
- resolve a contradiction,
- expose a minority viewpoint that has not yet been examined.

## Updating the board

The plan board is part of the persisted workspace file. Update it after every step:

- mark completed subquestions with their finding and confidence,
- promote follow-up tasks discovered during investigation,
- demote tasks that turned out to be lower-value than predicted,
- mark `saturated` (with reason) when 3 consecutive searches yield no new evidence.

## Subquestion range for this tier

Pro tier: aim for **5–12 subquestions**. Fewer means the question fits the standard tier (`deep-research`). More usually means scope creep — split into two pro-tier jobs rather than running one with 15+ subquestions.
