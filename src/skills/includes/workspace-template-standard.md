Use this internal structure for the workspace file. The YAML `loop_state` header is machine-readable and MUST be updated every iteration.

```markdown
---
loop_state:
  iteration: 1
  gate_passed: false
  gate_checklist:
    main_question_answered: false
    major_claims_sourced: false
    contradictions_checked: false
    uncertainty_explicit: false
    report_structured: false
  stale_iterations: 0
  total_searches: 0
  total_fetches: 0
  total_subagents: 0
---

# Research question
- [exact question]
- [decision context]
- [constraints]

# Plan Board
| # | Subquestion | Priority | Evidence Type | Assigned To | Status |
|---|-------------|----------|---------------|-------------|--------|

# Evolving report
- Current thesis: ...
- Confirmed findings: ...
- Contested findings: ...

# Immediate context
- Last step: ...
- Blocking: ...
- Next action: ...

# Open tasks
- [ ] ...
```
