# Budget

This skill runs on a tight budget. Numbers are guidance, not hard caps; the host enforces.

- **Searches:** 5–10 calls.
- **Page reads:** 2–5.
- **Iterations:** one pass, plus at most one verification pass. No Ralph loop.

## Termination triggers

Stop and produce output when any of the following is true:

- The core claim has at least one primary source or two independent secondary sources.
- The budget is exhausted.
- The question is unanswerable from web sources within the budget — say so explicitly in the output.

Do not iterate further hoping for a better answer. If one pass plus verification did not resolve it, this is a deep-research case.
