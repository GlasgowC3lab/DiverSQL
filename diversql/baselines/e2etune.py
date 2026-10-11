"""
E2ETune baseline (OLAP workload generation component).

    Yao, Li, Zhang, Chen, Chen, Li.
    "E2ETune: End-to-End Knob Tuning via Fine-tuned Generative Language Model."
    PVLDB 18(5): 1466-1480, 2025.

E2ETune's overall goal is knob tuning, but it contains a self-contained OLAP
*workload generation* pipeline (paper Section 5.1) used to synthesise the
diverse workloads it fine-tunes on. That pipeline is the baseline we
reproduce here, adapted to Trino / Iceberg.

"""

import json
import random
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from diversql.baselines.common import BaselineContext, write_baseline_workload
from diversql.baselines.query_generator import sanitize_sql


BASELINE = "e2etune"

_TASK_OVERVIEW = (
    "Task Overview: You are generating realistic and complex analytical (OLAP) "
    "SQL queries to build a diverse benchmark workload for a data warehouse."
)

_GUIDANCE = (
    "Guidance for Query Generation:\n"
    "- Write valid Trino (Presto) SQL over the Iceberg tables described below.\n"
    "- Use explicit JOIN syntax and only the listed tables/columns and join keys.\n"
    "- Produce a non-trivial analytical query: joins, filtering, grouping, "
    "aggregation and/or ordering. Avoid SELECT *.\n"
    "- Vary the query shape from previous queries to maximise workload diversity."
)

_INSTRUCTIONS = (
    "You are an expert data-warehouse SQL author. Produce exactly one query in "
    "the requested JSON format. Sample queries shown to you are for illustration "
    "of complexity only -- do NOT copy them."
)

# a couple of built-in complexity exemplars (generic; the paper uses benchmark
# queries as samples). Kept schema-agnostic so they only convey *shape*.
_SEED_EXEMPLARS = [
    ("SELECT t1.k, COUNT(*) AS n, SUM(t2.v) AS total\n"
     "FROM a t1 JOIN b t2 ON t1.id = t2.a_id\n"
     "WHERE t2.d >= DATE '2000-01-01'\n"
     "GROUP BY t1.k HAVING COUNT(*) > 10\n"
     "ORDER BY total DESC LIMIT 100"),
    ("SELECT c.region, AVG(o.amount) AS avg_amt,\n"
     "       RANK() OVER (ORDER BY AVG(o.amount) DESC) AS rnk\n"
     "FROM customer c JOIN orders o ON c.id = o.cust_id\n"
     "GROUP BY c.region"),
    ("SELECT p.cat, s.total FROM part p JOIN (\n"
     "  SELECT part_id, SUM(qty) AS total FROM lineitem GROUP BY part_id\n"
     ") s ON p.id = s.part_id WHERE s.total > 1000 ORDER BY s.total DESC"),
]

_OUTPUT_SCHEMA = {
    "name": "e2etune_query",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {
            "sql": {"type": "string"},
            "goal": {"type": "string"},
        },
        "required": ["sql", "goal"],
        "additionalProperties": False,
    },
}


def _predicate_aid(ctx: BaselineContext, tables: List[str], rng: random.Random,
                   max_cols: int = 6, max_vals: int = 5) -> str:
    """Component 4: sample concrete column values from the live DB."""
    lines: List[str] = []
    budget = max_cols
    for table in tables:
        if budget <= 0:
            break
        cols = ctx.columns_for(table)
        rng.shuffle(cols)
        for col in cols:
            if budget <= 0:
                break
            vals = ctx.sample_column_values(table, col["name"], limit=max_vals)
            if not vals:
                continue
            shown = ", ".join(str(v) for v in vals[:max_vals])
            lines.append(f"- {table}.{col['name']} ({col['type']}): {shown}")
            budget -= 1
    if not lines:
        return "Predicate Generation Aid: (no sample values available)"
    return "Predicate Generation Aid (example column values):\n" + "\n".join(lines)


def _build_prompt(ctx: BaselineContext, tables: List[str], rng: random.Random) -> str:
    ddl = ctx.ddl_for(tables)
    joins = ctx.join_rules_text(tables)
    join_block = "\n".join(f"- {j}" for j in joins) if joins else "- (no direct joins)"
    aid = _predicate_aid(ctx, tables, rng)
    n_samples = rng.randint(1, 3)
    samples = rng.sample(_SEED_EXEMPLARS, k=min(n_samples, len(_SEED_EXEMPLARS)))
    sample_block = "\n\n".join(f"-- example {i+1}\n{s}" for i, s in enumerate(samples))

    return (
        f"{_TASK_OVERVIEW}\n\n"
        f"Database Schema (subset):\n{ddl}\n\n"
        f"Join keys:\n{join_block}\n\n"
        f"{_GUIDANCE}\n\n"
        f"{aid}\n\n"
        f"Sample OLAP Queries (illustration of complexity only, do not copy):\n"
        f"{sample_block}\n\n"
        "Output Format: return a JSON object with keys 'sql' and 'goal'."
    )


def _generate_one(ctx: BaselineContext, tables: List[str], seed: int) -> Dict[str, Any]:
    rng = random.Random(seed)
    prompt = _build_prompt(ctx, tables, rng)
    raw = ctx.responses_text(
        instructions=_INSTRUCTIONS,
        prompt=prompt,
        json_schema=_OUTPUT_SCHEMA,
    )
    data = json.loads(raw)
    return {
        "sql": sanitize_sql(data.get("sql", "")),
        "goal": data.get("goal", ""),
        "selected_tables": tables,
    }


def _repair(ctx: BaselineContext, sql: str, error: str, tables: List[str]) -> Optional[str]:
    """Quality control: fix a query using the EXPLAIN error message."""
    ddl = ctx.ddl_for(tables)
    prompt = (
        f"The following Trino SQL query failed validation.\n\n"
        f"Query:\n{sql}\n\nError:\n{error}\n\n"
        f"Schema:\n{ddl}\n\n"
        "Return a corrected query in JSON with keys 'sql' and 'goal'."
    )
    try:
        raw = ctx.responses_text(
            instructions=_INSTRUCTIONS,
            prompt=prompt,
            json_schema=_OUTPUT_SCHEMA,
            temperature=0.2,
            reasoning="low",
        )
        return sanitize_sql(json.loads(raw).get("sql", ""))
    except Exception:
        return None


def generate_workload(
    ctx: BaselineContext,
    *,
    workload_name: str,
    num_queries: int = 100,
    min_tables: int = 2,
    max_tables: int = 8,
    max_repair: int = 3,
    generation_workers: int = 8,
    validation_workers: int = 8,
    batch_multiplier: float = 1.4,
    max_rounds: int = 12,
    warmup: bool = True,
    random_seed: Optional[int] = None,
    workload_root=None,
) -> Dict[str, Any]:
    """Run the E2ETune OLAP generation pipeline and write a workload + report."""
    started_at = datetime.now(timezone.utc)
    rng = random.Random(random_seed)
    schema_tables = ctx.schema_tables()

    if warmup:
        ctx.warm_up()

    accepted: List[Dict[str, Any]] = []
    rounds = 0
    total_generated = 0
    total_repaired = 0
    repair_attempts = 0

    while len(accepted) < num_queries and rounds < max_rounds:
        rounds += 1
        remaining = num_queries - len(accepted)
        batch = max(4, int(remaining * batch_multiplier))

        # Diversity control (1): random table subset per query
        jobs = []
        for _ in range(batch):
            n = rng.randint(min_tables, min(max_tables, len(schema_tables)))
            tables = sorted(rng.sample(schema_tables, k=min(n, len(schema_tables))))
            jobs.append((tables, rng.randint(0, 10**9)))

        candidates: List[Dict[str, Any]] = []
        with ThreadPoolExecutor(max_workers=max(1, generation_workers)) as ex:
            futs = [ex.submit(_generate_one, ctx, t, s) for t, s in jobs]
            for fut in as_completed(futs):
                try:
                    candidates.append(fut.result())
                except Exception as e:
                    print(f"[e2etune] generation failed: {type(e).__name__}: {e}")
        total_generated += len(candidates)

        # Quality control: EXPLAIN validation + bounded repair loop
        valid, invalid = ctx.validate_batch(candidates, workers=validation_workers)
        accepted.extend({"sql": c["sql"], "goal": c.get("goal", ""),
                         "selected_tables": c.get("selected_tables", []),
                         "extra": {"repaired": False}} for c in valid)

        # try to repair the invalid ones
        for c in invalid:
            if len(accepted) >= num_queries:
                break
            sql = c["sql"]
            err = c.get("error", "")
            tables = c.get("selected_tables", schema_tables)
            fixed = None
            for _ in range(max_repair):
                repair_attempts += 1
                cand = _repair(ctx, sql, err, tables)
                if not cand:
                    break
                ok, err2 = ctx.validate_explain(cand)
                if ok:
                    fixed = cand
                    break
                sql, err = cand, err2
            if fixed:
                total_repaired += 1
                accepted.append({"sql": fixed, "goal": c.get("goal", ""),
                                 "selected_tables": tables, "extra": {"repaired": True}})

        if not candidates:
            break

    accepted = accepted[:num_queries]

    pipeline_report = {
        "method": "E2ETune OLAP workload generation (Yao et al., PVLDB 2025)",
        "prompt_components": [
            "Task Overview", "Database Schema (random subset DDL)",
            "Guidance for Query Generation (Trino dialect)",
            "Predicate Generation Aid (sampled live column values)",
            "Sample OLAP Queries (illustration only)", "Output Format (JSON)",
        ],
        "diversity_control": [
            "random table subset per query",
            "random sampled column values in predicate aid",
            "random sample-query exemplars",
        ],
        "quality_control": "EXPLAIN validation + bounded repair loop using the error message",
        "table_range": [min_tables, max_tables],
        "counts": {
            "rounds": rounds,
            "total_generated": total_generated,
            "repaired_into_workload": total_repaired,
            "repair_attempts": repair_attempts,
            "accepted": len(accepted),
            "target": num_queries,
        },
    }

    return write_baseline_workload(
        baseline=BASELINE,
        workload_name=workload_name,
        queries=accepted,
        ctx=ctx,
        started_at=started_at,
        pipeline_report=pipeline_report,
        workload_root=workload_root,
    )
