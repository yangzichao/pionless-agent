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
    contradiction_pass_completed: false
    uncertainty_explicit: false
    methodology_section_present: false
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
- Confirmed findings (with source count): ...
- Contested findings: ...
- Contradictions found: ...

# Immediate context
- Last step: ...
- Blocking: ...
- Next action: ...
- Subagent status: ...

# Open tasks
- [ ] ...
```
