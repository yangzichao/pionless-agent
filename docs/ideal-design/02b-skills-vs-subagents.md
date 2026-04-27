## Skills vs Subagents

> A skill is a workflow package the caller reads; a subagent is a runtime the parent spawns.

Skills ([ch 01](01-skill-anatomy.md)) and subagents ([ch 02](02-agent-anatomy.md)) sit close enough that authors routinely pick the wrong one. The structural distinction is who owns the runtime: a skill never does — it injects workflow knowledge into the caller's existing session and the caller executes the procedure — while a subagent always does, because it is launched as its own session via the `Agent` tool, runs in an isolated context with its own model and tools, and returns only a summary to its parent. A skill makes the caller more capable in place; a subagent peels off a side conversation, runs to completion, and hands back a result. Most "should this be a skill or an agent?" questions resolve once you ask: does the work need to happen *in* the caller's context, or *away* from it?

### Side-by-side

| Axis | Skill | Subagent |
|---|---|---|
| Form | Directory package (`SKILL.md` + companions) | Single `.md` file |
| Runtime | None of its own — attaches to the caller's session | Spawned as its own session via the `Agent` tool |
| Context | Lives inside the caller's context | Isolated context; sees only its prompt + tool results |
| Output | The caller does the work; no separate return value | Returns a summary string to its parent |
| State | Stateless workflow knowledge | Owns a conversation while it runs |
| Identity | Not an actor — a manual the actor reads | An actor with its own model, tools, system prompt |
| Composition | A caller loads it via `skills:` in frontmatter; the host activates it when its `description` matches the situation | A parent spawns it via the `Agent` tool when its logic decides to delegate |

### When to pick which

- Pick a **skill** when the unit is *how to do something*. The work happens in the caller's context with the caller's tools.
- Pick a **subagent** when the unit is *do it and hand back a result*. The parent should not see the intermediate context.
- Pick **both** when the work genuinely needs both — e.g. a research subagent that loads a research skill at startup. The subagent gives isolation and a summarized return; the skill gives the procedure.
