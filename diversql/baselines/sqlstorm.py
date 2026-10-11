"""
SQLStorm baseline.

    Schmidt, Leis, Boncz, Neumann.
    "SQLStorm: Taking Database Benchmarking into the LLM Era."
    PVLDB 18(11): 4144-4157, 2025.  https://github.com/SQL-Storm/SQLStorm

Faithful adaptation of the four-step SQLStorm methodology (paper Section 3) to
the Trino / Iceberg lakehouse.
"""
import random
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from diversql.baselines.common import BaselineContext, write_baseline_workload
from diversql.baselines.query_generator import sanitize_sql


BASELINE = "sqlstorm"

# --- Step 1: the SQLStorm prompt suite (paper Table 2, P1-P7) ---------------
PROMPTS: Dict[str, str] = {
    "P1": (
        "Generate an interesting and elaborate SQL query for performance "
        "benchmarking, potentially including constructs such as outer joins, "
        "(correlated) subqueries, CTEs, window functions, set operators, "
        "complicated predicates/expressions/calculations, string expressions, "
        "and NULL logic."
    ),
    "P2": "Generate an interesting and elaborate SQL query for performance benchmarking.",
    "P3": "Generate a SQL query for performance benchmarking.",
    "P4": "Generate a simple SQL query for benchmarking.",
    "P5": (
        "Generate an interesting and elaborate SQL query for performance "
        "benchmarking, potentially including constructs such as outer joins, "
        "(correlated) subqueries, CTEs, window functions, set operators, "
        "complicated predicates/expressions/calculations, string expressions, "
        "and NULL logic. Incorporate obscure semantical corner cases and "
        "unusual or even bizarre SQL semantics."
    ),
    "P6": "Generate an interesting and elaborate SQL query for benchmarking string processing.",
    "P7": (
        "Generate an interesting and elaborate SQL query for performance "
        "benchmarking, potentially including constructs such as outer joins, "
        "(correlated) subqueries, (recursive) CTEs, window functions, set "
        "operators, complicated predicates/expressions/calculations, string "
        "expressions, and NULL logic."
    ),
}
PROMPT_ORDER = ["P1", "P2", "P3", "P4", "P5", "P6", "P7"]

# SQLStorm's "PS" schema suffix, re-targeted at Trino.
_SCHEMA_SUFFIX = (
    "Do not explain the query, only output one SQL query. "
    "Use only the following {dataset} schema (Iceberg tables queried through "
    "Trino). Use Trino SQL syntax and only the tables and columns below:\n"
    "{ddl}"
)

_INSTRUCTIONS = (
    "You are an expert SQL author writing analytical queries for database "
    "performance benchmarking. Output exactly one SQL query and nothing else "
    "-- no prose, no markdown fences, no comments."
)

# SQLStorm's "PF" cross-dialect rewrite prompt, re-targeted at Trino.
_REWRITE_INSTRUCTIONS = (
    "You rewrite SQL queries so they run on Trino (Presto SQL). Fix dialect "
    "issues: rewrite '::' casts to CAST(...), put every ungrouped column and "
    "every column used outside an aggregate/window into the GROUP BY clause, "
    "replace Postgres-only functions with Trino equivalents, and remove "
    "statement-terminating semicolons. Do not change the query's intent. "
    "Output only the converted query, no explanation."
)

# a fixed timestamp so volatile queries are reproducible (paper Section 3.3)
_FIXED_DATE = "DATE '2024-10-01'"
_FIXED_TS = "TIMESTAMP '2024-10-01 00:00:00'"


# ---------------------------------------------------------------------------
# Step 2 helpers: cleaning
# ---------------------------------------------------------------------------

_FENCE = re.compile(r"```[a-zA-Z]*")
_NOW_FUNCS = re.compile(
    r"\b(current_timestamp|now\s*\(\s*\)|localtimestamp)\b", re.IGNORECASE
)
_CUR_DATE = re.compile(r"\b(current_date|today\s*\(\s*\))\b", re.IGNORECASE)


def _clean_query(raw: str) -> Optional[str]:
    """Dedup-key-ready cleaning: strip fences/comments, first statement, fixed time."""
    if not raw:
        return None
    text = _FENCE.sub("", raw)
    # drop line comments
    text = "\n".join(
        line for line in text.splitlines() if not line.strip().startswith("--")
    )
    # keep the first statement (SQLStorm extracts the first SELECT)
    # split on ';' but keep semicolons inside strings out of scope for simplicity
    first = text.split(";")[0]
    # prefer starting at the first SELECT / WITH
    m = re.search(r"\b(WITH|SELECT)\b", first, flags=re.IGNORECASE)
    if m:
        first = first[m.start():]
    first = _NOW_FUNCS.sub(_FIXED_TS, first)
    first = _CUR_DATE.sub(_FIXED_DATE, first)
    first = sanitize_sql(first)
    return first or None


def _dedup_key(sql: str) -> str:
    return re.sub(r"\s+", " ", sql.strip().lower())


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

def _generate_one(ctx: BaselineContext, prompt_id: str, ddl: str, temperature: float) -> Dict[str, Any]:
    suffix = _SCHEMA_SUFFIX.format(dataset=ctx.schema_json.get("name", "dataset"), ddl=ddl)
    prompt = f"{PROMPTS[prompt_id]}\n\n{suffix}"
    raw = ctx.responses_text(
        instructions=_INSTRUCTIONS,
        prompt=prompt,
        temperature=temperature,
    )
    return {"prompt_id": prompt_id, "raw": raw}


def _rewrite_for_trino(ctx: BaselineContext, sql: str) -> str:
    try:
        out = ctx.responses_text(
            instructions=_REWRITE_INSTRUCTIONS,
            prompt=sql,
            temperature=0.0,
            reasoning="low",
        )
        cleaned = _clean_query(out)
        return cleaned or sql
    except Exception:
        return sql


def generate_workload(
    ctx: BaselineContext,
    *,
    workload_name: str,
    num_queries: int = 100,
    prompt_ids: Optional[List[str]] = None,
    temperature: float = 1.0,          # SQLStorm uses high temperature for diversity
    generation_workers: int = 8,
    validation_workers: int = 8,
    rewrite_pass: bool = True,
    batch_multiplier: float = 1.6,     # over-generate to survive selection
    max_rounds: int = 12,
    warmup: bool = True,
    random_seed: Optional[int] = None,
    workload_root=None,
) -> Dict[str, Any]:
    """Run the SQLStorm pipeline and write a workload directory + report."""
    started_at = datetime.now(timezone.utc)
    rng = random.Random(random_seed)
    prompt_ids = prompt_ids or PROMPT_ORDER

    if warmup:
        ctx.warm_up()

    # Whole-schema DDL suffix (fetched once, cached).
    ddl = ctx.full_ddl()

    ctx_temp = temperature
    seen_keys: set[str] = set()
    accepted: List[Dict[str, Any]] = []
    prompt_yield: Dict[str, Dict[str, int]] = {
        p: {"generated": 0, "cleaned": 0, "validated": 0} for p in prompt_ids
    }
    rounds = 0
    total_generated = 0
    total_duplicates = 0
    total_rewritten = 0

    while len(accepted) < num_queries and rounds < max_rounds:
        rounds += 1
        remaining = num_queries - len(accepted)
        batch = max(len(prompt_ids), int(remaining * batch_multiplier))

        # round-robin prompt assignment across the batch (mirrors per-prompt batches)
        assignments = [prompt_ids[i % len(prompt_ids)] for i in range(batch)]
        rng.shuffle(assignments)

        # --- Step 1: generate ---
        raws: List[Dict[str, Any]] = []
        with ThreadPoolExecutor(max_workers=max(1, generation_workers)) as ex:
            futs = [
                ex.submit(_generate_one, ctx, pid, ddl, ctx_temp)
                for pid in assignments
            ]
            for fut in as_completed(futs):
                try:
                    raws.append(fut.result())
                except Exception as e:  # generation failure -- skip
                    print(f"[sqlstorm] generation failed: {type(e).__name__}: {e}")
        total_generated += len(raws)
        for r in raws:
            prompt_yield[r["prompt_id"]]["generated"] += 1

        # --- Step 2: clean + dedup ---
        cleaned: List[Dict[str, Any]] = []
        for r in raws:
            sql = _clean_query(r["raw"])
            if not sql:
                continue
            key = _dedup_key(sql)
            if key in seen_keys:
                total_duplicates += 1
                continue
            seen_keys.add(key)
            prompt_yield[r["prompt_id"]]["cleaned"] += 1
            cleaned.append({"sql": sql, "prompt_id": r["prompt_id"], "dedup_key": key})

        # optional LLM rewrite pass for Trino compatibility (SQLStorm's PF step)
        if rewrite_pass and cleaned:
            with ThreadPoolExecutor(max_workers=max(1, generation_workers)) as ex:
                futs = {ex.submit(_rewrite_for_trino, ctx, c["sql"]): c for c in cleaned}
                for fut in as_completed(futs):
                    c = futs[fut]
                    try:
                        new_sql = fut.result()
                    except Exception:
                        new_sql = c["sql"]
                    if _dedup_key(new_sql) != c["dedup_key"]:
                        total_rewritten += 1
                    c["sql"] = new_sql

        # --- Step 3: selection via Trino EXPLAIN ---
        valid, _invalid = ctx.validate_batch(cleaned, workers=validation_workers)
        for c in valid:
            prompt_yield[c["prompt_id"]]["validated"] += 1
            accepted.append({
                "sql": c["sql"],
                "goal": f"SQLStorm {c['prompt_id']} benchmark query",
                "extra": {"prompt_id": c["prompt_id"]},
            })

        if not raws:  # nothing generated this round -- avoid infinite loop
            break

    accepted = accepted[:num_queries]

    # attach complexity mix per prompt for the report (computed at write time too)
    pipeline_report = {
        "method": "SQLStorm (Schmidt et al., PVLDB 2025)",
        "steps": [
            "generate (P1-P7 prompt suite + whole-schema DDL suffix)",
            "clean & rewrite (dedup, strip comments, first statement, fixed timestamp)",
            "LLM Trino-compatibility rewrite (PF prompt)" if rewrite_pass else "no rewrite pass",
            "select via Trino EXPLAIN",
            "static low/medium/high complexity classification",
        ],
        "prompts": {p: PROMPTS[p] for p in prompt_ids},
        "temperature": temperature,
        "rewrite_pass": rewrite_pass,
        "counts": {
            "rounds": rounds,
            "total_generated": total_generated,
            "duplicates_removed": total_duplicates,
            "rewritten": total_rewritten,
            "accepted": len(accepted),
            "target": num_queries,
        },
        "per_prompt_yield": prompt_yield,
        "validation": "Trino EXPLAIN (single-engine analogue of SQLStorm parse>=2/exec>=1)",
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
