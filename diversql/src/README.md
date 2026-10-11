# workload_generation/src — DiverSQL Framework Implementation

## The pipeline in one breath

```
config ─┐
        ▼
schema → sampling → prompt ──▶ llm ──▶ validation ──▶ diversity_tracker
   ▲         ▲         ▲                                      │
   └─────────┴─────────┴──────── feedback ◀──────────────────┘   (closes the loop)
                         concurrency drives the batch;  
                         report writes the output, 
                         main.py wires it all
```

A single query: **sample a shape** (family + add-ons + plan-shape) → **ask the
feedback loop for operator hints** → **sample tables/columns/values** (biased to
under-used ones) → **build the prompt** → **call the LLM** → **EXPLAIN-validate** →
**try to accept** (dedup + novelty caps) → **update the tracker**. The batch runs
many of these through the adaptive concurrency pool until N are accepted.

## Files & responsibilities

| module | responsibility  |
|--------|----------------|
| `config.py` | every constant + rationale (the only place magic numbers live)|
| `schema.py` | dataset schema, FK graph, live Trino DDL/column introspection |
| `sampling.py` | coverage-weighted table selection + predicate value aid | 
| `prompt.py` | families / add-ons / plan-shapes, task+schema text, templates, hint injection | 
| `operator_space.py` | C_phys operator ceiling + lever→operator map (from `resources/`) | 
| `llm.py` | client, retry (+observer), structured `generate_sql` (+token usage), warmup |
| `concurrency.py` | AIMD controller, saturating pool, retry-observer wiring, progress signal | 
| `validation.py` | EXPLAIN plan, plan signatures, plan DAG, structural n-grams | 
| `diversity_tracker.py` | **schema-usage + structural** memory; acceptance, dedup, caps, coverage/entropy | 
| `feedback.py` | the loop: deficit-hint policy (F-1), reward (F-2), plateau (F-4), gaps (F-6) |
| `pipeline.py` | `generate_query` (single) + `generate_query_batch` (accept loop) | 
| `report.py` | `write_workload_directory` + `generation_report.json` assembly | 
| `main.py` | public API surface (what `lakehouse.py` imports);  |
