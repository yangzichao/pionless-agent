# Math and Notation Rules

When the answer includes formulas, code, or symbolic notation, preserve characters exactly through Markdown rendering.

- Do not accidentally rewrite or strip `$`, `\`, `_`, `^`, `{}`, `[]`, or `*` when they are part of notation.
- Prefer fenced code blocks for literal formulas, pseudo-LaTeX, or syntax examples that must not be interpreted by Markdown.
- Use inline math only when the renderer is likely to support it; otherwise present the expression in backticks or a fenced block so the formula survives intact.
- If a sentence mixes prose and notation, check the final text to ensure currency symbols, shell variables, and math delimiters are not confused with each other.
