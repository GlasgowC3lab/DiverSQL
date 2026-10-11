"""
pipeline -- orchestration: one query, and the batch accept-loop.

"""

import math
import random
import threading
from collections import Counter

from . import config, validation
from .concurrency import run_pool
from .prompt import (sample_shape_spec, build_schema_context, build_task_text,
                     PROMPT_TEMPLATE, INSTRUCTIONS_TEMPLATE)
from .sampling import (sample_tables_v2, build_value_aid,
                       _VALUE_CACHE, _VALUE_CACHE_LOCK)
from .schema import (build_table_ddl_context, fetch_table_columns_cached,
                     get_relevant_relationships)
from .llm import generate_sql, last_retry_count
from .diversity_tracker import (DiversityTracker, _edge_key, _dedup_key,
                                _skeleton_key, _bare_column_name)
from .feedback import DEFAULT_POLICY
from .report import _record_batch_stats

__all__ = ["generate_query", "generate_query_batch", "_levers_of"]

# Shared default so ad-hoc single-query calls (Lakehouse.generate_query) work
# without a caller-supplied tracker; batches always pass their own.
_DEFAULT_TRACKER = DiversityTracker()


def _levers_of(q: dict) -> set:
    levers = set(q.get("shape_addons", []))
    ps = q.get("plan_shape")
    if ps and ps != "none":
        levers.add(ps)
    return levers


def generate_query(
    *,
    conn_factory,
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    client,
    tracker=None,
    policy=None,
    model_name: str = None,
    temperature: float = None,
    reasoning: str = None,
    min_tables: int = None,
    max_tables: int = None,
    random_seed: int | None = None,
    ddl_cache: dict | None = None,
    ddl_cache_lock=None,
    connected_fraction: float = None,
    value_cache: dict | None = None,
    value_cache_lock=None,
    variant: dict | None = None,
    shape_sampler=None,
    table_sampler=None,
    task_augmenter=None,
) -> dict:
    """One query: shape + deficit-hints + coverage-weighted tables +
    grounded prompt + LLM. Hint selection is driven by the tracker.

    ``shape_sampler``/``table_sampler``/``task_augmenter`` are injection seams for
    experiments (e.g. target-conditioned
    generation) and default to the stock v8 behaviour, so every existing caller is
    unaffected:
      * ``shape_sampler(rng) -> spec``       default: :func:`sample_shape_spec`
      * ``table_sampler(schema, n_tables, *, rng, table_usage, edge_usage,
        connected_fraction) -> (tables, mode)``  default: :func:`sample_tables_v2`
      * ``task_augmenter(task, selected_tables, rng, family=name) -> task``  default: identity
    """
    tracker = tracker if tracker is not None else _DEFAULT_TRACKER
    policy = policy or DEFAULT_POLICY
    shape_sampler = shape_sampler or sample_shape_spec
    table_sampler = table_sampler or sample_tables_v2
    model_name = model_name or config.MODEL_NAME
    temperature = config.TEMPERATURE if temperature is None else temperature
    reasoning = reasoning or config.DEFAULT_REASONING
    min_tables = config.MIN_TABLES if min_tables is None else min_tables
    max_tables = config.MAX_TABLES if max_tables is None else max_tables
    connected_fraction = config.CONNECTED_FRACTION if connected_fraction is None else connected_fraction
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if value_cache is None:
        value_cache = _VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _VALUE_CACHE_LOCK

    rng = random.Random(random_seed)

    if variant is not None:
        spec = {"family": variant, "addons": [], "plan_shape": None}
    else:
        spec = shape_sampler(rng)
    family = spec["family"]

    # Adaptive piece: ONE budgeted, coverage-weighted construct selection.
    hint_ids: list[str] = []
    if variant is None:
        for c in policy.choose_constructs(tracker, rng, family):
            spec["addons"].append({"name": c["name"], "line": c["line"]})
            hint_ids.append(c["name"])

    n_range = family.get("n_tables_range")
    if n_range == "high":
        lo = max(min_tables, min(5, max_tables))
        n_tables = rng.randint(lo, max_tables)
    elif n_range is not None:
        lo, hi = n_range
        n_tables = rng.randint(max(1, lo), max(1, hi))
    else:
        n_tables = rng.randint(min_tables, max_tables)

    usage = tracker.usage_snapshot()

    selected_tables, sampling_mode = table_sampler(
        schema_json, n_tables, rng=rng,
        table_usage=usage["tables"], edge_usage=usage["edges"],
        connected_fraction=connected_fraction,
    )
    ddl_context = build_table_ddl_context(
        conn_factory=conn_factory, catalog=catalog, schema=trino_schema,
        tables=selected_tables, ddl_cache=ddl_cache, ddl_cache_lock=ddl_cache_lock,
    )
    columns_by_table = {
        t: fetch_table_columns_cached(
            conn_factory=conn_factory, catalog=catalog, schema=trino_schema,
            table=t, ddl_cache=ddl_cache, ddl_cache_lock=ddl_cache_lock,
        )
        for t in selected_tables
    }
    value_aid = build_value_aid(
        conn_factory=conn_factory, catalog=catalog, schema=trino_schema,
        tables=selected_tables, columns_by_table=columns_by_table, rng=rng,
        value_cache=value_cache, value_cache_lock=value_cache_lock,
        column_usage=usage["columns"],
    )
    schema_context = build_schema_context(
        schema=schema_json, selected_tables=selected_tables,
        ddl_context=ddl_context, value_aid=value_aid,
    )
    has_join_rules = bool(get_relevant_relationships(schema_json, selected_tables))
    task = build_task_text(
        spec, n_tables=len(selected_tables), rng=rng, has_join_rules=has_join_rules,
    )
    if task_augmenter is not None:
        task = task_augmenter(task, selected_tables, rng, family=family["name"])

    base_temp = max(temperature, config.TEMPERATURE_FLOOR)
    query_temperature = min(1.0, max(0.0, base_temp + family["temp_delta"]))

    sql_result = generate_sql(
        client=client, schema_context=schema_context, task=task,
        model_name=model_name, temperature=query_temperature, reasoning=reasoning,
    )

    plan_shape = spec.get("plan_shape")
    return {
        "sql": sql_result["sql"],
        "goal": sql_result["goal"],
        "tables_used": sql_result["tables_used"],
        "columns_used": sql_result["columns_used"],
        "assumptions": sql_result["assumptions"],
        "selected_tables": selected_tables,
        "ddl_context": ddl_context,
        "schema_context": schema_context,
        "prompt_template": PROMPT_TEMPLATE,
        "instructions_template": INSTRUCTIONS_TEMPLATE,
        "model_name": model_name,
        "temperature": query_temperature,
        "catalog": catalog,
        "schema": trino_schema,
        "prompt_variant": family["name"],
        "shape_addons": [a["name"] for a in spec["addons"]],
        "deficit_hints": hint_ids,
        "hint_depth": len(hint_ids),
        "sampling_mode": sampling_mode,
        "plan_shape": plan_shape["name"] if plan_shape else "none",
    }


def generate_query_batch(
    *,
    conn_factory,
    schema_json: dict,
    num_queries: int,
    catalog: str,
    trino_schema: str,
    client_factory,
    tracker=None,
    model_name: str = None,
    temperature: float = None,
    reasoning: str = None,
    min_tables: int = None,
    max_tables: int = None,
    random_seed: int | None = None,
    ddl_cache: dict | None = None,
    ddl_cache_lock=None,
    generation_workers: int = None,
    connected_fraction: float = None,
    skeleton_cap: int = None,
    plan_signature_cap: int = None,
    max_attempt_factor: float = None,
    progress_cb=None,
    policy=None,
    shape_sampler=None,
    table_sampler=None,
    task_augmenter=None,
) -> list[dict]:
    model_name = model_name or config.MODEL_NAME
    temperature = config.TEMPERATURE if temperature is None else temperature
    reasoning = reasoning or config.DEFAULT_REASONING
    min_tables = config.MIN_TABLES if min_tables is None else min_tables
    max_tables = config.MAX_TABLES if max_tables is None else max_tables
    generation_workers = generation_workers or config.GENERATION_WORKERS
    connected_fraction = config.CONNECTED_FRACTION if connected_fraction is None else connected_fraction
    skeleton_cap = config.SKELETON_CAP if skeleton_cap is None else skeleton_cap
    plan_signature_cap = config.PLAN_SIGNATURE_CAP if plan_signature_cap is None else plan_signature_cap
    max_attempt_factor = config.MAX_ATTEMPT_FACTOR if max_attempt_factor is None else max_attempt_factor
    tracker = tracker if tracker is not None else _DEFAULT_TRACKER
    policy = policy or DEFAULT_POLICY

    rng = random.Random(random_seed)
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()

    thread_local = threading.local()

    def get_client():
        if not hasattr(thread_local, "client"):
            thread_local.client = client_factory()
        return thread_local.client

    def worker(seed: int) -> dict:
        q = generate_query(
            conn_factory=conn_factory, schema_json=schema_json, catalog=catalog,
            trino_schema=trino_schema, client=get_client(), tracker=tracker,
            policy=policy,
            model_name=model_name, temperature=temperature, reasoning=reasoning,
            min_tables=min_tables, max_tables=max_tables, random_seed=seed,
            ddl_cache=ddl_cache, ddl_cache_lock=ddl_cache_lock,
            connected_fraction=connected_fraction,
            shape_sampler=shape_sampler, table_sampler=table_sampler,
            task_augmenter=task_augmenter,
        )
        q["contention_retries"] = last_retry_count()
        if q.get("sql"):
            plan_json = validation.explain_plan_json(conn_factory, q["sql"])
            if plan_json is None:
                q["plan_valid"] = False
            else:
                sig, family = validation.plan_signatures(plan_json)
                q["plan_valid"] = sig is not None
                q["plan_sig"] = sig
                q["plan_family"] = family
                try:
                    q["plan_ngrams"] = validation.plan_ngrams(plan_json)
                except Exception:
                    q["plan_ngrams"] = Counter()
        else:
            q["plan_valid"] = False
        return q

    def accept_args(q: dict) -> dict:
        sql = q["sql"]
        tables = q.get("selected_tables", [])
        edges = [
            _edge_key(rel[0], rel[2])
            for rel in get_relevant_relationships(schema_json, tables)
        ]
        columns = sorted({
            _bare_column_name(c)
            for c in (q.get("columns_used") or [])
            if isinstance(c, str) and c.strip()
        })
        return {
            "sql_key": _dedup_key(sql),
            "skeleton": _skeleton_key(sql),
            "tables": tables,
            "edges": edges,
            "columns": columns,
            "levers": _levers_of(q),
            "plan_ngrams": q.get("plan_ngrams") or Counter(),
        }

    accepted: list[dict] = []
    overflow: list[dict] = []
    counts = Counter()
    max_attempts = max(num_queries, math.ceil(num_queries * max_attempt_factor))

    def on_complete(q: dict) -> None:
        if not q.get("sql", ""):
            return
        if not q.get("plan_valid"):
            counts["invalid"] += 1
            return
        verdict = tracker.try_accept(
            **accept_args(q), skeleton_cap=skeleton_cap,
            plan_sig=q.get("plan_sig"), plan_family=q.get("plan_family"),
            plan_signature_cap=plan_signature_cap,
        )
        if verdict == "accepted":
            accepted.append(q)
        elif verdict == "plan_duplicate":
            counts["plan_dup"] += 1
        elif verdict == "plan_capped":
            counts["plan_cap"] += 1
            overflow.append(q)
        elif verdict == "skeleton_capped":
            counts["skeleton"] += 1
            overflow.append(q)
        elif verdict == "near_duplicate":
            counts["near_dup"] += 1
            overflow.append(q)
        else:
            counts["duplicate"] += 1

    def _progress():
        return {"accepted": len(accepted), "target": num_queries,
                "rejected_invalid": counts["invalid"]}

    attempts, conc_snapshot = run_pool(
        worker=worker, on_complete=on_complete,
        is_done=lambda: len(accepted) >= num_queries,
        ceiling=generation_workers, max_attempts=max_attempts, rng=rng,
        progress_cb=progress_cb, progress_snapshot=_progress,
    )
    valid_explain = attempts - counts["invalid"]
    try:
        tracker._concurrency_snapshot = conc_snapshot
        tracker._accounting = {
            "total_candidates": attempts,
            "valid": valid_explain,
            "invalid": counts["invalid"],
            "validity_rate": round(valid_explain / attempts, 4) if attempts else None,
        }
    except Exception:
        pass

    # Overflow filler: backfill from cap-rejected uniques within the budget.
    while len(accepted) < num_queries and overflow:
        q = overflow.pop(0)
        if tracker.try_accept(
            **accept_args(q), skeleton_cap=skeleton_cap,
            plan_sig=q.get("plan_sig"), plan_family=q.get("plan_family"),
            plan_signature_cap=plan_signature_cap, enforce_caps=False,
        ) == "accepted":
            accepted.append(q)

    _record_batch_stats({
        "attempts": attempts, "max_attempts": max_attempts,
        "accepted": len(accepted),
        "rejected_invalid": counts["invalid"], "rejected_duplicate": counts["duplicate"],
        "rejected_plan_dup": counts["plan_dup"], "rejected_plan_cap": counts["plan_cap"],
        "rejected_skeleton": counts["skeleton"], "rejected_near_dup": counts["near_dup"],
    })
    if sum(counts.values()):
        print(f"[novelty control] rejected {counts['invalid']} invalid, "
              f"{counts['duplicate']} sql-duplicates, {counts['plan_dup']} plan-duplicates, "
              f"{counts['plan_cap']} plan-capped, {counts['near_dup']} near-duplicates, "
              f"{counts['skeleton']} skeleton-capped "
              f"({attempts}/{max_attempts} attempts for {len(accepted)} queries)")

    return accepted
