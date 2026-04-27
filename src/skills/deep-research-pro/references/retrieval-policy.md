# Retrieval Policy

For each major subquestion, search from multiple angles. Pro-tier minimum is **3–5 query variants per major subquestion**.

## Required angles

- **Exact-match queries** — names, versions, dates, APIs, regulations, identifiers.
- **Semantic / paraphrase queries** — broader recall, alternate phrasings.
- **Contradiction-seeking queries** — try to disprove the current thesis. Required at this tier.
- **Site-specific queries** — target authoritative domains directly (`site:` operators or equivalent).
- **Temporal queries** — capture evolution over time, especially for fast-moving topics.

## Query design

- Lead with the most specific terms first.
- Quote multi-word entities to force exact matches when the search engine supports it.
- For temporal angles, include explicit year ranges or "before:/after:" filters when supported.
- For contradiction angles, search for "criticism of", "limitations of", "<claim> is wrong", "fails", "counterevidence".

## When to escalate angles

If the standard 5 angles return little, add domain-specific angles:

- For legal/regulatory: jurisdiction-specific queries, dissenting opinions, enforcement actions.
- For technical: changelog/issue-tracker queries, security advisory queries, deprecation notices.
- For market data: filings, earnings calls, third-party benchmark databases.

## Saturation handling

If 3 consecutive queries on the same subquestion yield no new evidence, mark the subquestion `saturated` on the plan board with the angles tried, then move on. Saturation is acceptable at the pro tier; thrashing is not.
