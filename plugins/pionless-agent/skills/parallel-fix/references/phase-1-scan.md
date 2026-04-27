# Phase 1 — Find & Draft

**Goal: maximize recall.** Find every plausible issue within scope. The user prunes in phase 2 — your job is not to miss things. Err on the side of over-reporting. A thin queue means you scanned too timidly; redo it.

## Steps

### 1. Orient

Run, in order:

- `git rev-parse --show-toplevel`
- `git branch --show-current`
- `ls` of the project root
- read root `CLAUDE.md` if present
- `git status --short`

If `git status` shows uncommitted changes, **warn the user** that workers branch from HEAD and will not see those changes; recommend `git stash` before proceeding. Do not abort — let the user decide.

### 2. Scope, category, checklist

Parse the description and define three things explicitly. Write them into the queue-file header.

- **Scope** — the file or directory set to scan. Stay within what the description names; within scope, go deep.
- **Category** — one of: `security` / `bugs` / `performance` / `types` / `lint-cleanup` / `tests` / `docs` / `mixed`.
- **Checklist** — concrete items to look for. Seed by category from `references/checklist-by-category.md`. List **at least 6–10** items.

For `mixed` or unclear, build the checklist from the description plus your judgment.

### 3. Three-angle parallel scan

If the host supports spawning workers, in a **single message** spawn three scanning workers (e.g., the `Explore` subagent type with `thoroughness: "very thorough"`) over the same scope and checklist, each with a distinct angle. Pass the full scope plus checklist to each. Request structured output:

```
file:line | severity (high|med|low) | checklist item or angle | issue description
```

The three angles:

- **Angle A — Direct.** "Find every instance matching any checklist item within `<scope>`. Do not filter by confidence — flag low-confidence inline. Grep exhaustively for each item; do not stop at the first hit per file."
- **Angle B — Adversarial.** "You are an attacker, fuzzer, or malicious user. Within `<scope>`, find every place that breaks under hostile input, unexpected state, concurrent calls, partial failures, or edge cases the author did not anticipate. What would you exploit? What input crashes this? What invariant is assumed but not enforced? What happens on auth-expired, network-dropped, or half-written state?"
- **Angle C — Harsh reviewer.** "You are the strictest staff-level code reviewer. Within `<scope>`, flag everything that would fail your review: fragile patterns, hidden assumptions, subtle bugs, bad abstractions, inconsistent error handling, concurrency smells, API misuse, missing guards on public entrypoints. Assume the author is junior and missed things. Be ruthless; a passing review is the failure mode."

If the host does not support spawning workers, run the three angles sequentially in this thread. Quality should not degrade — only parallelism is lost.

### 4. Self-pass — what did they all miss?

After the three angles return, read the actual code in scope yourself. Ask: **"what did all three miss?"** Likely gaps:

- the same bug repeated across files — if they found one instance, grep the pattern and enumerate all of them,
- cross-file interaction bugs (A calls B with assumptions B does not meet),
- issues in adjacent config, build, migration, or CI files,
- boring-but-real items like missing validation on a public entrypoint,
- inverted or mismatched defaults.

Add your findings to the pool.

### 5. Merge, dedupe, classify

Combine A + B + C + self. Dedupe by `(file, line, issue-kind)`. Classify each as `high` / `med` / `low`. **Keep low-confidence findings** — prefix the `Issue` field with `[low-confidence]` so the user can prune in phase 2. Bias toward including, not excluding.

### 6. Thin-pool retry (capped)

If after merge the pool is noticeably smaller than the checklist suggested (e.g., ≤3 findings on a non-trivial scope), run **one** additional pass:

- add 2–3 more items to the checklist, or
- expand scope by one adjacent directory, and
- re-run angle C only.

Cap at one retry. If the pool is still thin, finalize as-is and flag "thin results" in the summary so the user knows.

### 7. Write the queue file

Derive a slug from the description (lowercase, dashes, ≤30 chars). Ensure `.claude/fix-queue/` exists (`mkdir -p`). Write the queue file at:

```
<project>/.claude/fix-queue/YYYYMMDD-HHMM-<slug>.md
```

Use `assets/queue-file-template.md` for the structure.

### 8. Stop

Print a compact summary — total tasks, severity breakdown, per-pass counts, path to the queue file — and **stop this turn**. Do not proceed to phase 3 yet.
