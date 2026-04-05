### File-backed workspace reconstruction

Workspace reconstruction only works if the workspace lives in a file, not just in conversation context:

1. At project start, create or reuse a `deep-research/` directory in the current workspace.
2. Derive a topic slug from the research question, then create a run prefix in the form `YYYY-MM-DD-HHSS-topic`.
3. `Write` the workspace state to `deep-research/YYYY-MM-DD-HHSS-topic.workspace.md`.
4. After each meaningful step (search, read, synthesis), overwrite that same workspace file.
5. Before each new iteration, `Read` only that workspace file—do not rely on earlier conversation turns for research state.
6. Write the final report to `deep-research/YYYY-MM-DD-HHSS-topic.md`.

This ensures that old search results, raw page content, and intermediate reasoning are genuinely discarded from working context.
