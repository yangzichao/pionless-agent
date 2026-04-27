# Safety Rules

## Repository

- Never push.
- Never force-push.
- Never rewrite history on the working branch.
- Never modify the user's git config.

## Worktrees and branches

- Always remove the worktree and delete the worker's branch after merge or terminal failure (`references/phase-4-merge.md`).
- After all chains complete, run `git worktree list` as a sanity check; surface any leftovers to the user.
- If a worktree cannot be removed cleanly, surface the path; do not silently leave it.

## Stranded dispatch

If a previous run was interrupted, rows may be left in `dispatched` state without a worker result. Phase 3's first action is to recover these — never silently skip them. See `references/phase-3-dispatch.md`.

## Interruption

If the user Ctrl-C's mid-dispatch, leftover worktrees may remain. Note this in the output so the user can run `git worktree list` and clean up manually. Do not assume the harness handled cleanup.

## Project state

- If the working tree has uncommitted changes at phase 1, warn the user; recommend `git stash`. Do not abort.
- If the project lacks a recognized toolchain at phase 5, surface this and skip the final check rather than guessing.

## Output discipline

- Always update the queue-file status column at every transition. The file is the user's live log.
- Use compact Markdown tables; avoid walls of prose.
- End each run with a one-paragraph executive summary: counts by final status plus the path to the queue file.
