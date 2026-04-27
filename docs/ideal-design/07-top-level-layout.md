## 7. Top-Level Layout

> **Status: deferred.** This chapter is the synthesis of chapters 3–6. The current draft below was written before those chapters were finalized and references concepts (e.g. `src/contracts/`, `src/shared/` vs root `shared/`, `platforms/`) that are not yet pinned down upstream. Treat the contents as a working sketch, not a settled layout — revisit and rewrite once chapters 3–6 are finalized.

Once two lower-level decisions are fixed, most of the repository shape follows from them:

- a skill is a directory package;
- an agent is a single markdown definition.

The top-level layout should therefore be organized by **lifecycle first** and **runtime concept second**.

### First split: source vs generated

The most important boundary is between files humans author and files the build derives. Source-of-truth content should live under one authoring tree. Generated platform outputs, assembled plugin bundles, and normalized published skills should live elsewhere.

If source and generated files mix inside the same subtree, authors stop knowing where edits belong, reviews become noisy, and stale generated artifacts drift.

### Source tree

```text
repo-root/
  src/
    skills/
      quick-research/
        SKILL.md
        assets/
        references/
        scripts/
      deep-research/
      deep-research-pro/
      parallel-fix/
    agents/
      quick-research.md
      deep-research.md
      deep-research-pro.md
      deep-research-worker.md
      deep-research-verifier.md
      parallel-fix-worker.md
    contracts/
      quick-research.yaml
      deep-research.yaml
      deep-research-pro.yaml
      deep-research-worker.yaml
      deep-research-verifier.yaml
      parallel-fix-worker.yaml
    shared/
      fragments/
      templates/
      schemas/
```

This is the recommended authoring layout.

- `src/skills/` contains self-contained skill packages.
- `src/agents/` contains source-of-truth agent definitions.
- `src/contracts/` contains machine-readable companion contracts, keyed by the same basename as the agent they describe.
- `src/shared/` contains reusable fragments, templates, and schemas that should not belong to any one skill or agent.

Skills and agents should be siblings. They are different runtime concepts and deserve different top-level homes. Contracts should be a parallel tree, not hidden inside agent files or skill folders.

### Agent layout: keep it flat

The part that is easiest to overdesign is `src/agents/`. Do not make each agent a folder by default.

```text
src/agents/
  deep-research.md
  deep-research-pro.md
  quick-research.md
  deep-research-worker.md
  deep-research-verifier.md
  parallel-fix-worker.md
```

This is the right source layout for agents because the source-of-truth runtime object is one markdown file.

Folder nesting does not buy much here:

- An orchestrator/worker distinction is a runtime relationship, not a filesystem type.
- Nesting workers under one orchestrator couples a reusable worker to one parent.
- Splitting into `orchestrators/` and `workers/` freezes one role classification too early; an agent can be a main-session orchestrator in one context and a leaf worker in another.

When an agent needs related material, that material usually belongs somewhere else:

- reusable workflow knowledge belongs in a skill;
- a machine-readable output contract belongs in `src/contracts/`;
- test fixtures belong in `tests/`;
- helper scripts belong in `scripts/` or inside a skill if the skill owns the workflow.

Only introduce an agent folder if the source-of-truth agent format itself stops being single-file. Until then, flat files are the stable convention.

### Platform packaging layer

Platform-specific packaging metadata should live outside `src/`:

```text
platforms/
  claude-code/
    .claude-plugin/
  codex/
    .codex-plugin/
```

These directories hold platform scaffolding and packaging metadata. They do not replace `src/agents/` or `src/skills/` as the source of truth. A build may write generated agent files into platform-specific output directories, but humans should still edit the source definitions under `src/`.

### Generated outputs

The build may materialize several different outputs, each for a different purpose:

```text
shared/
  skills/                  # normalized published skill trees

dist/
  claude-plugin/
  codex-plugin/

plugins/
  pionless-agent/          # assembled repo-local installable bundle
```

The exact folder names can change. The important invariant is that these are all derived artifacts. If a file can be regenerated, it should not be the place humans edit.

### Recommendation

The repository should be grouped by runtime concept inside one authoring tree:

1. `src/skills/<name>/` for self-contained skill packages.
2. `src/agents/<name>.md` as a flat file set.
3. `src/contracts/<name>.yaml` for machine-readable companion contracts.
4. `src/shared/` for reusable fragments, templates, and schemas.
5. generated platform/package outputs outside `src/`.

This resolves the agent-layout question cleanly. Agents are not mini-packages at the source layer. They are single-file definitions, with contracts and other companions stored in parallel trees when needed.
