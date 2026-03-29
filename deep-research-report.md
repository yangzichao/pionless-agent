# Building a High-Performance Deep Research Agent Using Orchestrator–Worker, Ralph Loop, and IterResearch Workspace Reconstruction

## Executive summary

A “super capable” deep research agent is best engineered as a **closed-loop, multi-agent distributed system** where (a) an **orchestrator** continuously decomposes work and delegates to specialized **worker agents**, (b) progress is driven by a **durable iterative harness** (a *Ralph Loop*-style repeat-until-done control loop), and (c) the agent’s *effective* reasoning context is kept **bounded and clean** via **IterResearch-style workspace reconstruction**—a Markovian state design that retains only the research question, an evolving report, and minimal “immediate context” from the last step. This directly targets the core failure modes of long-horizon research agents: context-window suffocation and noise contamination. citeturn17view3turn3view0turn3view1

At the architectural level, the most reliable pattern is a **hierarchical orchestrator–worker loop**: the orchestrator maintains a **Plan Board** (a structured, searchable task graph), runs **hybrid deep retrieval** (vector + symbolic) through a dedicated retrieval service, and continuously **reconstructs a workspace** after each tool/worker interaction. Orchestrator–worker patterns are explicitly recommended when subtasks can’t be known ahead of time and must be decided dynamically, and are widely used for deep research because they enable parallel, specialized exploration and synthesis. citeturn4view0turn4view1turn3view1turn16view1

The critical engineering insight is to separate:

- **Durable full history for audit/observability** (stored externally), from  
- **Bounded “cognitive workspace” for each reasoning step** (fed to models), per IterResearch’s reconstructed-state design. citeturn17view3turn5view2

This yields a system that can scale to deeper interaction horizons without degrading the agent’s reasoning capacity, consistent with IterResearch’s reported interaction scaling and its explicit state definition. citeturn3view0turn5view2

### Explicit assumptions

- **“Palph Loop” is interpreted as “Ralph Loop.”** Web evidence strongly supports “Ralph Loop” as the widely referenced iterative stop-hook loop for agentic development, including an Anthropic-verified plugin and an official Claude Code plugin README describing the technique. No credible agent-architecture references to “Palph Loop” were found. citeturn3view4turn3view3turn1search1  
- Programming language, infrastructure, and datasets are **unspecified**, so this report provides **design choices + alternatives** (with tradeoffs) rather than hard-binding to a single stack.  
- The target is a **research/report agent** (not a transaction agent). Therefore, **citations, cross-references, and long-horizon iteration** are first-class requirements, aligned with DeepResearch Bench evaluation dimensions that explicitly include citation quality. citeturn17view2turn12search4

## System architecture

### Architecture diagram

```mermaid
flowchart TB
  U[User / Client UI] --> API[API Gateway]
  API --> J[Research Job Service]

  subgraph ControlPlane[Control Plane]
    J --> ORCH[Orchestrator (Lead Researcher)]
    ORCH --> PB[Plan Board Store<br/>(task DAG + priorities)]
    ORCH --> WR[Workspace Reconstructor<br/>(IterResearch-style)]
    ORCH --> SYN[Synthesis & Minto Writer]
    ORCH --> QC[Quality Gates<br/>(cross-ref + eval)]
    QC -->|done| SYN
    QC -->|not done| RL[Run Harness<br/>(Ralph Loop controller)]
    RL --> ORCH
  end

  subgraph WorkerPlane[Worker Plane]
    ORCH --> Q[Task Queue / Scheduler]
    Q --> W1[Worker: Web/Corpus Search]
    Q --> W2[Worker: Scholar/Patent/Regulatory]
    Q --> W3[Worker: Data/Code/Math]
    Q --> W4[Worker: Claim Verification / Contradiction]
    Q --> W5[Worker: Domain Specialist]
  end

  subgraph Retrieval[Deep Retrieval Layer]
    W1 --> RET[Retrieval Service API]
    W2 --> RET
    W4 --> RET
    RET --> LEX[Lexical/Symbolic Retrieval<br/>BM25 / filters / KG queries]
    RET --> VEC[Vector Retrieval<br/>DPR/Embeddings/ANN]
    RET --> FUSE[Rank Fusion + Normalization<br/>RRF / weighted fusion]
    RET --> RERANK[Reranker<br/>cross-encoder / LLM rerank]
    RERANK --> EVID[Evidence Store<br/>(chunks + metadata + provenance)]
  end

  subgraph State[State & Observability]
    EVID --> OBS[Tracing/Telemetry + Audit Log]
    PB --> OBS
    WR --> WS[Workspace State Store<br/>(Question + Evolving Report + Immediate Context)]
    WS --> OBS
  end

  SYN --> OUT[Final Report + Citations]
  OUT --> API --> U
```

This diagram formalizes three nested loops:

- **Orchestrator–worker loop**: Generate subtasks → dispatch workers → aggregate results → repeat. This matches standard orchestrator–worker definitions used in multi-agent orchestration guidance and deep research implementations. citeturn4view0turn4view1turn3view1turn16view1  
- **Workspace reconstruction loop**: After each interaction, rebuild the minimal workspace state (question + evolving report + immediate context), explicitly aligned to IterResearch’s Markovian state design and structured “Think, Report, Action” decision. citeturn17view3turn5view2  
- **Ralph Loop harness**: A repeat-until-completion control mechanism that restarts/continues iterations with preserved artifacts, analogous to the stop-hook “re-feed the same prompt until DONE” technique described in Ralph Loop references. citeturn3view4turn3view3  

### Component responsibilities and boundaries

The orchestrator should do **coordination and stateful decision-making**, not raw searching. This mirrors deep research systems where a lead agent spawns subagents (often in parallel) and synthesizes findings, while subagents act as “intelligent filters” using search tools. citeturn3view1turn4view2

Key responsibilities:

- **Orchestrator**: maintain Plan Board; choose next tasks via Plan-Board Search; enforce budgets; assemble citations; trigger reconstruction and quality gates.  
- **Workers**: execute scoped tasks with isolated context; return structured findings with provenance; do not own global state. This matches the “specialization + parallelization + result synthesis” rationale for orchestrator–worker. citeturn4view0turn4view1  
- **Workspace Reconstructor**: compress and filter raw findings into an evolving report; ensure bounded prompt context as in IterResearch. citeturn5view2turn17view3  
- **Retrieval Service**: provide hybrid retrieval, rank fusion, reranking, evidence chunking, and provenance capture. Hybrid lexical+semantic retrieval is recommended because lexical search excels at exact matches and interpretability while vector search captures meaning; hybrid approaches combine strengths. citeturn16view3turn9search2turn9search3  
- **Quality gates**: cross-reference and claim verification loops; detect contradictions; enforce citation accuracy constraints (important because deep research benchmarks explicitly score citation quality). citeturn17view2turn10search0  

### Alternatives comparison tables

#### Orchestration runtime options

| Option | Why you’d choose it | Tradeoffs | Fit for this design |
|---|---|---|---|
| Graph-based orchestration (LangGraph-style) | Natural for orchestrator–worker graphs; supports dynamic worker fan-out (Send-style) and shared state aggregation; commonly used for orchestrator–worker workflows. citeturn4view1turn8view0 | Requires graph-thinking; debugging needs good tracing | Excellent for dynamic research DAGs |
| Durable workflow engine (Temporal / Durable Functions / Step Functions) | Strong durability, retries, timers, backpressure; great for long-horizon jobs | More engineering overhead; LLM tool-calling integration is DIY | Excellent for enterprise-grade reliability |
| “Agent harness” framework (Deep Agents-style) | Bundles planning, subagents, file-backed context, and durability features via runtime; promotes tool boundary enforcement at sandbox/tool layer. citeturn8view0turn8view2 | Opinionated; may constrain custom scheduling or state schema | Great for MVP → then harden |

#### Retrieval architecture options

| Option | Core idea | Pros | Cons | When to pick |
|---|---|---|---|---|
| Classic sparse first-stage (BM25) | Lexical scoring from Probabilistic Relevance Framework; strong for exact terms/IDs | Fast; interpretable; robust across domains citeturn6search1turn16view3 | Misses semantic paraphrases | Always include as baseline |
| Dense bi-encoder (DPR / embeddings) | Retrieve by vector similarity; good semantic recall | Strong open-domain performance; ANN-scalable citeturn6search2turn6search14 | Can miss exact-match constraints; embedding drift | Use for semantic breadth |
| Late-interaction retrieval (ColBERT) | Token-level matching with late interaction | Better relevance than pure bi-encoder in many settings citeturn6search3turn6search7 | Heavier infra than simple embeddings | Use for high-precision corpora |
| Learned sparse expansion (SPLADE) | Neural sparse vectors for inverted-index retrieval | Bridges lexical matching + neural generalization citeturn9search1turn9search5 | More training/ops complexity | Use when you want “symbolic-ish” speed with neural power |
| Hybrid retrieval + rank fusion (recommended) | Run sparse + dense, then fuse (RRF/weighted) | Robust across query types; reduces single-model failure citeturn9search0turn16view3 | More moving parts; needs score normalization | Default for deep research |

#### State store options for bounded workspace + audit

| Layer | Recommended storage pattern | Why |
|---|---|---|
| Workspace state (IterResearch) | **Structured document store** (e.g., Postgres JSONB / DynamoDB) for `(question, evolving_report, immediate_context, plan_board_pointer)` | Fast reads/writes each step; easy versioning; fits Markovian state definition. citeturn17view3turn5view2 |
| Evidence store | Object store + metadata index (URL, hash, chunk ids, timestamps) | Separates heavy content from state; supports provenance and dedupe |
| Audit log / trace | Append-only event log (Kafka / Kinesis / Postgres events) | Keep full history externally while keeping prompts bounded—key to reconciling IterResearch minimal workspace with enterprise observability needs. citeturn17view3turn8view0 |

## Core methods and algorithms

### Plan-Board Search

**Goal:** turn “planning” into a **search problem over a task graph**, where the orchestrator continually chooses the next best tasks given time/cost budgets and current knowledge gaps.

This is inspired by deep research agents that explicitly plan with todo-lists and adapt plans as new info emerges. citeturn4view2turn8view0

**Plan Board data model (conceptual):**

- Nodes: *Task cards* (objective, queries, expected artifacts, dependency links, budget).
- Edges: dependencies (“must do before”), and evidence links (“task produced evidence used by …”).
- A *frontier*: tasks ready to execute.
- Priority heuristic: expected value of information (VOI) / risk / novelty / coverage.

**Heuristic design (actionable):**
- **Coverage gain**: does this task fill an explicit gap in the evolving report?
- **Source diversity gain**: does it add a new type of primary source (standard, paper, official doc)?
- **Contradiction risk**: is a key claim supported by only one source?
- **Cost**: estimated tokens, tool calls, time.
- **Staleness**: for time-sensitive domains, prefer recent sources (DeepResearch systems are judged partly on reliability and citations). citeturn17view2

### Deep retrieval

Deep research retrieval should be **multi-stage**:

1. **Generate multiple query candidates** (per Plan Board task), including:
   - keyword/exact queries (symbolic),
   - semantic paraphrases (vector),
   - “negated” queries for contradiction hunting (verification).  
2. **Retrieve using both sparse and dense**:
   - BM25/BM25F for lexical match citeturn6search1turn16view3  
   - Dense retrieval (DPR/embeddings) for semantic match citeturn6search2turn6search14  
3. **Fuse rankings**:
   - Reciprocal Rank Fusion (RRF) is a simple, strong baseline for combining ranked lists. citeturn9search0  
   - If your backend supports hybrid scoring, ensure global score normalization before combining (a known issue in distributed search). citeturn16view3turn9search3  
4. **Rerank top-K**:
   - Cross-encoder reranking (BERT reranking) is a standard second stage that improves ranking quality, at higher compute cost. citeturn7search2turn7search5  
5. **Extract evidence chunks + provenance**:
   - Store `(source_id, url, title, timestamp, chunk_text, offsets, hash)`; enforce dedupe by content hash.

### Workspace reconstruction

IterResearch provides a precise blueprint:

- State = **workspace** comprising `(question, evolving report, immediate context)` citeturn17view3turn5view2  
- Each step produces a structured decision with **(Think, Report, Action)** citeturn17view3turn5view2  
- Transition reconstructs workspace by **discarding history** and keeping only those essential elements, preventing context blowup. citeturn17view3turn5view2  

**Engineering adaptation (important):**  
You can still store the full interaction history in an audit log; you just **don’t feed it back** into the model context. This keeps enterprise observability without breaking the “bounded cognitive workspace” principle.

### Iterative deepening

Treat research like a search tree and use **iterative deepening** to control depth and cost. In classical AI, depth-first iterative deepening is valued for strong space properties and “optimal admissible” behavior under assumptions. citeturn7search0turn7search3

**Practical mapping to research:**
- Depth 0: outline + source plan + definitions
- Depth 1: fill main claims with ≥2 independent sources
- Depth 2: drill into contested/critical claims, standards, numeric estimates
- Depth 3+: long-horizon exploration (literature review level), only if budgets allow

This naturally aligns with workspace reconstruction: each deepening step updates the evolving report and resets noise.

### Cross-reference and verification strategies

Deep research systems are evaluated on citation trustworthiness; DeepResearch Bench explicitly defines a retrieval/citation framework (FACT) and a report-quality framework (RACE). citeturn17view2turn12search4

Actionable cross-reference strategies:

- **Triangulation rule**: “important claim” must be supported by **two independent sources** (different orgs/domains).  
- **Claim graphing**: extract atomic claims → attach evidence chunks → run entailment/contradiction checks.  
- **Evidence retrieval for verification**: FEVER formalizes claim verification as supported/refuted/NEI with evidence sentences. citeturn10search0turn10search8  
- **Post-hoc research-and-revise**: RARR retrieves evidence *after* generation and revises text to align with evidence, emphasizing attribution. citeturn10search6turn10search18  
- **Self-consistency hallucination checks**: SelfCheckGPT uses sampling-based inconsistency signals for hallucination detection in black-box settings. citeturn10search1turn10search17  

### Synthesis into Minto Pyramid prose

Barbara Minto’s Pyramid Principle is a widely used executive communication structure: **start with the answer**, then provide grouped supporting arguments, then details. (Primary reference: Minto’s book metadata is publicly archived; many modern explainers exist, but the core idea is “answer first.”) citeturn7search10turn7search1

**Operationalizing Minto inside the agent:**
- Top: the single best answer (or decision recommendation).
- Next layer: 3–5 MECE “key pillars”.
- Next: evidence blocks per pillar (with citations).
- Appendices: extended sources, tables, method notes.

## APIs, data schemas, and state management

### Public API surface

A minimal, production-usable API set:

- `POST /v1/research/jobs`  
  Creates a research job with constraints.

- `GET /v1/research/jobs/{job_id}`  
  Returns job status, current workspace snapshot, and artifact pointers.

- `POST /v1/research/jobs/{job_id}:iterate`  
  Triggers one controlled iteration (useful for HITL or debugging).

- `GET /v1/research/jobs/{job_id}/report`  
  Returns the latest report draft + citations.

- `POST /v1/research/jobs/{job_id}:finalize`  
  Runs final quality gate + Minto synthesis and returns final report.

### Internal service APIs

- `POST /v1/retrieval/query`  
  Input: query bundle (lexical + vector), filters, desired k.  
  Output: ranked evidence candidates with provenance.

- `POST /v1/workers/dispatch`  
  Input: worker role + task payload + allowed tools.  
  Output: structured worker result.

- `POST /v1/verify/claims`  
  Input: claims + evidence candidates  
  Output: support/refute/uncertain labels + confidence.

### Core data schemas

Below are compact JSON-style schemas (illustrative; implement as OpenAPI/JSONSchema in code).

**ResearchJob**
```json
{
  "job_id": "uuid",
  "created_at": "iso8601",
  "status": "queued|running|blocked|succeeded|failed",
  "user_request": {
    "question": "string",
    "constraints": {
      "time_budget_s": 1200,
      "cost_budget_usd": 5.0,
      "min_source_count": 12,
      "source_preferences": ["primary", "official", "peer_reviewed"]
    }
  },
  "workspace_head": "workspace_version_id",
  "artifacts": {
    "report_md": "object://.../report.md",
    "citations_json": "object://.../citations.json"
  }
}
```

**WorkspaceState (IterResearch-compatible)**
```json
{
  "workspace_version_id": "uuid",
  "question": "string",
  "evolving_report": {
    "executive_summary": "string",
    "key_findings": [{"claim_id": "c1", "text": "..." }],
    "open_questions": ["..."],
    "assumptions": ["..."],
    "glossary": [{"term": "...", "definition": "..."}]
  },
  "immediate_context": {
    "last_action": {"type": "tool_call|worker_task|finalize", "payload": {}},
    "last_observation": {"summary": "string", "evidence_ids": ["e1","e2"]}
  },
  "plan_board_ref": "plan_board_version_id",
  "budgets": {"step": 17, "max_steps": 200, "remaining_cost_usd": 1.40}
}
```
This structure is a direct engineering translation of IterResearch’s explicit “question + evolving report + immediate context” workspace definition. citeturn17view3turn5view2

**PlanBoard**
```json
{
  "plan_board_version_id": "uuid",
  "tasks": [
    {
      "task_id": "t12",
      "title": "Find primary docs on X",
      "status": "todo|doing|done|blocked",
      "priority": 0.82,
      "depends_on": ["t3"],
      "queries": [
        {"type": "lexical", "q": "\"standard name\" site:org"},
        {"type": "semantic", "q": "paraphrase of goal"}
      ],
      "acceptance_criteria": [
        "At least 2 independent primary sources",
        "Extract definitions + dates + scope"
      ],
      "outputs": {"evidence_ids": [], "claim_ids": []}
    }
  ]
}
```

**EvidenceChunk**
```json
{
  "evidence_id": "e123",
  "source": {
    "url": "string",
    "title": "string",
    "publisher": "string",
    "published_at": "iso8601|null",
    "retrieved_at": "iso8601",
    "content_hash": "sha256"
  },
  "chunk": {
    "text": "string",
    "offsets": {"start": 1200, "end": 1800},
    "tokens": 240
  },
  "tags": ["primary", "peer_reviewed", "standard"],
  "quality": {"ocr": false, "extraction_confidence": 0.93}
}
```

### State management strategy

A robust approach is **dual-state**:

- **Prompt state (bounded)**: WorkspaceState only (IterResearch). citeturn17view3turn5view2  
- **System state (complete)**: event log of every tool call, worker output, and intermediate artifact for debugging, reproducibility, and evaluation—without polluting model context.

Durability and resilience best practices include checkpointing and retries; for example, Deep Agents documentation explicitly recommends pairing retries with checkpointing for long-running tasks on unreliable networks. citeturn8view3turn8view0

## Reliability, fault tolerance, deployment, and scaling

### Fault tolerance patterns

Deep research agents fail in messy ways: network timeouts, 429 rate limits, search API flakiness, and partial tool failures. Your design should assume this and make progress **idempotent and resumable**.

Key mechanisms:

- **Checkpoint every iteration**: store WorkspaceState + PlanBoard version and an immutable event record. Deep Agents guidance notes model clients retry with exponential backoff and recommends checkpointing to preserve progress in long tasks. citeturn8view3turn8view0  
- **Idempotent task execution**: deterministic `task_id` + `attempt` + `inputs_hash` so reruns don’t duplicate evidence or citations.  
- **Circuit breakers** for tools: if a search provider degrades, fall back to alternative retrievers or cached corpora.  
- **Graceful degradation**: if deep verification fails, still return best-effort report with explicit uncertainty labels and an “unverified claims” appendix.

### Scaling model: token and concurrency economics

Multi-agent systems scale capacity but consume significantly more tokens; Anthropic reports multi-agent systems using far more tokens than single chat interactions and notes this tradeoff for economic viability. citeturn3view1

Scaling tactics:

- **Parallelize only high-VOI tasks**: orchestrator–worker pattern encourages parallelization, but uncontrolled fan-out explodes cost. citeturn4view0turn16view1  
- **Adaptive depth**: iterative deepening (depth limits) prevents “runaway research.” citeturn7search0turn7search3  
- **Cache embeddings and page fetches** by URL hash; dedupe evidence globally.  
- **Rerank selectively**: rerank only top 50–200 candidates and only for tasks flagged “high stakes.”

### Deployment plan

A pragmatic deployment progression:

- **MVP (single-tenant)**: one orchestrator service + worker pool + retrieval service + Postgres (state) + object store (evidence).  
- **V1 (multi-tenant)**: per-tenant namespace isolation in state/evidence; rate limits; tenant-keys; audit logs.  
- **V2 (enterprise)**: dedicated workflow engine (Temporal/Step Functions), policy-enforced tool sandboxing, SSO integration, and formal evaluation pipelines.

If using a “Ralph Loop” style harness, implement it as a **job runner** that repeatedly triggers the next iteration until completion criteria are met—mirroring the “repeat until completion promise or max iterations” behavior described in Ralph Loop references. citeturn3view4turn3view3

## Security and privacy considerations

### Threat model highlights for deep research agents

Deep research agents are especially exposed to:

- **Prompt injection** (direct and indirect through retrieved documents), which can manipulate agent behavior and tool use. OWASP explicitly highlights prompt injection risks and notes that RAG/fine-tuning do not fully mitigate them. citeturn13search5turn13search17  
- **Excessive agency**: workers with broad tool permissions can exfiltrate data or mutate systems. Deep Agents’ security stance emphasizes enforcing boundaries at the tool/sandbox level rather than expecting the model to self-police. citeturn8view2  
- **Tool-protocol risks (MCP)**: token passthrough, SSRF, confused deputy issues, and local server compromise are explicitly documented with concrete mitigations in MCP security guidance. citeturn17view0  
- **AI system risk governance**: NIST AI RMF provides a governance-to-operations framework for managing AI risks (security, privacy, reliability, accountability). citeturn13search2turn13search26  
- **Adversarial tactics**: MITRE ATLAS catalogs real-world tactics/techniques against AI systems, useful for red teaming. citeturn13search1  

### Concrete controls

Principle: **least privilege per agent role** + **tool boundary enforcement**.

- **Tool allowlists per worker**: e.g., “Scholar worker” cannot call file-write tools; “Data worker” cannot browse web; “Verification worker” cannot access internal KB.  
- **Network egress controls**: retrieval service can fetch only via safe HTTP client with SSRF protections; block cloud metadata IPs (MCP security docs explicitly call out metadata endpoint risks in SSRF scenarios). citeturn17view0  
- **Credential isolation**: use short-lived tokens; never allow “token passthrough” where clients provide arbitrary downstream tokens (explicitly identified as forbidden in MCP security guidance). citeturn17view0  
- **Prompt-injection hardening**:  
  - Strip executable instructions from retrieved text before feeding into decision prompts.  
  - Use a “tool firewall”: the orchestrator validates tool calls against policy (“why needed?”, “what data leaves boundary?”).  
- **Privacy**:  
  - Data minimization in prompts (only what’s needed for current iteration—reinforced by IterResearch minimal workspace). citeturn17view3  
  - PII redaction in logs and evidence stores; tenant encryption-at-rest.

## Evaluation plan with metrics, experiments, and an end-to-end example

### Evaluation metrics

A strong plan combines **end-to-end deep research benchmarks** + **component metrics**.

**End-to-end report quality and citation trustworthiness**
- **DeepResearch Bench**: 100 PhD-level tasks across 22 fields; provides two complementary evaluation frameworks: **RACE** (report quality) and **FACT** (retrieval effectiveness + citation accuracy). citeturn17view2turn12search4  
- Track the same (or aligned) dimensions in internal evals: comprehensiveness, insight depth, instruction following, readability, citation accuracy, effective citations. citeturn12search6turn17view2  

**Retrieval quality**
- **nDCG-style ranking** is grounded in cumulated-gain evaluation methods from IR literature. citeturn15search1  
- **MRR** is appropriate when users “need one correct hit fast”; useful for “find the source” subtasks. citeturn15search2turn15search26  

**Factuality and verification**
- FEVER-style supported/refuted/NEI scoring for extracted claims. citeturn10search0turn10search8  
- SelfCheckGPT-style consistency signals for hallucination risk flags (especially useful when external evidence is sparse). citeturn10search1turn10search17  
- RARR-style *attribution-preserving revision success* (did revision reduce unsupported claims while keeping structure/style). citeturn10search6turn10search18  

**Efficiency**
- Cost per report, tool calls per accepted claim, time-to-first-draft, time-to-final, and “depth achieved under budget.” IterResearch explicitly argues for efficiency-aware exploration and shows strong interaction scaling; your eval should measure scaling curves. citeturn3view0turn5view2  

### Experiments and ablations

A rigorous evaluation matrix:

- **Ablate workspace reconstruction**:  
  - A: mono-context accumulation baseline  
  - B: IterResearch-style reconstructed workspace  
  Compare long-horizon performance degradation curves (quality vs steps). This directly tests IterResearch’s claim that reconstruction prevents context suffocation/noise contamination. citeturn3view0turn17view3  

- **Ablate retrieval strategy**:  
  - BM25 only  
  - vector only (DPR/embeddings) citeturn6search2  
  - hybrid + RRF fusion citeturn9search0  
  - hybrid + rerank (BERT reranker) citeturn7search2  

- **Ablate verification gate**:  
  - none  
  - FEVER-like claim verification  
  - RARR post-hoc revise loop citeturn10search6  

- **Ablate orchestration style**:  
  - single-agent tool loop  
  - orchestrator–worker with 3, 5, 8 workers  
  Evaluate quality vs token cost using insights that multi-agent yields better capacity but higher token usage. citeturn3view1turn4view0  

### Algorithms and pseudocode for the core loops

#### Main orchestrator loop (IterResearch + orchestrator–workers)

```pseudo
function RUN_RESEARCH_JOB(job):
  ws = LOAD_WORKSPACE(job.workspace_head)          # bounded IterResearch workspace
  pb = LOAD_PLAN_BOARD(ws.plan_board_ref)

  while not DONE(ws, pb) and within_budget(ws):
    # 1) Plan-Board Search: pick next tasks
    ready_tasks = FRONTIER(pb)
    batch = SELECT_TASK_BATCH(ready_tasks, ws)     # heuristic VOI/cost/diversity

    # 2) Dispatch workers (parallel where safe)
    results = PARALLEL_MAP(batch, task -> DISPATCH_WORKER(task, ws))

    # 3) Deep retrieval + evidence normalization
    evidences = []
    for r in results:
      evidences += INGEST_EVIDENCE(r)              # chunk, hash, provenance
    STORE_EVIDENCE(evidences)

    # 4) Update plan board (close tasks, spawn new)
    pb = UPDATE_PLAN_BOARD(pb, results, ws)

    # 5) Workspace reconstruction (IterResearch)
    ws = RECONSTRUCT_WORKSPACE(
           question = ws.question,
           evolving_report = UPDATE_REPORT(ws.evolving_report, results, evidences),
           immediate_context = {last_action=batch, last_observation=SUMMARIZE(results)}
         )

    CHECKPOINT(job, ws, pb)                        # durability + audit history

  # 6) Quality gates and final synthesis
  ws = RUN_CROSS_REFERENCE_AND_VERIFY(ws, pb)
  final = MINTO_SYNTHESIZE(ws.evolving_report)
  return final
```

This aligns to IterResearch’s “Think, Report, Action” structure and reconstructed workspace transition. citeturn17view3turn5view2  
It also matches orchestrator–worker cyclic execution: generate subtasks, assign workers, collect results, update state, repeat. citeturn16view1turn4view0  

#### Ralph Loop harness (durable repeat-until-done)

```pseudo
function RALPH_HARNESS(job):
  # concept: repeat runs, preserve artifacts, stop only when completion criteria met
  for iter in 1..MAX_ITER:
    final_or_partial = RUN_RESEARCH_JOB_STEP(job)   # one or more orchestrator cycles
    if COMPLETION_PROMISE_MET(job):                 # e.g., "DONE" criteria or gate pass
      return final_or_partial
    else:
      ENFORCE_FRESH_CONTEXT_NEXT_ITER(job)          # new model context; load workspace from store
  return BEST_EFFORT_WITH_WARNINGS(job)
```

This is the service-side analogue of Ralph Loop’s “stop hook re-feeds the same prompt while files/git history persist until completion.” citeturn3view3turn3view4  

#### Hybrid retrieval with RRF + rerank

```pseudo
function HYBRID_RETRIEVE(query_bundle, filters):
  L1 = BM25_SEARCH(query_bundle.lexical, filters)            # sparse
  L2 = VECTOR_SEARCH(query_bundle.semantic, filters)         # dense ANN
  fused = RRF_FUSE([L1, L2], k=60)                           # fusion baseline
  top = TAKE(fused, 200)
  reranked = CROSS_ENCODER_RERANK(query_bundle, top)         # expensive, limited k
  return TAKE(reranked, 50)
```

RRF is established as a strong fusion method. citeturn9search0  
Cross-encoder reranking is a standard second-stage approach. citeturn7search2turn7search5  

### Example end-to-end workflow (illustrative)

**User prompt (research request):**  
“Evaluate whether Company X’s new standard Y materially improves safety compared to prior standard Z. Provide a cited report, compare requirements, and highlight unresolved risks.”

**Iteration snapshot (Plan Board excerpt):**
- Task A: locate official standard Y doc and change log (primary)
- Task B: locate standard Z official text (primary)
- Task C: find independent analyses (peer-reviewed / regulator)
- Task D: extract requirement diffs into a table
- Task E: verify 5 key claims with ≥2 sources each

**Worker output schema (example):**
```json
{
  "task_id": "TaskA",
  "findings": [
    {"claim": "Standard Y introduces requirement R1...", "evidence_ids": ["e12","e15"]}
  ],
  "recommended_next_tasks": ["TaskD"],
  "source_urls": ["..."]
}
```

**Workspace reconstruction (what the orchestrator feeds itself next):**
- Question: unchanged
- Evolving report: updated with new verified requirements, open questions, and a “diff plan”
- Immediate context: last task batch + summary + evidence ids  
This is exactly the “only essential elements” workspace design in IterResearch. citeturn17view3turn5view2  

**Cross-reference gate (claim verification):**
- Extract top claims → run evidence retrieval for each claim and for each claim’s negation → label supported/refuted/uncertain (FEVER-style). citeturn10search0turn10search8  

**Final output shape (Minto Pyramid):**
- Answer: “Yes/No/Partially, under conditions…”
- 3 pillars: “Requirements delta,” “Evidence quality,” “Residual risks”
- Details: tables + citations
- Appendix: source list + unresolved claims

### What “good” looks like (acceptance criteria)

Use DeepResearch Bench as a north star because it evaluates both report quality and citation trustworthiness. citeturn17view2turn12search4

A practical internal bar for “ship quality”:
- ≥90% of critical claims backed by ≥2 independent sources  
- Citation accuracy checks pass (sampled manual audit + automated)  
- Stable quality under longer horizons (no degradation beyond N steps), validating workspace reconstruction’s purpose. citeturn17view3turn3view0  

## Bibliography of prioritized sources

Primary and official sources (highest priority):

- IterResearch paper (Alibaba Tongyi Lab et al.), including explicit Markovian workspace reconstruction state design and structured (Think, Report, Action) decisions. citeturn3view0turn17view3  
- Anthropic engineering: multi-agent research system using orchestrator–worker; notes cost/token tradeoffs. citeturn3view1  
- Microsoft Logic Apps Labs: orchestrator–workers pattern definition, benefits, and when-to-use guidance. citeturn4view0  
- LangGraph documentation: orchestrator-worker concept and dynamic worker creation with shared state aggregation. citeturn4view1  
- Anthropic-verified Ralph Loop plugin and Claude Code Ralph Wiggum README describing stop-hook iterative loops and completion promises. citeturn3view4turn3view3  
- DeepResearch Bench official site + paper: benchmark design and the RACE/FACT evaluation frameworks emphasizing report quality and citation trustworthiness. citeturn17view2turn12search4  
- MCP official security best practices (confused deputy, token passthrough, SSRF). citeturn17view0  
- OWASP GenAI/LLM risk: prompt injection risk and limitations of RAG/fine-tuning as mitigations. citeturn13search5turn13search17  
- NIST AI RMF 1.0: risk management framing for AI systems. citeturn13search2turn13search26  
- MITRE ATLAS: adversarial threat landscape for AI systems. citeturn13search1  

Core retrieval and evaluation literature (high priority):

- BM25 / Probabilistic Relevance Framework review (Stephen Robertson et al.). citeturn6search1  
- Dense Passage Retrieval (DPR). citeturn6search2turn6search14  
- ColBERT late interaction retrieval. citeturn6search3turn6search7  
- SPLADE (learned sparse expansion). citeturn9search1turn9search5  
- Reciprocal Rank Fusion (RRF). citeturn9search0  
- Passage re-ranking with BERT (cross-encoder reranking). citeturn7search2turn7search5  
- nDCG / cumulated gain evaluation methods (Järvelin & Kekäläinen). citeturn15search1  
- MRR definition (Craswell / Stanford IR handout). citeturn15search2turn15search26  

Verification and cross-reference research (high priority):

- FEVER dataset for claim verification with evidence. citeturn10search0turn10search8  
- RARR (research + revise for attribution/factuality). citeturn10search6turn10search18  
- SelfCheckGPT (sampling-based hallucination detection). citeturn10search1turn10search17  

Communication structure (supporting priority):

- Barbara Minto’s Pyramid Principle (archived book listing) and modern summaries of the framework. citeturn7search10turn7search1