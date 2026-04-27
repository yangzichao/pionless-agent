## Skills vs Subagents

Skills ([ch 01](01-skill-anatomy.md)) and subagents ([ch 02](02-agent-anatomy.md)) sit close enough that authors routinely pick the wrong one. This chapter is the side-by-side so the choice is obvious.

### Side-by-side

| Axis | Skill | Subagent |
|---|---|---|
| Form | Directory package (`SKILL.md` + companions) | Single `.md` file |
| Runtime | None of its own — attaches to a caller's session | Spawned as its own session via the `Agent` tool |
| Context | Lives inside the caller's context | Isolated context; sees only its prompt + tool results |
| Output | The caller does the work; no separate return value | Returns a summary string to its parent |
| State | Stateless workflow knowledge | Owns a conversation while it runs |
| Identity | Not an actor — a manual the actor reads | An actor with its own model, tools, system prompt |
| Composition | A subagent or main session loads it via `skills:` | A parent spawns it via `Agent` |

### When to pick which

- Pick a **skill** when the unit is *how to do something*. The work happens in the caller's context with the caller's tools.
- Pick a **subagent** when the unit is *do it and hand back a result*. The parent should not see the intermediate context.
- Pick **both** when the work genuinely needs both — e.g. a research subagent that loads a research skill at startup. The subagent gives isolation and a summarized return; the skill gives the procedure.
