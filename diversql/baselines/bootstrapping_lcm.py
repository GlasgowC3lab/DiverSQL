"""
Bootstrapping-LCM baseline (a.k.a. DiGiT SDG pipeline).

    Nidd, Miksovic, Gschwind, Fusco, Giovannini, Giurgiu.
    "Bootstrapping Learned Cost Models with Synthetic SQL Queries."
    VLDB 2025 Workshop AIDB.  arXiv:2508.19807.
    https://github.com/menidd/QueryGeneration2025

Adaptation of the DiGiT "Steering SDG towards Diversity" pipeline (paper
Section 4, prompt outline in Figure 2) to Trino / Iceberg:

"""

import math
import random
import threading
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from diversql.baselines.common import (
    BaselineContext,
    enumerate_connected_subsets,
    trino_literal,
    type_kind,
    write_baseline_workload,
)
from diversql.shared.sql_features import query_features, _tokens
from diversql.baselines.query_generator import sanitize_sql, get_relevant_relationships


BASELINE = "bootstrapping_lcm"

_INSTRUCTIONS = (
    "You are a SQL author generating synthetic training queries for a learned "
    "cost model. Write one valid Trino (Presto) SQL query over the given "
    "Iceberg tables. Output only the SQL query."
)

# DiGiT Figure 2 prompt outline; the clause-bias constraint precedes the examples.
_BASE_PROMPT = (
    "These tables have been created:\n{ddl}\n\n"
    "Write an interesting and complicated SQL query that uses all of these tables:\n"
    "{table_list}\n"
    "{bias}"
    "{examples_block}"
)

_CLAUSE_BIAS = {
    "none": "",
    "group_by": "Whenever possible, please use a GROUP BY clause. Use operators for more complex groups.\n",
    "order_by": "Whenever possible, please use an ORDER BY clause to rank the output.\n",
}

# Operations the mechanical example generator can emit (and the coverage
# report tracks for example tuning).
_EXAMPLE_OPS = ("filter", "group_by", "order_by")
_BIASED_CLAUSE_P = 0.9      # paper: desired clause included with 90% probability
_DEFAULT_OP_P = 0.5


# ---------------------------------------------------------------------------
# Coverage state
# ---------------------------------------------------------------------------

class _Coverage:
    """Table / column / operation usage counts over the accepted queries."""

    def __init__(self) -> None:
        self.tables: Counter = Counter()
        self.columns: Counter = Counter()        # (table, column) -> count
        self.ops: Counter = Counter()
        self.queries = 0

    def add(self, sql: str, subschema: Tuple[str, ...], ctx: BaselineContext) -> None:
        feats = query_features(sql)
        used_tables = set(feats.get("tables") or []) or set(subschema)
        tokens = set(_tokens(sql))
        for t in used_tables:
            self.tables[t] += 1
        for t in subschema:
            if t not in used_tables:
                continue
            for col in ctx.columns_for(t):
                if col["name"].lower() in tokens:
                    self.columns[(t, col["name"])] += 1
        if feats.get("num_where"):
            self.ops["filter"] += 1
        if feats.get("num_group_by"):
            self.ops["group_by"] += 1
        if feats.get("num_order_by"):
            self.ops["order_by"] += 1
        if feats.get("num_having"):
            self.ops["having"] += 1
        if feats.get("num_aggregations"):
            self.ops["aggregation"] += 1
        if feats.get("num_joins"):
            self.ops["join"] += 1
        self.queries += 1

    def snapshot(self) -> Dict[str, Any]:
        return {
            "queries": self.queries,
            "columns": dict(self.columns),
            "ops": dict(self.ops),
        }


def _targeted_columns(
    ctx: BaselineContext, tables: Tuple[str, ...], snapshot: Optional[Dict[str, Any]],
    rng: random.Random, fraction: float, min_columns: int,
) -> Optional[Dict[str, List[str]]]:
    """
    Column subset per table for coverage-gap steering: key columns plus the
    least-referenced ``fraction`` of the remaining columns.  ``None`` (all
    columns) until a coverage report exists.
    """
    if not snapshot or not snapshot.get("queries"):
        return None
    counts = snapshot["columns"]
    out: Dict[str, List[str]] = {}
    for t in tables:
        keys = ctx.key_columns(t)
        others = [c["name"] for c in ctx.columns_for(t) if c["name"] not in keys]
        rng.shuffle(others)  # random tie-breaking
        others.sort(key=lambda c: counts.get((t, c), 0))
        k = max(min_columns, math.ceil(fraction * len(others)))
        out[t] = others[:k]
    return out


def _gap_operation(snapshot: Optional[Dict[str, Any]]) -> Optional[str]:
    if not snapshot or not snapshot.get("queries"):
        return None
    ops = snapshot["ops"]
    return min(_EXAMPLE_OPS, key=lambda o: ops.get(o, 0))


# ---------------------------------------------------------------------------
# Mechanical example generation
# ---------------------------------------------------------------------------

class _ValueCache:
    """Thread-safe cache of sampled column values for example filters."""

    def __init__(self, ctx: BaselineContext, limit: int = 20) -> None:
        self.ctx = ctx
        self.limit = limit
        self._data: Dict[Tuple[str, str], List[Any]] = {}
        self._lock = threading.Lock()

    def get(self, table: str, column: str) -> List[Any]:
        key = (table, column)
        with self._lock:
            if key in self._data:
                return self._data[key]
        vals = self.ctx.sample_column_values(table, column, limit=self.limit)
        with self._lock:
            self._data[key] = vals
        return vals


def _join_tree(
    tables: Tuple[str, ...], rels: List[tuple], rng: random.Random,
) -> Tuple[str, List[Tuple[str, str]]]:
    """
    Spanning tree of the subschema's FK edges: a base table plus, for every
    other table, ``(table, on_clause)`` joining it to an already-joined table.
    """
    base = rng.choice(list(tables))
    joined = {base}
    steps: List[Tuple[str, str]] = []
    remaining = list(rels)
    rng.shuffle(remaining)
    progress = True
    while progress and len(joined) < len(tables):
        progress = False
        for rel in list(remaining):
            lt, lcols, rt, rcols = rel
            if (lt in joined) == (rt in joined):
                continue
            new = rt if lt in joined else lt
            on = " AND ".join(f"{lt}.{a} = {rt}.{b}" for a, b in zip(lcols, rcols))
            steps.append((new, on))
            joined.add(new)
            remaining.remove(rel)
            progress = True
    return base, steps


def _mechanical_example(
    ctx: BaselineContext,
    tables: Tuple[str, ...],
    shown: Dict[str, List[dict]],
    ops: Dict[str, float],
    rng: random.Random,
    values: _ValueCache,
) -> str:
    """
    One valid SELECT built algorithmically from the subschema: all tables
    joined along FK edges, one projected column per table (up to four), and a
    filter / GROUP BY / ORDER BY each included with probability ``ops[op]``.
    Used only as a few-shot example (never emitted into the workload).
    """
    rels = get_relevant_relationships(ctx.schema_json, list(tables))
    base, steps = _join_tree(tables, rels, rng)
    order = [base] + [t for t, _ in steps]

    proj = []
    for t in order:
        cols = [c for c in shown.get(t, []) if c["name"] not in ctx.key_columns(t)] or shown.get(t, [])
        if cols:
            proj.append(f"{t}.{rng.choice(cols)['name']}")
    proj = proj[:4] or [f"{base}.*"]

    where = None
    if rng.random() < ops.get("filter", 0.0):
        candidates = [(t, c) for t in order for c in shown.get(t, [])
                      if type_kind(c["type"]) != "other" and c["name"] not in ctx.key_columns(t)]
        rng.shuffle(candidates)
        for t, c in candidates[:4]:
            vals = values.get(t, c["name"])
            if vals:
                op = "=" if type_kind(c["type"]) in ("string", "boolean") else rng.choice(["=", "<", ">", "<=", ">="])
                where = f"{t}.{c['name']} {op} {trino_literal(rng.choice(vals), c['type'])}"
                break

    group = rng.random() < ops.get("group_by", 0.0)
    order_by = rng.random() < ops.get("order_by", 0.0)

    if group:
        select = f"SELECT {proj[0]}, COUNT(*) AS cnt"
    else:
        select = f"SELECT {', '.join(proj)}"
    lines = [select, f"FROM {base}"]
    lines += [f"JOIN {t} ON {on}" for t, on in steps]
    if where:
        lines.append(f"WHERE {where}")
    if group:
        lines.append(f"GROUP BY {proj[0]}")
    if order_by:
        lines.append("ORDER BY cnt DESC" if group else f"ORDER BY {proj[0]}")
    lines.append("LIMIT 100")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# DataBuilder: few-shot prompt
# ---------------------------------------------------------------------------

def _build_prompt(
    ctx: BaselineContext,
    tables: Tuple[str, ...],
    *,
    n_shot: int,
    bias: str,
    snapshot: Optional[Dict[str, Any]],
    rng: random.Random,
    values: _ValueCache,
    column_fraction: float,
    min_columns: int,
) -> Tuple[str, Dict[str, Any]]:
    subset = _targeted_columns(ctx, tables, snapshot, rng, column_fraction, min_columns)
    ddl = ctx.ddl_with_keys(list(tables), subset)

    # columns visible in the DDL: the targeted subset plus the subschema's join keys
    join_keys: Dict[str, set] = {t: set() for t in tables}
    for lt, lcols, rt, rcols in get_relevant_relationships(ctx.schema_json, list(tables)):
        join_keys[lt].update(lcols)
        join_keys[rt].update(rcols)
    shown: Dict[str, List[dict]] = {}
    for t in tables:
        cols = ctx.columns_for(t)
        if subset is not None:
            keep = set(subset[t]) | join_keys[t]
            cols = [c for c in cols if c["name"] in keep]
        shown[t] = cols

    gap_op = _gap_operation(snapshot)
    ops = {op: _DEFAULT_OP_P for op in _EXAMPLE_OPS}
    if bias in ops:
        ops[bias] = _BIASED_CLAUSE_P
    if gap_op:
        ops[gap_op] = max(ops[gap_op], _BIASED_CLAUSE_P)

    if n_shot > 0:
        examples = [_mechanical_example(ctx, tables, shown, ops, rng, values) for _ in range(n_shot)]
        examples_block = "\nThese are some examples:\n" + "\n\n".join(examples) + "\n"
    else:
        examples_block = ""

    prompt = _BASE_PROMPT.format(
        ddl=ddl,
        table_list="\n".join(tables),
        bias=_CLAUSE_BIAS.get(bias, ""),
        examples_block=examples_block,
    )
    steering = {
        "targeted_columns": subset is not None,
        "gap_operation": gap_op,
    }
    return prompt, steering


def _generate(job, ctx, tables, n_shot, bias, temperature, seed, snapshot, values,
              column_fraction, min_columns, generations) -> List[Dict[str, Any]]:
    rng = random.Random(seed)
    prompt, steering = _build_prompt(
        ctx, tables, n_shot=n_shot, bias=bias, snapshot=snapshot, rng=rng,
        values=values, column_fraction=column_fraction, min_columns=min_columns,
    )
    out = []
    for g in range(generations):
        raw = ctx.responses_text(
            instructions=_INSTRUCTIONS,
            prompt=prompt,
            temperature=temperature,
        )
        out.append({
            "order": (job, g),
            "sql": sanitize_sql(raw),
            "tables": tables,
            "n_shot": n_shot,
            "bias": bias,
            "temperature": temperature,
            "steering": steering,
        })
    return out


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

def generate_workload(
    ctx: BaselineContext,
    *,
    workload_name: str,
    num_queries: int = 100,
    min_subschema: int = 2,
    max_subschema: int = 5,
    n_shot: int = 3,                 # DiGiT: 0-shot vs 3-shot settings
    zero_shot_fraction: float = 0.3,
    clause_bias: Optional[List[str]] = None,     # ["none","group_by","order_by"]
    temperatures: Optional[List[float]] = None,  # varied per prompt
    generations_per_prompt: int = 1,
    batch_size: int = 100,           # prompts per coverage iteration
    column_fraction: float = 0.5,    # share of non-key columns kept when steering
    min_columns: int = 3,
    generation_workers: int = 8,
    validation_workers: int = 8,
    max_rounds: Optional[int] = None,
    warmup: bool = True,
    random_seed: Optional[int] = None,
    workload_root=None,
) -> Dict[str, Any]:
    """Run the DiGiT SDG pipeline and write a workload directory + report."""
    started_at = datetime.now(timezone.utc)
    rng = random.Random(random_seed)
    clause_bias = clause_bias or ["none", "group_by", "order_by"]
    temperatures = temperatures or [0.6, 0.9]
    generations_per_prompt = max(1, int(generations_per_prompt))
    if max_rounds is None:
        max_rounds = max(12, 4 * math.ceil(num_queries / max(1, batch_size * generations_per_prompt)))

    if warmup:
        ctx.warm_up()

    schema_tables = ctx.schema_tables()
    graph = ctx.relationship_graph()

    # Create Subschema: every connected FK subschema in the size range.
    subschemas = enumerate_connected_subsets(
        schema_tables, graph, min_size=min_subschema, max_size=max_subschema,
    )
    fallback_subschemas = not subschemas
    if fallback_subschemas:  # no FK edges: single tables
        subschemas = [(t,) for t in schema_tables]
    rng.shuffle(subschemas)
    size_mix = Counter(len(s) for s in subschemas)

    values = _ValueCache(ctx)
    coverage = _Coverage()
    accepted: List[Dict[str, Any]] = []
    seen: set = set()
    rounds = 0
    cursor = 0                        # DataBuilder position in the subschema loop
    total_generated = 0
    total_duplicates = 0
    total_invalid = 0
    batch_log: List[Dict[str, Any]] = []

    while len(accepted) < num_queries and rounds < max_rounds:
        rounds += 1
        snapshot = coverage.snapshot()

        jobs = []
        for _ in range(batch_size):
            sub = subschemas[cursor % len(subschemas)]
            cursor += 1
            bias = rng.choice(clause_bias)
            temp = rng.choice(temperatures)
            shot = 0 if rng.random() < zero_shot_fraction else n_shot
            jobs.append((sub, shot, bias, temp, rng.randint(0, 10**9)))

        candidates: List[Dict[str, Any]] = []
        with ThreadPoolExecutor(max_workers=max(1, generation_workers)) as ex:
            futs = [
                ex.submit(_generate, j, ctx, sub, shot, bias, temp, seed, snapshot, values,
                          column_fraction, min_columns, generations_per_prompt)
                for j, (sub, shot, bias, temp, seed) in enumerate(jobs)
            ]
            for fut in as_completed(futs):
                try:
                    candidates.extend(fut.result())
                except Exception as e:
                    print(f"[bootstrapping_lcm] generation failed: {type(e).__name__}: {e}")
        total_generated += len(candidates)

        # Validators: dedup + syntactic correctness (EXPLAIN), in prompt order
        candidates.sort(key=lambda c: c["order"])
        deduped = []
        for c in candidates:
            key = " ".join(c["sql"].lower().split())
            if not key or key in seen:
                total_duplicates += 1
                continue
            seen.add(key)
            deduped.append(c)

        valid, invalid = ctx.validate_batch(deduped, workers=validation_workers)
        total_invalid += len(invalid)
        valid.sort(key=lambda c: c["order"])
        for c in valid:
            if len(accepted) >= num_queries:
                break
            coverage.add(c["sql"], c["tables"], ctx)
            accepted.append({
                "sql": c["sql"],
                "goal": "DiGiT synthetic LCM training query",
                "selected_tables": list(c["tables"]),
                "extra": {
                    "n_shot": c["n_shot"],
                    "clause_bias": c["bias"],
                    "temperature": c["temperature"],
                    "coverage_steering": c["steering"],
                },
            })

        batch_log.append({
            "round": rounds,
            "prompts": len(jobs),
            "generated": len(candidates),
            "valid": len(valid),
            "accepted_total": len(accepted),
            "steered": bool(snapshot["queries"]),
            "gap_operation": _gap_operation(snapshot),
        })

        if not candidates:
            break

    accepted = accepted[:num_queries]
    n_tables = len(schema_tables)

    pipeline_report = {
        "method": "Bootstrapping-LCM / DiGiT (Nidd et al., VLDB AIDB 2025)",
        "steps": [
            "preprocessing (schema + FK graph)",
            "create subschema (all connected FK subschemas in the size range, shuffled)",
            "DataBuilder loop over subschemas: Figure 2 prompt with CREATE TABLE + FK clauses, "
            "clause-bias constraint, mechanically generated examples",
            "validators (dedup + Trino EXPLAIN)",
            "coverage report per batch -> targeted column subsets + example tuning towards gaps",
        ],
        "subschemas": {
            "size_range": [min_subschema, max_subschema],
            "enumerated": len(subschemas),
            "size_mix": dict(sorted(size_mix.items())),
            "prompted": min(cursor, len(subschemas)),
            "wrapped_around": cursor > len(subschemas),
            "no_fk_fallback": fallback_subschemas,
        },
        "prompting": {
            "n_shot": n_shot,
            "zero_shot_fraction": zero_shot_fraction,
            "clause_bias_options": clause_bias,
            "biased_clause_probability": _BIASED_CLAUSE_P,
            "temperatures": temperatures,
            "generations_per_prompt": generations_per_prompt,
            "batch_size": batch_size,
            "example_source": "mechanically generated from subschema (FK spanning-tree joins)",
        },
        "coverage": {
            "table_usage": dict(coverage.tables),
            "tables_covered": len(coverage.tables),
            "tables_total": n_tables,
            "columns_covered": len(coverage.columns),
            "operator_usage": dict(coverage.ops),
            "column_fraction": column_fraction,
            "batches": batch_log,
        },
        "counts": {
            "rounds": rounds,
            "total_generated": total_generated,
            "duplicates_removed": total_duplicates,
            "invalid": total_invalid,
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
