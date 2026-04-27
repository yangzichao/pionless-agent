# Output Conventions

When the host supports file writes and the project uses the `deep-research/` convention, follow this layout.

## Directory

All research output goes into a `deep-research/` directory at the project root. Create it if it does not exist.

## Filename

Standalone reports:

```
deep-research/YYYY-MM-DD-HHMM-<topic>.md
```

Where:

- `YYYY-MM-DD` is the current date.
- `HHMM` is the current hour and minute (24h, no separator).
- `<topic>` is a short lowercase hyphenated slug derived from the research question.

Example: `deep-research/2026-04-26-1530-react-vs-vue.md`

## Forbidden

- Writing to the project root.
- Arbitrary names like `report.md` or `output.md`.
- Paths outside `deep-research/`.

## Subagent mode

In subagent mode, the parent orchestrator owns file writes. Return findings inline using `assets/report-template-subagent.md`; do not write a file unless the parent's task card explicitly asks for one.

## Host without write access

If the host has no file-write tool, return the report inline in the conversation. State explicitly that it was not persisted.
