"""report -- write_workload_directory + run-stats (moved from v6/v8)."""

import json, threading
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from . import config
from .llm import drain_token_usage
from .prompt import (PROMPT_VARIANTS, PLAN_SHAPES, CONSTRUCTS, FINISHERS,
                     INSTRUCTIONS_TEMPLATE, PROMPT_TEMPLATE)
GENERATOR_VERSION = "query_generator_v8"

_RUN_STATS_LOCK = threading.Lock()

_RUN_STATS: dict = {}

def _record_batch_stats(stats: dict) -> None:
    """Accumulate one batch's attempt/rejection counts (generate_workload may
    call the batch several times before writing)."""
    with _RUN_STATS_LOCK:
        for k, v in stats.items():
            _RUN_STATS[k] = _RUN_STATS.get(k, 0) + v
        _RUN_STATS["batches"] = _RUN_STATS.get("batches", 0) + 1

def _drain_run_stats() -> dict:
    """Return the accumulated stats and reset, so the next workload starts fresh."""
    with _RUN_STATS_LOCK:
        s = dict(_RUN_STATS)
        _RUN_STATS.clear()
    if s.get("attempts") and s.get("accepted") is not None:
        s["acceptance_rate"] = round(s["accepted"] / s["attempts"], 4)
        s["budget_used_pct"] = (
            round(100.0 * s["attempts"] / s["max_attempts"], 1)
            if s.get("max_attempts") else None
        )
    return s

def _write_workload_directory_base(
    *,
    workload_name: str,
    queries: list[dict],
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    model_name: str,
    base_url: str,
    temperature: float,
    min_tables: int,
    max_tables: int,
    random_seed: int | None,
    workload_root: str | Path = config.WORKLOADS_DIR,
    started_at: datetime | None = None,
    extra_report_fields: dict | None = None,
) -> dict:
    """Same artefact layout as v3, tagged v6, with an added ``generation_stats``
    section (attempts / budget / rejections drained from _RUN_STATS)."""
    if started_at is None:
        started_at = datetime.now(timezone.utc)

    workload_root = Path(workload_root)
    workload_dir = workload_root / workload_name
    workload_dir.mkdir(parents=True, exist_ok=True)

    prompt_examples = []

    for i, query_meta in enumerate(queries, start=1):
        query_name = f"q{i}"
        sql_path = workload_dir / f"{query_name}.sql"
        sql_path.write_text(query_meta["sql"].strip() + "\n", encoding="utf-8")

        query_meta["query_name"] = query_name
        query_meta["file"] = str(sql_path)

        if i <= 3:
            prompt_examples.append({
                "query_name": query_name,
                "selected_tables": query_meta["selected_tables"],
                "schema_context": query_meta["schema_context"],
                "goal": query_meta["goal"],
            })

    ended_at = datetime.now(timezone.utc)

    variant_mix = Counter(q.get("prompt_variant", "unknown") for q in queries)
    sampling_mix = Counter(q.get("sampling_mode", "unknown") for q in queries)
    addon_mix = Counter(a for q in queries for a in q.get("shape_addons", []))
    plan_shape_mix = Counter(q.get("plan_shape", "none") for q in queries)

    generation_stats = _drain_run_stats()
    token_usage = drain_token_usage()
    n_written = len(queries)
    tokens_per_query = (
        token_usage.get("total_tokens", 0) / n_written if n_written else None
    )

    report = {
        "workload_name": workload_name,
        "workload_dir": str(workload_dir),
        "generator": GENERATOR_VERSION,
        "created_at_utc": started_at.isoformat(),
        "completed_at_utc": ended_at.isoformat(),
        "duration_s": (ended_at - started_at).total_seconds(),
        "num_queries": n_written,
        "token_usage": token_usage,
        "tokens_per_query": tokens_per_query,
        "model": {
            "name": model_name,
            "base_url": base_url,
            "temperature": temperature,
        },
        "schema": {
            "catalog": catalog,
            "schema": trino_schema,
            "dataset_name": schema_json.get("name"),
        },
        "selection": {
            "min_tables": min_tables,
            "max_tables": max_tables,
            "random_seed": random_seed,
        },
        "generation_stats": generation_stats,
        "config": {
            "objective": "diversity-max (fidelity is a non-goal)",
            "temperature_floor": config.TEMPERATURE_FLOOR,
            "exotic_constructs_enabled": True,
            "plan_signature_cap": 3,
            "max_attempt_factor": 4.0,
        },
        "prompting": {
            "instructions_template": INSTRUCTIONS_TEMPLATE,
            "prompt_template": PROMPT_TEMPLATE,
            "families": {
                v["name"]: {"weight": v["weight"],
                            "n_tables_range": v.get("n_tables_range"),
                            "task": v["task"]}
                for v in PROMPT_VARIANTS
            },
            "constructs": [c["name"] for c in CONSTRUCTS],
            "finishers": {f["name"]: f["p"] for f in FINISHERS},
            "plan_shapes": {p["name"]: p["weight"] for p in PLAN_SHAPES},
            "semantic_fields": ["goal"],
        },
        "diversity_mechanisms": {
            "objective": "maximise diversity; NOT calibrated to real TPC-DS",
            "hot_generation": f"D-1: temperature floored at {config.TEMPERATURE_FLOOR} (SQLStorm-style)",
            "rich_constructs": (
                "D-2: boosted window/set-op add-ons + anti-join + GROUPING SETS "
                "(exotic recursive/correlated/LATERAL always available)"
            ),
            "wide_bimodal_size": "D-3: full table range (no v5 shrink); simple low mode + multi_role high mode",
            "expanded_plan_shapes": "D-4: 8 plan shapes (v3's 5 + outer_join, rollup, windowed)",
            "strict_plan_cap": "D-5: plan_signature_cap 8 -> 3 (forces more distinct plan families)",
            "plan_novelty_control": (
                "inherited: plan-graph dedup (min-NN > 0) + plan-family cap, "
                "on top of SQL/skeleton/near-dup control. Attempt budget unchanged (4x)."
            ),
            "mixed_table_sampling": "coverage-weighted connected walk / connectivity-guaranteed uniform subset (E2ETune)",
            "coverage_aware_seeding": "1/(1+usage) table + edge weighting (SQL-Factory Eq. 7, DiGiT)",
            "predicate_value_aid": "sampled live column values, weighted toward unused columns (E2ETune component 4)",
            "prompt_variant_mix": dict(variant_mix),
            "shape_addon_mix": dict(addon_mix),
            "plan_shape_mix": dict(plan_shape_mix),
            "sampling_mode_mix": dict(sampling_mix),
        },
        "queries": [
            {
                "query_name": q["query_name"],
                "file": q["file"],
                "sql": q["sql"],
                "goal": q["goal"],
                "selected_tables": q["selected_tables"],
                "tables_used": q["tables_used"],
                "columns_used": q["columns_used"],
                "assumptions": q["assumptions"],
                "prompt_variant": q.get("prompt_variant"),
                "shape_addons": q.get("shape_addons", []),
                "plan_shape": q.get("plan_shape"),
                "sampling_mode": q.get("sampling_mode"),
                "temperature": q.get("temperature"),
            }
            for q in queries
        ],
        "prompt_examples": prompt_examples,
    }

    if extra_report_fields:
        report.update(extra_report_fields)

    report_path = workload_dir / "generation_report.json"
    report_path.write_text(json.dumps(report, indent=2, default=str), encoding="utf-8")

    return report

def write_workload_directory(
    *,
    tracker=None,
    extra_report_fields: dict | None = None,
    **kwargs,
):
    extra = dict(extra_report_fields or {})
    extra["generator"] = GENERATOR_VERSION
    fb = {
        "mechanism": "unified budgeted construct selection (one coverage-weighted draw per query)",
        "reward_unit": f"child-path operator {config.NGRAM_N}-grams (count-weighted, analyzer-aligned)",
        "family_construct_budget": config.FAMILY_CONSTRUCT_BUDGET,
        "softmax_temp": config.HINT_SOFTMAX_TEMP,
        "conditional_weight": config.CONDITIONAL_WEIGHT,
        "ceiling_source": "resources/ (operators_ground_truth.csv + lever_operator_map.csv)",
    }
    if tracker is not None:
        fb.update(tracker.plan_feedback_snapshot())
        fb["feedback_enabled"] = tracker.feedback_enabled
    extra.setdefault("plan_feedback", fb)
    return _write_workload_directory_base(extra_report_fields=extra, **kwargs)
